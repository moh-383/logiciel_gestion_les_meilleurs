from datetime import datetime

from django.db.models import Avg, Case, Count, F, FloatField, When
from django.db.models.functions import Cast

from .models import AffectationEnseignant, Creneau, Seance
from .serializers import CreneauSerializer, SeanceCreateSerializer, SeanceSerializer


class CreneauxView(generics.ListCreateAPIView):
    serializer_class = CreneauSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_enseignants"

    def get_affectation(self):
        affectation = AffectationEnseignant.objects.select_related("site").get(pk=self.kwargs["pk"])
        if not dans_perimetre(self.request.user, affectation.site_id):
            raise PermissionDenied("Affectation hors de votre périmètre.")
        return affectation

    def get_queryset(self):
        return self.get_affectation().creneaux.filter(actif=True).order_by("jour_semaine", "heure_debut")

    def perform_create(self, serializer):
        serializer.save(affectation=self.get_affectation())


class CreneauDetailView(generics.RetrieveUpdateAPIView):
    serializer_class = CreneauSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_enseignants"

    def get_queryset(self):
        return Creneau.objects.select_related("affectation__site")

    def get_object(self):
        creneau = super().get_object()
        if not dans_perimetre(self.request.user, creneau.affectation.site_id):
            raise PermissionDenied("Créneau hors de votre périmètre.")
        return creneau


class MonPlanningView(generics.ListAPIView):
    serializer_class = CreneauSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "voir_pedagogie"

    def get_queryset(self):
        return Creneau.objects.filter(
            affectation__enseignant=self.request.user,
            affectation__actif=True,
            actif=True,
        ).order_by("jour_semaine", "heure_debut")


class SeanceCreateView(APIView):
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "voir_pedagogie"

    def post(self, request):
        serializer = SeanceCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            affectation = AffectationEnseignant.objects.get(pk=data["affectation_id"])
        except AffectationEnseignant.DoesNotExist:
            raise ValidationError({"affectation_id": "Affectation introuvable."})

        # Un enseignant ne peut déclarer une séance que sur SA PROPRE
        # affectation — jamais au nom d'un collègue.
        if affectation.enseignant_id != request.user.id:
            raise PermissionDenied("Cette affectation ne vous appartient pas.")

        creneau = None
        if data.get("creneau_id"):
            creneau = Creneau.objects.filter(pk=data["creneau_id"], affectation=affectation).first()
            if creneau is None:
                raise ValidationError({"creneau_id": "Créneau introuvable pour cette affectation."})

        seance, _ = Seance.objects.update_or_create(
            affectation=affectation,
            date_seance=data["date_seance"],
            defaults={
                "creneau": creneau,
                "statut": data["statut"],
                "nb_presents": data.get("nb_presents"),
                "nb_absents": data.get("nb_absents"),
                "commentaire": data.get("commentaire", ""),
            },
        )
        return Response(SeanceSerializer(seance).data, status=status.HTTP_201_CREATED)


class RapportMensuelEnseignantView(APIView):
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_enseignants"

    def get(self, request, pk):
        enseignant = Utilisateur.objects.get(pk=pk)
        if not dans_perimetre(request.user, enseignant.site_id):
            raise PermissionDenied("Enseignant hors de votre périmètre.")

        mois = request.query_params.get("mois")
        try:
            debut = datetime.strptime(mois, "%Y-%m").date()
        except (TypeError, ValueError):
            raise ValidationError({"mois": "Format attendu : YYYY-MM."})
        fin = (debut.replace(day=28) + timedelta(days=4)).replace(day=1)

        seances = Seance.objects.filter(
            affectation__enseignant=enseignant,
            date_seance__gte=debut,
            date_seance__lt=fin,
        )

        nb_tenues = seances.filter(statut="tenue").count()
        nb_annulees = seances.filter(statut="annulee").count()

        presence = seances.filter(
            statut="tenue", nb_presents__isnull=False, nb_absents__isnull=False
        ).annotate(
            taux=Case(
                When(nb_presents=0, nb_absents=0, then=None),
                default=Cast(F("nb_presents"), FloatField())
                / (Cast(F("nb_presents"), FloatField()) + Cast(F("nb_absents"), FloatField())),
                output_field=FloatField(),
            )
        ).aggregate(moyenne=Avg("taux"))

        return Response({
            "enseignant_id": str(enseignant.id),
            "mois": mois,
            "nb_seances_tenues": nb_tenues,
            "nb_seances_annulees": nb_annulees,
            "taux_presence_moyen": presence["moyenne"],
        })