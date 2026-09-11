from datetime import date
from rest_framework.test import APITestCase
from accounts.models import Utilisateur
from core.models import Permission, Poste, Site
from .models import AffectationEnseignant, Creneau, Seance


class PlanningEtRapportApiTests(APITestCase):
    def setUp(self):
        self.site = Site.objects.create(nom="Ouaga 2000")
        direction = Poste.objects.create(nom="Direction générale", tous_sites=True)
        direction.permissions.add(Permission.objects.create(code="gerer_enseignants", libelle="Gérer enseignants"))
        self.direction = Utilisateur.objects.create_user("+22670000010", "mot-de-passe-solide", nom="Fatou", poste=direction)
        poste = Poste.objects.create(nom="Enseignant")
        poste.permissions.add(Permission.objects.create(code="voir_pedagogie", libelle="Voir pédagogie"))
        self.enseignant = Utilisateur.objects.create_user("+22670000011", "mot-de-passe-solide", nom="Moussa", poste=poste, site=self.site)
        self.affectation = AffectationEnseignant.objects.create(enseignant=self.enseignant, site=self.site, classe="3ème B", matiere="Mathématiques", annee_scolaire="2026-2027")

    def test_direction_cree_une_affectation(self):
        self.client.force_authenticate(self.direction)
        response = self.client.post(f"/api/v1/enseignants/{self.enseignant.id}/affectations", {"site_id": str(self.site.id), "classe": "4ème A", "matiere": "Physique", "annee_scolaire": "2026-2027"}, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertEqual(AffectationEnseignant.objects.count(), 2)

    def test_enseignant_voit_son_planning_et_declare_sa_seance(self):
        Creneau.objects.create(affectation=self.affectation, jour_semaine=0, heure_debut="08:00", heure_fin="10:00")
        self.client.force_authenticate(self.enseignant)
        self.assertEqual(self.client.get("/api/v1/mon-planning").status_code, 200)
        response = self.client.post("/api/v1/seances", {"affectation_id": str(self.affectation.id), "date_seance": "2026-10-06", "statut": "tenue", "nb_presents": 28, "nb_absents": 2}, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertEqual(Seance.objects.count(), 1)

    def test_enseignant_ne_peut_pas_declarer_pour_un_collegue(self):
        autre = Utilisateur.objects.create_user("+22670000012", "mot-de-passe-solide", nom="Issa", poste=self.enseignant.poste, site=self.site)
        self.client.force_authenticate(autre)
        response = self.client.post("/api/v1/seances", {"affectation_id": str(self.affectation.id), "date_seance": "2026-10-06"}, format="json")
        self.assertEqual(response.status_code, 403)

    def test_rapport_mensuel_calcule_le_taux_de_presence(self):
        Seance.objects.create(affectation=self.affectation, date_seance=date(2026, 10, 6), statut="tenue", nb_presents=27, nb_absents=3)
        Seance.objects.create(affectation=self.affectation, date_seance=date(2026, 10, 13), statut="tenue", nb_presents=30, nb_absents=0)
        Seance.objects.create(affectation=self.affectation, date_seance=date(2026, 10, 20), statut="annulee")
        self.client.force_authenticate(self.direction)
        response = self.client.get(f"/api/v1/enseignants/{self.enseignant.id}/rapport-mensuel?mois=2026-10")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["nb_seances_tenues"], 2)
        self.assertAlmostEqual(response.data["taux_presence_moyen"], 0.95, places=2)
