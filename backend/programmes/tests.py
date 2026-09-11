from datetime import date, timedelta

from rest_framework.test import APITestCase

from accounts.models import Utilisateur
from core.models import Permission, Poste, Site
from eleves.models import Echeance, Eleve

from .models import GroupeProgramme, InscriptionProgramme, Programme, SessionProgramme, TarifProgramme


class Lot3ApiTests(APITestCase):
    def setUp(self):
        self.site = Site.objects.create(nom="Ouagadougou Lot 3")
        self.autre_site = Site.objects.create(nom="Bobo Lot 3")
        poste = Poste.objects.create(nom="Gestionnaire Lot 3")
        for code in (
            "gerer_programmes",
            "gerer_tarifs",
            "inscrire_programmes",
            "voir_programmes",
            "saisir_resultats_examens",
            "valider_actions_sensibles",
        ):
            poste.permissions.add(Permission.objects.get_or_create(code=code, defaults={"libelle": code})[0])
        self.user = Utilisateur.objects.create_user("+22670101010", "mot-de-passe-solide", nom="Awa", poste=poste, site=self.site)
        self.client.force_authenticate(self.user)
        self.eleve = Eleve.objects.create(matricule="L3-001", nom="Kaboré", prenom="Awa", sexe="F", site=self.site, classe="Terminale", type_cours="regulier")
        self.programme = Programme.objects.create(type="bac", nom="Prépa Bac", annee_scolaire="2026-2027", statut="ouvert", matieres=["Maths"])
        self.session = SessionProgramme.objects.create(programme=self.programme, site=self.site, intitule="Prépa Bac octobre", date_debut=date.today() + timedelta(days=1), date_fin=date.today() + timedelta(days=31), capacite=10, statut="ouvert")
        self.groupe = GroupeProgramme.objects.create(session=self.session, niveau="Terminale", matiere="Maths", capacite=1)
        TarifProgramme.objects.create(site=self.site, groupe=self.groupe, montant=15000, debut_validite=date.today())

    def _brouillon(self, eleve=None):
        return InscriptionProgramme.objects.create(eleve=eleve or self.eleve, groupe=self.groupe, remise=1000, motif_remise="Bourse")

    def test_confirmation_genere_echeance_et_fige_tarif(self):
        inscription = self._brouillon()
        response = self.client.post(f"/api/v1/inscriptions-programmes/{inscription.id}/confirmer")
        self.assertEqual(response.status_code, 200)
        inscription.refresh_from_db()
        self.assertEqual(inscription.statut, "confirmee")
        self.assertEqual(inscription.tarif_fixe, 15000)
        self.assertEqual(Echeance.objects.get(inscription_programme=inscription).montant_du, 14000)

    def test_confirmation_refuse_depassement_capacite(self):
        premiere = self._brouillon()
        self.client.post(f"/api/v1/inscriptions-programmes/{premiere.id}/confirmer")
        autre = Eleve.objects.create(matricule="L3-002", nom="Sawadogo", prenom="Issa", sexe="M", site=self.site, classe="Terminale", type_cours="regulier")
        seconde = self._brouillon(autre)
        response = self.client.post(f"/api/v1/inscriptions-programmes/{seconde.id}/confirmer")
        self.assertEqual(response.status_code, 400)
        self.assertEqual(Echeance.objects.count(), 1)

    def test_inscription_hors_site_est_refusee(self):
        eleve_externe = Eleve.objects.create(matricule="L3-003", nom="Traoré", prenom="Ali", sexe="M", site=self.autre_site, classe="Terminale", type_cours="regulier")
        response = self.client.post("/api/v1/inscriptions-programmes", {"eleve": str(eleve_externe.id), "groupe": str(self.groupe.id)}, format="json")
        self.assertEqual(response.status_code, 403)

    def test_annulation_session_annule_echeance_non_reglee(self):
        inscription = self._brouillon()
        self.client.post(f"/api/v1/inscriptions-programmes/{inscription.id}/confirmer")
        response = self.client.post(f"/api/v1/sessions-programmes/{self.session.id}/annuler")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["statut"], "annule")
        self.assertEqual(Echeance.objects.get().statut, "annulee")

    def test_resultat_bac_et_statistiques(self):
        inscription = self._brouillon()
        self.client.post(f"/api/v1/inscriptions-programmes/{inscription.id}/confirmer")
        inscription.refresh_from_db()
        cree = self.client.post("/api/v1/resultats-examens", {"inscription": str(inscription.id), "note": "14.50", "observation": "Bon travail"}, format="json")
        self.assertEqual(cree.status_code, 201)
        self.assertTrue(cree.data["admis"])
        stats = self.client.get(f"/api/v1/programmes/{self.programme.id}/statistiques-examens")
        self.assertEqual(stats.status_code, 200)
        self.assertEqual(stats.data["admis"], 1)
        self.assertEqual(stats.data["resultats_saisis"], 1)
