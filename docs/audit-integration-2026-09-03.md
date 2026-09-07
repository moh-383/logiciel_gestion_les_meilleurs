# Audit d'intégration A ↔ B — 2026-09-03

## Conclusion

La chaîne Paiements n'est pas intégrable à ce stade. Le mobile contient un prototype offline-first utilisable localement, mais le backend est le squelette Django généré par défaut : aucune application métier, aucun modèle, aucune migration, aucune route sous `/api/v1`, aucune authentification JWT et aucune configuration PostgreSQL ne sont présents.

La correction mobile de sérialisation UTC a été appliquée dans `mobile/lib/core/sync_service.dart`. Elle respecte le contrat mais ne rend pas la synchronisation fonctionnelle tant que les P0 ci-dessous ne sont pas faits.

## État par couche

| Couche | État | Constats |
|---|---|---|
| Flutter — saisie paiement | 🟡 Partiel | Création locale, UUID client et historique local existent. Aucun contrôle du montant par rapport au solde, ni authentification. |
| Drift — stockage local | 🟡 Partiel | Paiements, échéances et demandes sont persistés. Les échéances/élèves ne sont jamais importés depuis l'API. |
| Sync | 🟡 Partiel | Lot vers `POST /sync/paiements`, verrou anti-concurrence et conservation en cas de panne. Les réponses HTTP 4xx sont assimilées à une erreur réseau. |
| API client | 🔵 Maquette | URL codée en dur vers `localhost`, aucun bearer token, refresh ou intercepteur 401. |
| Backend Django | ⚪ Non implémenté | Seulement l'admin Django. |
| PostgreSQL | ⚪ Non configuré | SQLite de développement dans `settings.py`; aucune dépendance ou variable d'environnement PostgreSQL. |
| Tests | 🔴 En échec conceptuel | Le seul widget test est le compteur Flutter par défaut, alors que cet écran n'existe plus. Aucun test backend. |

## P0 — bloque l'intégration

### Backend API et modèles absents

**B attend :** `POST /api/v1/sync/paiements`, JSON `{ paiements: [...] }`, réponse individualisée dans `resultats`.

**A fournit :** aucune route `/api/v1`; `config/urls.py` ne contient que `/admin/`.

**Impact :** toute synchronisation renvoie 404 ou une erreur de connexion.

**Correction recommandée :** créer les applications Django et migrations du socle partagé (`Site`, `Poste`, `Permission`, `Utilisateur`, `Eleve`, `Echeance`) avant de créer `Paiement`, dont les clés étrangères doivent être réelles. Configurer PostgreSQL par variables d'environnement, puis exposer les routes sous le préfixe unique `/api/v1`.

**Responsable :** A pour le socle partagé; B pour le domaine Paiements une fois ces modèles disponibles; décision commune pour le modèle utilisateur.

### Authentification JWT absente

**B attend :** header `Authorization: Bearer <token>`.

**A fournit :** aucune route `/auth/login`, `/auth/refresh` ou `/auth/logout`; aucun JWT ni règle de permission côté serveur.

**Impact :** le serveur ne peut pas identifier le site ou l'utilisateur qui a saisi un paiement; l'exigence de cloisonnement par site n'est pas applicable.

**Responsable :** commun/A selon la répartition convenue.

## P1 — critique dès que les P0 existent

### Contrat de synchronisation incomplet pour les notes

La saisie locale stocke `note`, mais le lot Flutter et l'exemple `POST /sync/paiements` ne la transmettent pas. `POST /paiements`, lui, l'accepte. Sans décision, une note créée hors ligne serait perdue côté serveur.

**Décision à prendre avec A :** ajouter `note` (nullable) à chaque élément du lot `/sync/paiements`, ou déclarer explicitement que les notes hors ligne ne sont pas prises en charge. Recommandation : ajouter le champ nullable.

### Erreurs de synchronisation mal classées

`SyncService` traite tout `DioException` comme une panne réseau. Or `401`, `403`, `409`, `422` et `5xx` exigent des comportements distincts :

- `401` : refresh/connexion ; ne pas masquer l'erreur ;
- `403`/`422` : conserver le paiement mais afficher une erreur métier ;
- `409` : réponse métier par élément et statut local `conflit` ;
- erreur réseau/timeout et `5xx` : conserver `en_attente` et réessayer.

Cette correction dépend de la stratégie de stockage des tokens, absente pour l'instant.

### URL de serveur non configurable

`http://localhost:8000` cible le téléphone/émulateur lui-même, pas le poste de développement dans la plupart des scénarios Android. La base URL doit être fournie par `--dart-define` (ou une configuration d'environnement), avec une valeur distincte pour émulateur, appareil réel et production.

## P2

- Les demandes d'annulation et leur validation sont uniquement locales. Elles ne sont jamais placées dans une file de synchronisation et n'appellent aucun endpoint du contrat.
- `paiementsEnAttenteDeSync()` n'envoie pas les éléments `conflit`, ce qui est cohérent avec l'arbitrage manuel, mais l'interface ne présente pas la raison de conflit ni le processus d'arbitrage.
- Le statut d'une échéance est recalculé localement et ne peut pas être source de vérité : le serveur doit le calculer transactionnellement.
- Les montants utilisent `double` dans Drift. Pour des FCFA entiers, utiliser un entier (montant en FCFA) dans le contrat et la base est préférable.

## P3

- Remplacer le test Flutter par des tests de formulaire, de calcul de solde et de synchronisation avec un faux client HTTP.
- Ajouter des logs structurés et non sensibles autour de la synchronisation.
- Mettre à jour les README de démarrage backend/mobile et ajouter un fichier d'environnement d'exemple sans secrets.

## Ordre de réalisation recommandé

1. Décider le modèle utilisateur, la configuration PostgreSQL et le paquet Django REST/JWT retenu.
2. Implémenter et migrer le socle A, avec données de développement minimales.
3. Implémenter login/refresh et vérifier les permissions/site dans un test API.
4. Implémenter le modèle et les endpoints Paiements, dont l'unicité de `client_uuid` et le traitement transactionnel du lot de synchronisation.
5. Ajouter l'authentification et la configuration d'URL au mobile.
6. Réaliser le scénario E2E : login, lecture d'échéance, paiement local, synchronisation, réponse `cree`, puis vérification du statut local et de la base serveur.

## Exigences de contrat à préserver

- Préfixe : `/api/v1`.
- Dates : ISO 8601 UTC avec `Z`.
- Idempotence : contrainte unique côté serveur sur `Paiement.client_uuid`; le même UUID doit renvoyer le même `paiement_id`, sans créer de doublon.
- Isolation par site : déterminée par l'utilisateur authentifié, jamais par un `site_id` fourni par le client pour créer un paiement.
- Réponse de lot : un résultat par `client_uuid`; un conflit ne supprime aucune donnée locale.
