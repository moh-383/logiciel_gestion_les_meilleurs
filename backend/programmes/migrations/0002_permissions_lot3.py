from django.db import migrations


PERMISSIONS = {
    "gerer_programmes": "Créer, ouvrir, clôturer ou annuler les programmes et groupes",
    "gerer_tarifs": "Configurer les tarifs et les remises des programmes",
    "inscrire_programmes": "Créer et modifier les inscriptions aux programmes",
    "voir_programmes": "Consulter les programmes, groupes et bilans du site",
    "saisir_resultats_examens": "Saisir les résultats Bac et BEPC",
}


def ajouter_permissions(apps, schema_editor):
    Permission = apps.get_model("core", "Permission")
    for code, libelle in PERMISSIONS.items():
        Permission.objects.get_or_create(code=code, defaults={"libelle": libelle})


def retirer_permissions(apps, schema_editor):
    apps.get_model("core", "Permission").objects.filter(code__in=PERMISSIONS).delete()


class Migration(migrations.Migration):
    dependencies = [("core", "0003_permission_gerer_echanges"), ("programmes", "0001_initial")]
    operations = [migrations.RunPython(ajouter_permissions, retirer_permissions)]
