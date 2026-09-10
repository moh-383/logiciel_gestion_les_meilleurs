from django.core.validators import MaxValueValidator, MinValueValidator


class Creneau(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    affectation = models.ForeignKey(AffectationEnseignant, on_delete=models.CASCADE, related_name="creneaux")
    jour_semaine = models.PositiveSmallIntegerField(validators=[MinValueValidator(0), MaxValueValidator(6)])
    heure_debut = models.TimeField()
    heure_fin = models.TimeField()
    actif = models.BooleanField(default=True)

    class Meta:
        indexes = [models.Index(fields=("affectation", "jour_semaine"))]

    def __str__(self):
        return f"{self.affectation} — jour {self.jour_semaine} {self.heure_debut}-{self.heure_fin}"


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
        indexes = [models.Index(fields=("affectation", "date_seance"))]
        constraints = [
            models.UniqueConstraint(fields=("affectation", "date_seance"), name="une_seance_par_jour_et_affectation")
        ]

    def __str__(self):
        return f"{self.affectation} — {self.date_seance} ({self.statut})"
    