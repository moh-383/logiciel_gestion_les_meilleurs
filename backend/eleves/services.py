from django.db import transaction
from rest_framework.exceptions import PermissionDenied

from core.permissions import dans_perimetre

from .models import ContactParent, Eleve


@transaction.atomic
def enregistrer_eleve(*, data, utilisateur):
    client_uuid = data.get("client_uuid")

    # Si l'élève existe déjà avec ce client_uuid,
    # on le retourne sans créer de doublon.
    if client_uuid:
        existant = Eleve.objects.filter(client_uuid=client_uuid).first()

        if existant:
            return existant, False

    # Vérification du périmètre du site.
    site = data["site"]

    if not dans_perimetre(utilisateur, site.id):
        raise PermissionDenied(
            "Site hors de votre périmètre."
        )

    contacts = data.get("contacts", [])

    # Création de l'élève.
    eleve = Eleve.objects.create(
        client_uuid=client_uuid,
        matricule=data["matricule"],
        nom=data["nom"],
        prenom=data["prenom"],
        date_naissance=data.get("date_naissance"),
        sexe=data["sexe"],
        site=site,
        classe=data["classe"],
        type_cours=data["type_cours"],
    )

    # Création des contacts parents liés à l'élève.
    ContactParent.objects.bulk_create(
        [
            ContactParent(eleve=eleve, **contact)
            for contact in contacts
        ]
    )

    return eleve, True