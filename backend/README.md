# Backend — socle partagé

API Django REST du MVP : authentification JWT, utilisateurs/rôles, sites,
élèves, contacts parents et échéances. Les Paiements seront ajoutés dans une
application séparée qui référencera ce socle.

## Démarrage local

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
$env:DJANGO_USE_SQLITE = "true" # développement local seulement
python manage.py migrate
python manage.py runserver
```

Pour PostgreSQL, renseigner les variables `POSTGRES_*` de `.env.example` dans
l'environnement (l'application ne charge volontairement pas un fichier `.env`
elle-même), puis supprimer `DJANGO_USE_SQLITE`.

## Vérification

```powershell
$env:DJANGO_USE_SQLITE = "true"
python manage.py check
python manage.py test
```

Le guide pas à pas, avec données de démonstration, appels PowerShell et
résultats attendus, est disponible dans
[`docs/guide-test-backend.md`](../docs/guide-test-backend.md). Le guide de
revue et de push Git est dans [`docs/guide-push-git.md`](../docs/guide-push-git.md).

## Routes fournies

- `POST /api/v1/auth/login`, `/refresh`, `/logout`
- `/api/v1/utilisateurs`, `/postes`, `/permissions`, `/sites`
- `/api/v1/eleves`, `/contacts`, `/eleves/{id}/contacts`,
  `/eleves/{id}/echeances`

Les routes n'ont volontairement pas de slash terminal, conformément au contrat
API. Les requêtes protégées utilisent `Authorization: Bearer <access_token>`.
