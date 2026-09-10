from rest_framework import serializers

from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    eleve_nom = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = ("id", "type_notification", "canal", "statut", "message", "eleve_nom", "date_creation", "date_envoi")

    def get_eleve_nom(self, obj):
        return f"{obj.eleve.prenom} {obj.eleve.nom}" if obj.eleve else None