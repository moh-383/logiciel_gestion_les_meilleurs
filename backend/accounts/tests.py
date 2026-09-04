from django.urls import reverse
from rest_framework.test import APITestCase

from core.models import Permission, Poste, Site
from .models import Utilisateur


class AuthentificationApiTests(APITestCase):
    def setUp(self):
        self.site = Site.objects.create(nom="Ouaga")
        self.poste = Poste.objects.create(nom="Secrétaire")
        permission = Permission.objects.create(code="gerer_eleves", libelle="Gérer élèves")
        self.poste.permissions.add(permission)
        self.user = Utilisateur.objects.create_user("+22670000000", "mot-de-passe-solide", nom="Awa", poste=self.poste, site=self.site)

    def test_login_retourne_jetons_et_profil(self):
        response = self.client.post("/api/v1/auth/login", {"telephone": "+22670000000", "mot_de_passe": "mot-de-passe-solide"}, format="json")
        self.assertEqual(response.status_code, 200)
        self.assertIn("access_token", response.data)
        self.assertEqual(response.data["utilisateur"]["site_id"], str(self.site.id))
        self.assertEqual(response.data["utilisateur"]["poste"]["permissions"], ["gerer_eleves"])

    def test_mauvais_mot_de_passe_est_non_authentifie(self):
        response = self.client.post("/api/v1/auth/login", {"telephone": "+22670000000", "mot_de_passe": "incorrect"}, format="json")
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.data["error"], "identifiants_invalides")
