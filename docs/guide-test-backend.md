# Guide de test — API Django et Paiements

Ce guide permet de vérifier le backend sans Flutter ni PostgreSQL, grâce à une
base SQLite locale temporaire. **SQLite est seulement un mode de test** : le
déploiement et l'intégration multi-sites utiliseront PostgreSQL.

## 1. Préparer l'environnement

Dans PowerShell :

```powershell
cd C:\Users\USER\Documents\logiciel_gestion_les_meilleurs\backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
$env:DJANGO_USE_SQLITE = "true"
python manage.py migrate
```

Résultat attendu : plusieurs lignes `Applying ... OK` et aucune erreur rouge.

> Si PowerShell refuse l'activation, lancez une seule fois
> `Set-ExecutionPolicy -Scope Process Bypass`, puis réessayez.

## 2. Vérifier automatiquement le projet

```powershell
$env:DJANGO_USE_SQLITE = "true"
python manage.py check
python manage.py test accounts eleves paiements
```

Résultats attendus :

- `System check identified no issues (0 silenced).`
- `Ran 7 tests ... OK`.

Si l'un de ces résultats n'apparaît pas, ne poussez pas le code : copiez l'erreur
complète pour la corriger avant le commit.

## 3. Créer des données de démonstration

Toujours dans `backend`, après les migrations :

```powershell
python manage.py shell
```

Collez le bloc suivant, puis pressez Entrée deux fois :

```python
from core.models import Site, Poste, Permission
from accounts.models import Utilisateur
from eleves.models import Eleve, Echeance

site, _ = Site.objects.get_or_create(nom="Ouagadougou")
poste, _ = Poste.objects.get_or_create(nom="Administrateur test", defaults={"tous_sites": True})
poste.tous_sites = True
poste.save()

for code, libelle in [
    ("gerer_comptes", "Gérer les comptes"),
    ("gerer_eleves", "Gérer les élèves"),
    ("saisir_paiement", "Saisir les paiements"),
    ("voir_finances", "Voir les finances"),
    ("valider_actions_sensibles", "Valider les actions sensibles"),
]:
    permission, _ = Permission.objects.get_or_create(code=code, defaults={"libelle": libelle})
    poste.permissions.add(permission)

user, _ = Utilisateur.objects.get_or_create(
    telephone="+22670000000",
    defaults={"nom": "Administrateur test", "poste": poste, "site": site},
)
user.nom, user.poste, user.site, user.is_active = "Administrateur test", poste, site, True
user.set_password("MotDePasse123!")
user.save()

eleve, _ = Eleve.objects.get_or_create(
    matricule="ELV-DEMO-001",
    defaults={"nom": "Kaboré", "prenom": "Adama", "sexe": "M", "site": site, "classe": "3ème B", "type_cours": "renforcement_regulier"},
)
echeance, _ = Echeance.objects.get_or_create(
    eleve=eleve,
    montant_du=15000,
    date_echeance="2026-08-20",
)
print(f"SITE_ID={site.id}")
print(f"ELEVE_ID={eleve.id}")
print(f"ECHEANCE_ID={echeance.id}")
exit()
```

Résultat attendu : trois lignes `SITE_ID=`, `ELEVE_ID=` et `ECHEANCE_ID=`.
Copiez ces UUID ; ils seront utilisés dans les étapes suivantes.

## 4. Lancer le serveur

Dans le premier terminal :

```powershell
$env:DJANGO_USE_SQLITE = "true"
python manage.py runserver
```

Résultat attendu : `Starting development server at http://127.0.0.1:8000/`.
Laissez ce terminal ouvert.

## 5. Vérifier login et synchronisation offline

Ouvrez un deuxième PowerShell et exécutez :

```powershell
$loginBody = @{ telephone = "+22670000000"; mot_de_passe = "MotDePasse123!" } | ConvertTo-Json
$login = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/v1/auth/login" -ContentType "application/json" -Body $loginBody
$headers = @{ Authorization = "Bearer $($login.access_token)" }
$login.utilisateur
```

Résultat attendu : le profil `Administrateur test`, son `site_id` et la liste
des permissions. Une réponse 401 signifie que le compte ou le mot de passe
n'ont pas été créés correctement.

Remplacez `COLLER_ECHEANCE_ID` par l'UUID obtenu à l'étape 3 :

```powershell
$syncBody = @{
  paiements = @(@{
    client_uuid = "11111111-1111-4111-8111-111111111111"
    echeance_id = "COLLER_ECHEANCE_ID"
    montant = 15000
    mode_paiement = "especes"
    note = "Test hors ligne"
    date_locale = "2026-09-04T10:15:00Z"
  })
} | ConvertTo-Json -Depth 5

$sync = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8000/api/v1/sync/paiements" -Headers $headers -ContentType "application/json" -Body $syncBody
$sync
```

Résultat attendu : `resultats[0].statut = cree` et un `paiement_id` UUID.

Exécutez exactement la même commande une seconde fois. Résultat attendu : même
`paiement_id`, toujours `cree`, sans nouveau paiement créé. C'est le test
d'idempotence indispensable au mode offline-first.

## 6. Vérifier le résultat côté API

```powershell
Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:8000/api/v1/eleves/COLLER_ELEVE_ID/paiements" -Headers $headers
Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:8000/api/v1/sites/COLLER_SITE_ID/stats/paiements" -Headers $headers
```

Résultat attendu : un seul paiement dans `data`; les statistiques affichent
`montant_collecte: 15000`, `montant_attendu: 15000` et
`taux_recouvrement: 1`.

## 7. À ne pas confondre

- `client_uuid` : UUID créé par Flutter et persistant localement ; c'est la
  clé anti-doublon.
- `paiement_id` : UUID généré par le serveur après acceptation.
- `401` : token absent ou expiré ; il faut appeler `/auth/refresh` ou se reconnecter.
- `403` : permission ou site insuffisant.
- `conflit` dans `resultats` : aucun paiement n'est créé ; l'élément reste à
  arbitrer dans le mobile.
