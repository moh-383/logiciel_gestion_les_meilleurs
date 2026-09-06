
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Permission, Poste, Site
from .permissions import ALaPermissionMetier
from .serializers import (
    PermissionSerializer,
    PosteAssignerPermissionsSerializer,
    PosteSerializer,
    SiteSerializer,
)


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

    @action(detail=True, methods=["put"], url_path="permissions")
    def definir_permissions(self, request, pk=None):
        """
        Remplace intégralement les permissions associées au poste.
        """
        poste = self.get_object()

        serializer = PosteAssignerPermissionsSerializer(
            data=request.data
        )
        serializer.is_valid(raise_exception=True)

        poste.permissions.set(
            serializer.validated_data["permissions"]
        )

        return Response(
            PosteSerializer(poste).data
        )


class SiteViewSet(viewsets.ModelViewSet):
    serializer_class = SiteSerializer
    permission_classes = (ALaPermissionMetier,)

    def get_queryset(self):
        user = self.request.user
        if user.poste and user.poste.tous_sites:
            return Site.objects.all().order_by("nom")
        return Site.objects.filter(pk=user.site_id).order_by("nom")

    def get_permissions(self):
        self.permission_metier = (
            "gerer_comptes"
            if self.request.method not in ("GET", "HEAD", "OPTIONS")
            else None
        )
        return super().get_permissions()

