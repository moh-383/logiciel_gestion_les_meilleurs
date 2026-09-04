from rest_framework import status, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from core.permissions import ALaPermissionMetier
from .models import Utilisateur
from .serializers import UtilisateurSerializer


def _profil_utilisateur(user):
    poste = user.poste
    return {
        "id": str(user.id), "nom": user.nom,
        "poste": None if not poste else {"nom": poste.nom, "permissions": list(poste.permissions.values_list("code", flat=True)), "tous_sites": poste.tous_sites},
        "site_id": str(user.site_id) if user.site_id else None,
    }


class ConnexionView(APIView):
    permission_classes = ()

    def post(self, request):
        telephone = request.data.get("telephone", "")
        mot_de_passe = request.data.get("mot_de_passe", request.data.get("password", ""))
        user = Utilisateur.objects.filter(telephone=telephone, is_active=True).select_related("poste", "site").first()
        if user is None or not user.check_password(mot_de_passe):
            return Response({"error": "identifiants_invalides", "message": "Téléphone ou mot de passe incorrect."}, status=status.HTTP_401_UNAUTHORIZED)
        refresh = RefreshToken.for_user(user)
        return Response({"access_token": str(refresh.access_token), "refresh_token": str(refresh), "utilisateur": _profil_utilisateur(user)})


class DeconnexionView(APIView):
    def post(self, request):
        token = request.data.get("refresh_token")
        if not token:
            return Response({"error": "requete_invalide", "message": "refresh_token obligatoire."}, status=status.HTTP_400_BAD_REQUEST)
        try:
            RefreshToken(token).blacklist()
        except Exception:
            return Response({"error": "requete_invalide", "message": "refresh_token invalide."}, status=status.HTTP_400_BAD_REQUEST)
        return Response(status=status.HTTP_204_NO_CONTENT)


class UtilisateurViewSet(viewsets.ModelViewSet):
    serializer_class = UtilisateurSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_comptes"

    def get_queryset(self):
        queryset = Utilisateur.objects.select_related("poste", "site").order_by("nom")
        for key in ("site_id", "poste_id", "actif"):
            value = self.request.query_params.get(key)
            if value is not None:
                queryset = queryset.filter(**{"is_active" if key == "actif" else key: value})
        return queryset
