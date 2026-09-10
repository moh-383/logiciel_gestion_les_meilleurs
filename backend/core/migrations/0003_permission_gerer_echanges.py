from django.db import migrations


def creer_permission(apps, schema_editor):
    Permission = apps.get_model('core', 'Permission')
    Permission.objects.get_or_create(
        code='gerer_echanges',
        defaults={'libelle': "Enregistrer un échange ou un incident concernant un élève"},
    )


def supprimer_permission(apps, schema_editor):
    apps.get_model('core', 'Permission').objects.filter(code='gerer_echanges').delete()


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0002_permission_alertes_paiement'),
    ]

    operations = [
        migrations.RunPython(creer_permission, supprimer_permission),
    ]