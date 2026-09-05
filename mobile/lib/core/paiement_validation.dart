/// Validation métier pure (sans dépendance Flutter) pour la saisie d'un
/// paiement local, avant tout envoi au serveur.
///
/// Le serveur reste la source de vérité (voir
/// `backend/paiements/services.py::enregistrer_paiement`, qui rejette tout
/// dépassement du solde de l'échéance). Mais sans ce contrôle côté mobile,
/// une secrétaire hors ligne peut enregistrer localement un paiement que le
/// serveur refusera de toute façon à la synchronisation (`conflit` /
/// dépassement de solde) — le paiement reste alors coincé en statut
/// "conflit" sans que personne ne comprenne pourquoi. Ce contrôle évite
/// d'en arriver là dans la grande majorité des cas (hors création
/// concurrente sur deux appareils avant sync, qui reste un cas géré côté
/// serveur/arbitrage manuel).
///
/// Retourne un message d'erreur (à afficher tel quel à l'utilisateur) si la
/// saisie est invalide, ou `null` si elle peut être enregistrée.
String? validerMontantPaiement({
  required double? montant,
  required double montantRestant,
}) {
  if (montant == null || montant <= 0) {
    return 'Entre un montant valide.';
  }

  // Tolérance pour absorber les imprécisions de calcul en double (FCFA
  // n'a pas de décimales, mais les soustractions flottantes peuvent laisser
  // des résidus du type 0.000000001).
  const tolerance = 0.5;

  if (montantRestant <= tolerance) {
    return 'Cette échéance est déjà soldée.';
  }
  if (montant > montantRestant + tolerance) {
    return 'Le montant dépasse le solde restant '
        '(${montantRestant.toStringAsFixed(0)} FCFA).';
  }
  return null;
}
