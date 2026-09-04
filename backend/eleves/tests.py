from rest_framework.test import APITestCase

from accounts.models import Utilisateur
from core.models import Permission, Poste, Site


class EleveApiTests(APITestCase):
    def setUp(self):
        self.site = Site.objects.create(nom="Ouaga")
        self.autre_site = Site.objects.create(nom="Bobo")
        poste = Poste.objects.create(nom="Secrétaire")
        poste.permissions.add(Permission.objects.create(code="gerer_eleves", libelle="Gérer élèves"))
        self.user = Utilisateur.objects.create_user("+22671111111", "mot-de-passe-solide", nom="Moussa", poste=poste, site=self.site)
        self.client.force_authenticate(self.user)

    def test_creation_eleve_et_contacts_dans_son_site(self):
        response = self.client.post("/api/v1/eleves", {
            "matricule": "ELV-001", "nom": "Kaboré", "prenom": "Adama", "date_naissance": "2011-03-14",
            "sexe": "M", "site_id": str(self.site.id), "classe": "3ème B", "type_cours": "renforcement_regulier",
            "contacts": [{"nom": "Fatou Kaboré", "telephone": "+22670123456", "lien": "mère"}],
        }, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertEqual(len(response.data["contacts"]), 1)
        self.assertEqual(self.client.get("/api/v1/eleves").data["data"][0]["matricule"], "ELV-001")

    def test_creation_dans_un_autre_site_est_refusee(self):
        response = self.client.post("/api/v1/eleves", {
            "matricule": "ELV-002", "nom": "Traoré", "prenom": "Issa", "sexe": "M",
            "site_id": str(self.autre_site.id), "classe": "Terminale", "type_cours": "renforcement_regulier",
        }, format="json")
        self.assertEqual(response.status_code, 403)
