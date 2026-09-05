from django.db import IntegrityError

from rest_framework import generics, status, viewsets
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from core.permissions import ALaPermissionMetier, dans_perimetre
from .models import ContactParent, Echeance, Eleve
from .serializers import (
    ContactParentSerializer,
    EcheanceSerializer,
    EleveDetailSerializer,
    EleveSerializer,
    EleveSyncSerializer,
)
from .services import enregistrer_eleve


class EleveViewSet(viewsets.ModelViewSet):
    serializer_class = EleveSerializer
    permission_classes = (ALaPermissionMetier,)

    def get_serializer_class(self):
        if self.action == "retrieve":
            return EleveDetailSerializer
        return EleveSerializer

    def get_queryset(self):
        qs = (
            Eleve.objects
            .select_related("site")
            .prefetch_related("contacts")
            .order_by("nom", "prenom")
        )

        user = self.request.user

        if not user.tous_sites:
            qs = qs.filter(site_id=user.site_id)

        for field in ("site_id", "classe", "statut"):
            value = self.request.query_params.get(field)

            if value:
                qs = qs.filter(**{field: value})

        if q := self.request.query_params.get("q"):
            qs = qs.filter(
                nom__icontains=q
            ) | qs.filter(
                prenom__icontains=q
            ) | qs.filter(
                matricule__icontains=q
            )

        return qs

    def get_permissions(self):
        self.permission_metier = (
            "gerer_eleves"
            if self.request.method not in ("GET", "HEAD", "OPTIONS")
            else None
        )

        return super().get_permissions()

    def perform_create(self, serializer):
        eleve, _ = enregistrer_eleve(
            data=serializer.validated_data,
            utilisateur=self.request.user,
        )

        serializer.instance = eleve

    def perform_update(self, serializer):
        site = serializer.validated_data.get(
            "site",
            serializer.instance.site
        )

        if not dans_perimetre(
            self.request.user,
            site.id
        ):
            raise PermissionDenied(
                "Site hors de votre périmètre."
            )

        serializer.save()


class EleveSyncView(APIView):
    """
    Synchronisation des élèves créés hors connexion.

    POST /sync/eleves

    Reçoit une liste d'élèves contenant obligatoirement un client_uuid.
    """

    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_eleves"

    def post(self, request):
        if not isinstance(request.data, list):
            return Response(
                {
                    "detail": "Le corps de la requête doit être une liste."
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        resultats = []

        for item in request.data:
            serializer = EleveSyncSerializer(data=item)

            if not serializer.is_valid():
                resultats.append(
                    {
                        "client_uuid": item.get("client_uuid"),
                        "statut": "erreur",
                        "erreurs": serializer.errors,
                    }
                )
                continue

            try:
                eleve, created = enregistrer_eleve(
                    data=serializer.validated_data,
                    utilisateur=request.user,
                )

                resultats.append(
                    {
                        "client_uuid": str(eleve.client_uuid),
                        "id": str(eleve.id),
                        "statut": "cree" if created else "deja_existant",
                    }
                )

            except PermissionDenied as exc:
                resultats.append(
                    {
                        "client_uuid": item.get("client_uuid"),
                        "statut": "erreur",
                        "raison": str(exc),
                    }
                )

            except IntegrityError:
                resultats.append(
                    {
                        "client_uuid": item.get("client_uuid"),
                        "statut": "conflit",
                        "raison": "matricule_deja_utilise",
                    }
                )

        return Response(
            {"resultats": resultats},
            status=status.HTTP_200_OK,
        )


class ContactViewSet(viewsets.ModelViewSet):
    serializer_class = ContactParentSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_eleves"

    def get_queryset(self):
        qs = ContactParent.objects.select_related("eleve__site")

        return (
            qs
            if self.request.user.tous_sites
            else qs.filter(eleve__site_id=self.request.user.site_id)
        )


class ContactsEleveView(generics.ListCreateAPIView):
    serializer_class = ContactParentSerializer
    permission_classes = (ALaPermissionMetier,)

    def get_eleve(self):
        eleve = Eleve.objects.get(pk=self.kwargs["pk"])

        if not dans_perimetre(
            self.request.user,
            eleve.site_id
        ):
            raise PermissionDenied(
                "Élève hors de votre périmètre."
            )

        return eleve

    def get_queryset(self):
        return self.get_eleve().contacts.all()

    def get_permissions(self):
        self.permission_metier = (
            "gerer_eleves"
            if self.request.method == "POST"
            else None
        )

        return super().get_permissions()

    def perform_create(self, serializer):
        serializer.save(eleve=self.get_eleve())


class EcheancesEleveView(generics.ListAPIView):
    serializer_class = EcheanceSerializer

    def get_queryset(self):
        eleve = Eleve.objects.get(pk=self.kwargs["pk"])

        if not dans_perimetre(
            self.request.user,
            eleve.site_id
        ):
            raise PermissionDenied(
                "Élève hors de votre périmètre."
            )

        return eleve.echeances.order_by("date_echeance")