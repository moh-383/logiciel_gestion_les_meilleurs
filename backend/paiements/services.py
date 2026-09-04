from decimal import Decimal

from django.db import transaction
from django.db.models import Sum
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from eleves.models import Echeance
from .models import Paiement


def recalculer_statut_echeance(echeance):
    total = echeance.paiements.filter(statut="valide").aggregate(total=Sum("montant"))["total"] or Decimal("0")
    if total >= echeance.montant_du:
        statut = "a_jour"
    elif total > 0:
        statut = "partiel"
    elif echeance.date_echeance < timezone.localdate():
        statut = "retard"
    else:
        statut = "a_jour"
    Echeance.objects.filter(pk=echeance.pk).update(statut=statut)
    echeance.statut = statut


@transaction.atomic
def enregistrer_paiement(*, data, utilisateur):
    """Crée un paiement ou renvoie son équivalent existant de façon idempotente."""
    client_uuid = data["client_uuid"]
    existant = Paiement.objects.filter(client_uuid=client_uuid).first()
    if existant:
        return existant, False

    echeance = Echeance.objects.select_for_update().select_related("eleve__site").get(pk=data["echeance"].pk)
    if not utilisateur.tous_sites and echeance.eleve.site_id != utilisateur.site_id:
        raise ValidationError("Échéance hors de votre périmètre.")

    montant = data["montant"]
    if montant <= 0:
        raise ValidationError({"montant": "Le montant doit être strictement positif."})
    total = echeance.paiements.filter(statut="valide").aggregate(total=Sum("montant"))["total"] or Decimal("0")
    if total + montant > echeance.montant_du:
        raise ValidationError({"montant": "Le paiement dépasse le solde de l'échéance."})

    paiement = Paiement.objects.create(
        client_uuid=client_uuid, echeance=echeance, montant=montant,
        mode_paiement=data["mode_paiement"], note=data.get("note", ""),
        date_paiement=data.get("date_paiement") or timezone.now(), saisi_par=utilisateur,
    )
    recalculer_statut_echeance(echeance)
    return paiement, True
