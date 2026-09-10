from rest_framework.test import APITestCase

from accounts.models import Utilisateur
from core.models import Permission, Poste, Site
from eleves.models import Eleve

from .models import Echange


class EchangesApiTests(APITestCase):
    def setUp(self):
        self.site = Site.objects.create(nom="Ouaga")
        self.autre_site = Site.objects.create(nom="Bobo")
        poste = Poste.objects.create(nom="Enseignant")
        permission = Permission.objects.get(code="gerer_echanges")
        poste.permissions.add(permission)
        self.user = Utilisateur.objects.create_user(
            "+22672222222", "mot-de-passe-solide", nom="Issa", poste=poste, site=self.site
        )
        self.client.force_authenticate(self.user)
        self.eleve = Eleve.objects.create(
            matricule="ELV-100", nom="Sawadogo", prenom="Boureima", sexe="M",
            site=self.site, classe="2nde C", type_cours="regulier",
        )

    def test_creation_echange_dans_son_site(self):
        response = self.client.post(
            f"/api/v1/eleves/{self.eleve.id}/echanges",
            {"type_echange": "appel", "titre": "Appel maman", "date_echange": "2026-09-08T10:00:00Z"},
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["cree_par_nom"], "Issa")

    def test_sync_est_idempotente(self):
        corps = [{
            "client_uuid": "11111111-1111-1111-1111-111111111111",
            "eleve_id": str(self.eleve.id), "type_echange": "incident_discipline",
            "titre": "Bagarre en cour", "date_echange": "2026-09-08T10:00:00Z",
        }]
        premiere = self.client.post("/api/v1/sync/echanges", corps, format="json")
        deuxieme = self.client.post("/api/v1/sync/echanges", corps, format="json")
        self.assertEqual(premiere.data["resultats"][0]["statut"], "cree")
        self.assertEqual(deuxieme.data["resultats"][0]["statut"], "deja_existant")
        self.assertEqual(Echange.objects.count(), 1)

    def test_eleve_hors_site_est_refuse(self):
        eleve_autre_site = Eleve.objects.create(
            matricule="ELV-200", nom="Traoré", prenom="Ali", sexe="M",
            site=self.autre_site, classe="Terminale", type_cours="regulier",
        )
        response = self.client.post(
            f"/api/v1/eleves/{eleve_autre_site.id}/echanges",
            {"type_echange": "remarque", "titre": "Test", "date_echange": "2026-09-08T10:00:00Z"},
            format="json",
        )
        self.assertEqual(response.status_code, 403)