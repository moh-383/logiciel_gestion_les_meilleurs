from django.utils import timezone
from rest_framework.test import APITestCase

from accounts.models import Utilisateur
from core.models import Permission, Poste, Site
from eleves.models import Echeance, Eleve

from .models import Notification
from .services import notifier_retards_du_jour, recalculer_statuts_du_jour


class NotificationsRetardsTests(APITestCase):
    def setUp(self):
        self.site = Site.objects.create(nom="Ouaga")
        poste = Poste.objects.create(nom="Secrétaire")
        permission = Permission.objects.get(code="recevoir_alertes_paiement")
        poste.permissions.add(permission)
        self.secretaire = Utilisateur.objects.create_user(
            "+22670000001", "mot-de-passe-solide", nom="Awa", poste=poste, site=self.site
        )
        self.secretaire.fcm_token = "token-test"
        self.secretaire.save()

        self.eleve = Eleve.objects.create(
            matricule="ELV-001", nom="Kaboré", prenom="Adama", sexe="M",
            site=self.site, classe="3ème", type_cours="regulier",
        )
        self.echeance = Echeance.objects.create(
            eleve=self.eleve, montant_du=15000,
            date_echeance=timezone.localdate() - timezone.timedelta(days=5),
            statut="a_jour",
        )

    def test_recalcul_bascule_echeance_expiree_en_retard(self):
        recalculer_statuts_du_jour()
        self.echeance.refresh_from_db()
        self.assertEqual(self.echeance.statut, "retard")

    def test_notification_creee_pour_utilisateur_avec_permission_et_token(self):
        recalculer_statuts_du_jour()
        notifier_retards_du_jour()
        notifs = Notification.objects.filter(destinataire=self.secretaire, canal="fcm")
        self.assertEqual(notifs.count(), 1)

    def test_pas_de_doublon_le_meme_jour(self):
        recalculer_statuts_du_jour()
        notifier_retards_du_jour()
        notifier_retards_du_jour()  # deuxième exécution le même jour
        notifs = Notification.objects.filter(destinataire=self.secretaire, canal="fcm")
        self.assertEqual(notifs.count(), 1)