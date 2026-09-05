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

        from decimal import Decimal

from rest_framework.test import APITestCase

from accounts.models import Utilisateur
from core.models import Permission, Poste, Site
from paiements.models import Paiement
from .models import Echeance, Eleve

class EleveApiTests(APITestCase):
    pass



class EleveResumeFinancierApiTests(APITestCase):
    """Sprint 5 — résumé financier intégré à la fiche élève."""

    def setUp(self):
        self.site = Site.objects.create(nom="Ouaga")
        poste = Poste.objects.create(nom="Secrétaire")
        poste.permissions.add(Permission.objects.create(code="gerer_eleves", libelle="Gérer élèves"))
        self.user = Utilisateur.objects.create_user("+22671111111", "mot-de-passe-solide", nom="Moussa", poste=poste, site=self.site)
        self.client.force_authenticate(self.user)

        self.eleve = Eleve.objects.create(
            matricule="ELV-010", nom="Ouédraogo", prenom="Salimata", sexe="F",
            site=self.site, classe="Terminale D", type_cours="renforcement_regulier",
        )
        echeance_soldee = Echeance.objects.create(
            eleve=self.eleve, montant_du=Decimal("15000"), date_echeance="2026-01-01", statut="a_jour",
        )
        echeance_retard = Echeance.objects.create(
            eleve=self.eleve, montant_du=Decimal("30000"), date_echeance="2026-08-01", statut="retard",
        )
        Paiement.objects.create(
            client_uuid="11111111-1111-1111-1111-111111111111",
            echeance=echeance_soldee, montant=Decimal("15000"), mode_paiement="especes",
            date_paiement="2026-01-05T10:00:00Z", saisi_par=self.user, statut="valide",
        )
        Paiement.objects.create(
            client_uuid="22222222-2222-2222-2222-222222222222",
            echeance=echeance_retard, montant=Decimal("5000"), mode_paiement="especes",
            date_paiement="2026-08-10T10:00:00Z", saisi_par=self.user, statut="valide",
        )

    def test_fiche_eleve_expose_le_resume_financier(self):
        response = self.client.get(f"/api/v1/eleves/{self.eleve.id}")
        self.assertEqual(response.status_code, 200)
        resume = response.data["resume_financier"]
        self.assertEqual(Decimal(resume["montant_du_total"]), Decimal("45000"))
        self.assertEqual(Decimal(resume["montant_paye_total"]), Decimal("20000"))
        self.assertEqual(Decimal(resume["solde_restant"]), Decimal("25000"))
        self.assertEqual(resume["statut_global"], "retard")
        self.assertGreater(resume["jours_retard_max"], 0)

    def test_liste_eleves_nexpose_pas_le_resume_financier(self):
        response = self.client.get("/api/v1/eleves")
        self.assertEqual(response.status_code, 200)
        self.assertNotIn("resume_financier", response.data["data"][0])
