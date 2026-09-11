# Audit de reprise — 11 septembre 2026

## État général

Le dépôt est un monorepo : application mobile Flutter/Riverpod avec stockage
local Drift/SQLite, API Django REST avec JWT, et tableau de bord Next.js.
L'API est conçue pour PostgreSQL mais **la configuration active l'écrase
inconditionnellement par SQLite**. Le backend implémente le MVP et une partie
de la communication/notifications. Le front mobile est l'application métier
principale ; le web est un dashboard de direction limité aux statistiques de
paiement.

Les suites Django déclarent 37 tests et le contrôle Django est valide. La
vérification statique Flutter n'a pas pu être menée à terme dans cet
environnement : le SDK ne peut pas lire sa configuration de télémétrie hors du
workspace (`PathAccessException`, accès refusé). Le build Next.js est réussi.

## MVP

| Fonctionnalité | État | Observations |
|---|---|---|
| Authentification JWT | Partiellement done | Login/refresh/logout et stockage chiffré existent ; expiration non testée mobile. |
| Élèves | Partiellement done | CRUD, cloisonnement, import/offline existent ; aucun DELETE élève, ce qui est cohérent avec les relations `PROTECT` mais doit devenir une désactivation explicitement décidée. |
| Paiements | Done côté API / partiel mobile | Idempotence `client_uuid`, calcul transactionnel et annulation validée existent ; tests de synchronisation mobile absents. |
| Offline | Partiellement done | Drift + files d'attente paiements, élèves, échanges et demandes. |
| Synchronisation | Partiellement done | Paiements en lot et mise à jour locale existent ; pas de test Dio/Drift du pipeline complet ni retry différencié. |
| Administration | Partiellement done | Sites, postes, utilisateurs et catalogue fonctionnent côté API ; l'écran mobile n'expose pas l'assignation des permissions aux postes. |
| Permissions | Partiellement done | Relations POSTE–PERMISSION réelles et contrôles serveur présents ; catalogue mobile volontairement non cliquable, mais l'UX ne l'explique pas. |
| Validation | Partiellement done | Une annulation de paiement crée une demande et sa validation annule le paiement ; la création offline de demande dépend d'un paiement déjà synchronisé. |

## Lot 2

| Fonctionnalité | Responsable | État | Observations |
|---|---|---|---|
| Notifications automatiques | B | Partiellement done | Modèles, service de retard, FCM et endpoint existent ; pas de preuve E2E planifiée/exécutée. |
| Échanges/incidents élève | B | Partiellement done | API, local/offline et écrans présents ; couverture backend mais pas couverture mobile. |
| Dashboard direction / rapports | B | Partiellement done | Dashboard web financier compilé ; aucun rapport mensuel généré ni couverture de données Lot 2. |
| Enseignants/affectations | A | Bloqué | Code et migrations existent mais application Django absente de `INSTALLED_APPS` et routes absentes de `config/urls.py` : module inaccessible. |
| Planning/rapports enseignants | A | Bloqué | Dépend du branchement du module Enseignants. |
| Fiche site enrichie / rapports responsables | A | Partiellement done | Site minimal et stats paiements ; enrichissement/rapports non démontrés. |
| Intégration Sprint 11 | Ensemble | Non commencée | Aucun test E2E reproductible mobile↔API. |

## Lot 3

Les valeurs `type_cours: vacances` sont déjà acceptées côté élève, mais il
n'existe aucun modèle ou flux de sessions/tarification de vacances. Aucun
modèle, endpoint, écran ou statistique Bac/BEPC n'a été trouvé. Ces modules ne
doivent pas démarrer avant la stabilisation de la synchronisation et du
cloisonnement.

## Bugs confirmés et risques

1. **P0 — PostgreSQL inopérant.** `backend/config/settings.py` définit bien
   une base conditionnelle, puis la remplace par SQLite. Toute exécution, y
   compris en production, ignore `POSTGRES_*`.
2. **P1 — Lot 2 Enseignants non livré.** Dossier et migrations présents, mais
   app/URLs non enregistrées : les tables et endpoints ne sont pas chargés.
3. **P1 — Double écoute réseau mobile.** `main.dart` appelle deux fois
   `demarrerEcouteConnexion()`. Une seule souscription est conservée pour
   l'arrêt ; les événements et imports peuvent être doublés.
4. **P1 — Audit de synchro insuffisant.** Le flux paiement est
   `Drift(en_attente) → POST /sync/paiements → résultat par UUID → Drift`.
   Il est idempotent côté serveur, mais il n'a pas de tests mobiles couvrant
   réussite, réponse partielle, 401, 403, perte réseau et répétition.
5. **P2 — Faux positif UX possible sur le bouton Synchroniser.** Le message
   `0 synchronisé` est un résultat normal lorsque la file est vide ou qu'une
   sync est déjà en cours ; il ne distingue pas ces cas. Le code détecte les
   paiements `en_attente` et `conflit`, appelle le bon endpoint, et met à jour
   Drift pour chaque résultat. Aucune preuve de reproduction du bug signalé
   n'a encore été fournie ; un test de service doit le trancher.
6. **P2 — Création de site non reproduite dans le code actuel.** Le POST
   `/sites` est correct et l'écran invalide `sitesProvider` avant son succès.
   Il manque un test de création/rafraîchissement ; sans trace réseau de
   l'incident, la cause historique est indéterminée.
7. **P2 — Suppression d'élève non définie.** Le contrat ne prévoit pas DELETE,
   et paiements/échéances protègent l'élève. Recommandation : ajout ultérieur
   d'une désactivation logique, avec `gerer_eleves`, motif et audit trail ; ne
   pas supprimer physiquement sans décision produit.

## Plan immédiat

1. Corriger la sélection PostgreSQL/SQLite et ajouter un test de configuration.
2. Brancher et tester le module Enseignants ou le retirer explicitement du
   périmètre du Lot 2 ; conserver le code existant.
3. Corriger l'unique écoute réseau et écrire les tests unitaires du service de
   synchronisation paiement, dont le compteur et les résultats partiels.
4. Ajouter des tests API de création de site, liste après création et
   cloisonnement ; ensuite valider sur l'application avec une trace HTTP.
5. Couvrir l'E2E login → import → paiement offline → reconnexion → sync →
   affichage local, puis documenter le scénario de recette.
