import uuid

from django.conf import settings
from django.db import models


class Paiement(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    # UUID produit par l'appareil : clé d'idempotence de la synchronisation.
    client_uuid = models.UUIDField(unique=True)
    echeance = models.ForeignKey("eleves.Echeance", on_delete=models.PROTECT, related_name="paiements")
    montant = models.DecimalField(max_digits=12, decimal_places=0)
    mode_paiement = models.CharField(max_length=30)
    note = models.TextField(blank=True)
    date_paiement = models.DateTimeField()
    saisi_par = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="paiements_saisis")
    statut = models.CharField(max_length=20, default="valide")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=("echeance", "statut")), models.Index(fields=("date_paiement",))]


class DemandeValidation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    type_action = models.CharField(max_length=50, default="annulation_paiement")
    paiement = models.ForeignKey(Paiement, on_delete=models.PROTECT, related_name="demandes_annulation")
    demandeur = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="demandes_soumises")
    valideur = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.PROTECT, related_name="demandes_traitees")
    statut = models.CharField(max_length=20, default="en_attente")
    motif = models.TextField()
    commentaire = models.TextField(blank=True)
    date_demande = models.DateTimeField(auto_now_add=True)
    date_traitement = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=("paiement",), condition=models.Q(statut="en_attente"), name="une_annulation_en_attente_par_paiement")]
