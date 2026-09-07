# Logiciel de gestion : Structure de cours d'appui scolaire

Logiciel de gestion pour la structure de cours d'appui scolaire (collège et lycée) "Cours d'appui les meilleurs". Il est  multi-sites, remplaçe le suivi manuel actuel (groupes WhatsApp, cahiers, appels) par un système centralisé : élèves, paiements, rôles, communication et résultats aux examens.

📄 Cahier des charges complet : `docs/cahier_des_charges.pdf`
🎨 Maquettes des écrans MVP : `docs/maquettes.html`

---

## Sommaire

- [Stack technique](#stack-technique)
- [Structure du dépôt](#structure-du-dépôt)
- [Répartition du travail (équipe de 2)](#répartition-du-travail-équipe-de-2)
- [Feuille de route](#feuille-de-route)
- [Démarrage du projet](#démarrage-du-projet)
- [Convention Git](#convention-git)
- [Modèle de données partagé](#modèle-de-données-partagé)

---

## Stack technique

| Composant | Techno | Utilisé par |
|---|---|---|
| App mobile (terrain) | **Flutter** + Drift/Isar (offline-first) | Secrétaires, enseignants, responsables de site |
| Dashboard web | **React / Next.js** | Direction (générale et pédagogique) |
| Backend / API | **Python** (FastAPI ou Django REST Framework) | Commun |
| Base de données | **PostgreSQL** | Commun |
| Notifications push | Firebase Cloud Messaging | Remplace les groupes WhatsApp |
| Génération d'images (résultats d'examens) | Rendu HTML→image côté serveur | Module Résultats aux examens |

Contrainte clé : certains sites ont une connexion internet instable → **l'app mobile doit fonctionner hors ligne** (saisie locale + synchronisation différée avec gestion des conflits).

---

## Structure du dépôt

Monorepo, un dossier par composant :

```
.
├── backend/            # API Python (FastAPI/Django) + logique métier + migrations DB
├── mobile/             # App Flutter (secrétaires, enseignants, responsables de site)
├── web/                # Dashboard Next.js (direction)
├── docs/
│   ├── cahier_des_charges.docx
│   ├── maquettes.html
│   └── api-contract.md
    └── schema-bdd.md    #base de données (le mcd) 
    └── planning-sprints.md
├── .github/
│   └── workflows/              
├── README.md
└── CONTRIBUTING.md  # convention de code, branches, commits
```

Chaque sous-dossier (`backend/`, `mobile/`, `web/`) aura son propre README technique une fois le projet initialisé (installation, variables d'environnement, lancement local).

---

## Répartition du travail (équipe de 2)

Découpage retenu : **par module de bout en bout** (backend + mobile + web associés), pas par couche technique. Chacun est responsable de son module sur toute la chaîne, ce qui évite les dépendances bloquantes entre les deux personnes. Le **schéma de base de données** et le **contrat d'API** sont conçus **ensemble**, avant le développement de chaque lot.

### Lot 1 : MVP

| | Personne A | Personne B |
|---|---|---|
| Module | **Élèves & Inscriptions** + **Administration & Rôles** | **Paiements & Finances** (offline-first) |
| Pourquoi en premier | Fondation dont tous les autres modules dépendent (fiche élève, auth, permissions) | Module le plus complexe techniquement (offline + sync), le risque le plus élevé, à traiter tôt |
| Livrables | Fiche élève, création/édition élève, gestion des postes/permissions modulaires | Fiche financière élève, encaissement, détection des retards, workflow d'approbation d'annulation |

### Lot 2 : v2

| | Personne A | Personne B |
|---|---|---|
| Module | **Enseignants** + **Sites** | **Communication élève-parent** + **Rapports & Tableau de bord** |

### Lot 3 : v2

| | Personne A | Personne B |
|---|---|---|
| Module | **Cours de vacances** | **Résultats aux examens** (Bac / BEPC) |

### Règle de synchronisation
Avant chaque lot, les deux personnes se mettent d'accord sur :
1. Le schéma de données concerné (tables, relations)
2. Le contrat d'API (endpoints, formats de requête/réponse)

Ensuite chacun développe son module en autonomie (backend + mobile/web associés), avec des points de synchronisation réguliers pour vérifier que l'intégration fonctionne.

---

## Feuille de route

- [ ] Schéma de base de données commun (Lot 1)
- [ ] Contrat d'API du MVP (`docs/api-contract.md`)
- [ ] Lot 1 : MVP : Élèves, Administration/Rôles, Paiements
- [ ] Lot 2 : Enseignants, Sites, Communication, Rapports
- [ ] Lot 3 : Cours de vacances, Résultats aux examens
- [ ] Déploiement (hébergement cloud simple, DigitalOcean/Railway/Hetzner)

---

## Démarrage du projet

> À compléter une fois l'initialisation technique faite par l'équipe.

```bash
# Backend
cd backend
# instructions d'installation à venir (venv, dépendances, migrations)

# App mobile
cd mobile
flutter pub get
flutter run

# Dashboard web
cd web
npm install
npm run dev
```

---

## Convention Git

- **Branches** : `main` (stable) ← `dev` (intégration) ← branches de feature nommées `module/nom-court` (ex. `paiements/encaissement`, `eleves/fiche`)
- **Commits** : messages courts et descriptifs, préfixés par le module (ex. `paiements: ajoute la détection des retards`)
- **Pull requests** : une PR par fonctionnalité, revue croisée entre les deux personnes avant fusion dans `dev`, même en équipe de 2, ça évite les régressions silencieuses sur un module partagé (schéma de données commun notamment)

---

## Modèle de données partagé

Les entités suivantes sont communes à plusieurs modules et doivent être conçues ensemble avant tout développement :

- `Eleve` (élève)
- `Site`
- `Utilisateur` / `Poste` / `Permission` (système de rôles modulaires)
- `Paiement`

Le détail du schéma sera documenté dans `docs/schema-bdd.md` (à créer lors de la session de conception commune).
