# Guide express — partie 2 : validation métier, migration `note`, tests

Suite de `GUIDE_CORRECTIONS_B_2026-09-04.md`. Ce round couvre trois choses
liées entre elles : le contrôle du montant avant saisie, le correctif de
migration Drift (bug rencontré en conditions réelles le 2026-09-05), et le
remplacement du test obsolète par des tests utiles.

## 1. Fichiers à copier

| Fichier fourni | Destination |
|---|---|
| `paiement_validation.dart` | `mobile/lib/core/paiement_validation.dart` (nouveau fichier) |
| `encaissement_form_screen.dart` | `mobile/lib/features/paiements/encaissement_form_screen.dart` (remplace l'existant) |
| `database.dart` | `mobile/lib/data/database.dart` (remplace l'existant) |
| `paiement_validation_test.dart` | `mobile/test/paiement_validation_test.dart` (nouveau fichier) |
| `database_test.dart` | `mobile/test/database_test.dart` (nouveau fichier) |

**Supprime** l'ancien test obsolète :

```powershell
cd mobile
Remove-Item .\test\widget_test.dart
```

## 2. Ce que ça change concrètement

- **`paiement_validation.dart`** : fonction pure `validerMontantPaiement(...)`,
  testable sans lancer Flutter (pas de `WidgetTester`, pas de `pump()`).
  Bloque désormais : montant vide/négatif, échéance déjà soldée, montant qui
  dépasserait le solde restant (le cas qui, avant, aboutissait silencieusement
  au statut local `avance` puis à un rejet côté serveur à la synchronisation).
- **`encaissement_form_screen.dart`** : utilise cette fonction avant tout
  enregistrement local, et arrondit le montant à l'entier FCFA
  (`montant.roundToDouble()`) pour rester cohérent avec le `DecimalField`
  sans décimales du backend.
- **`database.dart`** : garde-fou `_colonneExiste(...)` avant le
  `addColumn(paiements, paiements.note)`, plus un constructeur
  `AppDatabase.forTesting(...)` pour les tests ci-dessous.

## 3. Lancer les tests

```powershell
cd mobile
flutter pub get
flutter test
```

Résultat attendu : tous les tests passent, y compris les nouveaux groupes
`validerMontantPaiement`, `Calcul du solde des échéances` et
`Workflow de validation (annulation de paiement)`.

Si un test échoue avec une erreur de type `MissingPluginException` ou liée à
`path_provider`/`sqlite3_flutter_libs` : c'est normal en environnement de test
si un import indirect tente d'ouvrir la vraie base fichier. Les tests fournis
n'utilisent que `AppDatabase.forTesting(NativeDatabase.memory())`, donc ils ne
devraient pas déclencher ce problème — mais si ça arrive, vérifie qu'aucun
autre provider Riverpod n'est instancié involontairement pendant le test.

## 4. Vérification manuelle du contrôle de montant

Sur l'app (toujours avec `--dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1`
et `adb reverse` actif) :

1. Ouvre une échéance avec un solde restant, ex. 15 000 FCFA.
2. Saisis un montant supérieur, ex. 20 000 FCFA, et appuie sur "Continuer".
3. Attendu : un message *"Le montant dépasse le solde restant (15000 FCFA)"*
   apparaît, **rien n'est enregistré localement**.
4. Saisis 15 000 FCFA exactement → doit passer, l'échéance passe au statut
   "Soldé".

## 5. Commit

```powershell
git add mobile/lib/core/paiement_validation.dart `
        mobile/lib/features/paiements/encaissement_form_screen.dart `
        mobile/lib/data/database.dart `
        mobile/test/paiement_validation_test.dart `
        mobile/test/database_test.dart
git rm mobile/test/widget_test.dart
git status
git commit -m "mobile: valide le montant avant saisie, corrige la migration note, ajoute des tests"
git push origin <ta-branche>
```

Comme `database.dart` touche à la structure de la base locale (donc
potentiellement au contrat de synchronisation si de nouvelles colonnes sont
ajoutées plus tard), préviens A au même titre que pour `sync_service.dart`.

## 6. Point resté ouvert (P2, non bloquant)

Le type `double` pour `montant` dans Drift (vs `DecimalField` entier côté
Django) reste en place — le correctif actuel (arrondi avant enregistrement +
validation du solde) réduit fortement le risque, mais une migration vers un
entier natif (FCFA sans décimales) resterait la solution la plus propre à
moyen terme si le temps le permet.
