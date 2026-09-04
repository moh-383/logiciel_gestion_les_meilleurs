from rest_framework import generics, viewsets
from rest_framework.exceptions import PermissionDenied

from core.permissions import ALaPermissionMetier
from .models import ContactParent, Echeance, Eleve
from .serializers import ContactParentSerializer, EcheanceSerializer, EleveSerializer


def dans_perimetre(user, site_id):
    return user.tous_sites or str(user.site_id) == str(site_id)


class EleveViewSet(viewsets.ModelViewSet):
    serializer_class = EleveSerializer
    permission_classes = (ALaPermissionMetier,)

    def get_queryset(self):
        qs = Eleve.objects.select_related("site").prefetch_related("contacts").order_by("nom", "prenom")
        user = self.request.user
        if not user.tous_sites:
            qs = qs.filter(site_id=user.site_id)
        for field in ("site_id", "classe", "statut"):
            value = self.request.query_params.get(field)
            if value:
                qs = qs.filter(**{field: value})
        if q := self.request.query_params.get("q"):
            qs = qs.filter(nom__icontains=q) | qs.filter(prenom__icontains=q) | qs.filter(matricule__icontains=q)
        return qs

    def get_permissions(self):
        self.permission_metier = "gerer_eleves" if self.request.method not in ("GET", "HEAD", "OPTIONS") else None
        return super().get_permissions()

    def perform_create(self, serializer):
        site_id = serializer.validated_data["site"].id
        if not dans_perimetre(self.request.user, site_id):
            raise PermissionDenied("Site hors de votre périmètre.")
        serializer.save()

    def perform_update(self, serializer):
        site = serializer.validated_data.get("site", serializer.instance.site)
        if not dans_perimetre(self.request.user, site.id):
            raise PermissionDenied("Site hors de votre périmètre.")
        serializer.save()


class ContactViewSet(viewsets.ModelViewSet):
    serializer_class = ContactParentSerializer
    permission_classes = (ALaPermissionMetier,)
    permission_metier = "gerer_eleves"

    def get_queryset(self):
        qs = ContactParent.objects.select_related("eleve__site")
        return qs if self.request.user.tous_sites else qs.filter(eleve__site_id=self.request.user.site_id)


class ContactsEleveView(generics.ListCreateAPIView):
    serializer_class = ContactParentSerializer
    permission_classes = (ALaPermissionMetier,)

    def get_eleve(self):
        eleve = Eleve.objects.get(pk=self.kwargs["pk"])
        if not dans_perimetre(self.request.user, eleve.site_id):
            raise PermissionDenied("Élève hors de votre périmètre.")
        return eleve

    def get_queryset(self):
        return self.get_eleve().contacts.all()

    def get_permissions(self):
        self.permission_metier = "gerer_eleves" if self.request.method == "POST" else None
        return super().get_permissions()

    def perform_create(self, serializer):
        serializer.save(eleve=self.get_eleve())


class EcheancesEleveView(generics.ListAPIView):
    serializer_class = EcheanceSerializer

    def get_queryset(self):
        eleve = Eleve.objects.get(pk=self.kwargs["pk"])
        if not dans_perimetre(self.request.user, eleve.site_id):
            raise PermissionDenied("Élève hors de votre périmètre.")
        return eleve.echeances.order_by("date_echeance")
