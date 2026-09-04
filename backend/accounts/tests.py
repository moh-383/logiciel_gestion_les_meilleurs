
from django.urls import reverse
from rest_framework.test import APITestCase

from core.models import Permission, Poste, Site
from .models import Utilisateur


class AuthentificationApiTests(APITestCase):
    def setUp(self):
        self.site = Site.objects.create(nom="Ouaga")
        self.poste = Poste.objects.create(nom="Secrétaire")

        permission = Permission.objects.create(
            code="gerer_eleves",
            libelle="Gérer élèves",
        )
        self.poste.permissions.add(permission)

        self.user = Utilisateur.objects.create_user(
            "+22670000000",
            "mot-de-passe-solide",
            nom="Awa",
            poste=self.poste,
            site=self.site,
        )

    def test_login_retourne_jetons_et_profil(self):
        response = self.client.post(
            "/api/v1/auth/login",
            {
                "telephone": "+22670000000",
                "mot_de_passe": "mot-de-passe-solide",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        self.assertIn("access_token", response.data)
        self.assertEqual(
            response.data["utilisateur"]["site_id"],
            str(self.site.id),
        )
        self.assertEqual(
            response.data["utilisateur"]["poste"]["permissions"],
            ["gerer_eleves"],
        )

    def test_mauvais_mot_de_passe_est_non_authentifie(self):
        response = self.client.post(
            "/api/v1/auth/login",
            {
                "telephone": "+22670000000",
                "mot_de_passe": "incorrect",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 401)
        self.assertEqual(
            response.data["error"],
            "identifiants_invalides",
        )


class CloisonnementUtilisateurApiTests(APITestCase):
    def setUp(self):
        self.site_a = Site.objects.create(nom="Site A")
        self.site_b = Site.objects.create(nom="Site B")

        permission = Permission.objects.create(
            code="gerer_comptes",
            libelle="Gérer les comptes",
        )

        self.poste = Poste.objects.create(
            nom="Administrateur de site"
        )
        self.poste.permissions.add(permission)

        self.user = Utilisateur.objects.create_user(
            "+22670000001",
            "mot-de-passe-solide",
            nom="Utilisateur Site A",
            poste=self.poste,
            site=self.site_a,
        )

        self.autre_user = Utilisateur.objects.create_user(
            "+22670000002",
            "mot-de-passe-solide",
            nom="Utilisateur Site B",
            poste=self.poste,
            site=self.site_b,
        )

        self.client.force_authenticate(user=self.user)

    def test_liste_utilisateurs_filtree_par_site(self):
        response = self.client.get("/api/v1/utilisateurs/")

        self.assertEqual(response.status_code, 200)

        utilisateurs = response.data

        self.assertTrue(
            any(
                utilisateur["id"] == str(self.user.id)
                for utilisateur in utilisateurs
            )
        )

        self.assertFalse(
            any(
                utilisateur["id"] == str(self.autre_user.id)
                for utilisateur in utilisateurs
            )
        )

    def test_creation_utilisateur_dans_un_autre_site_est_refusee(self):
        response = self.client.post(
            "/api/v1/utilisateurs/",
            {
                "telephone": "+22670000003",
                "mot_de_passe": "mot-de-passe-solide",
                "nom": "Nouvel utilisateur",
                "poste_id": str(self.poste.id),
                "site_id": str(self.site_b.id),
            },
            format="json",
        )

        self.assertEqual(response.status_code, 403)

        self.assertFalse(
            Utilisateur.objects.filter(
                telephone="+22670000003"
            ).exists()
        )

    def test_modification_utilisateur_vers_un_autre_site_est_refusee(self):
        response = self.client.patch(
            f"/api/v1/utilisateurs/{self.autre_user.id}/",
            {
                "site_id": str(self.site_a.id),
            },
            format="json",
        )

        self.assertEqual(response.status_code, 404)

        self.autre_user.refresh_from_db()

        self.assertEqual(
            str(self.autre_user.site_id),
            str(self.site_b.id),
        )

