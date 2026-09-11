import uuid

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class AffectationEnseignant(models.Model):
    """Affectation d'un enseignant à une classe, sur un site donné."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    enseignant = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="affectations_enseignement")
    site = models.ForeignKey("core.Site", on_delete=models.PROTECT, related_name="affectations")
    classe = models.CharField(max_length=120)
    matiere = models.CharField(max_length=120, blank=True)
    annee_scolaire = models.CharField(max_length=9)
    actif = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("annee_scolaire", "classe", "matiere")
        constraints = [models.UniqueConstraint(fields=("enseignant", "site", "classe", "matiere", "annee_scolaire"), name="affectation_enseignant_unique")]

    def __str__(self):
        return f"{self.enseignant} — {self.classe} ({self.matiere})"


class Creneau(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    affectation = models.ForeignKey(AffectationEnseignant, on_delete=models.CASCADE, related_name="creneaux")
    jour_semaine = models.PositiveSmallIntegerField(validators=[MinValueValidator(0), MaxValueValidator(6)])
    heure_debut = models.TimeField()
    heure_fin = models.TimeField()
    actif = models.BooleanField(default=True)

    class Meta:
        indexes = [
            models.Index(
                fields=("affectation", "jour_semaine"),
                name="enseignant_crn_jour_idx",
            )
        ]


class Seance(models.Model):
    STATUTS = (("tenue", "Tenue"), ("annulee", "Annulée"))

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    affectation = models.ForeignKey(AffectationEnseignant, on_delete=models.CASCADE, related_name="seances")
    creneau = models.ForeignKey(Creneau, null=True, blank=True, on_delete=models.SET_NULL, related_name="seances")
    date_seance = models.DateField()
    statut = models.CharField(max_length=10, choices=STATUTS, default="tenue")
    nb_presents = models.PositiveSmallIntegerField(null=True, blank=True)
    nb_absents = models.PositiveSmallIntegerField(null=True, blank=True)
    commentaire = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(
                fields=("affectation", "date_seance"),
                name="enseignant_seance_date_idx",
            )
        ]
        constraints = [models.UniqueConstraint(fields=("affectation", "date_seance"), name="une_seance_par_jour_et_affectation")]
