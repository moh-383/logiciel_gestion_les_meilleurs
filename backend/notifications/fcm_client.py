"""Wrapper minimal autour de firebase-admin, isolé du reste du code pour
rester mockable dans les tests sans dépendre d'un vrai projet Firebase."""
import firebase_admin
from django.conf import settings
from firebase_admin import credentials, messaging

_app = None


def _app_firebase():
    global _app
    if _app is None:
        if not settings.FIREBASE_CREDENTIALS_PATH:
            raise RuntimeError("FIREBASE_CREDENTIALS_PATH non configuré.")
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        _app = firebase_admin.initialize_app(cred)
    return _app


def envoyer_push_fcm(*, token: str, titre: str, corps: str) -> None:
    _app_firebase()
    messaging.send(
        messaging.Message(
            notification=messaging.Notification(title=titre, body=corps),
            token=token,
        )
    )