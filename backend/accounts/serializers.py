from rest_framework import serializers

from core.models import Poste, Site
from .models import Utilisateur


class UtilisateurSerializer(serializers.ModelSerializer):
    poste_id = serializers.PrimaryKeyRelatedField(source="poste", queryset=Poste.objects.all(), allow_null=True, required=False)
    site_id = serializers.PrimaryKeyRelatedField(source="site", queryset=Site.objects.all(), allow_null=True, required=False)

    class Meta:
        model = Utilisateur
        fields = ("id", "nom", "telephone", "poste_id", "site_id", "is_active")
        read_only_fields = ("id",)

    def create(self, validated_data):
        password = self.initial_data.get("mot_de_passe")
        if not password:
            raise serializers.ValidationError({"mot_de_passe": "Ce champ est obligatoire."})
        return Utilisateur.objects.create_user(password=password, **validated_data)

    def update(self, instance, validated_data):
        password = self.initial_data.get("mot_de_passe")
        for attribute, value in validated_data.items():
            setattr(instance, attribute, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance
