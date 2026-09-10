import uuid

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('core', '0001_initial'),
        ('eleves', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Notification',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('type_notification', models.CharField(default='retard_paiement', max_length=50)),
                ('canal', models.CharField(choices=[('fcm', 'FCM'), ('sms', 'SMS')], max_length=10)),
                ('statut', models.CharField(default='en_attente', max_length=20)),
                ('message', models.TextField()),
                ('date_creation', models.DateTimeField(auto_now_add=True)),
                ('date_envoi', models.DateTimeField(blank=True, null=True)),
                ('destinataire', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='notifications_recues', to=settings.AUTH_USER_MODEL)),
                ('echeance', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='notifications', to='eleves.echeance')),
                ('eleve', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='notifications', to='eleves.eleve')),
                ('site', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='notifications', to='core.site')),
            ],
        ),
        migrations.AddIndex(
            model_name='notification',
            index=models.Index(fields=['site', 'date_creation'], name='notif_site_date_idx'),
        ),
    ]