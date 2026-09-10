from django.core.management.base import BaseCommand

from notifications.services import notifier_retards_du_jour, recalculer_statuts_du_jour


class Command(BaseCommand):
    help = "Recalcule les statuts d'échéances et notifie les retards du jour (à planifier une fois par jour)."

    def handle(self, *args, **options):
        recalculer_statuts_du_jour()
        notifier_retards_du_jour()
        self.stdout.write(self.style.SUCCESS("Vérification des retards terminée."))