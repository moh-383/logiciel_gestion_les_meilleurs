# Guide de contribution

Ce document fixe les règles de travail pour l'équipe (2 personnes) sur ce projet. L'objectif : pouvoir avancer chacun de son côté sur son module sans se marcher dessus, et garder un historique Git compréhensible même des mois plus tard.

## Sommaire

- [Avant de commencer](#avant-de-commencer)
- [Répartition du travail](#répartition-du-travail)
- [Branches](#branches)
- [Commits](#commits)
- [Pull requests](#pull-requests)
- [Style de code](#style-de-code)
- [Tests](#tests)
- [Modifier le schéma de données ou le contrat d'API](#modifier-le-schéma-de-données-ou-le-contrat-dapi)

---

## Avant de commencer

Lire, dans l'ordre :
1. `README.md` — vue d'ensemble et stack technique
2. `docs/schema-bdd.md` — modèle de données
3. `docs/api-contract.md` — endpoints disponibles
4. `docs/planning-sprints.md` — où en est le projet, sprint en cours

## Répartition du travail

Le projet est découpé **par module de bout en bout** (backend + mobile/web associés), pas par couche technique — voir `README.md` pour le détail complet de la répartition entre Personne A et Personne B, lot par lot.

Avant de commencer un nouveau lot, les deux personnes valident ensemble le schéma de données et le contrat d'API concernés. Une fois cette étape faite, chacun travaille en autonomie sur son module.

## Branches

- `main` : code stable, déployable. Jamais de commit direct dessus.
- `dev` : branche d'intégration, où les modules se rejoignent avant de passer en `main`.
- Branches de feature : `module/description-courte`, par exemple :
  - `eleves/fiche-creation`
  - `paiements/sync-offline`
  - `admin/permissions-modulaires`

Une branche de feature part de `dev` et y retourne via pull request.

```bash
git checkout dev
git pull
git checkout -b paiements/encaissement-partiel
```

## Commits

Messages courts, au présent, préfixés par le module concerné :

```
paiements: ajoute la détection automatique des retards
eleves: corrige le filtre par site sur la liste
admin: ajoute la table de liaison poste-permission
```

Éviter les commits fourre-tout ("wip", "fix", "update") — un commit doit représenter une intention claire, même petite. Ça facilite énormément la relecture et, si besoin, l'annulation d'un changement précis plus tard.

## Pull requests

Même en équipe de 2, toute fusion vers `dev` passe par une pull request avec **revue croisée** (l'autre personne relit avant de fusionner) :

- Titre clair : `[module] description` (ex. `[paiements] Synchronisation hors-ligne v1`)
- Description : ce que ça change, comment le tester manuellement si pertinent
- La CI (`.github/workflows/`) doit passer au vert avant fusion
- Attention particulière si la PR touche une table partagée (`ELEVE`, `SITE`, `UTILISATEUR`) ou un endpoint du contrat d'API — dans ce cas, prévenir l'autre personne avant de coder, pas seulement à la revue

Fusion de `dev` vers `main` : à la fin de chaque sprint ou lot, une fois testé.

## Style de code

| Composant | Convention |
|---|---|
| Backend (Python) | `ruff` pour le lint/format, types (`type hints`) sur les fonctions publiques |
| Mobile (Flutter/Dart) | `dart format`, `flutter analyze` sans warning avant de pousser |
| Web (Next.js/TypeScript) | ESLint + Prettier (config par défaut Next.js), typage strict activé |

Les workflows CI (`.github/workflows/`) vérifient automatiquement le lint et le formatage sur chaque pull request — un échec de CI bloque la fusion.

### Migrations de schéma (mobile — Drift)

Dès qu'une table de `mobile/lib/data/tables.dart` change (nouvelle colonne, nouvelle table), la base SQLite déjà installée sur les téléphones de test ne se met **pas** à jour automatiquement. Réflexe à avoir systématiquement :

1. Incrémenter `schemaVersion` dans `database.dart`
2. Ajouter un bloc `if (from < X) { await m.addColumn(...); }` dans `onUpgrade` décrivant la transition
3. Si la colonne n'est pas nullable, lui donner une valeur par défaut (`.withDefault(...)`), sinon la migration échoue sur les lignes déjà existantes

Oublier cette étape provoque une erreur `SqliteException` du type "no such column" au lancement de l'app sur un appareil ayant déjà une ancienne version de la base.

## Tests

- **Backend** : tests avec `pytest`, au minimum sur la logique métier sensible (calcul de statut d'échéance, workflow de validation, cloisonnement par site)
- **Mobile** : tests unitaires sur la logique de synchronisation offline en priorité — c'est la partie la plus risquée du projet
- **Web** : tests peuvent rester légers pour le MVP (le dashboard est surtout de l'affichage), à renforcer si la logique métier y grandit

Pas besoin de viser une couverture élevée dès le MVP — mais toute la logique liée à l'argent (paiements, échéances) et à la sécurité (permissions, cloisonnement) doit être testée, sans exception.

## Modifier le schéma de données ou le contrat d'API

Ce sont les deux documents les plus sensibles du projet, car les deux modules du MVP en dépendent :

1. Ne jamais modifier `docs/schema-bdd.md` ou `docs/api-contract.md` seul dans son coin.
2. En discuter à deux (même rapidement), mettre à jour le document en premier.
3. Ensuite seulement, adapter le code.

Un désaccord sur le schéma ou l'API coûte beaucoup plus cher à corriger après coup (migrations, code déjà écrit des deux côtés) qu'à trancher avant.
