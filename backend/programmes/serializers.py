from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import serializers

from .models import GroupeProgramme, InscriptionProgramme, Programme, ResultatExamen, SeanceProgramme, SessionProgramme, TarifProgramme


class ProgrammeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Programme
        fields = ("id", "type", "nom", "annee_scolaire", "statut", "matieres", "notes_bilan")
        read_only_fields = ("id",)

    def validate(self, attrs):
        kind = attrs.get("type", getattr(self.instance, "type", None))
        matieres = attrs.get("matieres", getattr(self.instance, "matieres", []))
        if kind in ("bac", "bepc") and not matieres:
            raise serializers.ValidationError({"matieres": "Au moins une matière est obligatoire pour un programme examen."})
        return attrs


class SessionSerializer(serializers.ModelSerializer):
    programme_id = serializers.UUIDField(read_only=True)
    site_id = serializers.UUIDField(read_only=True)
    effectif_confirme = serializers.SerializerMethodField()

    class Meta:
        model = SessionProgramme
        fields = ("id", "programme_id", "site_id", "intitule", "date_debut", "date_fin", "capacite", "statut", "notes_bilan", "effectif_confirme")
        read_only_fields = ("id", "programme_id", "site_id", "effectif_confirme")

    def get_effectif_confirme(self, obj):
        return getattr(obj, "effectif_confirme", None) or InscriptionProgramme.objects.filter(groupe__session=obj, statut="confirmee").values("eleve_id").distinct().count()

    def validate(self, attrs):
        debut = attrs.get("date_debut", getattr(self.instance, "date_debut", None))
        fin = attrs.get("date_fin", getattr(self.instance, "date_fin", None))
        if debut and fin and fin <= debut:
            raise serializers.ValidationError({"date_fin": "La date de fin doit être postérieure à la date de début."})
        return attrs


class GroupeSerializer(serializers.ModelSerializer):
    session_id = serializers.UUIDField(read_only=True)
    effectif_confirme = serializers.SerializerMethodField()
    tarif_actif = serializers.SerializerMethodField()

    class Meta:
        model = GroupeProgramme
        fields = ("id", "session_id", "niveau", "matiere", "capacite", "enseignant", "statut", "effectif_confirme", "tarif_actif")
        read_only_fields = ("id", "session_id", "effectif_confirme", "tarif_actif")

    def get_effectif_confirme(self, obj):
        return getattr(obj, "effectif_confirme", None) or obj.inscriptions.filter(statut="confirmee").count()

    def get_tarif_actif(self, obj):
        tarif = obj.tarifs.filter(debut_validite__lte=timezone.localdate()).filter(Q(fin_validite__isnull=True) | Q(fin_validite__gte=timezone.localdate())).order_by("-debut_validite").first()
        return tarif.montant if tarif else None


class TarifSerializer(serializers.ModelSerializer):
    class Meta:
        model = TarifProgramme
        fields = ("id", "site", "programme", "groupe", "montant", "debut_validite", "fin_validite")
        read_only_fields = ("id",)

    def validate(self, attrs):
        debut = attrs.get("debut_validite", getattr(self.instance, "debut_validite", None))
        fin = attrs.get("fin_validite", getattr(self.instance, "fin_validite", None))
        if fin and fin < debut:
            raise serializers.ValidationError({"fin_validite": "La fin de validité doit être postérieure ou égale au début."})
        if not attrs.get("programme", getattr(self.instance, "programme", None)) and not attrs.get("groupe", getattr(self.instance, "groupe", None)):
            raise serializers.ValidationError("Un tarif doit cibler un programme ou un groupe.")
        return attrs


class InscriptionSerializer(serializers.ModelSerializer):
    eleve_nom = serializers.SerializerMethodField()
    groupe_libelle = serializers.SerializerMethodField()
    echeance_id = serializers.UUIDField(source="echeance_programme.id", read_only=True, allow_null=True)

    class Meta:
        model = InscriptionProgramme
        fields = ("id", "eleve", "eleve_nom", "groupe", "groupe_libelle", "tarif_fixe", "remise", "motif_remise", "statut", "date_inscription", "echeance_id", "motif_annulation")
        read_only_fields = ("id", "tarif_fixe", "statut", "date_inscription", "echeance_id")

    def get_eleve_nom(self, obj):
        return f"{obj.eleve.prenom} {obj.eleve.nom}"

    def get_groupe_libelle(self, obj):
        return f"{obj.groupe.session.intitule} — {obj.groupe.niveau}{' / ' + obj.groupe.matiere if obj.groupe.matiere else ''}"

    def validate(self, attrs):
        remise = attrs.get("remise", getattr(self.instance, "remise", 0))
        motif = attrs.get("motif_remise", getattr(self.instance, "motif_remise", ""))
        if remise and not motif.strip():
            raise serializers.ValidationError({"motif_remise": "Le motif est obligatoire pour une remise."})
        return attrs


class SeanceProgrammeSerializer(serializers.ModelSerializer):
    class Meta:
        model = SeanceProgramme
        fields = ("id", "groupe", "date_seance", "nb_presents", "nb_absents", "commentaire")
        read_only_fields = ("id", "groupe")


class ResultatExamenSerializer(serializers.ModelSerializer):
    eleve_nom = serializers.SerializerMethodField()
    programme = serializers.CharField(source="inscription.groupe.session.programme.nom", read_only=True)
    matiere = serializers.CharField(source="inscription.groupe.matiere", read_only=True)
    admis = serializers.SerializerMethodField()

    class Meta:
        model = ResultatExamen
        fields = ("id", "inscription", "eleve_nom", "programme", "matiere", "note", "admis", "observation", "saisi_le")
        read_only_fields = ("id", "eleve_nom", "programme", "matiere", "admis", "saisi_le")

    def get_eleve_nom(self, obj):
        return f"{obj.inscription.eleve.prenom} {obj.inscription.eleve.nom}"

    def get_admis(self, obj):
        return obj.note >= 10

    def validate_inscription(self, inscription):
        if inscription.statut != "confirmee":
            raise serializers.ValidationError("Seule une inscription confirmée peut recevoir un résultat.")
        if inscription.groupe.session.programme.type not in ("bac", "bepc"):
            raise serializers.ValidationError("Les résultats sont réservés aux programmes Bac et BEPC.")
        return inscription
