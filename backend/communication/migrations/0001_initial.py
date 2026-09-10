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
            name='Echange',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('client_uuid', models.UUIDField(blank=True, null=True, unique=True)),
                ('type_echange', models.CharField(choices=[('appel', 'Appel téléphonique'), ('reunion', 'Réunion'), ('incident_discipline', 'Incident disciplinaire'), ('remarque', 'Remarque'), ('autre', 'Autre')], default='remarque', max_length=30)),
                ('titre', models.CharField(max_length=200)),
                ('description', models.TextField(blank=True)),
                ('date_echange', models.DateTimeField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('cree_par', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='echanges_crees', to=settings.AUTH_USER_MODEL)),
                ('eleve', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='echanges', to='eleves.eleve')),
                ('site', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='echanges', to='core.site')),
            ],
            options={'ordering': ('-date_echange',)},
        ),
        migrations.AddIndex(
            model_name='echange',
            index=models.Index(fields=['eleve', '-date_echange'], name='comm_ech_eleve_date_idx'),
        ),
        migrations.AddIndex(
            model_name='echange',
            index=models.Index(fields=['site', '-date_echange'], name='comm_ech_site_date_idx'),
        ),
    ]