from datetime import datetime, timedelta

from django.db.models import Avg, Case, F, FloatField, Q, When
from django.db.models.functions import Cast
from rest_framework import generics, status
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import Utilisateur
from core.permissions import ALaPermissionMetier, dans_perimetre
from .models import AffectationEnseignant, Creneau, Seance
from .serializers import AffectationSerializer, CreneauSerializer, EnseignantSerializer, SeanceCreateSerializer, SeanceSerializer


class EnseignantListView(generics.ListAPIView):
    serializer_class, permission_classes, permission_metier = EnseignantSerializer, (ALaPermissionMetier,), "gerer_enseignants"
    def get_queryset(self):
        qs = Utilisateur.objects.filter(poste__permissions__code="voir_pedagogie").prefetch_related("affectations_enseignement")
        if not self.request.user.tous_sites:
            qs = qs.filter(Q(site_id=self.request.user.site_id) | Q(affectations_enseignement__site_id=self.request.user.site_id))
        if site_id := self.request.query_params.get("site_id"):
            qs = qs.filter(affectations_enseignement__site_id=site_id)
        return qs.distinct().order_by("nom")


class EnseignantDetailView(generics.RetrieveAPIView):
    serializer_class, permission_classes, permission_metier = EnseignantSerializer, (ALaPermissionMetier,), "gerer_enseignants"
    queryset = Utilisateur.objects.prefetch_related("affectations_enseignement")
    def get_object(self):
        enseignant = super().get_object()
        if not self.request.user.tous_sites and not enseignant.affectations_enseignement.filter(site_id=self.request.user.site_id).exists():
            raise PermissionDenied("Enseignant hors de votre périmètre.")
        return enseignant


class AffectationsCreateView(generics.CreateAPIView):
    serializer_class, permission_classes, permission_metier = AffectationSerializer, (ALaPermissionMetier,), "gerer_enseignants"
    def perform_create(self, serializer):
        enseignant = Utilisateur.objects.get(pk=self.kwargs["pk"])
        site_id = self.request.data.get("site_id")
        if not dans_perimetre(self.request.user, site_id):
            raise PermissionDenied("Site hors de votre périmètre.")
        serializer.save(enseignant=enseignant, site_id=site_id)


class AffectationDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class, permission_classes, permission_metier = AffectationSerializer, (ALaPermissionMetier,), "gerer_enseignants"
    queryset = AffectationEnseignant.objects.select_related("site")
    def get_object(self):
        affectation = super().get_object()
        if not dans_perimetre(self.request.user, affectation.site_id):
            raise PermissionDenied("Affectation hors de votre périmètre.")
        return affectation


class CreneauxView(generics.ListCreateAPIView):
    serializer_class, permission_classes, permission_metier = CreneauSerializer, (ALaPermissionMetier,), "gerer_enseignants"
    def get_affectation(self):
        try:
            affectation = AffectationEnseignant.objects.select_related("site").get(pk=self.kwargs["pk"])
        except AffectationEnseignant.DoesNotExist:
            raise ValidationError({"affectation_id": "Affectation introuvable."})
        if not dans_perimetre(self.request.user, affectation.site_id):
            raise PermissionDenied("Affectation hors de votre périmètre.")
        return affectation
    def get_queryset(self):
        return self.get_affectation().creneaux.filter(actif=True).order_by("jour_semaine", "heure_debut")
    def perform_create(self, serializer):
        serializer.save(affectation=self.get_affectation())


class CreneauDetailView(generics.RetrieveUpdateAPIView):
    serializer_class, permission_classes, permission_metier = CreneauSerializer, (ALaPermissionMetier,), "gerer_enseignants"
    queryset = Creneau.objects.select_related("affectation__site")
    def get_object(self):
        creneau = super().get_object()
        if not dans_perimetre(self.request.user, creneau.affectation.site_id):
            raise PermissionDenied("Créneau hors de votre périmètre.")
        return creneau


class MonPlanningView(generics.ListAPIView):
    serializer_class, permission_classes, permission_metier = CreneauSerializer, (ALaPermissionMetier,), "voir_pedagogie"
    def get_queryset(self):
        return Creneau.objects.filter(affectation__enseignant=self.request.user, affectation__actif=True, actif=True).order_by("jour_semaine", "heure_debut")


class MesAffectationsView(generics.ListAPIView):
    serializer_class, permission_classes, permission_metier = AffectationSerializer, (ALaPermissionMetier,), "voir_pedagogie"

    def get_queryset(self):
        return AffectationEnseignant.objects.filter(enseignant=self.request.user, actif=True).order_by("annee_scolaire", "classe", "matiere")


class MesSeancesView(generics.ListAPIView):
    serializer_class, permission_classes, permission_metier = SeanceSerializer, (ALaPermissionMetier,), "voir_pedagogie"

    def get_queryset(self):
        return Seance.objects.filter(affectation__enseignant=self.request.user).select_related("affectation").order_by("-date_seance")


class SeanceCreateView(APIView):
    permission_classes, permission_metier = (ALaPermissionMetier,), "voir_pedagogie"
    def post(self, request):
        serializer = SeanceCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        try:
            affectation = AffectationEnseignant.objects.get(pk=data["affectation_id"], actif=True)
        except AffectationEnseignant.DoesNotExist:
            raise ValidationError({"affectation_id": "Affectation introuvable ou inactive."})
        if affectation.enseignant_id != request.user.id:
            raise PermissionDenied("Cette affectation ne vous appartient pas.")
        creneau = None
        if data.get("creneau_id"):
            creneau = Creneau.objects.filter(pk=data["creneau_id"], affectation=affectation, actif=True).first()
            if creneau is None:
                raise ValidationError({"creneau_id": "Créneau introuvable pour cette affectation."})
        seance, _ = Seance.objects.update_or_create(affectation=affectation, date_seance=data["date_seance"], defaults={"creneau": creneau, "statut": data["statut"], "nb_presents": data.get("nb_presents"), "nb_absents": data.get("nb_absents"), "commentaire": data.get("commentaire", "")})
        return Response(SeanceSerializer(seance).data, status=status.HTTP_201_CREATED)


class RapportMensuelEnseignantView(APIView):
    permission_classes, permission_metier = (ALaPermissionMetier,), "gerer_enseignants"
    def get(self, request, pk):
        enseignant = Utilisateur.objects.get(pk=pk)
        if not request.user.tous_sites and not enseignant.affectations_enseignement.filter(site_id=request.user.site_id).exists():
            raise PermissionDenied("Enseignant hors de votre périmètre.")
        mois = request.query_params.get("mois")
        try:
            debut = datetime.strptime(mois, "%Y-%m").date().replace(day=1)
        except (TypeError, ValueError):
            raise ValidationError({"mois": "Format attendu : YYYY-MM."})
        fin = (debut.replace(day=28) + timedelta(days=4)).replace(day=1)
        seances = Seance.objects.filter(affectation__enseignant=enseignant, date_seance__gte=debut, date_seance__lt=fin)
        presence = seances.filter(statut="tenue", nb_presents__isnull=False, nb_absents__isnull=False).annotate(taux=Case(When(nb_presents=0, nb_absents=0, then=None), default=Cast(F("nb_presents"), FloatField()) / (Cast(F("nb_presents"), FloatField()) + Cast(F("nb_absents"), FloatField())), output_field=FloatField())).aggregate(moyenne=Avg("taux"))
        return Response({"enseignant_id": str(enseignant.id), "mois": mois, "nb_seances_tenues": seances.filter(statut="tenue").count(), "nb_seances_annulees": seances.filter(statut="annulee").count(), "taux_presence_moyen": presence["moyenne"]})


class MonRapportMensuelView(RapportMensuelEnseignantView):
    permission_metier = "voir_pedagogie"

    def get(self, request):
        # Un enseignant ne consulte que ses propres données ; le calcul reste
        # exactement le même que le rapport consulté par la direction.
        mois = request.query_params.get("mois")
        try:
            debut = datetime.strptime(mois, "%Y-%m").date().replace(day=1)
        except (TypeError, ValueError):
            raise ValidationError({"mois": "Format attendu : YYYY-MM."})
        fin = (debut.replace(day=28) + timedelta(days=4)).replace(day=1)
        seances = Seance.objects.filter(affectation__enseignant=request.user, date_seance__gte=debut, date_seance__lt=fin)
        presence = seances.filter(statut="tenue", nb_presents__isnull=False, nb_absents__isnull=False).annotate(taux=Case(When(nb_presents=0, nb_absents=0, then=None), default=Cast(F("nb_presents"), FloatField()) / (Cast(F("nb_presents"), FloatField()) + Cast(F("nb_absents"), FloatField())), output_field=FloatField())).aggregate(moyenne=Avg("taux"))
        return Response({"enseignant_id": str(request.user.id), "mois": mois, "nb_seances_tenues": seances.filter(statut="tenue").count(), "nb_seances_annulees": seances.filter(statut="annulee").count(), "taux_presence_moyen": presence["moyenne"]})
