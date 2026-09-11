import uuid

from django.conf import settings
from django.db import models


class Notification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    type_notification = models.CharField(max_length=50, default="retard_paiement")
    site = models.ForeignKey("core.Site", on_delete=models.PROTECT, related_name="notifications")
    eleve = models.ForeignKey(
        "eleves.Eleve", on_delete=models.SET_NULL, null=True, blank=True, related_name="notifications"
    )
    echeance = models.ForeignKey(
        "eleves.Echeance", on_delete=models.SET_NULL, null=True, blank=True, related_name="notifications"
    )
    destinataire = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="notifications_recues",
    )
    canal = models.CharField(max_length=10, choices=(("fcm", "FCM"), ("sms", "SMS")))
    statut = models.CharField(max_length=20, default="en_attente")  # envoyee / echec / en_attente
    message = models.TextField()
    date_creation = models.DateTimeField(auto_now_add=True)
    date_envoi = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [
            models.Index(
                fields=("site", "date_creation"),
                name="notif_site_date_idx",
            )
        ]
