# Déploiement de test : Railway, Vercel et Firebase

Ce guide publie un environnement de **test** distinct de la base locale. Ne
réutilisez jamais les mots de passe ou données réelles de l'école pour une
démonstration externe.

## 1. Préparer GitHub

Railway et Vercel déploient depuis GitHub. Vérifiez d'abord localement :

```powershell
cd C:\Users\USER\Documents\logiciel_gestion_les_meilleurs
cd backend; ..\.venv\Scripts\python.exe manage.py check; cd ..
cd web; npm run lint; npm run build; cd ..
git status
```

Commitez et poussez les changements voulus sur une branche dédiée, par exemple
`codex/deploiement-test`. Aucun secret, fichier Firebase Admin SDK ou `.env`
ne doit être ajouté au commit.

## 2. Railway : API Django et PostgreSQL

1. Créez un compte Railway avec GitHub puis créez un projet depuis le dépôt.
2. Pour le service issu du dépôt, définissez **Root Directory** sur `backend`.
   Railway utilisera `backend/railway.toml` : migrations avant déploiement,
   Gunicorn et sonde `/api/v1/health`.
3. Ajoutez un service PostgreSQL nommé `Postgres`.
4. Dans les variables du service backend, ajoutez les variables suivantes :

```text
POSTGRES_DB=${{Postgres.PGDATABASE}}
POSTGRES_USER=${{Postgres.PGUSER}}
POSTGRES_PASSWORD=${{Postgres.PGPASSWORD}}
POSTGRES_HOST=${{Postgres.PGHOST}}
POSTGRES_PORT=${{Postgres.PGPORT}}
DJANGO_SECRET_KEY=<secret long et unique>
DJANGO_DEBUG=false
DJANGO_ALLOWED_HOSTS=<domaine-railway-sans-https>
DJANGO_CORS_ALLOWED_ORIGINS=https://<domaine-vercel>
```

Ne définissez pas `DJANGO_USE_SQLITE` sur Railway. Générez le secret Django
localement, puis copiez seulement le résultat dans Railway :

```powershell
& ..\.venv\Scripts\python.exe -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

5. Dans Railway, générez le domaine public de l'API, puis vérifiez :

```powershell
Invoke-WebRequest https://<domaine-railway>/api/v1/health | Select-Object -Expand Content
```

La réponse attendue est `{"status": "ok"}`. Un appel à
`/api/v1/sites` sans jeton doit renvoyer 401.

## 3. Vercel — dashboard Direction

1. Importez le même dépôt GitHub dans Vercel.
2. Définissez **Root Directory** sur `web`.
3. Dans les variables d'environnement de Production et Preview, ajoutez :

```text
NEXT_PUBLIC_API_BASE_URL=https://<domaine-railway>/api/v1
```

4. Déployez. Copiez l'URL Vercel exacte dans
`DJANGO_CORS_ALLOWED_ORIGINS` sur Railway, puis redéployez le backend.
5. Connectez-vous au dashboard avec un compte créé dans la base Railway, pas
avec le compte de démonstration local.

## 4. Compte de test dans Railway

Dans le shell du service Railway, lancez `python manage.py shell`, puis créez
au minimum un site, un poste Direction et un utilisateur. Les permissions sont
déjà créées par les migrations ; ajoutez-les toutes au poste :

```python
from accounts.models import Utilisateur
from core.models import Permission, Poste, Site

site, _ = Site.objects.get_or_create(nom="Site de démonstration")
poste, _ = Poste.objects.get_or_create(nom="Direction test")
poste.tous_sites = True
poste.save()
poste.permissions.add(*Permission.objects.all())

user, _ = Utilisateur.objects.get_or_create(
    telephone="+22670000000",
    defaults={"nom": "Direction test", "poste": poste, "site": site},
)
user.nom, user.poste, user.site, user.is_active = "Direction test", poste, site, True
user.set_password("CHANGEZ-MOI-AVANT-PARTAGE")
user.save()
```

Remplacez le mot de passe avant d'inviter un testeur, puis transmettez-le par
un canal privé.

## 5. Firebase Cloud Messaging (facultatif pour la démo)

Les notifications ne sont activées que si vous ajoutez l'un des deux secrets :

- `FIREBASE_CREDENTIALS_JSON_BASE64` : recommandé pour Railway ;
- `FIREBASE_CREDENTIALS_PATH` : uniquement si l'hébergeur fournit le fichier.

Pour encoder localement le JSON Admin SDK sans l'ajouter à Git :

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\secrets\firebase-admin.json"))
```

Copiez le résultat dans la variable Railway
`FIREBASE_CREDENTIALS_JSON_BASE64`. Ne le communiquez à personne et ne le
collez jamais dans un terminal partagé, un commit ou une capture d'écran.

## 6. APK et Firebase App Distribution

Construisez l'APK avec l'URL Railway :

```powershell
cd C:\Users\USER\Documents\logiciel_gestion_les_meilleurs\mobile
flutter build apk --release --dart-define=API_BASE_URL=https://<domaine-railway>/api/v1
```

Après `firebase login`, envoyez-le au testeur :

```powershell
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk `
  --app <FIREBASE_ANDROID_APP_ID> `
  --testers "testeur@example.com" `
  --release-notes "Version de test connectée à l'environnement Railway"
```

Le lien d'installation et l'APK sont limités à la phase de test. Avant une
diffusion publique, configurez une clé de signature Android release privée.

## 7. Recette avant partage

1. Vérifier `/api/v1/health` et la connexion dashboard.
2. Créer un paiement, puis actualiser le dashboard et son détail de site.
3. Installer l'APK depuis Firebase sur un téléphone réel.
4. Tester hors-ligne, reconnexion et synchronisation.
5. Si FCM est activé : autoriser les notifications et vérifier le token mobile.
6. À la fin du test, supprimer les comptes et données de démonstration ou
   recréer l'environnement de test.
