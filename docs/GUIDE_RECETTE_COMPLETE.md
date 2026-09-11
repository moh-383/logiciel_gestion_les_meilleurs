# Guide de recette complet

Ce guide permet de voir et tester les fonctionnalités effectivement livrées,
sans supposer de connaissances techniques. Faites les scénarios dans l'ordre :
les données créées au début sont utilisées par les écrans suivants.

## 1. Démarrer les trois applications

Ouvrez trois terminaux PowerShell à la racine du dépôt.

```powershell
# Terminal API
cd backend
.\venv\Scripts\Activate.ps1
$env:DJANGO_USE_SQLITE = "true"
python manage.py migrate
python manage.py runserver
```

```powershell
# Terminal mobile : émulateur Android
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

Sur Windows/macOS desktop, remplacez `10.0.2.2` par `127.0.0.1`. Sur un
téléphone réel, utilisez l'IPv4 du PC et démarrez l'API avec
`python manage.py runserver 0.0.0.0:8000`. Les instructions détaillées pour
créer le premier compte et les données de démo sont dans
[`guide-test-backend.md`](guide-test-backend.md).

```powershell
# Terminal dashboard
cd web
npm ci
$env:NEXT_PUBLIC_API_BASE_URL = "http://127.0.0.1:8000/api/v1"
npm run dev
```

Ouvrez ensuite `http://localhost:3000` pour le dashboard Direction.

## 2. Préparer les rôles de test

Dans l'administration mobile, créez des postes puis des utilisateurs associés.
Le serveur reste l'autorité : un écran visible ne remplace jamais un droit
serveur.

| Rôle de test | Permissions minimales | Ce que vous vérifiez |
|---|---|---|
| Direction | `gerer_comptes`, `gerer_eleves`, `saisir_paiement`, `voir_finances`, `valider_actions_sensibles`, `gerer_enseignants`, `voir_pedagogie`, `gerer_programmes`, `gerer_tarifs`, `inscrire_programmes`, `voir_programmes`, `saisir_resultats_examens` | Tous les parcours |
| Secrétariat | `gerer_eleves`, `saisir_paiement`, `inscrire_programmes` | Dossiers, encaissements, inscriptions |
| Enseignant | `voir_pedagogie` | Son planning, ses séances, son rapport |

Pour une recette multi-sites, créez un deuxième site et un compte Secrétariat
limité à ce site. Il ne doit jamais voir ni modifier les données du premier.

## 3. Parcours Administration et comptes

1. Connectez-vous avec Direction, ouvrez **Administration**.
2. Dans **Sites**, créez un site puis revenez à la liste : il doit apparaître
   immédiatement.
3. Dans **Postes**, ouvrez un poste, attribuez puis enregistrez ses permissions.
   Le catalogue **Permissions** est informatif ; l'attribution se fait dans la
   fiche du poste.
4. Dans **Utilisateurs**, créez un compte Secrétariat lié à un seul site.
5. Déconnectez-vous et reconnectez-vous avec ce compte : seuls les modules
   autorisés doivent être proposés. Essayez une URL/API d'un autre site : elle
   doit être refusée ou ne retourner aucune donnée hors périmètre.

## 4. Parcours Élèves, échéances et échanges

1. Avec le compte Secrétariat, ouvrez **Élèves** puis créez un élève.
2. Ouvrez sa fiche, ajoutez un parent/contact et une échéance de paiement.
3. Modifiez sa classe ou son statut, enregistrez et vérifiez la fiche.
4. Passez son statut à **Inactif** : l'élève n'est pas supprimé et son
   historique reste consultable.
5. Ajoutez un échange ou incident dans la fiche ; coupez ensuite le réseau et
   créez un autre échange. Après reconnexion, utilisez la synchronisation et
   vérifiez que les deux éléments sont visibles.

## 5. Parcours Paiements hors ligne et validation

1. Ouvrez **Paiements**, choisissez l'échéance de l'élève et encaissez une
   première somme. Le restant et le statut de l'échéance doivent évoluer.
2. Désactivez Wi-Fi/données, encaissez un second paiement puis revenez à la
   liste. Le paiement porte l'état **En attente** : il est seulement local.
3. Rétablissez le réseau et appuyez sur **Synchroniser**. Le résultat doit
   indiquer le nombre envoyé ; répéter l'action ne doit créer aucun doublon.
4. Sur un paiement déjà synchronisé, utilisez **Demander annulation** et
   saisissez un motif.
5. Connectez-vous avec Direction, ouvrez **Demandes de validation**, approuvez
   ou rejetez la demande, puis retournez à l'historique de paiement pour
   constater le statut final.

## 6. Parcours Enseignants et pédagogie

1. Avec Direction, ouvrez **Enseignants** et choisissez un enseignant.
2. Ajoutez une affectation (site, classe, matière, année), puis créez les
   créneaux de son planning depuis l'API ou l'outil prévu dans la fiche selon
   votre rôle.
3. Connectez-vous avec le compte Enseignant, ouvrez **Mon espace enseignant**,
   contrôlez le planning et déclarez une séance tenue avec présents/absents.
4. Ouvrez le rapport mensuel : le nombre de séances et le taux de présence
   doivent refléter la saisie. Un enseignant ne peut pas déclarer la séance
   d'un collègue.

## 7. Parcours Programmes spéciaux : vacances, Bac et BEPC

1. Avec un compte ayant `gerer_programmes`, ouvrez **Programmes spéciaux** et
   créez un programme **Vacances**, **Préparation Bac** ou **Préparation BEPC**.
   Pour Bac/BEPC, renseignez au moins une matière.
2. Créez une session sur le bon site, ses groupes et un tarif actif. Ouvrez la
   session lorsqu'elle est prête.
3. Avec `inscrire_programmes`, inscrivez un élève dans un groupe et confirmez
   son inscription. Une échéance est alors créée avec le tarif figé, moins une
   éventuelle remise motivée.
4. Vérifiez qu'un groupe complet refuse une inscription supplémentaire.
5. Pour Bac/BEPC, saisissez une note entre 0 et 20 avec le droit
   `saisir_resultats_examens`, puis consultez les statistiques du programme
   (candidats, admis, taux et moyenne).
6. Annulez une session non réglée et vérifiez que les échéances associées sont
   annulées, sans effacer l'historique.

## 8. Dashboard Direction et notifications

1. Connectez-vous au dashboard web avec le compte Direction.
2. Vérifiez les cartes effectif, collecté, attendu et recouvrement ; filtrez
   un site puis utilisez **Actualiser**.
3. Après un paiement synchronisé, actualisez le dashboard : le montant collecté
   et le taux de recouvrement doivent changer.
4. Pour les notifications push, configurez Firebase pour l'environnement,
   autorisez les notifications sur le téléphone et connectez le compte. Sans
   configuration Firebase, les autres fonctionnalités restent testables mais
   aucune notification push réelle ne sera reçue.

## 9. Vérifications automatisées avant de valider la recette

```powershell
# backend (depuis backend/)
$env:DJANGO_USE_SQLITE = "true"
python manage.py check
python manage.py test

# mobile (depuis mobile/)
flutter test
flutter analyze

# web (depuis web/)
npm run lint
npm run build
```

Une recette est acceptée quand ces commandes passent et que les scénarios 3 à
8 ont été validés sur le même environnement API. Notez pour chaque anomalie le
compte utilisé, le site, l'heure, l'action et le message affiché : cela rend la
reproduction immédiate.
