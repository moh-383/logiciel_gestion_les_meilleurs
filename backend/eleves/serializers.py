from decimal import Decimal

from django.db.models import Sum
from django.utils import timezone
from rest_framework import serializers

from core.models import Site
from .models import ContactParent, Echeance, Eleve


class ContactParentSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContactParent
        fields = ("id", "nom", "telephone", "lien")
        read_only_fields = ("id",)


class EleveSerializer(serializers.ModelSerializer):
    contacts = ContactParentSerializer(many=True, required=False)

    site_id = serializers.PrimaryKeyRelatedField(
        source="site",
        queryset=Site.objects.all()
    )

    class Meta:
        model = Eleve
        fields = (
            "id",
            "client_uuid",
            "matricule",
            "nom",
            "prenom",
            "date_naissance",
            "sexe",
            "site_id",
            "classe",
            "type_cours",
            "statut",
            "contacts",
        )
        read_only_fields = ("id",)

    def create(self, validated_data):
        contacts = validated_data.pop("contacts", [])

        eleve = Eleve.objects.create(**validated_data)

        ContactParent.objects.bulk_create(
            [
                ContactParent(eleve=eleve, **contact)
                for contact in contacts
            ]
        )

        return eleve

    def update(self, instance, validated_data):
        # Les contacts se modifient via leurs routes dédiées.
        validated_data.pop("contacts", None)

        return super().update(instance, validated_data)


class EleveDetailSerializer(EleveSerializer):
    """
    Utilisé uniquement sur GET /eleves/{id} :
    ajoute le résumé financier agrégé.
    """

    resume_financier = serializers.SerializerMethodField()

    class Meta(EleveSerializer.Meta):
        fields = EleveSerializer.Meta.fields + ("resume_financier",)

    def get_resume_financier(self, eleve):
        echeances = list(eleve.echeances.all())
        aujourdhui = timezone.localdate()

        montant_du_total = sum(
            (e.montant_du for e in echeances),
            Decimal("0")
        )

        montant_paye_total = (
            eleve.echeances
            .filter(paiements__statut="valide")
            .aggregate(
                total=Sum("paiements__montant")
            )["total"]
            or Decimal("0")
        )

        statuts = {e.statut for e in echeances}

        if "retard" in statuts:
            statut_global = "retard"
        elif "partiel" in statuts:
            statut_global = "partiel"
        else:
            statut_global = "a_jour"

        jours_retard_max = 0

        if statut_global == "retard":
            jours_retard_max = max(
                (
                    aujourdhui - e.date_echeance
                ).days
                for e in echeances
                if e.statut == "retard"
            )

        return {
            "montant_du_total": montant_du_total,
            "montant_paye_total": montant_paye_total,
            "solde_restant": montant_du_total - montant_paye_total,
            "statut_global": statut_global,
            "jours_retard_max": jours_retard_max,
        }


class EleveSyncSerializer(EleveSerializer):
    """
    Serializer utilisé pour la synchronisation des élèves
    créés hors connexion.

    Les vérifications d'unicité sont désactivées ici afin que
    le service puisse gérer lui-même :
    - l'idempotence via client_uuid ;
    - les conflits de matricule.
    """

    client_uuid = serializers.UUIDField(
        required=True,
        validators=[],
    )

    matricule = serializers.CharField(
        max_length=50,
        validators=[],
    )

class EcheanceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Echeance
        fields = (
            "id",
            "eleve",
            "montant_du",
            "date_echeance",
            "statut",
        )
        read_only_fields = ("id", "statut")