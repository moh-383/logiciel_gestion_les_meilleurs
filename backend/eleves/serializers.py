from rest_framework import serializers

from core.models import Site
from .models import ContactParent, Echeance, Eleve


class ContactParentSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContactParent
        fields = ("id", "nom", "telephone", "lien")
        read_only_fields = ("id",)


class EleveSerializer(serializers.ModelSerializer):
    contacts = ContactParentSerializer(many=True, required=False)
    site_id = serializers.PrimaryKeyRelatedField(source="site", queryset=Site.objects.all())

    class Meta:
        model = Eleve
        fields = ("id", "matricule", "nom", "prenom", "date_naissance", "sexe", "site_id", "classe", "type_cours", "statut", "contacts")
        read_only_fields = ("id",)

    def create(self, validated_data):
        contacts = validated_data.pop("contacts", [])
        eleve = Eleve.objects.create(**validated_data)
        ContactParent.objects.bulk_create([ContactParent(eleve=eleve, **contact) for contact in contacts])
        return eleve

    def update(self, instance, validated_data):
        # Les contacts se modifient via leurs routes dédiées pour éviter une suppression implicite.
        validated_data.pop("contacts", None)
        return super().update(instance, validated_data)


class EcheanceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Echeance
        fields = ("id", "eleve", "montant_du", "date_echeance", "statut")
        read_only_fields = ("id", "statut")
