from rest_framework import serializers

from .models import Echange


class EchangeSerializer(serializers.ModelSerializer):
    cree_par_nom = serializers.CharField(source="cree_par.nom", read_only=True)

    class Meta:
        model = Echange
        fields = ("id", "client_uuid", "eleve", "type_echange", "titre", "description", "cree_par_nom", "date_echange", "created_at")
        read_only_fields = ("id", "created_at")


class EchangeEcritureSerializer(serializers.Serializer):
    client_uuid = serializers.UUIDField(required=False)
    type_echange = serializers.ChoiceField(choices=Echange.TYPES)
    titre = serializers.CharField(max_length=200)
    description = serializers.CharField(required=False, allow_blank=True)
    date_echange = serializers.DateTimeField()