# Règles métier — Lot 3 : vacances et préparation aux examens

## Statut et objectif

Ce document est la spécification de référence avant développement. Il complète
le MVP sans modifier ses principes : un paiement reste traçable, les données
sont cloisonnées par site et aucun élève n'est supprimé physiquement.

Le Lot 3 couvre deux offres distinctes :

1. **Sessions vacances** : cours intensifs limités dans le temps.
2. **Préparation Bac/BEPC** : programmes annuels ou intensifs par matière.

Les montants, capacités et dates sont configurés par site ; ils ne sont jamais
codés en dur dans l'application.

## Vocabulaire

| Terme | Définition |
|---|---|
| Programme | Offre pédagogique commercialisable : Vacances, Bac ou BEPC. |
| Session | Occurrence d'un programme sur un site, avec dates, capacité et statut. |
| Groupe | Sous-ensemble d'une session, défini par niveau/classe et éventuellement matière. |
| Inscription | Lien historique entre un élève et un groupe. |
| Tarif | Prix configuré, applicable à un programme/groupe/site sur une période. |
| Échéance | Somme due générée après validation de l'inscription ; elle réutilise le moteur Paiements existant. |

## Cycle de vie

```text
BROUILLON → OUVERT → COMPLET / CLÔTURÉ → TERMINÉ → ARCHIVÉ
                 └→ ANNULÉ

INSCRIPTION : BROUILLON → CONFIRMÉE → ANNULÉE
```

- Seul un programme **ouvert** accepte des inscriptions.
- Un groupe devient **complet** quand son effectif confirmé atteint sa
  capacité. Les inscriptions existantes restent visibles.
- Une session clôturée ou terminée n'est pas modifiable, sauf ses notes de
  bilan par un poste autorisé.
- Annuler une session n'efface rien : les inscriptions restent auditées et les
  échéances non réglées sont annulées. Toute modification d'un paiement déjà
  encaissé passe par le workflow de validation existant.

## Règles sessions vacances

1. Une session possède obligatoirement : site, intitulé, date de début, date
   de fin, capacité et statut.
2. La date de fin doit être strictement postérieure à la date de début.
3. Un groupe est rattaché à une unique session et définit au minimum une
   classe/niveau, une capacité et un tarif actif.
4. Un élève ne peut avoir qu'une inscription confirmée pour le même programme,
   même site et période dont les dates se chevauchent.
5. L'inscription peut être créée hors ligne en statut `brouillon_local`, mais
   sa confirmation et l'émission de l'échéance exigent la disponibilité du
   serveur afin d'éviter le dépassement de capacité.
6. La capacité est contrôlée sous transaction lors de la confirmation, jamais
   seulement par l'interface mobile.
7. L'annulation par le gestionnaire avant le premier paiement annule
   l'inscription. Après paiement, elle devient une demande sensible avec
   motif obligatoire.

## Règles préparation Bac / BEPC

1. Un programme examen a `type_examen` égal à `bac` ou `bepc`, une année
   scolaire et une ou plusieurs matières.
2. Le niveau est cohérent avec l'examen : BEPC pour les classes de collège,
   Bac pour les classes terminales. La liste exacte des classes est un
   paramètre administrable par site.
3. Un élève peut être inscrit à plusieurs matières d'un même programme, mais
   une seule fois par matière.
4. Chaque matière peut avoir son propre tarif, groupe, enseignant, planning et
   capacité.
5. Les séances sont déclarées par l'enseignant avec présence agrégée, selon le
   module Enseignants. Les notes individuelles ne font pas partie du premier
   incrément du Lot 3.
6. Le bilan affiche séances prévues/tenues, taux de présence agrégé, effectif
   inscrit et état de paiement. Il ne prétend pas prédire une réussite à
   l'examen.

## Tarification et paiements

1. Un tarif est un montant FCFA entier, strictement positif, associé à un
   site, programme/groupe et période de validité.
2. Le prix est copié dans l'inscription confirmée : changer le tarif futur ne
   modifie jamais une inscription déjà confirmée.
3. Une inscription confirmée crée une échéance. Les paiements partiels et les
   annulations utilisent les règles Paiements déjà en production.
4. Une remise exige un motif et la permission `gerer_tarifs`; toute remise
   supérieure au seuil configurable du site (proposition : 20 %) exige la
   validation `valider_actions_sensibles`.
5. Aucun trop-perçu n'est accepté. Un remboursement n'est pas automatisé : il
   est traité comme action sensible, avec une référence de paiement.

## Rôles et permissions à ajouter

| Permission | Autorise |
|---|---|
| `gerer_programmes` | Créer, ouvrir, clôturer ou annuler sessions et groupes. |
| `gerer_tarifs` | Configurer les tarifs et remises. |
| `inscrire_programmes` | Créer ou modifier les inscriptions avant paiement. |
| `voir_programmes` | Consulter groupes, effectifs et bilans du site. |
| `saisir_resultats_examens` | Futur incrément : saisir les résultats Bac/BEPC. |

La direction peut recevoir ces permissions avec `tous_sites=true`; les autres
postes restent limités à leur site.

## Données minimales à créer

```text
PROGRAMME(id, type, nom, annee_scolaire, statut)
SESSION(id, programme_id, site_id, date_debut, date_fin, capacite, statut)
GROUPE(id, session_id, niveau, matiere?, capacite, enseignant_id?, statut)
TARIF(id, site_id, programme_id?, groupe_id?, montant, debut_validite, fin_validite?)
INSCRIPTION_PROGRAMME(id, eleve_id, groupe_id, tarif_fixe, remise, statut, date_inscription)
```

L'échéance produite est reliée à l'inscription par une clé étrangère nullable,
afin de préserver les échéances historiques existantes.

## Indicateurs dashboard

- sessions ouvertes, complètes, clôturées et taux de remplissage par site ;
- inscrits confirmés par programme, niveau et matière ;
- montant attendu, encaissé et restant par session ;
- séances prévues/tenues et taux de présence agrégé par groupe ;
- pour Bac/BEPC, résultats saisis et taux de réussite uniquement après la
  création du futur module Résultats.

Les indicateurs financiers excluent les paiements annulés et respectent le
périmètre de site de l'utilisateur connecté.

## Découpage recommandé

1. **Lot 3A** : programmes, sessions vacances, groupes, tarifs, inscriptions
   et échéances ; tests de capacité et de cloisonnement.
2. **Lot 3B** : planning/présence des groupes et indicateurs dashboard.
3. **Lot 3C** : résultats Bac/BEPC, import contrôlé et statistiques de
   réussite.

## Décisions à valider avant implémentation

- seuil exact de remise et qui l'approuve ;
- classes éligibles Bac/BEPC par site ;
- une échéance unique ou un échéancier par inscription ;
- politique de remboursement après annulation ;
- saisie des notes individuelles ou résultats finaux seulement.
