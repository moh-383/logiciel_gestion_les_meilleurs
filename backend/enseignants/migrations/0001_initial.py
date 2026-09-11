import uuid

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    initial = True
    dependencies = [("core", "0001_initial"), migrations.swappable_dependency(settings.AUTH_USER_MODEL)]

    operations = [
        migrations.CreateModel(name="AffectationEnseignant", fields=[
            ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
            ("classe", models.CharField(max_length=120)), ("matiere", models.CharField(blank=True, max_length=120)),
            ("annee_scolaire", models.CharField(max_length=9)), ("actif", models.BooleanField(default=True)),
            ("created_at", models.DateTimeField(auto_now_add=True)),
            ("enseignant", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="affectations_enseignement", to=settings.AUTH_USER_MODEL)),
            ("site", models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name="affectations", to="core.site")),
        ], options={"ordering": ("annee_scolaire", "classe", "matiere")}),
        migrations.AddConstraint(model_name="affectationenseignant", constraint=models.UniqueConstraint(fields=("enseignant", "site", "classe", "matiere", "annee_scolaire"), name="affectation_enseignant_unique")),
    ]
