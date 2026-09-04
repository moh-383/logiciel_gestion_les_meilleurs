from rest_framework import serializers

from .models import Permission, Poste, Site


class PermissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Permission
        fields = ("id", "code", "libelle")


class PosteSerializer(serializers.ModelSerializer):
    permissions = serializers.SlugRelatedField(many=True, slug_field="code", queryset=Permission.objects.all(), required=False)

    class Meta:
        model = Poste
        fields = ("id", "nom", "tous_sites", "permissions")


class SiteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Site
        fields = ("id", "nom", "adresse", "capacite", "responsable")
        read_only_fields = ("id",)
