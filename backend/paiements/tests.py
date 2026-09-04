import uuid

from rest_framework.test import APITestCase

from accounts.models import Utilisateur
from core.models import Permission, Poste, Site
from eleves.models import Echeance, Eleve
from .models import DemandeValidation, Paiement


class PaiementsApiTests(APITestCase):
    def setUp(self):
        self.site = Site.objects.create(nom="Ouagadougou")
        poste = Poste.objects.create(nom="Secrétaire")
        for code in ("saisir_paiement", "voir_finances", "valider_actions_sensibles"):
            poste.permissions.add(Permission.objects.create(code=code, libelle=code))
        self.user = Utilisateur.objects.create_user("+22670000000", "mot-de-passe-solide", nom="Awa", poste=poste, site=self.site)
        self.client.force_authenticate(self.user)
        self.eleve = Eleve.objects.create(matricule="ELV-001", nom="Kaboré", prenom="Adama", sexe="M", site=self.site, classe="3ème", type_cours="regulier")
        self.echeance = Echeance.objects.create(eleve=self.eleve, montant_du=15000, date_echeance="2026-08-01")

    def test_sync_est_idempotente_et_solde_echeance(self):
        client_uuid = str(uuid.uuid4())
        corps = {"paiements": [{"client_uuid": client_uuid, "echeance_id": str(self.echeance.id), "montant": "15000", "mode_paiement": "especes", "note": "Réglé hors ligne", "date_locale": "2026-09-04T10:15:00Z"}]}
        first = self.client.post("/api/v1/sync/paiements", corps, format="json")
        second = self.client.post("/api/v1/sync/paiements", corps, format="json")
        self.assertEqual(first.status_code, 200)
        self.assertEqual(first.data["resultats"][0]["statut"], "cree")
        self.assertEqual(second.data["resultats"][0]["paiement_id"], first.data["resultats"][0]["paiement_id"])
        self.assertEqual(Paiement.objects.count(), 1)
        self.echeance.refresh_from_db()
        self.assertEqual(self.echeance.statut, "a_jour")

    def test_sync_retourne_un_conflit_sans_creer_depassement(self):
        corps = {"paiements": [{"client_uuid": str(uuid.uuid4()), "echeance_id": str(self.echeance.id), "montant": "20000", "mode_paiement": "especes", "date_locale": "2026-09-04T10:15:00Z"}]}
        response = self.client.post("/api/v1/sync/paiements", corps, format="json")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["resultats"][0]["statut"], "conflit")
        self.assertEqual(Paiement.objects.count(), 0)

    def test_annulation_validee_annule_paiement_et_recalcule_echeance(self):
        paiement = Paiement.objects.create(client_uuid=uuid.uuid4(), echeance=self.echeance, montant=15000, mode_paiement="especes", date_paiement="2026-09-04T10:15:00Z", saisi_par=self.user)
        demande = self.client.post(f"/api/v1/paiements/{paiement.id}/demande-annulation", {"motif": "Double saisie"}, format="json")
        self.assertEqual(demande.status_code, 201)
        traite = self.client.patch(f"/api/v1/demandes-validation/{demande.data['id']}", {"statut": "validee", "commentaire": "Confirmé"}, format="json")
        self.assertEqual(traite.status_code, 200)
        paiement.refresh_from_db()
        self.echeance.refresh_from_db()
        self.assertEqual(paiement.statut, "annule")
        self.assertEqual(self.echeance.statut, "retard")
        self.assertEqual(DemandeValidation.objects.get().statut, "validee")
