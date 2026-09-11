from django.test import TestCase
from rest_framework.test import APIClient

from accounts.models import Utilisateur

from .models import Permission, Poste, Site


class PosteApiTests(TestCase):
    """Tests de la gestion des permissions d'un poste."""

    def setUp(self):
        self.client = APIClient()

        # Poste à modifier
        self.poste = Poste.objects.create(
            nom="Secrétaire",
            tous_sites=False,
        )

        # Permissions disponibles
        self.permission_saisir = Permission.objects.create(
            code="saisir_paiement",
            libelle="Saisir un paiement",
        )

        self.permission_voir = Permission.objects.create(
            code="voir_finances",
            libelle="Voir les finances",
        )

        permission_gerer_comptes = Permission.objects.create(
            code="gerer_comptes",
            libelle="Gérer les comptes",
        )

        # Poste de direction avec la permission nécessaire
        poste_direction = Poste.objects.create(
            nom="Direction générale",
            tous_sites=True,
        )

        poste_direction.permissions.add(permission_gerer_comptes)

        # Utilisateur autorisé
        self.direction = Utilisateur.objects.create_user(
            "+22670000010",
            "mot-de-passe-solide",
            nom="Fatou",
            poste=poste_direction,
        )

    def test_definir_permissions_remplace_integralement_la_liste(self):
        """PUT remplace toutes les permissions existantes."""

        self.poste.permissions.add(self.permission_saisir)

        self.client.force_authenticate(self.direction)

        response = self.client.put(
            f"/api/v1/postes/{self.poste.id}/permissions",
            {"permissions": ["voir_finances"]},
            format="json",
        )

        self.assertEqual(response.status_code, 200)

        codes = set(
            self.poste.permissions.values_list("code", flat=True)
        )

        self.assertEqual(
            codes,
            {"voir_finances"},
        )

        self.assertEqual(
            response.data["permissions"],
            ["voir_finances"],
        )

    def test_code_permission_inconnu_est_rejete(self):
        """Une permission inexistante doit être refusée."""

        self.client.force_authenticate(self.direction)

        response = self.client.put(
            f"/api/v1/postes/{self.poste.id}/permissions",
            {"permissions": ["permission_qui_nexiste_pas"]},
            format="json",
        )

        self.assertEqual(response.status_code, 400)

    def test_utilisateur_sans_gerer_comptes_est_refuse(self):
        """Un utilisateur sans gerer_comptes reçoit 403."""

        poste_sans_droit = Poste.objects.create(
            nom="Enseignant",
        )

        utilisateur_sans_droit = Utilisateur.objects.create_user(
            "+22670000011",
            "mot-de-passe-solide",
            nom="Issa",
            poste=poste_sans_droit,
        )

        self.client.force_authenticate(utilisateur_sans_droit)

        response = self.client.put(
            f"/api/v1/postes/{self.poste.id}/permissions",
            {"permissions": ["voir_finances"]},
            format="json",
        )

        self.assertEqual(response.status_code, 403)

    def test_patch_generique_ne_modifie_pas_les_permissions(self):
        """PATCH /postes/{id} ne doit plus écrire les permissions."""

        self.poste.permissions.add(self.permission_saisir)

        self.client.force_authenticate(self.direction)

        response = self.client.patch(
            f"/api/v1/postes/{self.poste.id}",
            {"permissions": ["voir_finances"]},
            format="json",
        )

        self.assertEqual(response.status_code, 200)

        codes = set(
            self.poste.permissions.values_list("code", flat=True)
        )

        self.assertEqual(
            codes,
            {"saisir_paiement"},
        )


class SiteApiTests(TestCase):
    """Le POST site doit être immédiatement observable dans la liste API."""

    def setUp(self):
        self.client = APIClient()
        permission = Permission.objects.create(
            code="gerer_comptes", libelle="Gérer les comptes"
        )
        poste = Poste.objects.create(nom="Direction", tous_sites=True)
        poste.permissions.add(permission)
        self.direction = Utilisateur.objects.create_user(
            "+22670009999", "mot-de-passe-solide", nom="Direction", poste=poste
        )
        self.client.force_authenticate(self.direction)

    def test_site_cree_apparait_dans_la_liste(self):
        response = self.client.post("/api/v1/sites", {"nom": "Koudougou"}, format="json")

        self.assertEqual(response.status_code, 201)
        self.assertTrue(Site.objects.filter(nom="Koudougou").exists())

        liste = self.client.get("/api/v1/sites")
        self.assertEqual(liste.status_code, 200)
        self.assertIn("Koudougou", [site["nom"] for site in liste.data["data"]])
