# Guide de démonstration

## Objectif

Présenter un parcours traçable : administration, fiche élève, paiement hors
ligne, synchronisation, validation d'annulation et indicateurs Direction.

## Préparation

Créer sans modifier le code : un compte Direction multi-sites avec toutes les
permissions, un compte Secrétariat d'un seul site, deux sites, un élève actif
et deux échéances. Suivre `docs/guide-test-backend.md` et vérifier que le
téléphone, l'API et le dashboard ciblent le même environnement.

## Déroulé

1. Connecter le compte Secrétariat et montrer son site.
2. Créer ou modifier un élève, puis ouvrir sa fiche.
3. Saisir un paiement connecté et montrer l'historique.
4. Couper le réseau, créer un second paiement et montrer le bandeau en attente.
5. Rétablir le réseau, synchroniser et vérifier le résultat.
6. Demander l'annulation d'un paiement avec un motif.
7. Connecter un responsable autorisé, approuver ou rejeter, puis vérifier le statut.
8. Avec Direction, créer un site et vérifier son apparition dans la liste.
9. Ouvrir un poste, affecter des permissions, puis ouvrir le dashboard web.
10. Filtrer un site et actualiser ses statistiques financières.

## Limites à annoncer

Le dashboard actuel est une vue financière par site, pas un reporting
exhaustif ni un export mensuel. Les notifications FCM nécessitent une
configuration Firebase réelle ; SMS et e-mail ne sont pas fournis. Les modules
Enseignants et Programmes spéciaux sont disponibles ; leur recette complète
figure dans `GUIDE_RECETTE_COMPLETE.md`.

## Secours

Sans Internet, montrer la création locale et l'état en attente, sans prétendre
que le serveur a confirmé le paiement. En cas d'erreur API, conserver le
message et les données locales, puis consulter les logs Django. En cas de
problème mobile, utiliser les appels du guide backend et noter l'incident.

## Questions probables

- Suppression d'élève : non physique ; le dossier devient inactif et conserve
  l'historique financier.
- Paiement sans Internet : oui, via un UUID local et une synchronisation
  idempotente.
- Annulation : demande motivée puis validation par `valider_actions_sensibles`.
- Cloisonnement : l'API filtre les données selon le site de l'utilisateur.
