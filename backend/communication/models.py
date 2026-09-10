import uuid

from django.conf import settings
from django.db import models


class Echange(models.Model):
    TYPES = (
        ("appel", "Appel téléphonique"),
        ("reunion", "Réunion"),
        ("incident_discipline", "Incident disciplinaire"),
        ("remarque", "Remarque"),
        ("autre", "Autre"),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    client_uuid = models.UUIDField(null=True, blank=True, unique=True)
    eleve = models.ForeignKey("eleves.Eleve", on_delete=models.PROTECT, related_name="echanges")
    site = models.ForeignKey("core.Site", on_delete=models.PROTECT, related_name="echanges")
    type_echange = models.CharField(max_length=30, choices=TYPES, default="remarque")
    titre = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    cree_par = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="echanges_crees")
    date_echange = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=("eleve", "-date_echange")), models.Index(fields=("site", "-date_echange"))]
        ordering = ("-date_echange",)