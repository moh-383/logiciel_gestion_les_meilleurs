from rest_framework import generics

from core.permissions import ALaPermissionMetier

from .models import Notification
from .serializers import NotificationSerializer


class NotificationsListView(generics.ListAPIView):
    """Historique des notifications, cloisonné par site comme le reste
    de l'API. Aucune permission métier dédiée n'est exigée en lecture :
    tout utilisateur authentifié de son site peut consulter l'historique
    qui le concerne (cohérent avec le futur écran "Historique des échanges")."""

    serializer_class = NotificationSerializer
    permission_classes = (ALaPermissionMetier,)

    def get_queryset(self):
        user = self.request.user
        qs = Notification.objects.select_related("eleve").order_by("-date_creation")
        if not user.tous_sites:
            qs = qs.filter(site_id=user.site_id)
        for field in ("type_notification", "statut"):
            if value := self.request.query_params.get(field):
                qs = qs.filter(**{field: value})
        return qs