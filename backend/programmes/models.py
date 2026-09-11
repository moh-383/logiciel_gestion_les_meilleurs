import uuid

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class Programme(models.Model):
    TYPES = (("vacances", "Vacances"), ("bac", "Bac"), ("bepc", "BEPC"))
    STATUTS = (("brouillon", "Brouillon"), ("ouvert", "Ouvert"), ("cloture", "Clôturé"), ("termine", "Terminé"), ("archive", "Archivé"), ("annule", "Annulé"))

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    type = models.CharField(max_length=12, choices=TYPES)
    nom = models.CharField(max_length=160)
    annee_scolaire = models.CharField(max_length=9)
    statut = models.CharField(max_length=12, choices=STATUTS, default="brouillon")
    matieres = models.JSONField(default=list, blank=True)
    notes_bilan = models.TextField(blank=True)

    class Meta:
        ordering = ("-annee_scolaire", "nom")


class SessionProgramme(models.Model):
    STATUTS = Programme.STATUTS

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    programme = models.ForeignKey(Programme, on_delete=models.PROTECT, related_name="sessions")
    site = models.ForeignKey("core.Site", on_delete=models.PROTECT, related_name="sessions_programmes")
    intitule = models.CharField(max_length=160)
    date_debut = models.DateField()
    date_fin = models.DateField()
    capacite = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    statut = models.CharField(max_length=12, choices=STATUTS, default="brouillon")
    notes_bilan = models.TextField(blank=True)

    class Meta:
        ordering = ("-date_debut", "intitule")
        indexes = [models.Index(fields=("site", "statut", "date_debut"))]


class GroupeProgramme(models.Model):
    STATUTS = (("ouvert", "Ouvert"), ("complet", "Complet"), ("cloture", "Clôturé"), ("annule", "Annulé"))

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(SessionProgramme, on_delete=models.PROTECT, related_name="groupes")
    niveau = models.CharField(max_length=120)
    matiere = models.CharField(max_length=120, blank=True)
    capacite = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    enseignant = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="groupes_programmes")
    statut = models.CharField(max_length=12, choices=STATUTS, default="ouvert")

    class Meta:
        ordering = ("niveau", "matiere")
        constraints = [models.UniqueConstraint(fields=("session", "niveau", "matiere"), name="groupe_programme_unique")]


class TarifProgramme(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    site = models.ForeignKey("core.Site", on_delete=models.PROTECT, related_name="tarifs_programmes")
    programme = models.ForeignKey(Programme, null=True, blank=True, on_delete=models.PROTECT, related_name="tarifs")
    groupe = models.ForeignKey(GroupeProgramme, null=True, blank=True, on_delete=models.PROTECT, related_name="tarifs")
    montant = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    debut_validite = models.DateField()
    fin_validite = models.DateField(null=True, blank=True)

    class Meta:
        ordering = ("-debut_validite",)
        indexes = [models.Index(fields=("site", "groupe", "debut_validite"))]


class InscriptionProgramme(models.Model):
    STATUTS = (("brouillon_local", "Brouillon local"), ("brouillon", "Brouillon"), ("confirmee", "Confirmée"), ("annulee", "Annulée"))

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    eleve = models.ForeignKey("eleves.Eleve", on_delete=models.PROTECT, related_name="inscriptions_programmes")
    groupe = models.ForeignKey(GroupeProgramme, on_delete=models.PROTECT, related_name="inscriptions")
    tarif_fixe = models.PositiveIntegerField(null=True, blank=True)
    remise = models.PositiveIntegerField(default=0)
    motif_remise = models.TextField(blank=True)
    statut = models.CharField(max_length=20, choices=STATUTS, default="brouillon")
    date_inscription = models.DateTimeField(auto_now_add=True)
    annulee_par = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.PROTECT, related_name="inscriptions_programmes_annulees")
    motif_annulation = models.TextField(blank=True)

    class Meta:
        indexes = [models.Index(fields=("eleve", "statut")), models.Index(fields=("groupe", "statut"))]
        constraints = [models.UniqueConstraint(fields=("eleve", "groupe"), condition=models.Q(statut="confirmee"), name="inscription_groupe_confirmee_unique")]


class SeanceProgramme(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    groupe = models.ForeignKey(GroupeProgramme, on_delete=models.CASCADE, related_name="seances")
    date_seance = models.DateField()
    nb_presents = models.PositiveIntegerField(null=True, blank=True)
    nb_absents = models.PositiveIntegerField(null=True, blank=True)
    commentaire = models.TextField(blank=True)

    class Meta:
        ordering = ("-date_seance",)
        constraints = [models.UniqueConstraint(fields=("groupe", "date_seance"), name="une_seance_programme_par_jour")]


class ResultatExamen(models.Model):
    """Résultat final saisi par matière pour une inscription Bac ou BEPC."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    inscription = models.OneToOneField(InscriptionProgramme, on_delete=models.PROTECT, related_name="resultat_examen")
    note = models.DecimalField(max_digits=4, decimal_places=2, validators=[MinValueValidator(0), MaxValueValidator(20)])
    observation = models.TextField(blank=True)
    saisi_par = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="resultats_examens_saisis")
    saisi_le = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-saisi_le",)
