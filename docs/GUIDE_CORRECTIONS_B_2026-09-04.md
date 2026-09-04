# Guide express : corrections mobile (côté B), 2026-09-04

Ce guide part du principe que tu es déjà sur ta branche de travail (ou `dev`
à jour). Adapte les chemins si ton dossier local diffère.

## 1. Sauvegarder l'état actuel (sécurité)

```powershell
cd C:\Users\USER\Documents\logiciel_gestion_les_meilleurs
git status
git stash push -m "avant correctifs sync_service + auth_service"
```

(Si `git status` est propre, tu peux sauter le `stash`.)

## 2. Remplacer les deux fichiers corrigés

Copie le contenu des fichiers fournis (`sync_service.dart`, `auth_service.dart`)
en écrasant :

- `mobile/lib/core/sync_service.dart`
- `mobile/lib/core/auth_service.dart`

```powershell
git stash pop   # si tu avais stashé, pour ne pas perdre d'éventuels autres changements locaux
```

## 3. Vérifier qu'il ne reste aucune trace de conflit

```powershell
cd mobile
Select-String -Path .\lib\core\sync_service.dart -Pattern "<<<<<<<|=======|>>>>>>>"
```

Résultat attendu : **aucune ligne retournée**. Si quelque chose s'affiche,
il reste un conflit ailleurs dans le repo, cherche dans tout `mobile/lib` :

```powershell
Get-ChildItem -Recurse -Include *.dart | Select-String -Pattern "<<<<<<<|=======|>>>>>>>"
```

## 4. Vérifier le point de vigilance "colonne note"

Ouvre `mobile/lib/data/database.dart` et regarde l'historique des
`schemaVersion` / `onUpgrade`. Si tu ne trouves pas de bloc qui ajoute
explicitement la colonne `note` de la table `paiements` à un moment donné
(et que cette colonne n'était pas là dès la toute première version publiée
aux testeurs), ajoute-le avant de livrer :

```dart
if (from < 5) {
  await m.addColumn(paiements, paiements.note);
}
```

... et pense à incrémenter `schemaVersion` en conséquence, et à mettre à jour
le commentaire en tête de fichier (`// v5 : ajout de note`).

## 5. Compiler et analyser

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Tous ces retours doivent être verts avant de committer.

## 6. Test manuel bout-en-bout (avec le backend de A déjà démarré)

Suis `docs/guide-test-backend.md` jusqu'à l'étape 4 (serveur lancé), puis au
lieu de PowerShell, utilise l'app mobile :

1. Lance l'app (émulateur Android → `apiBaseUrl` par défaut `10.0.2.2:8000`
   fonctionne tel quel).
2. Connecte-toi avec le compte créé à l'étape 3 du guide backend.
3. **Ferme complètement l'app et relance-la.** Avant le correctif, tu étais
   systématiquement renvoyé à l'écran de login ici, vérifie que ce n'est
   plus le cas : c'est la preuve que `TokenStore.save()` fonctionne.
4. Saisis un paiement, coupe le Wi-Fi/data de l'émulateur, vérifie le badge
   "en attente de synchronisation", réactive la connexion, vérifie que le
   badge disparaît et que le paiement apparaît côté serveur
   (`GET /api/v1/eleves/{id}/paiements`).

## 7. Commit séparé et propre

Ne mélange pas ces correctifs avec d'autres travaux en cours (règle rappelée
dans `docs/guide-push-git.md`) :

```powershell
git add mobile/lib/core/sync_service.dart mobile/lib/core/auth_service.dart
git status   # relis bien la liste avant de committer
git commit -m "mobile: corrige conflit de fusion sync + persistance session auth"
```

Si tu as aussi fait le correctif de migration `note` (étape 4) :

```powershell
git add mobile/lib/data/database.dart
git commit -m "mobile: migration Drift pour la colonne note (v5)"
```

Pense aussi à committer la mise à jour de l'audit :

```powershell
git add docs/audit-integration-2026-09-04.md
git commit -m "docs: met à jour l'audit d'intégration (backend avancé, bugs mobile corrigés)"
```

## 8. Push et information à A

```powershell
git push origin <ta-branche>
```

Puis ouvre une PR vers `dev`. **Préviens A explicitement** parce que
`sync_service.dart` touche au contrat `/sync/paiements` (champ `note`) — même
si le contrat n'a pas changé, la revue croisée est la règle du projet dès
qu'on touche à une zone partagée (cf. `CONTRIBUTING.md`).

Message de PR suggéré :

> [paiements] Corrige un conflit de fusion bloquant la compilation et un bug
> de persistance de session (TokenStore.save() n'écrivait jamais rien via une
> extension writeAll no-op). Met à jour l'audit d'intégration : le backend
> n'est plus au stade "squelette", la plupart des P0/P1 de l'ancien audit sont
> résolus côté serveur.

## 9. Nettoyage de la documentation

Archive ou supprime `docs/audit-integration-2026-09-03.md` (garde-le en
historique si tu préfères, mais indique clairement qu'il est remplacé) pour
que personne ne reparte du diagnostic périmé.
