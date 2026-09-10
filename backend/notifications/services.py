from django.db import transaction
from django.utils import timezone

from eleves.models import Echeance
from paiements.services import recalculer_statut_echeance

from .fcm_client import envoyer_push_fcm
from .models import Notification

PERMISSION_ALERTE = "recevoir_alertes_paiement"


def recalculer_statuts_du_jour():
    """À lancer avant la détection des retards : une échéance dont la date
    est dépassée sans qu'aucun paiement n'ait été touché ne bascule sinon
    jamais en 'retard' toute seule (le recalcul n'est déclenché qu'à
    l'enregistrement d'un paiement, voir paiements/services.py)."""
    aujourdhui = timezone.localdate()
    a_verifier = Echeance.objects.filter(
        statut="a_jour", date_echeance__lt=aujourdhui
    ).select_related("eleve__site")
    for echeance in a_verifier:
        recalculer_statut_echeance(echeance)


@transaction.atomic
def notifier_retards_du_jour():
    aujourdhui = timezone.localdate()
    echeances_en_retard = (
        Echeance.objects.filter(statut="retard")
        .select_related("eleve__site")
        .exclude(
            notifications__type_notification="retard_paiement",
            notifications__date_creation__date=aujourdhui,
        )
    )

    for echeance in echeances_en_retard:
        site = echeance.eleve.site
        message = (
            f"{echeance.eleve.prenom} {echeance.eleve.nom} : "
            f"échéance en retard ({echeance.montant_du} F)."
        )

        destinataires = site.utilisateurs.filter(
            poste__permissions__code=PERMISSION_ALERTE
        ).exclude(fcm_token__isnull=True).exclude(fcm_token="")

        for utilisateur in destinataires:
            notif = Notification.objects.create(
                type_notification="retard_paiement", site=site, eleve=echeance.eleve,
                echeance=echeance, destinataire=utilisateur, canal="fcm", message=message,
            )
            try:
                envoyer_push_fcm(token=utilisateur.fcm_token, titre="Retard de paiement", corps=message)
                notif.statut, notif.date_envoi = "envoyee", timezone.now()
            except Exception:
                notif.statut = "echec"
            notif.save(update_fields=("statut", "date_envoi"))

        # Canal SMS réservé pour une prochaine itération : la ligne existe
        # déjà en base (statut 'en_attente') pour ne pas perdre de trace,
        # mais aucun envoi réel tant que la passerelle SMS n'est pas câblée.
        for contact in echeance.eleve.contacts.all():
            Notification.objects.get_or_create(
                type_notification="retard_paiement", site=site, eleve=echeance.eleve,
                echeance=echeance, canal="sms",
                defaults={"statut": "en_attente", "message": message},
            )