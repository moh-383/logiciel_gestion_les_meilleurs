from decimal import Decimal

from django.db import transaction
from django.db.models import Q, Sum
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from eleves.models import Echeance
from paiements.models import Paiement

from .models import GroupeProgramme, InscriptionProgramme, TarifProgramme


def tarif_actif(groupe):
    date = timezone.localdate()
    actif = Q(fin_validite__isnull=True) | Q(fin_validite__gte=date)
    return TarifProgramme.objects.filter(site_id=groupe.session.site_id, groupe=groupe, debut_validite__lte=date).filter(actif).order_by("-debut_validite").first() or TarifProgramme.objects.filter(site_id=groupe.session.site_id, programme=groupe.session.programme, groupe__isnull=True, debut_validite__lte=date).filter(actif).order_by("-debut_validite").first()


@transaction.atomic
def confirmer_inscription(*, inscription, utilisateur):
    inscription = InscriptionProgramme.objects.select_for_update().select_related("eleve", "groupe__session__programme").get(pk=inscription.pk)
    groupe = GroupeProgramme.objects.select_for_update().select_related("session__programme").get(pk=inscription.groupe_id)
    session = groupe.session
    if session.statut != "ouvert" or session.programme.statut != "ouvert" or groupe.statut != "ouvert":
        raise ValidationError("Le programme, la session ou le groupe n'accepte pas les inscriptions.")
    if inscription.eleve.site_id != session.site_id:
        raise ValidationError("L'élève doit appartenir au même site que la session.")
    deja = InscriptionProgramme.objects.filter(eleve=inscription.eleve, statut="confirmee", groupe__session__programme=session.programme, groupe__session__site=session.site, groupe__session__date_debut__lt=session.date_fin, groupe__session__date_fin__gt=session.date_debut).exclude(pk=inscription.pk)
    if deja.exists():
        raise ValidationError("Cet élève a déjà une inscription confirmée sur cette période.")
    if groupe.inscriptions.filter(statut="confirmee").count() >= groupe.capacite:
        groupe.statut = "complet"
        groupe.save(update_fields=("statut",))
        raise ValidationError("Ce groupe est complet.")
    tarif = tarif_actif(groupe)
    if not tarif:
        raise ValidationError("Aucun tarif actif n'est configuré pour ce groupe.")
    remise = inscription.remise or 0
    if remise >= tarif.montant:
        raise ValidationError({"remise": "La remise doit rester inférieure au tarif."})
    if remise > 0 and not utilisateur.a_permission("gerer_tarifs"):
        raise ValidationError("La permission gerer_tarifs est requise pour appliquer une remise.")
    if remise * 100 > tarif.montant * 20 and not utilisateur.a_permission("valider_actions_sensibles"):
        raise ValidationError("Une remise supérieure à 20 % exige une validation sensible.")
    inscription.tarif_fixe = tarif.montant
    inscription.statut = "confirmee"
    inscription.save(update_fields=("tarif_fixe", "statut"))
    Echeance.objects.create(eleve=inscription.eleve, montant_du=tarif.montant - remise, date_echeance=session.date_debut, inscription_programme=inscription)
    if groupe.inscriptions.filter(statut="confirmee").count() >= groupe.capacite:
        groupe.statut = "complet"
        groupe.save(update_fields=("statut",))
    return inscription


@transaction.atomic
def annuler_inscription(*, inscription, utilisateur, motif):
    if not motif.strip():
        raise ValidationError({"motif": "Le motif d'annulation est obligatoire."})
    inscription = InscriptionProgramme.objects.select_for_update().get(pk=inscription.pk)
    echeance = Echeance.objects.filter(inscription_programme=inscription).first()
    if echeance:
        total = echeance.paiements.filter(statut="valide").aggregate(total=Sum("montant"))["total"] or Decimal(0)
        if total:
            raise ValidationError("Un paiement existe : l'annulation doit suivre le workflow de validation des paiements.")
        echeance.statut = "annulee"
        echeance.save(update_fields=("statut",))
    inscription.statut = "annulee"
    inscription.annulee_par = utilisateur
    inscription.motif_annulation = motif
    inscription.save(update_fields=("statut", "annulee_par", "motif_annulation"))
    GroupeProgramme.objects.filter(pk=inscription.groupe_id, statut="complet").update(statut="ouvert")
    return inscription


@transaction.atomic
def annuler_session(*, session):
    """Annule les échéances non réglées sans effacer l'historique de session."""
    session = session.__class__.objects.select_for_update().get(pk=session.pk)
    if session.statut == "annule":
        return session
    echeances = Echeance.objects.select_for_update().filter(
        inscription_programme__groupe__session=session,
    )
    for echeance in echeances:
        total = echeance.paiements.filter(statut="valide").aggregate(
            total=Sum("montant"),
        )["total"] or Decimal(0)
        if total == 0:
            echeance.statut = "annulee"
            echeance.save(update_fields=("statut",))
    session.statut = "annule"
    session.save(update_fields=("statut",))
    session.groupes.exclude(statut="annule").update(statut="annule")
    return session
