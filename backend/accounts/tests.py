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


class UtilisateurCloisonnementApiTests(APITestCase):
    """Sprint 5 — durcissement du cloisonnement par site sur UtilisateurViewSet."""

    def setUp(self):
        self.site_a = Site.objects.create(nom="Ouaga 2000")
        self.site_b = Site.objects.create(nom="Bobo")

        self.poste_secretaire = Poste.objects.create(nom="Secrétaire", tous_sites=False)
        self.poste_direction = Poste.objects.create(nom="Direction générale", tous_sites=True)
        gerer_comptes = Permission.objects.create(code="gerer_comptes", libelle="Gérer comptes")
        self.poste_secretaire.permissions.add(gerer_comptes)
        self.poste_direction.permissions.add(gerer_comptes)

        self.secretaire_a = Utilisateur.objects.create_user(
            "+22670000001", "mot-de-passe-solide", nom="Awa (site A)",
            poste=self.poste_secretaire, site=self.site_a,
        )
        self.secretaire_b = Utilisateur.objects.create_user(
            "+22670000002", "mot-de-passe-solide", nom="Issa (site B)",
            poste=self.poste_secretaire, site=self.site_b,
        )
        self.direction = Utilisateur.objects.create_user(
            "+22670000003", "mot-de-passe-solide", nom="Fatou (direction)",
            poste=self.poste_direction, site=None,
        )

    def test_liste_est_filtree_par_site_sans_parametre_client(self):
        self.client.force_authenticate(self.secretaire_a)
        response = self.client.get("/api/v1/utilisateurs")
        self.assertEqual(response.status_code, 200)
        noms = {u["nom"] for u in response.data["data"]}
        self.assertEqual(noms, {"Awa (site A)"})

    def test_parametre_site_id_ne_permet_pas_de_sortir_du_perimetre(self):
        self.client.force_authenticate(self.secretaire_a)
        response = self.client.get(f"/api/v1/utilisateurs?site_id={self.site_b.id}")
        self.assertEqual(response.status_code, 403)

    def test_parametre_site_id_sur_son_propre_site_fonctionne(self):
        self.client.force_authenticate(self.secretaire_a)
        response = self.client.get(f"/api/v1/utilisateurs?site_id={self.site_a.id}")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data["data"]), 1)

    def test_direction_voit_tous_les_sites(self):
        self.client.force_authenticate(self.direction)
        response = self.client.get("/api/v1/utilisateurs")
        self.assertEqual(response.status_code, 200)
        noms = {u["nom"] for u in response.data["data"]}
        self.assertEqual(noms, {"Awa (site A)", "Issa (site B)", "Fatou (direction)"})

    def test_detail_hors_perimetre_renvoie_404_pas_403(self):
        self.client.force_authenticate(self.secretaire_a)
        response = self.client.get(f"/api/v1/utilisateurs/{self.secretaire_b.id}")
        self.assertEqual(response.status_code, 404)

    def test_creation_avec_site_hors_perimetre_est_refusee(self):
        self.client.force_authenticate(self.secretaire_a)
        response = self.client.post("/api/v1/utilisateurs", {
            "nom": "Nouveau compte", "telephone": "+22670000099",
            "mot_de_passe": "mot-de-passe-solide",
            "site_id": str(self.site_b.id),
        }, format="json")
        self.assertEqual(response.status_code, 403)

    def test_creation_sans_site_est_rattachee_automatiquement_au_site_du_createur(self):
        self.client.force_authenticate(self.secretaire_a)
        response = self.client.post("/api/v1/utilisateurs", {
            "nom": "Nouveau compte", "telephone": "+22670000098",
            "mot_de_passe": "mot-de-passe-solide",
        }, format="json")
        self.assertEqual(response.status_code, 201)
        cree = Utilisateur.objects.get(telephone="+22670000098")
        self.assertEqual(cree.site_id, self.site_a.id)

    def test_deplacement_vers_site_hors_perimetre_est_refuse(self):
        self.client.force_authenticate(self.secretaire_a)
        response = self.client.patch(f"/api/v1/utilisateurs/{self.secretaire_a.id}", {
            "site_id": str(self.site_b.id),
        }, format="json")
        self.assertEqual(response.status_code, 403)

    def test_direction_peut_creer_sur_nimporte_quel_site(self):
        self.client.force_authenticate(self.direction)
        response = self.client.post("/api/v1/utilisateurs", {
            "nom": "Compte direction", "telephone": "+22670000097",
            "mot_de_passe": "mot-de-passe-solide",
            "site_id": str(self.site_b.id),
        }, format="json")
        self.assertEqual(response.status_code, 201)