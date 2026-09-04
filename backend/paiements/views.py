from django.db import IntegrityError, transaction
from django.db.models import Count, Sum
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import Site
from core.permissions import ALaPermissionMetier
from eleves.models import Eleve
from .models import DemandeValidation, Paiement
from .serializers import (DemandeValidationSerializer, PaiementEcritureSerializer,
                          PaiementSerializer, PaiementSyncSerializer, TraitementDemandeSerializer)
from .services import enregistrer_paiement, recalculer_statut_echeance


def _site_accessible(user, site_id):
    return user.tous_sites or user.site_id == site_id


class PaiementCreateView(APIView):
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "saisir_paiement"

    def post(self, request):
        serializer = PaiementEcritureSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        paiement, cree = enregistrer_paiement(data=serializer.validated_data, utilisateur=request.user)
        return Response(PaiementSerializer(paiement).data, status=status.HTTP_201_CREATED if cree else status.HTTP_200_OK)


class PaiementsSyncView(APIView):
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "saisir_paiement"

    def post(self, request):
        entries = request.data.get("paiements")
        if not isinstance(entries, list) or not entries:
            raise ValidationError({"paiements": "Une liste non vide est obligatoire."})
        resultats = []
        for entry in entries:
            serializer = PaiementSyncSerializer(data=entry)
            if not serializer.is_valid():
                resultats.append({"client_uuid": entry.get("client_uuid"), "statut": "conflit", "raison": serializer.errors})
                continue
            try:
                paiement, _ = enregistrer_paiement(data=serializer.validated_data, utilisateur=request.user)
                resultats.append({"client_uuid": str(paiement.client_uuid), "statut": "cree", "paiement_id": str(paiement.id)})
            except (ValidationError, IntegrityError) as exc:
                resultats.append({"client_uuid": entry.get("client_uuid"), "statut": "conflit", "raison": getattr(exc, "detail", str(exc))})
        return Response({"resultats": resultats})


class PaiementsEleveView(generics.ListAPIView):
    serializer_class = PaiementSerializer

    def get_queryset(self):
        eleve = Eleve.objects.get(pk=self.kwargs["pk"])
        if not _site_accessible(self.request.user, eleve.site_id):
            raise PermissionDenied("Élève hors de votre périmètre.")
        return Paiement.objects.filter(echeance__eleve=eleve).select_related("echeance").order_by("-date_paiement")


class PaiementsSiteView(generics.ListAPIView):
    serializer_class = PaiementSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "voir_finances"

    def get_queryset(self):
        site = Site.objects.get(pk=self.kwargs["pk"])
        if not _site_accessible(self.request.user, site.id):
            raise PermissionDenied("Site hors de votre périmètre.")
        qs = Paiement.objects.filter(echeance__eleve__site=site).select_related("echeance").order_by("-date_paiement")
        if statut := self.request.query_params.get("statut"):
            qs = qs.filter(echeance__statut=statut)
        return qs


class StatsPaiementsSiteView(APIView):
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "voir_finances"

    def get(self, request, pk):
        site = Site.objects.get(pk=pk)
        if not _site_accessible(request.user, site.id):
            raise PermissionDenied("Site hors de votre périmètre.")
        echeances = site.eleves.prefetch_related("echeances").values("echeances__montant_du", "echeances__statut")
        montant_attendu = sum((item["echeances__montant_du"] or 0 for item in echeances), 0)
        paiements = Paiement.objects.filter(echeance__eleve__site=site, statut="valide")
        montant_collecte = paiements.aggregate(total=Sum("montant"))["total"] or 0
        statuts = site.eleves.values("echeances__statut").annotate(total=Count("echeances"))
        compteurs = {item["echeances__statut"]: item["total"] for item in statuts}
        return Response({"effectif": site.eleves.count(), "montant_collecte": montant_collecte, "montant_attendu": montant_attendu, "taux_recouvrement": float(montant_collecte / montant_attendu) if montant_attendu else 0, "nb_en_retard": compteurs.get("retard", 0), "nb_partiel": compteurs.get("partiel", 0)})


class DemandeAnnulationView(APIView):
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "saisir_paiement"

    def post(self, request, pk):
        paiement = Paiement.objects.select_related("echeance__eleve").get(pk=pk)
        if not _site_accessible(request.user, paiement.echeance.eleve.site_id):
            raise PermissionDenied("Paiement hors de votre périmètre.")
        if paiement.statut == "annule":
            raise ValidationError("Ce paiement est déjà annulé.")
        motif = request.data.get("motif", "").strip()
        if not motif:
            raise ValidationError({"motif": "Le motif est obligatoire."})
        try:
            demande = DemandeValidation.objects.create(paiement=paiement, demandeur=request.user, motif=motif)
        except IntegrityError:
            raise ValidationError("Une demande d'annulation est déjà en attente.")
        return Response(DemandeValidationSerializer(demande).data, status=status.HTTP_201_CREATED)


class DemandesValidationView(generics.ListAPIView):
    serializer_class = DemandeValidationSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "valider_actions_sensibles"

    def get_queryset(self):
        qs = DemandeValidation.objects.select_related("paiement__echeance__eleve").order_by("-date_demande")
        if not self.request.user.tous_sites:
            qs = qs.filter(paiement__echeance__eleve__site_id=self.request.user.site_id)
        for field in ("statut",):
            if value := self.request.query_params.get(field):
                qs = qs.filter(**{field: value})
        if site_id := self.request.query_params.get("site_id"):
            qs = qs.filter(paiement__echeance__eleve__site_id=site_id)
        return qs


class DemandeValidationDetailView(APIView):
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "valider_actions_sensibles"

    def get_object(self, pk):
        demande = DemandeValidation.objects.select_related("paiement__echeance__eleve").get(pk=pk)
        if not _site_accessible(self.request.user, demande.paiement.echeance.eleve.site_id):
            raise PermissionDenied("Demande hors de votre périmètre.")
        return demande

    def get(self, request, pk):
        return Response(DemandeValidationSerializer(self.get_object(pk)).data)

    @transaction.atomic
    def patch(self, request, pk):
        demande = self.get_object(pk)
        serializer = TraitementDemandeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        if demande.statut != "en_attente":
            raise ValidationError("Cette demande a déjà été traitée.")
        demande.statut = serializer.validated_data["statut"]
        demande.commentaire = serializer.validated_data.get("commentaire", "")
        demande.valideur = request.user
        demande.date_traitement = timezone.now()
        demande.save()
        if demande.statut == "validee":
            paiement = Paiement.objects.select_for_update().select_related("echeance").get(pk=demande.paiement_id)
            paiement.statut = "annule"
            paiement.save(update_fields=("statut",))
            recalculer_statut_echeance(paiement.echeance)
        return Response(DemandeValidationSerializer(demande).data)
