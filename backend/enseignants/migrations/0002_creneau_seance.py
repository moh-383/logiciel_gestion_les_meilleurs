import django.core.validators
import django.db.models.deletion
import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("enseignants", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="Creneau",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("jour_semaine", models.PositiveSmallIntegerField(validators=[django.core.validators.MinValueValidator(0), django.core.validators.MaxValueValidator(6)])),
                ("heure_debut", models.TimeField()),
                ("heure_fin", models.TimeField()),
                ("actif", models.BooleanField(default=True)),
                ("affectation", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="creneaux", to="enseignants.affectationenseignant")),
            ],
        ),
        migrations.CreateModel(
            name="Seance",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("date_seance", models.DateField()),
                ("statut", models.CharField(choices=[("tenue", "Tenue"), ("annulee", "Annulée")], default="tenue", max_length=10)),
                ("nb_presents", models.PositiveSmallIntegerField(blank=True, null=True)),
                ("nb_absents", models.PositiveSmallIntegerField(blank=True, null=True)),
                ("commentaire", models.TextField(blank=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("affectation", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="seances", to="enseignants.affectationenseignant")),
                ("creneau", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="seances", to="enseignants.creneau")),
            ],
        ),
        migrations.AddIndex(model_name="creneau", index=models.Index(fields=["affectation", "jour_semaine"], name="enseignant_crn_jour_idx")),
        migrations.AddIndex(model_name="seance", index=models.Index(fields=["affectation", "date_seance"], name="enseignant_seance_date_idx")),
        migrations.AddConstraint(
            model_name="seance",
            constraint=models.UniqueConstraint(fields=("affectation", "date_seance"), name="une_seance_par_jour_et_affectation"),
        ),
    ]