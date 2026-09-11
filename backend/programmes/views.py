from django.db.models import Avg, Count, F, Q, Sum
from django.db.models.functions import Cast
from rest_framework import generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions import ALaPermissionMetier, dans_perimetre
from eleves.models import Echeance
from paiements.models import Paiement

from .models import GroupeProgramme, InscriptionProgramme, Programme, ResultatExamen, SeanceProgramme, SessionProgramme, TarifProgramme
from .serializers import GroupeSerializer, InscriptionSerializer, ProgrammeSerializer, ResultatExamenSerializer, SeanceProgrammeSerializer, SessionSerializer, TarifSerializer
from .services import annuler_inscription, annuler_session, confirmer_inscription


def _verifier_modifiable(session):
    if session.statut in ("cloture", "termine", "archive", "annule"):
        raise ValidationError("Une session clôturée, terminée, archivée ou annulée n'est plus modifiable.")


class ProgrammeViewSet(viewsets.ModelViewSet):
    serializer_class = ProgrammeSerializer
    permission_classes = (ALaPermissionMetier,)
    queryset = Programme.objects.all()

    def get_permissions(self):
        self.permission_metier = "gerer_programmes" if self.request.method not in ("GET", "HEAD", "OPTIONS") else "voir_programmes"
        return super().get_permissions()

    @action(detail=True, methods=["post"])
    def ouvrir(self, request, pk=None):
        programme = self.get_object()
        if programme.statut not in ("brouillon", "cloture"):
            raise ValidationError("Seul un programme brouillon ou clôturé peut être ouvert.")
        programme.statut = "ouvert"
        programme.save(update_fields=("statut",))
        return Response(self.get_serializer(programme).data)


class SessionsProgrammeView(generics.ListCreateAPIView):
    serializer_class = SessionSerializer
    permission_classes = (ALaPermissionMetier,)

    def get_permissions(self):
        self.permission_metier = "gerer_programmes" if self.request.method == "POST" else "voir_programmes"
        return super().get_permissions()

    def get_programme(self):
        return Programme.objects.get(pk=self.kwargs["pk"])

    def get_queryset(self):
        qs = SessionProgramme.objects.filter(programme=self.get_programme()).select_related("programme", "site")
        if not self.request.user.tous_sites:
            qs = qs.filter(site_id=self.request.user.site_id)
        return qs

    def perform_create(self, serializer):
        site_id = self.request.data.get("site_id")
        if not dans_perimetre(self.request.user, site_id):
            raise PermissionDenied("Site hors de votre périmètre.")
        serializer.save(programme=self.get_programme(), site_id=site_id)


class SessionProgrammeDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = SessionSerializer
    permission_classes = (ALaPermissionMetier,)
    queryset = SessionProgramme.objects.select_related("programme", "site")

    def get_permissions(self):
        self.permission_metier = "gerer_programmes" if self.request.method != "GET" else "voir_programmes"
        return super().get_permissions()

    def get_object(self):
        obj = super().get_object()
        if not dans_perimetre(self.request.user, obj.site_id):
            raise PermissionDenied("Session hors de votre périmètre.")
        return obj

    def perform_update(self, serializer):
        session = self.get_object()
        if "statut" in serializer.validated_data:
            raise ValidationError({"statut": "Utilisez les actions ouvrir, clôturer, terminer ou annuler."})
        if set(serializer.validated_data) - {"notes_bilan"}:
            _verifier_modifiable(session)
        serializer.save()


class SessionTransitionView(APIView):
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_programmes"

    def post(self, request, pk, action):
        session = SessionProgramme.objects.select_related("programme", "site").get(pk=pk)
        if not dans_perimetre(request.user, session.site_id):
            raise PermissionDenied("Session hors de votre périmètre.")
        if action == "annuler":
            return Response(SessionSerializer(annuler_session(session=session)).data)
        transitions = {
            "ouvrir": (("brouillon", "cloture"), "ouvert"),
            "cloturer": (("ouvert", "complet"), "cloture"),
            "terminer": (("cloture",), "termine"),
            "archiver": (("termine", "annule"), "archive"),
        }
        autorises, cible = transitions.get(action, ((), None))
        if cible is None or session.statut not in autorises:
            raise ValidationError("Transition de statut non autorisée.")
        if action == "ouvrir" and session.programme.statut != "ouvert":
            raise ValidationError("Le programme parent doit être ouvert.")
        session.statut = cible
        session.save(update_fields=("statut",))
        return Response(SessionSerializer(session).data)


class GroupesSessionView(generics.ListCreateAPIView):
    serializer_class = GroupeSerializer
    permission_classes = (ALaPermissionMetier,)

    def get_session(self):
        session = SessionProgramme.objects.select_related("site").get(pk=self.kwargs["pk"])
        if not dans_perimetre(self.request.user, session.site_id):
            raise PermissionDenied("Session hors de votre périmètre.")
        return session

    def get_permissions(self):
        self.permission_metier = "gerer_programmes" if self.request.method == "POST" else "voir_programmes"
        return super().get_permissions()

    def get_queryset(self):
        return self.get_session().groupes.select_related("enseignant").all()

    def perform_create(self, serializer):
        session = self.get_session()
        _verifier_modifiable(session)
        serializer.save(session=session)


class GroupeDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = GroupeSerializer
    permission_classes = (ALaPermissionMetier,)
    queryset = GroupeProgramme.objects.select_related("session__site")

    def get_permissions(self):
        self.permission_metier = "gerer_programmes" if self.request.method != "GET" else "voir_programmes"
        return super().get_permissions()

    def get_object(self):
        obj = super().get_object()
        if not dans_perimetre(self.request.user, obj.session.site_id):
            raise PermissionDenied("Groupe hors de votre périmètre.")
        return obj

    def perform_update(self, serializer):
        _verifier_modifiable(self.get_object().session)
        serializer.save()


class TarifViewSet(viewsets.ModelViewSet):
    serializer_class = TarifSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_tarifs"

    def get_queryset(self):
        qs = TarifProgramme.objects.select_related("site", "programme", "groupe__session")
        if not self.request.user.tous_sites:
            qs = qs.filter(site_id=self.request.user.site_id)
        return qs

    def perform_create(self, serializer):
        site = serializer.validated_data["site"]
        groupe = serializer.validated_data.get("groupe")
        if not dans_perimetre(self.request.user, site.id):
            raise PermissionDenied("Site hors de votre périmètre.")
        if groupe and groupe.session.site_id != site.id:
            raise ValidationError({"groupe": "Le groupe doit appartenir au site du tarif."})
        serializer.save()


class InscriptionsView(generics.ListCreateAPIView):
    serializer_class = InscriptionSerializer
    permission_classes = (ALaPermissionMetier,)

    def get_permissions(self):
        self.permission_metier = "inscrire_programmes" if self.request.method == "POST" else "voir_programmes"
        return super().get_permissions()

    def get_queryset(self):
        qs = InscriptionProgramme.objects.select_related("eleve", "groupe__session__programme", "echeance_programme")
        if not self.request.user.tous_sites:
            qs = qs.filter(groupe__session__site_id=self.request.user.site_id)
        for field in ("eleve_id", "groupe_id", "statut"):
            if value := self.request.query_params.get(field):
                qs = qs.filter(**{field: value})
        if programme_id := self.request.query_params.get("programme_id"):
            qs = qs.filter(groupe__session__programme_id=programme_id)
        return qs.order_by("-date_inscription")

    def perform_create(self, serializer):
        groupe = serializer.validated_data["groupe"]
        eleve = serializer.validated_data["eleve"]
        if not dans_perimetre(self.request.user, groupe.session.site_id) or eleve.site_id != groupe.session.site_id:
            raise PermissionDenied("L'élève et le groupe doivent relever de votre site.")
        serializer.save(statut="brouillon")


class InscriptionDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = InscriptionSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "inscrire_programmes"
    queryset = InscriptionProgramme.objects.select_related("eleve", "groupe__session", "echeance_programme")

    def get_object(self):
        obj = super().get_object()
        if not dans_perimetre(self.request.user, obj.groupe.session.site_id):
            raise PermissionDenied("Inscription hors de votre périmètre.")
        return obj

    def perform_update(self, serializer):
        if self.get_object().statut == "confirmee":
            raise ValidationError("Une inscription confirmée ne peut plus être modifiée.")
        serializer.save()


class InscriptionConfirmerView(APIView):
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "inscrire_programmes"

    def post(self, request, pk):
        inscription = InscriptionProgramme.objects.select_related("groupe__session").get(pk=pk)
        if not dans_perimetre(request.user, inscription.groupe.session.site_id):
            raise PermissionDenied("Inscription hors de votre périmètre.")
        inscription = confirmer_inscription(inscription=inscription, utilisateur=request.user)
        return Response(InscriptionSerializer(inscription).data)


class InscriptionAnnulerView(APIView):
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "inscrire_programmes"

    def post(self, request, pk):
        inscription = InscriptionProgramme.objects.select_related("groupe__session").get(pk=pk)
        if not dans_perimetre(request.user, inscription.groupe.session.site_id):
            raise PermissionDenied("Inscription hors de votre périmètre.")
        inscription = annuler_inscription(inscription=inscription, utilisateur=request.user, motif=request.data.get("motif", ""))
        return Response(InscriptionSerializer(inscription).data)


class SeancesGroupeView(generics.ListCreateAPIView):
    serializer_class = SeanceProgrammeSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_programmes"

    def get_groupe(self):
        groupe = GroupeProgramme.objects.select_related("session__site").get(pk=self.kwargs["pk"])
        if not dans_perimetre(self.request.user, groupe.session.site_id):
            raise PermissionDenied("Groupe hors de votre périmètre.")
        if groupe.enseignant_id and groupe.enseignant_id != self.request.user.id and not self.request.user.a_permission("gerer_programmes"):
            raise PermissionDenied("Seul l'enseignant affecté peut déclarer cette séance.")
        return groupe

    def get_queryset(self):
        return self.get_groupe().seances.all()

    def perform_create(self, serializer):
        serializer.save(groupe=self.get_groupe())


class TableauBordProgrammeView(APIView):
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "voir_programmes"

    def get(self, request, pk):
        session = SessionProgramme.objects.get(pk=pk)
        if not dans_perimetre(request.user, session.site_id):
            raise PermissionDenied("Session hors de votre périmètre.")
        inscriptions = InscriptionProgramme.objects.filter(groupe__session=session, statut="confirmee")
        echeances = Echeance.objects.filter(inscription_programme__groupe__session=session)
        attendu = echeances.exclude(statut="annulee").aggregate(total=Sum("montant_du"))["total"] or 0
        encaisse = Paiement.objects.filter(echeance__in=echeances, statut="valide").aggregate(total=Sum("montant"))["total"] or 0
        seances = SeanceProgramme.objects.filter(groupe__session=session)
        presents = seances.aggregate(total=Sum("nb_presents"))["total"] or 0
        absents = seances.aggregate(total=Sum("nb_absents"))["total"] or 0
        return Response({"session_id": str(session.id), "effectif_inscrit": inscriptions.values("eleve_id").distinct().count(), "capacite": session.capacite, "taux_remplissage": float(inscriptions.values("eleve_id").distinct().count() / session.capacite) if session.capacite else 0, "montant_attendu": attendu, "montant_encaisse": encaisse, "montant_restant": attendu - encaisse, "seances_tenues": seances.count(), "taux_presence_agrege": float(presents / (presents + absents)) if presents + absents else None})


class ResultatsExamenView(generics.ListCreateAPIView):
    serializer_class = ResultatExamenSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "saisir_resultats_examens"

    def get_queryset(self):
        qs = ResultatExamen.objects.select_related("inscription__eleve", "inscription__groupe__session__programme")
        if not self.request.user.tous_sites:
            qs = qs.filter(inscription__groupe__session__site_id=self.request.user.site_id)
        if programme_id := self.request.query_params.get("programme_id"):
            qs = qs.filter(inscription__groupe__session__programme_id=programme_id)
        return qs

    def perform_create(self, serializer):
        inscription = serializer.validated_data["inscription"]
        if not dans_perimetre(self.request.user, inscription.groupe.session.site_id):
            raise PermissionDenied("Inscription hors de votre périmètre.")
        serializer.save(saisi_par=self.request.user)


class ResultatExamenDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = ResultatExamenSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "saisir_resultats_examens"
    queryset = ResultatExamen.objects.select_related("inscription__groupe__session")

    def get_object(self):
        obj = super().get_object()
        if not dans_perimetre(self.request.user, obj.inscription.groupe.session.site_id):
            raise PermissionDenied("Résultat hors de votre périmètre.")
        return obj


class StatistiquesExamenView(APIView):
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "voir_programmes"

    def get(self, request, pk):
        programme = Programme.objects.get(pk=pk, type__in=("bac", "bepc"))
        inscriptions = InscriptionProgramme.objects.filter(groupe__session__programme=programme, statut="confirmee")
        if not request.user.tous_sites:
            inscriptions = inscriptions.filter(groupe__session__site_id=request.user.site_id)
        resultats = ResultatExamen.objects.filter(inscription__in=inscriptions)
        total = inscriptions.count()
        saisis = resultats.count()
        admis = resultats.filter(note__gte=10).count()
        par_matiere = list(resultats.values("inscription__groupe__matiere").annotate(candidats=Count("id"), moyenne=Avg("note"), admis=Count("id", filter=Q(note__gte=10))).order_by("inscription__groupe__matiere"))
        return Response({"programme_id": str(programme.id), "programme": programme.nom, "type": programme.type, "candidats": total, "resultats_saisis": saisis, "admis": admis, "taux_reussite": float(admis / saisis) if saisis else None, "moyenne": resultats.aggregate(moyenne=Avg("note"))["moyenne"], "par_matiere": [{"matiere": x["inscription__groupe__matiere"] or "Général", "candidats": x["candidats"], "admis": x["admis"], "moyenne": x["moyenne"]} for x in par_matiere]})
