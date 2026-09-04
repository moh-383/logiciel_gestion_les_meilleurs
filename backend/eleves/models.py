import uuid

from django.db import models


class Eleve(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    matricule = models.CharField(max_length=50, unique=True)
    nom = models.CharField(max_length=100)
    prenom = models.CharField(max_length=100)
    date_naissance = models.DateField(null=True, blank=True)
    sexe = models.CharField(max_length=1, choices=(("M", "Masculin"), ("F", "Féminin")))
    site = models.ForeignKey("core.Site", on_delete=models.PROTECT, related_name="eleves")
    classe = models.CharField(max_length=100)
    type_cours = models.CharField(max_length=80)
    statut = models.CharField(max_length=20, default="actif")

    class Meta:
        indexes = [models.Index(fields=("site", "nom", "prenom"))]

    def __str__(self):
        return f"{self.prenom} {self.nom}"


class ContactParent(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    eleve = models.ForeignKey(Eleve, on_delete=models.CASCADE, related_name="contacts")
    nom = models.CharField(max_length=150)
    telephone = models.CharField(max_length=30)
    lien = models.CharField(max_length=50)


class Echeance(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    eleve = models.ForeignKey(Eleve, on_delete=models.PROTECT, related_name="echeances")
    montant_du = models.DecimalField(max_digits=12, decimal_places=0)
    date_echeance = models.DateField()
    statut = models.CharField(max_length=20, default="a_jour")

    class Meta:
        indexes = [models.Index(fields=("eleve", "date_echeance"))]
