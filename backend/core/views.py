from rest_framework import viewsets

from .models import Permission, Poste, Site
from .permissions import ALaPermissionMetier
from .serializers import PermissionSerializer, PosteSerializer, SiteSerializer


class PermissionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Permission.objects.order_by("code")
    serializer_class = PermissionSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_comptes"


class PosteViewSet(viewsets.ModelViewSet):
    queryset = Poste.objects.prefetch_related("permissions").order_by("nom")
    serializer_class = PosteSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_comptes"


class SiteViewSet(viewsets.ModelViewSet):
    serializer_class = SiteSerializer
    permission_classes = (ALaPermissionMetier,)

    def get_queryset(self):
        user = self.request.user
        if user.poste and user.poste.tous_sites:
            return Site.objects.all().order_by("nom")
        return Site.objects.filter(pk=user.site_id).order_by("nom")

    def get_permissions(self):
        self.permission_metier = "gerer_comptes" if self.request.method not in ("GET", "HEAD", "OPTIONS") else None
        return super().get_permissions()
