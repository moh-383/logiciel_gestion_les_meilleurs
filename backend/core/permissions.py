from rest_framework.permissions import BasePermission


class ALaPermissionMetier(BasePermission):
    """Contrôle les permissions du poste, sans dépendre des permissions Django."""

    def has_permission(self, request, view):
        required = getattr(view, "permission_metier", None)
        if required is None:
            return bool(request.user and request.user.is_authenticated)
        return request.user.is_authenticated and request.user.a_permission(required)
