from django.db import transaction
from rest_framework.exceptions import PermissionDenied

from core.permissions import dans_perimetre
from eleves.models import Eleve

from .models import Echange


@transaction.atomic
def enregistrer_echange(*, eleve_id, data, utilisateur):
    """Idempotent via client_uuid, comme enregistrer_eleve/enregistrer_paiement.
    Aucune fonction de mise à jour n'existe volontairement : un échange créé
    est immuable (trace d'audit), toute correction se fait via une nouvelle
    entrée plutôt qu'un PATCH."""
    client_uuid = data.get("client_uuid")
    if client_uuid:
        existant = Echange.objects.filter(client_uuid=client_uuid).first()
        if existant:
            return existant, False

    eleve = Eleve.objects.select_related("site").get(pk=eleve_id)
    if not dans_perimetre(utilisateur, eleve.site_id):
        raise PermissionDenied("Élève hors de votre périmètre.")

    echange = Echange.objects.create(
        client_uuid=client_uuid, eleve=eleve, site=eleve.site,
        type_echange=data["type_echange"], titre=data["titre"],
        description=data.get("description", ""), cree_par=utilisateur,
        date_echange=data["date_echange"],
    )
    return echange, True