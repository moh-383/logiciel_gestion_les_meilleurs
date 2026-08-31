# Planning : Sprints (MVP puis v2)

Sprints d'1 semaine, équipe de 2. Rythme volontairement modeste, mieux vaut un sprint tenu que trois sprints débordés. Chaque sprint se termine par une synchro courte des deux personnes (30 min suffisent) pour vérifier l'intégration.

Légende : **A** = Personne A (Élèves, Administration/Rôles, puis Enseignants/Sites, puis Vacances) · **B** = Personne B (Paiements offline, puis Communication/Rapports, puis Résultats aux examens)

---

## Sprint 0 : Cadrage technique (semaine 1)

Objectif : que les deux personnes partent sur des bases identiques avant d'écrire la première ligne de code métier.

- **Ensemble** : finaliser le schéma de base de données (`docs/schema-bdd.md`) et le contrat d'API (`docs/api-contract.md`), décider en particulier le format des dates et la liste complète des codes de permission
- **Ensemble** : initialiser le dépôt (structure de dossiers, `README.md`, branches `main`/`dev`)
- **A** : mettre en place le projet backend (choix définitif FastAPI/Django, structure, connexion PostgreSQL)
- **B** : initialiser le projet Flutter (structure, dépendance Drift/Isar, squelette de navigation)

*Rien de fonctionnel visible cette semaine : c'est normal, c'est la semaine la plus importante pour éviter les retouches plus tard.*

## Sprint 1 : Fondations auth & modèle

- **A** : authentification (login, JWT), tables `POSTE`, `PERMISSION`, `POSTE_PERMISSION`, `UTILISATEUR` en base + endpoints correspondants
- **B** : tables `ELEVE` (schéma seul, pas encore d'UI), `ECHEANCE`, `PAIEMENT` en base ; mise en place du stockage local Drift/Isar sur mobile

## Sprint 2 : Premiers écrans

- **A** : écran de connexion (mobile + web) ; endpoint et UI liste/fiche élève basique (lecture seule)
- **B** : endpoint de création de paiement (en ligne uniquement pour l'instant, pas encore l'offline) ; écran mobile liste des paiements du site (maquette déjà validée)

## Sprint 3 : CRUD élèves & encaissement

- **A** : création/modification d'élève (formulaire déjà maquetté) + contacts parents
- **B** : écran d'encaissement (déjà maquetté) branché à l'API ; calcul du statut d'échéance (à jour/partiel/en retard)

## Sprint 4 : Rôles & offline

- **A** : écran d'administration des rôles/permissions (déjà maquetté) ; assignation de postes aux utilisateurs
- **B** : mécanisme de synchronisation hors ligne v1 (`POST /sync/paiements`, gestion du `client_uuid`), le sprint le plus technique, ne pas hésiter à le laisser déborder sur le sprint 5 si besoin

## Sprint 5 : Workflow d'approbation & finitions

- **A** : cloisonnement par site (vérification que les permissions filtrent bien les données) ; finitions de la fiche élève (résumé financier intégré)
- **B** : workflow de demande de validation (annulation de paiement) ; gestion des conflits de synchronisation

## Sprint 6 : Intégration & tests croisés

- **Ensemble** : chacun teste le module de l'autre comme un vrai utilisateur (A teste les paiements, B teste les élèves/rôles) ; correction des incohérences trouvées
- **Ensemble** : préparer une démo interne (ex. montrer à un responsable de site pour retour rapide)

## Sprint 7 : Stabilisation MVP (buffer)

Semaine tampon, volontairement prévue à l'avance : corriger les bugs remontés en sprint 6, combler les manques. Un planning sans semaine tampon est un planning qui va glisser silencieusement, autant l'assumer dès le départ.

**→ Fin du MVP, environ 8 semaines après le lancement.**

---

## Lot 2 (v2) : sprints 8 à 11

| Sprint | A - Enseignants & Sites | B - Communication & Rapports |
|---|---|---|
| 8 | Fiche enseignant, affectation aux classes/sites | Notifications automatiques (retard, rappel de paiement) via Firebase |
| 9 | Planning des cours, rapports mensuels enseignants | Historique des échanges/incidents par élève |
| 10 | Fiche site enrichie, rapports des responsables de site | Tableau de bord direction (vue déjà maquettée), génération automatique de rapports mensuels |
| 11 | Intégration & tests croisés du lot | Intégration & tests croisés du lot |

## Lot 3 (v2) : sprints 12 à 14

| Sprint | A - Cours de vacances | B - Résultats aux examens |
|---|---|---|
| 12 | Sessions courtes, inscription et tarification spécifiques | Liste des candidats Bac/BEPC, répartition des appels sans doublon |
| 13 | Finitions et tests | Saisie des résultats, calcul des statistiques en temps réel |
| 14 | Intégration & tests croisés | Génération automatique du visuel de statistiques (Facebook/WhatsApp) |

---

## Résumé

| Étape | Durée estimée | Fin approximative (à partir du lancement) |
|---|---|---|
| Sprint 0 → 7 (MVP) | 8 semaines | ~2 mois |
| Lot 2 | 4 semaines | ~3 mois |
| Lot 3 | 3 semaines | ~3,5 mois |

Ces durées supposent un rythme régulier à temps partiel sans interruption prolongée (examens, autres engagements). En cas de semaine sans avancement, il vaut mieux décaler le planning que de compresser les sprints suivants, le rythme tenable compte plus que la date.

## Rituels suggérés

- **Point hebdomadaire** (30 min, début ou fin de semaine) : ce qui a été fait, ce qui bloque, objectif de la semaine suivante.
- **Revue de code croisée** avant de fusionner dans `dev`, même à 2, surtout sur le schéma de données partagé.
- **Démo courte** à la fin de chaque lot (MVP, lot 2, lot 3), même informelle, ça aide à garder le lien avec le besoin réel de la structure.
