from rest_framework import serializers

from eleves.models import Echeance
from .models import DemandeValidation, Paiement


class PaiementSerializer(serializers.ModelSerializer):
    echeance_id = serializers.UUIDField(read_only=True)
    eleve_id = serializers.UUIDField(source="echeance.eleve_id", read_only=True)

    class Meta:
        model = Paiement
        fields = ("id", "client_uuid", "echeance_id", "eleve_id", "montant", "mode_paiement", "note", "date_paiement", "statut")


class PaiementEcritureSerializer(serializers.Serializer):
    client_uuid = serializers.UUIDField()
    echeance_id = serializers.PrimaryKeyRelatedField(source="echeance", queryset=Echeance.objects.all())
    montant = serializers.DecimalField(max_digits=12, decimal_places=0, min_value=1)
    mode_paiement = serializers.ChoiceField(choices=("especes", "orange_money", "moov_money"))
    note = serializers.CharField(required=False, allow_blank=True, max_length=1000)


class PaiementSyncSerializer(PaiementEcritureSerializer):
    date_locale = serializers.DateTimeField(source="date_paiement")


class DemandeValidationSerializer(serializers.ModelSerializer):
    paiement_id = serializers.UUIDField(read_only=True)
    montant = serializers.DecimalField(source="paiement.montant", max_digits=12, decimal_places=0, read_only=True)
    mode_paiement = serializers.CharField(source="paiement.mode_paiement", read_only=True)
    eleve_nom = serializers.SerializerMethodField()

    def get_eleve_nom(self, obj):
        eleve = obj.paiement.echeance.eleve
        return f"{eleve.prenom} {eleve.nom}"

    class Meta:
        model = DemandeValidation
        fields = ("id", "type_action", "paiement_id", "montant", "mode_paiement", "eleve_nom", "statut", "motif", "commentaire", "date_demande", "date_traitement")
        read_only_fields = ("id", "type_action", "paiement_id", "montant", "mode_paiement", "eleve_nom", "statut", "date_demande", "date_traitement")


class TraitementDemandeSerializer(serializers.Serializer):
    statut = serializers.ChoiceField(choices=("validee", "rejetee"))
    commentaire = serializers.CharField(required=False, allow_blank=True, max_length=1000)
