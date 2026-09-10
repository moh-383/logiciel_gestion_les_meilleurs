from rest_framework import generics, status
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from core.models import Site
from core.permissions import ALaPermissionMetier, dans_perimetre
from eleves.models import Eleve

from .models import Echange
from .serializers import EchangeEcritureSerializer, EchangeSerializer
from .services import enregistrer_echange


class EchangesEleveView(generics.ListCreateAPIView):
    serializer_class = EchangeSerializer
    permission_classes = (ALaPermissionMetier,)

    def get_serializer_class(self):
        return EchangeEcritureSerializer if self.request.method == "POST" else EchangeSerializer

    def get_permissions(self):
        self.permission_metier = "gerer_echanges" if self.request.method == "POST" else None
        return super().get_permissions()

    def get_eleve(self):
        eleve = Eleve.objects.get(pk=self.kwargs["pk"])
        if not dans_perimetre(self.request.user, eleve.site_id):
            raise PermissionDenied("Élève hors de votre périmètre.")
        return eleve

    def get_queryset(self):
        return self.get_eleve().echanges.select_related("cree_par")

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        echange, cree = enregistrer_echange(
            eleve_id=self.kwargs["pk"], data=serializer.validated_data, utilisateur=request.user
        )
        return Response(
            EchangeSerializer(echange).data,
            status=status.HTTP_201_CREATED if cree else status.HTTP_200_OK,
        )


class EchangesSiteView(generics.ListAPIView):
    """Bulk échanges pour un site entier — même logique que EcheancesSiteView,
    pour l'import initial mobile sans un appel par élève."""
    serializer_class = EchangeSerializer
    permission_classes = (ALaPermissionMetier,)

    def get_queryset(self):
        site = Site.objects.get(pk=self.kwargs["pk"])
        if not dans_perimetre(self.request.user, site.id):
            raise PermissionDenied("Site hors de votre périmètre.")
        return Echange.objects.filter(site=site).select_related("eleve", "cree_par")


class EchangeSyncView(APIView):
    """Synchronisation en lot des échanges créés hors ligne — même contrat
    que EleveSyncView (liste brute, idempotence via client_uuid)."""
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_echanges"

    def post(self, request):
        if not isinstance(request.data, list):
            return Response({"detail": "Le corps de la requête doit être une liste."}, status=status.HTTP_400_BAD_REQUEST)

        resultats = []
        for item in request.data:
            eleve_id = item.get("eleve_id")
            serializer = EchangeEcritureSerializer(data=item)
            if not eleve_id or not serializer.is_valid():
                resultats.append({
                    "client_uuid": item.get("client_uuid"), "statut": "erreur",
                    "raison": serializer.errors if eleve_id else "eleve_id manquant",
                })
                continue
            try:
                echange, cree = enregistrer_echange(eleve_id=eleve_id, data=serializer.validated_data, utilisateur=request.user)
                resultats.append({
                    "client_uuid": str(echange.client_uuid), "id": str(echange.id),
                    "statut": "cree" if cree else "deja_existant",
                })
            except PermissionDenied as exc:
                resultats.append({"client_uuid": item.get("client_uuid"), "statut": "erreur", "raison": str(exc)})
            except Eleve.DoesNotExist:
                resultats.append({"client_uuid": item.get("client_uuid"), "statut": "erreur", "raison": "eleve_introuvable"})

        return Response({"resultats": resultats}, status=status.HTTP_200_OK)