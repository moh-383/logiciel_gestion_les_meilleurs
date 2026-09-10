from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0002_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='utilisateur',
            name='fcm_token',
            field=models.CharField(blank=True, max_length=255, null=True),
        ),
    ]