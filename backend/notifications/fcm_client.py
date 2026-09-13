"""Wrapper minimal autour de firebase-admin, isolé du reste du code pour
rester mockable dans les tests sans dépendre d'un vrai projet Firebase."""
import base64
import json

import firebase_admin
from django.conf import settings
from firebase_admin import credentials, messaging

_app = None


def _app_firebase():
    global _app
    if _app is None:
        if settings.FIREBASE_CREDENTIALS_JSON_BASE64:
            try:
                service_account = json.loads(
                    base64.b64decode(settings.FIREBASE_CREDENTIALS_JSON_BASE64).decode("utf-8")
                )
            except (ValueError, UnicodeDecodeError, json.JSONDecodeError) as error:
                raise RuntimeError("FIREBASE_CREDENTIALS_JSON_BASE64 est invalide.") from error
            cred = credentials.Certificate(service_account)
        elif settings.FIREBASE_CREDENTIALS_PATH:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        else:
            raise RuntimeError("Configurez FIREBASE_CREDENTIALS_PATH ou FIREBASE_CREDENTIALS_JSON_BASE64.")
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
