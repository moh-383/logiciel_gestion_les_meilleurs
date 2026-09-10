from django.db import migrations


def creer_permission(apps, schema_editor):
    Permission = apps.get_model('core', 'Permission')
    Permission.objects.get_or_create(
        code='recevoir_alertes_paiement',
        defaults={'libelle': 'Recevoir les notifications de retard de paiement'},
    )


def supprimer_permission(apps, schema_editor):
    apps.get_model('core', 'Permission').objects.filter(
        code='recevoir_alertes_paiement'
    ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(creer_permission, supprimer_permission),
    ]