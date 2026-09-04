import uuid

from django.conf import settings
from django.db import models


class IdentifiantUUID(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    class Meta:
        abstract = True


class Poste(IdentifiantUUID):
    nom = models.CharField(max_length=100, unique=True)
    tous_sites = models.BooleanField(default=False)

    def __str__(self):
        return self.nom


class Permission(IdentifiantUUID):
    code = models.CharField(max_length=80, unique=True)
    libelle = models.CharField(max_length=160)
    postes = models.ManyToManyField(Poste, related_name="permissions", blank=True)

    def __str__(self):
        return self.code


class Site(IdentifiantUUID):
    nom = models.CharField(max_length=120, unique=True)
    adresse = models.TextField(blank=True)
    capacite = models.PositiveIntegerField(null=True, blank=True)
    responsable = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="sites_responsable")

    def __str__(self):
        return self.nom
