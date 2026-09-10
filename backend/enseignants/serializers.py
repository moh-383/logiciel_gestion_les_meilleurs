from rest_framework import serializers

from .models import Creneau, Seance


class CreneauSerializer(serializers.ModelSerializer):
    class Meta:
        model = Creneau
        fields = ("id", "jour_semaine", "heure_debut", "heure_fin", "actif")
        read_only_fields = ("id",)


class SeanceCreateSerializer(serializers.Serializer):
    affectation_id = serializers.UUIDField()
    creneau_id = serializers.UUIDField(required=False, allow_null=True)
    date_seance = serializers.DateField()
    statut = serializers.ChoiceField(choices=Seance.STATUTS, default="tenue")
    nb_presents = serializers.IntegerField(required=False, allow_null=True, min_value=0)
    nb_absents = serializers.IntegerField(required=False, allow_null=True, min_value=0)
    commentaire = serializers.CharField(required=False, allow_blank=True, max_length=1000)


class SeanceSerializer(serializers.ModelSerializer):
    affectation_id = serializers.UUIDField(read_only=True)
    creneau_id = serializers.UUIDField(read_only=True, allow_null=True)

    class Meta:
        model = Seance
        fields = (
            "id", "affectation_id", "creneau_id", "date_seance",
            "statut", "nb_presents", "nb_absents", "commentaire",
        )
        read_only_fields = ("id",)