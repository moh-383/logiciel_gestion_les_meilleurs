# Audit d'intégration A ↔ B — 2026-09-04 (mise à jour)

> Ce document remplace `docs/audit-integration-2026-09-03.md`, devenu obsolète :
> il décrivait un backend "squelette vide", ce qui n'est plus le cas. Conserver
> l'ancien fichier comme archive historique si besoin, mais s'appuyer sur
> celui-ci pour la suite.

## Conclusion

Le socle backend (auth, permissions modulaires, isolement par site, paiements
+ synchronisation offline idempotente, workflow de validation) **existe et est
testé**. La chaîne n'est plus bloquée côté backend. En revanche, **deux bugs
mobile empêchaient toute intégration réelle** : un conflit Git non résolu qui
casse la compilation, et une persistance de session totalement inopérante.
Les deux sont corrigés dans cette itération (fichiers fournis séparément).

## État par couche (mise à jour)

| Couche | État | Constats |
|---|---|---|
| Backend Django — socle (`core`, `accounts`) | 🟢 Fait | `Site`, `Poste`, `Permission`, `Utilisateur` (custom user, téléphone), JWT (`/auth/login`, `/refresh`, `/logout`), permission modulaire `ALaPermissionMetier` basée sur `POSTE_PERMISSION`, pas de rôle en dur. |
| Backend Django — `eleves` | 🟢 Fait | `Eleve`, `ContactParent`, `Echeance`, endpoints CRUD, filtrage par site (`dans_perimetre`), recherche `?q=`. |
| Backend Django — `paiements` | 🟢 Fait | `Paiement` (idempotence via `client_uuid` unique), `DemandeValidation` (contrainte "une annulation en attente par paiement"), recalcul transactionnel du statut d'échéance, `POST /sync/paiements` en lot avec réponse par élément, workflow `demande-annulation` → `PATCH /demandes-validation/{id}` qui annule effectivement le paiement si validé. |
| PostgreSQL / SQLite dev | 🟢 Fait | Bascule via `DJANGO_USE_SQLITE`, config par variables d'environnement (`.env.example`). |
| Tests backend | 🟢 Fait | `accounts/tests.py`, `eleves/tests.py`, `paiements/tests.py` couvrent login, cloisonnement site, idempotence sync, conflit, workflow annulation. CI (`backend.yml`) exécute `ruff` + `pytest` avec Postgres de service. |
| Contrat `note` en sync | 🟢 Fait | `PaiementSyncSerializer` hérite de `PaiementEcritureSerializer`, qui inclut `note` (nullable) — le P1 signalé dans l'ancien audit est résolu côté serveur. |
| Mobile — saisie & stockage local | 🟡 Partiel | Drift fonctionnel (élèves, échéances, paiements, demandes de validation), UUID client généré (`uuid`), historique + demande d'annulation implémentés. Pas encore de contrôle du montant vs solde restant côté client (le serveur, lui, le fait). |
| Mobile — synchronisation | 🟡 Partiel → en cours de correction | Lot vers `/sync/paiements`, classification des erreurs (401 / 4xx métier / réseau), champ `note` transmis. **Bloqué jusqu'ici par un conflit Git non résolu (voir Bugs critiques).** |
| Mobile — authentification | 🔴 Cassé → corrigé | `TokenStore.save()` reposait sur une extension `writeAll` **vide** : aucune session n'était jamais persistée. Corrigé (voir ci-dessous). |
| Mobile — configuration réseau | 🟢 Correct | `apiBaseUrl` configurable via `--dart-define=API_BASE_URL=...`, valeur par défaut adaptée à l'émulateur Android. |
| Tests mobile | 🔴 Obsolète | `test/widget_test.dart` est encore le compteur par défaut Flutter — l'écran testé n'existe plus. À remplacer par des tests sur le formulaire d'encaissement, le calcul de solde et la synchro (mock Dio). |

## 🔴 Bugs critiques trouvés le 2026-09-04

### 1. Conflit de fusion Git non résolu — `mobile/lib/core/sync_service.dart`

Marqueurs `<<<<<<< HEAD` / `=======` / `>>>>>>> 34e8ff5...` laissés dans le
corps de `synchroniser()`. **Le fichier ne compile pas en l'état.**

Correction : fusionner les deux branches du conflit (envoi de `note` **et**
conservation du commentaire sur la conversion UTC). Fichier corrigé fourni :
`sync_service.dart` (à copier vers `mobile/lib/core/sync_service.dart`).

### 2. Persistance de session inopérante — `mobile/lib/core/auth_service.dart`

```dart
extension on FlutterSecureStorage {
  Future<void> writeAll(Map<String, String> storage) async {}
}
```

`FlutterSecureStorage` n'expose pas nativement `writeAll` : cette extension
"stub" ne fait **rien**. Conséquence : après un login réussi, aucune donnée
n'est écrite sur le disque sécurisé. `readSession()` renvoie systématiquement
`null` au redémarrage de l'app, et l'intercepteur Dio n'attache jamais de
`Authorization: Bearer ...` aux requêtes → tous les appels API échouent en 401,
y compris la synchronisation.

Correction : `TokenStore.save()` écrit désormais chaque paire clé/valeur
individuellement via `_storage.write(key:, value:)`. Fichier corrigé fourni :
`auth_service.dart` (à copier vers `mobile/lib/core/auth_service.dart`).

**Impact** : ces deux bugs, combinés, expliquent pourquoi "rien ne marchait"
même si chaque brique semblait correcte isolément. Une fois corrigés, le
scénario E2E (login → paiement local → synchro → confirmation serveur) décrit
dans `docs/guide-test-backend.md` peut réellement être exécuté de bout en bout
côté mobile.

## 🟡 Points de vigilance restants (P2 / à surveiller, pas bloquants)

- **Type des montants** : Drift stocke `montant` en `REAL` (double) côté
  mobile, alors que le backend utilise `DecimalField(max_digits=12,
  decimal_places=0)` (entier FCFA). Un montant flottant mal arrondi
  (ex. `14999.999999`) pourrait être rejeté ou mal interprété. Recommandation
  : envisager un entier natif (FCFA sans décimales) des deux côtés, ou au
  minimum arrondir explicitement avant sérialisation JSON.
- **Migration de la colonne `note`** : vérifier que l'ajout de la colonne
  `note` à `mobile/lib/data/tables.dart` (table `Paiements`) a bien été
  accompagné d'un incrément de `schemaVersion` + bloc `onUpgrade` (règle
  rappelée dans `CONTRIBUTING.md`). Les blocs actuels dans `database.dart`
  couvrent `matricule` (v2), `statut` + `demandesValidation` (v3),
  `syncRaison` (v4) — pas de trace explicite pour `note`. Si `note` existe
  depuis la version 1 du schéma, rien à faire ; sinon, un appareil ayant déjà
  la base installée plantera avec `SqliteException: no such column: note`.
  **À vérifier en priorité par B avant de livrer une nouvelle version aux
  testeurs terrain.**
- **Test mobile obsolète** : `mobile/test/widget_test.dart` teste un écran
  compteur qui n'existe plus. À remplacer (cf. section Tests de
  `CONTRIBUTING.md` : priorité sur la logique de sync offline).
- **Granularité des erreurs de sync** : la classification actuelle
  (401 / 4xx / réseau) est fonctionnelle mais ne distingue pas encore
  403 (permission) de 422 (validation) de 409 (conflit) comme demandé dans
  l'ancien audit — acceptable pour le MVP, à affiner si besoin de messages
  plus précis à l'utilisateur.

## Ordre de réalisation recommandé (mise à jour)

1. Appliquer les deux correctifs mobile ci-dessus (fichiers fournis).
2. Vérifier la migration Drift de la colonne `note` (point de vigilance).
3. Relancer `flutter analyze` et `dart format --output=none --set-exit-if-changed .`
   pour confirmer que le conflit Git ne laisse plus de trace.
4. Suivre le scénario E2E de `docs/guide-test-backend.md` (login, échéance,
   paiement local, synchro, vérification serveur) — cette fois avec l'app
   mobile réelle plutôt qu'avec PowerShell seul.
5. Remplacer `widget_test.dart` par des tests ciblés (formulaire, solde, sync
   avec mock Dio).
6. Committer les correctifs séparément du reste (cf. `docs/guide-push-git.md`),
   ouvrir une PR vers `dev`, prévenir A puisque `sync_service.dart` touche au
   contrat de synchronisation.
7. Archiver ou supprimer `docs/audit-integration-2026-09-03.md` pour éviter
   toute confusion future ; ce fichier (`...-09-04.md`) devient la référence.

## Exigences de contrat toujours à préserver (rappel, inchangé)

- Préfixe : `/api/v1`.
- Dates : ISO 8601 UTC avec `Z`.
- Idempotence : contrainte unique côté serveur sur `Paiement.client_uuid`.
- Isolation par site : déterminée par l'utilisateur authentifié, jamais par
  un `site_id` fourni par le client.
- Réponse de lot : un résultat par `client_uuid` ; un conflit ne supprime
  aucune donnée locale.
