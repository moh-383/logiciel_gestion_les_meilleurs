from rest_framework.permissions import BasePermission


class ALaPermissionMetier(BasePermission):
    """Contrôle les permissions du poste, sans dépendre des permissions Django."""

    def has_permission(self, request, view):
        required = getattr(view, "permission_metier", None)
        if required is None:
            return bool(request.user and request.user.is_authenticated)
        return request.user.is_authenticated and request.user.a_permission(required)


def dans_perimetre(user, site_id):
    """
    Vrai si `user` peut accéder aux données du site `site_id` :
    - soit son poste a `tous_sites = True` (direction),
    - soit c'est exactement son propre site.
    """
    if user.tous_sites:
        return True
    if site_id is None or user.site_id is None:
        return False
    return str(user.site_id) == str(site_id)