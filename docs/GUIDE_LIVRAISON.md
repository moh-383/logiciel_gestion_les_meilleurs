# Guide de livraison et de reprise

## Architecture

```text
Flutter mobile -> API REST Django -> PostgreSQL
       |                ^
       v                |
  Drift SQLite -> synchronisation paiements/élèves/échanges
Next.js dashboard -> API REST Django -> PostgreSQL
```

- `backend/` : API Django REST, JWT, permissions et migrations.
- `mobile/` : opérations terrain et stockage local Drift.
- `web/` : dashboard Direction avec statistiques financières serveur.
- `docs/` : contrat API, tests, livraison et démonstration.

Le périmètre de site est contrôlé par l'API, jamais par le seul frontend.

## Prérequis et installation

Versions observées : Python 3.13.7, Node.js 22.18.0, npm 10.9.3, Dart 3.13.2
et Flutter 3.47.2. Prévoir PostgreSQL, Android Studio et Firebase si FCM est
activé.

Dans `backend/` :

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
$env:DJANGO_USE_SQLITE = "true"
python manage.py migrate
python manage.py runserver
```

SQLite est réservé au test local. Pour PostgreSQL, ne définissez pas
`DJANGO_USE_SQLITE` et renseignez `POSTGRES_DB`, `POSTGRES_USER`,
`POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_PORT`, `DJANGO_SECRET_KEY`,
`DJANGO_DEBUG`, `DJANGO_ALLOWED_HOSTS` et `DJANGO_CORS_ALLOWED_ORIGINS`.
Ne placez jamais ces secrets dans Git.

Dans `web/` :

```powershell
npm ci
$env:NEXT_PUBLIC_API_BASE_URL = "http://127.0.0.1:8000/api/v1"
npm run dev
```

Dans `mobile/` :

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Pour un appareil physique ou le bureau, remplacez `10.0.2.2` par l'adresse
accessible de l'API. Les fichiers Firebase doivent correspondre à
l'environnement concerné.

> Dans PowerShell, copiez l'URL seule : jamais une URL Markdown telle que
> `[http://…](http://…)`. Pour Android Emulator, utilisez `10.0.2.2` ; pour
> Windows ou macOS desktop, utilisez `127.0.0.1` ; pour un téléphone réel,
> utilisez l'IP Wi-Fi du PC et démarrez Django avec `python manage.py runserver 0.0.0.0:8000`.

## Administration et reprise

Créer le premier compte Direction via `python manage.py shell`, avec un poste
multi-sites et les permissions `gerer_comptes`, `gerer_eleves`,
`saisir_paiement`, `voir_finances` et `valider_actions_sensibles`.

Ensuite, gérer les sites, utilisateurs et postes dans Administration. Touchez
un poste pour affecter ses permissions ; l'action est validée côté serveur.

Un élève est désactivé avec le statut `Inactif`, jamais supprimé physiquement :
ses échéances, paiements et historiques restent conservés. Dans sa fiche,
ouvrez **Modifier l'élève**, choisissez ce statut et enregistrez.

Le catalogue **Permissions** est volontairement en lecture seule : il montre
les droits possibles. Touchez un élément de **Postes** pour les attribuer à un
poste. Une demande de validation apparaît après **Demander annulation** sur
un paiement synchronisé ; elle est visible et traitable par un poste ayant
`valider_actions_sensibles`.

## Tests et synchronisation

```powershell
# backend/
$env:DJANGO_USE_SQLITE = "true"
python manage.py check
python manage.py test

# mobile/
flutter test
flutter analyze

# web/
npm run lint
npm run build
```

Test de référence : créer un paiement hors connexion, vérifier le bandeau en
attente, rétablir le réseau, synchroniser, contrôler `GET /eleves/{id}/paiements`,
répéter avec le même `client_uuid` sans doublon, puis actualiser le dashboard.
Le détail des appels est dans `docs/guide-test-backend.md`.

## Diagnostic et déploiement

- URL mobile : `mobile/lib/core/api_config.dart` et `--dart-define`.
- URL dashboard : `NEXT_PUBLIC_API_BASE_URL`.
- logs API : terminal Django ; erreurs `{error, message}`.
- migrations : `python manage.py makemigrations`, puis `python manage.py migrate`.
- sauvegarde PostgreSQL : `pg_dump`; restauration validée par `pg_restore` sur staging.

## Vérification Firebase / notifications push

La configuration Android présente dans le dépôt utilise le plugin Google
Services 4.5.0 ; il n'est pas nécessaire de le remplacer par 4.4.2. Les
identifiants Android et iOS attendus sont tous deux
`com.CoursDAppuiLesMeilleurs.mobile`.

Avant de tester un push réel :

1. Vérifiez que `mobile/android/app/google-services.json` et
   `mobile/ios/Runner/GoogleService-Info.plist` proviennent du même projet
   Firebase et correspondent exactement à ces identifiants.
2. Dans Firebase, activez Cloud Messaging. Pour iOS, ajoutez aussi la clé APNs
   (ou le certificat APNs) dans la configuration Cloud Messaging du projet,
   puis activez Push Notifications et Background Modes / Remote notifications
   dans la cible Xcode.
3. Générez une clé de compte de service Admin SDK, conservez-la hors du dépôt,
   puis définissez `FIREBASE_CREDENTIALS_PATH` vers ce fichier pour Django.
4. Sur un appareil physique, connectez-vous, acceptez la permission de
   notification, vérifiez que `PATCH /utilisateurs/me/fcm-token` enregistre un
   token, puis lancez la commande Django de notification des retards. Vérifiez
   le statut `envoyee` ou `echec` dans la table/route Notifications.

Les deux fichiers de configuration mobile et toute clé de service sont ignorés
par Git. Ne copiez jamais de clé Admin SDK dans le code, un fichier `.env`
versionné ou une capture d'écran partagée.

Avant production :

- [ ] `DEBUG=false`, secrets hors Git et HTTPS
- [ ] CORS limité aux vraies origines
- [ ] sauvegardes PostgreSQL restaurables
- [ ] migrations et comptes Direction appliqués
- [ ] URL API HTTPS partagée par mobile et dashboard
- [ ] tests, cloisonnement inter-sites et synchronisation réelle validés
- [ ] Firebase production configuré si utilisé

Le module Enseignants est enregistré dans Django et accessible dans le mobile
aux postes ayant les droits `gerer_enseignants` ou `voir_pedagogie`. Le parcours
de recette correspondant est détaillé dans `GUIDE_RECETTE_COMPLETE.md`.
