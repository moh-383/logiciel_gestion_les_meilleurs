# Plan d exécution de finalisation

## P0 Risque de données

| Problème | Cause | Fichiers | Rôle | Correction | Test |
|---|---|---|---|---|---|
| PostgreSQL ignoré | Une seconde configuration écrasait le choix conditionnel | `backend/config/settings.py` | A + B | Supprimer l'écrasement SQLite | Vérifier le moteur avec `DJANGO_USE_SQLITE=false` et lancer les tests sous SQLite |

## P1 Bugs fonctionnels importants

| Problème | Cause | Fichiers | Rôle | Correction | Test |
|---|---|---|---|---|---|
| Création de site pouvant afficher un faux succès | Le POST et le rafraîchissement de liste ne sont pas liés | administration Flutter, tests core | A | Attendre la liste rechargée avant le message de succès | POST/GET API, test repository/widget ultérieur |
| Écoute réseau doublée | Démarrage appelé deux fois | `main.dart`, `sync_service.dart` | B | Écoute idempotente et un unique appel | Test unitaire du service |
| Module Enseignants inaccessible et incomplet | App, migration initiale, imports et routes incomplets | `backend/enseignants`, mobile enseignants | A | Reconstituer le module avant branchement Django | Tests de modèles, API et mobile |

## P2 Intégration et synchronisation

| Problème | Cause | Fichiers | Rôle | Correction | Test |
|---|---|---|---|---|---|
| Synchronisation paiement non démontrée mobile | Absence de tests Dio/Drift | `sync_service.dart`, tests mobile | B | Couvrir succès, conflit, 401, 403, réseau et répétition | Test service avec base Drift mémoire et adaptateur HTTP simulé |
| Bouton peu explicite | Le résultat vide et la sync concurrente ont le même retour | écran paiements, service sync | B | Résultat explicite et feedback de chargement | Tests de résultat + test manuel |

## P3 Permissions et sécurité

| Problème | Cause | Fichiers | Rôle | Correction | Test |
|---|---|---|---|---|---|
| Gestion des permissions non exposée mobile | Catalogue seulement consultatif | administration Flutter | A | Écran de détail de poste, assignation explicite | 403, PUT permissions, widget |
| Suppression élève non spécifiée | Historique financier protégé par le modèle | élèves, contrat API | A | Décision : désactivation logique auditable, pas DELETE physique | Tests de conservation paiements et périmètre |

## P4 Lot 2 et dashboard

| Problème | Cause | Fichiers | Rôle | Correction | Test |
|---|---|---|---|---|---|
| Dashboard sans couverture | Page unique connectée aux stats paiements | `web/src/app/page.tsx` | B | Auditer auth, filtres et états API puis ajouter tests | Build, tests composant/API |
| Rapports mensuels | Endpoints/exports incomplets | backend, web | B | Définir le contrat à partir des données disponibles | Test API et rendu |

## Ordre d exécution

1. Terminer P0 et vérifier la configuration de bases.
2. Lier création de site et rafraîchissement réel, avec tests API.
3. Écrire les tests de synchronisation et corriger le feedback du bouton.
4. Finaliser workflow de validation et permissions d'administration.
5. Reprendre Enseignants de façon isolée ; ne pas le brancher tant que ses tests ne passent pas.
6. Finaliser et tester dashboard, puis produire les guides de livraison et de démonstration.

## État de reprise — 11 septembre 2026

### Terminé et vérifié

- **P0** : la sélection PostgreSQL/SQLite n'est plus écrasée par une seconde
  configuration SQLite.
- **P1 mobile** : une seule écoute réseau est démarrée ; le service est
  idempotent et le bouton de synchronisation distingue file vide, opération
  déjà en cours et erreur.
- **P2 synchronisation** : les tests Drift/Dio couvrent création, conflit,
  401, 403, réponse invalide et répétition sans doublon.
- **P3** : les permissions d'un poste sont éditables dans l'application ; la
  désactivation logique d'un élève conserve son historique.
- **Enseignants (rôle A)** : application Django, migration initiale, modèles,
  routes, planning, séances, rapport mensuel, contrôle de périmètre et accès
  mobile sont rétablis. Les scénarios création d'affectation, planning,
  séance, refus d'accès à l'affectation d'un collègue et rapport sont couverts.

### À faire avant livraison

- **Rôle B / recette** : exécuter un E2E réel login → paiement hors ligne →
  reconnexion → synchronisation → dashboard avec un appareil ou émulateur.
- **Dashboard et rapports** : le build est valide ; il reste à définir avec le
  métier le contrat des exports mensuels et à ajouter les tests associés.
- **Production** : tester PostgreSQL réel, appliquer les migrations, configurer
  secrets, HTTPS, CORS et une restauration de sauvegarde.

### Lot 3 — règles prêtes pour validation

La spécification implémentable des sessions vacances et des préparations
Bac/BEPC est disponible dans `docs/REGLES_METIER_LOT_3.md`. Le développement
commence par Lot 3A après validation des cinq décisions métier qui y figurent.

### Note environnement

Les dépendances Python déclarées dans `backend/requirements.txt` ont été
installées dans le venv local afin que Django charge correctement `corsheaders`.
