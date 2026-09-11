from django.db import migrations


PERMISSIONS = {
    "gerer_comptes": "Gérer les sites, postes et utilisateurs",
    "gerer_eleves": "Créer et modifier les dossiers élèves",
    "saisir_paiement": "Saisir et synchroniser les paiements",
    "voir_finances": "Consulter les indicateurs et rapports financiers",
    "valider_actions_sensibles": "Valider les annulations et actions sensibles",
    "gerer_enseignants": "Gérer les enseignants, affectations et plannings",
    "voir_pedagogie": "Consulter et déclarer les activités pédagogiques",
}


def ajouter_permissions(apps, schema_editor):
    Permission = apps.get_model("core", "Permission")
    for code, libelle in PERMISSIONS.items():
        Permission.objects.get_or_create(code=code, defaults={"libelle": libelle})


def retirer_permissions(apps, schema_editor):
    apps.get_model("core", "Permission").objects.filter(code__in=PERMISSIONS).delete()


class Migration(migrations.Migration):
    dependencies = [("core", "0003_permission_gerer_echanges")]
    operations = [migrations.RunPython(ajouter_permissions, retirer_permissions)]
