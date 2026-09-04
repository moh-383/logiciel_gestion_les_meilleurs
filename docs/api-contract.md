# Contrat d'API : MVP

Ce document fixe les endpoints du backend pour le MVP (Élèves & Inscriptions, Paiements & Finances, Administration & Rôles), afin que les deux personnes développent en parallèle (mobile Flutter, web Next.js, backend) contre une spec commune plutôt que contre l'implémentation de l'autre.

À valider **ensemble** avant le développement du Lot 1. Toute évolution de ce contrat en cours de route doit être discutée à deux avant modification, puisque les deux modules du MVP en dépendent.

## Conventions générales

- **Base URL** : `/api/v1`
- **Authentification** : JWT, `Authorization: Bearer <token>`, obtenu via `POST /auth/login`
- **Cloisonnement par site** : appliqué côté serveur à partir de l'utilisateur 
- **Dates/heures** : toutes les dates échangées avec l'API sont en UTC, format ISO 8601 avec suffixe `Z` (ex. `2026-08-20T10:15:00Z`). Le stockage local (mobile, offline) peut rester en heure locale de l'appareil pour l'affichage, mais la conversion en UTC est **obligatoire** à la sérialisation vers l'API (`.toUtc()` avant `.toIso8601String()` côté Flutter/Dart, `datetime.now(timezone.utc)` côté backend Python).authentifié (son `site_id` et son poste), jamais en paramètre client. Un utilisateur dont le poste n'a pas `tous_sites = true` ne voit et ne modifie que les données de son site.
- **Permissions** : chaque endpoint sensible vérifie que le poste de l'utilisateur possède la permission requise (ex. `gerer_comptes`, `voir_finances`) via la table `POSTE_PERMISSION`.
- **Pagination** : `?page=1&limit=20` sur les listes → réponse `{ "data": [...], "total": 132, "page": 1, "limit": 20 }`
- **Filtrage** : query params dédiés par ressource (voir chaque section)
- **Erreurs** : format uniforme `{ "error": "code_erreur", "message": "description lisible" }`, codes HTTP standards :
  - `400` requête invalide, `401` non authentifié, `403` permission refusée, `404` introuvable, `409` conflit (ex. doublon), `422` validation échouée

---

## 1. Authentification

| Méthode | Endpoint | Description |
|---|---|---|
| POST | `/auth/login` | Connexion (téléphone + mot de passe) → renvoie `access_token`, `refresh_token`, infos utilisateur (poste, permissions, site) |
| POST | `/auth/refresh` | Renouvelle un `access_token` à partir du `refresh_token` |
| POST | `/auth/logout` | Invalide le `refresh_token` |

**Exemple réponse `POST /auth/login`** :
```json
{
  "access_token": "...",
  "refresh_token": "...",
  "utilisateur": {
    "id": "uuid",
    "nom": "Ouédraogo",
    "poste": { "nom": "Secrétaire", "permissions": ["saisir_paiement"], "tous_sites": false },
    "site_id": "uuid"
  }
}
```

---

## 2. Administration & Rôles : *Personne A*

| Méthode | Endpoint | Permission requise | Description |
|---|---|---|---|
| GET | `/postes` | `gerer_comptes` | Liste des postes |
| POST | `/postes` | `gerer_comptes` | Créer un poste |
| GET | `/postes/{id}` | `gerer_comptes` | Détail d'un poste + permissions assignées |
| PATCH | `/postes/{id}` | `gerer_comptes` | Modifier un poste (nom, `tous_sites`) |
| PUT | `/postes/{id}/permissions` | `gerer_comptes` | Remplacer la liste de permissions assignées à ce poste |
| GET | `/permissions` | `gerer_comptes` | Catalogue des permissions disponibles |
| GET | `/utilisateurs` | `gerer_comptes` | Liste des utilisateurs (filtrable `?site_id=&poste_id=&actif=`) |
| POST | `/utilisateurs` | `gerer_comptes` | Créer un utilisateur |
| GET | `/utilisateurs/{id}` | `gerer_comptes` | Détail utilisateur |
| PATCH | `/utilisateurs/{id}` | `gerer_comptes` | Modifier (poste, site, statut actif) |
| GET | `/sites` | - (authentifié) | Liste des sites (utilisateur multi-sites voit tout, sinon uniquement le sien) |
| POST | `/sites` | `gerer_comptes` | Créer un site |
| GET | `/sites/{id}` | - (authentifié + périmètre) | Détail d'un site |
| PATCH | `/sites/{id}` | `gerer_comptes` | Modifier un site |

**Exemple `PUT /postes/{id}/permissions`** :
```json
{ "permissions": ["voir_finances", "voir_pedagogie", "gerer_comptes", "valider_actions_sensibles"] }
```

---

## 3. Élèves & Inscriptions : *Personne A*

| Méthode | Endpoint | Permission requise | Description |
|---|---|---|---|
| GET | `/eleves` | - (périmètre appliqué) | Liste, filtrable `?site_id=&classe=&statut=&q=` (`q` = recherche nom) |
| POST | `/eleves` | `gerer_eleves` | Créer un élève (+ contacts parents optionnels) |
| GET | `/eleves/{id}` | - (périmètre) | Fiche élève complète |
| PATCH | `/eleves/{id}` | `gerer_eleves` | Modifier (site, classe, statut, type de cours) |
| GET | `/eleves/{id}/contacts` | - (périmètre) | Contacts parents de l'élève |
| POST | `/eleves/{id}/contacts` | `gerer_eleves` | Ajouter un contact parent |
| PATCH | `/contacts/{id}` | `gerer_eleves` | Modifier un contact |
| DELETE | `/contacts/{id}` | `gerer_eleves` | Retirer un contact |

**Exemple `POST /eleves`** :
```json
{
  "nom": "Kaboré", "prenom": "Adama", "date_naissance": "2011-03-14", "sexe": "M",
  "site_id": "uuid", "classe": "3ème B", "type_cours": "renforcement_regulier",
  "contacts": [{ "nom": "Fatou Kaboré", "telephone": "+22670123456", "lien": "mère" }]
}
```

---

## 4. Paiements & Finances : *Personne B*

| Méthode | Endpoint | Permission requise | Description |
|---|---|---|---|
| GET | `/eleves/{id}/echeances` | - (périmètre) | Échéances d'un élève avec statut et solde |
| GET | `/eleves/{id}/paiements` | - (périmètre) | Historique des paiements d'un élève |
| GET | `/sites/{id}/paiements` | `voir_finances` | Liste des paiements/retards du site, filtrable `?statut=retard\|partiel\|a_jour` |
| GET | `/sites/{id}/stats/paiements` | `voir_finances` | Statistiques agrégées (collecté, taux de recouvrement, nb retards) |
| POST | `/paiements` | `saisir_paiement` | Enregistrer un paiement sur une échéance |
| POST | `/paiements/{id}/demande-annulation` | `saisir_paiement` | Soumet une demande d'annulation (crée une `DEMANDE_VALIDATION`) |
| POST | `/sync/paiements` | `saisir_paiement` | Synchronisation en lot des paiements créés hors-ligne (voir §6) |

**Exemple `POST /paiements`** :
```json
{
  "echeance_id": "uuid",
  "montant": 15000,
  "mode_paiement": "orange_money",
  "note": "paiement partiel",
  "client_uuid": "uuid-genere-localement"
}
```
`client_uuid` : identifiant généré côté mobile au moment de la saisie (avant même la synchronisation), pour permettre l'idempotence, si le même paiement est renvoyé deux fois pendant une resynchronisation, le serveur le reconnaît et ne le duplique pas.

**Exemple réponse `GET /sites/{id}/stats/paiements`** :
```json
{
  "effectif": 86, "montant_collecte": 2340000, "montant_attendu": 2580000,
  "taux_recouvrement": 0.907, "nb_en_retard": 14, "nb_partiel": 6
}
```

---

## 5. Demandes de validation (workflow d'approbation) : *Personne B*, consommé aussi par les responsables de site

| Méthode | Endpoint | Permission requise | Description |
|---|---|---|---|
| GET | `/demandes-validation` | `valider_actions_sensibles` | Liste, filtrable `?statut=en_attente&site_id=` |
| GET | `/demandes-validation/{id}` | `valider_actions_sensibles` | Détail d'une demande |
| PATCH | `/demandes-validation/{id}` | `valider_actions_sensibles` | Approuver ou rejeter (`{ "statut": "validee" \| "rejetee", "commentaire": "..." }`) : si validée, l'action sous-jacente (ex. annulation du paiement) est exécutée automatiquement |

---

## 6. Synchronisation hors-ligne (app mobile) : *Personne B*

L'app mobile stocke localement les paiements créés sans connexion. Dès que la connexion revient :

| Méthode | Endpoint | Description |
|---|---|---|
| POST | `/sync/paiements` | Envoie un lot de paiements en attente (tableau de paiements, chacun avec son `client_uuid`) |

**Exemple requête** :
```json
{
  "paiements": [
    { "client_uuid": "uuid-1", "echeance_id": "uuid", "montant": 15000, "mode_paiement": "especes", "note": "paiement partiel", "date_locale": "2026-08-20T10:15:00Z" },
    { "client_uuid": "uuid-2", "echeance_id": "uuid", "montant": 5000, "mode_paiement": "especes", "date_locale": "2026-08-20T10:22:00Z" }
  ]
}
```

**Exemple réponse** : le serveur confirme chaque paiement individuellement, y compris en cas de conflit :
```json
{
  "resultats": [
    { "client_uuid": "uuid-1", "statut": "cree", "paiement_id": "uuid-serveur" },
    { "client_uuid": "uuid-2", "statut": "conflit", "raison": "echeance_deja_soldee" }
  ]
}
```
Un `statut: "conflit"` ne supprime pas le paiement côté serveur ni côté mobile, il reste visible pour arbitrage manuel par le responsable de site ou la direction (voir `docs/schema-bdd.md`, section sur la résolution de conflits).

`note` est nullable et doit être conservée pendant la synchronisation. Pour une
requête répétée avec le même `client_uuid`, le serveur répond de nouveau avec
`statut: "cree"` et le même `paiement_id` : aucun doublon ne doit être créé.

---

## Résumé par responsable

| Domaine | Endpoints | Responsable |
|---|---|---|
| Auth | `/auth/*` | Commun : à faire en premier, ensemble |
| Administration & Rôles, Sites | `/postes/*`, `/permissions`, `/utilisateurs/*`, `/sites/*` | Personne A |
| Élèves & Inscriptions | `/eleves/*`, `/contacts/*` | Personne A |
| Paiements & Finances | `/paiements/*`, `/sync/*`, stats | Personne B |
| Demandes de validation | `/demandes-validation/*` | Personne B |

## Prochaine étape suggérée
## Historique des décisions actées

- **Format dates/heures** : UTC + ISO 8601 (`Z`), voir Conventions générales. *(tranché le 2026-09-03)*
- **Catalogue de permissions** : liste exhaustive dans `docs/schema-bdd.md`, section `PERMISSION`. *(tranché le 2026-09-03)*
- **Accès enseignant à la fiche élève** : refusé par design pour la V2, seules les données pédagogiques liées à ses propres cours seront accessibles. À affiner au Sprint 8.
