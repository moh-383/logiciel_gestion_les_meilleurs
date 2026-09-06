import datetime

from django.db import IntegrityError, transaction
from rest_framework.exceptions import PermissionDenied, ValidationError

from core.permissions import dans_perimetre

from .models import ContactParent, Eleve


def _generer_matricule():
    annee = datetime.date.today().year
    prefixe = f"ELV-{annee}-"
    dernier = (
        Eleve.objects.filter(matricule__startswith=prefixe)
        .order_by("-matricule")
        .values_list("matricule", flat=True)
        .first()
    )
    try:
        dernier_seq = int(dernier[len(prefixe):]) if dernier else 0
    except ValueError:
        dernier_seq = 0
    return f"{prefixe}{dernier_seq + 1:03d}"


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
    matricule_fourni = (data.get("matricule") or "").strip() or None

    eleve = None
    for _ in range(5):
        candidat = matricule_fourni or _generer_matricule()
        try:
            with transaction.atomic():
                eleve = Eleve.objects.create(
                    client_uuid=client_uuid,
                    matricule=candidat,
                    nom=data["nom"],
                    prenom=data["prenom"],
                    date_naissance=data.get("date_naissance"),
                    sexe=data["sexe"],
                    site=site,
                    classe=data["classe"],
                    type_cours=data["type_cours"],
                )
            break
        except IntegrityError:
            if matricule_fourni:
                raise

    if eleve is None:
        raise ValidationError(
            "Impossible de générer un matricule unique, réessayez."
        )

    # Création des contacts parents liés à l'élève.
    ContactParent.objects.bulk_create(
        [
            ContactParent(eleve=eleve, **contact)
            for contact in contacts
        ]
    )

    return eleve, True