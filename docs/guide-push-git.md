# Guide Git — vérification et push

Exécutez ces commandes depuis la racine du dépôt, après que les tests du guide
backend soient tous verts.

```powershell
cd C:\Users\USER\Documents\logiciel_gestion_les_meilleurs
git status
git diff --check
```

Résultat attendu : aucun message de `git diff --check`. `git status` affichera
les fichiers backend ajoutés/modifiés, ainsi que vos changements mobile déjà
existants.

## Important : ne pas mélanger les travaux

Les fichiers suivants étaient déjà modifiés avant le socle backend et doivent
être revus séparément :

- `mobile/lib/data/database.dart`
- `mobile/lib/data/database.g.dart`
- `mobile/lib/features/paiements/paiements_list_screen.dart`
- `mobile/pubspec.lock`

Ajoutez uniquement le backend, la documentation et la correction UTC isolée du
client de synchronisation :

```powershell
git add backend docs mobile/lib/core/sync_service.dart
git status
git commit -m "backend: ajoute socle partagé et API paiements offline"
git push origin main
```

Avant un projet d'équipe, la pratique recommandée est plutôt une branche puis
une pull request :

```powershell
git switch -c codex/backend-socle-paiements
git add backend docs mobile/lib/core/sync_service.dart
git commit -m "backend: ajoute socle partagé et API paiements offline"
git push -u origin codex/backend-socle-paiements
```

Résultat attendu : Git affiche le nom de la branche envoyée. Créez ensuite une
PR vers `dev` (si cette branche existe) ou vers `main`. Ne faites le push que
si `git status` confirme que vous êtes bien sur la branche voulue.
