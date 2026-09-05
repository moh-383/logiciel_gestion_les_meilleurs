import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/paiement_validation.dart';

void main() {
  group('validerMontantPaiement', () {
    test('refuse un montant nul ou non saisi', () {
      expect(
        validerMontantPaiement(montant: null, montantRestant: 10000),
        isNotNull,
      );
    });

    test('refuse un montant négatif ou nul', () {
      expect(
        validerMontantPaiement(montant: 0, montantRestant: 10000),
        isNotNull,
      );
      expect(
        validerMontantPaiement(montant: -100, montantRestant: 10000),
        isNotNull,
      );
    });

    test('refuse un paiement sur une échéance déjà soldée', () {
      expect(
        validerMontantPaiement(montant: 1000, montantRestant: 0),
        isNotNull,
      );
    });

    test('refuse un montant qui dépasse le solde restant', () {
      final erreur = validerMontantPaiement(
        montant: 20000,
        montantRestant: 15000,
      );
      expect(erreur, isNotNull);
      expect(erreur, contains('15000'));
    });

    test('accepte un paiement partiel valide', () {
      expect(
        validerMontantPaiement(montant: 5000, montantRestant: 15000),
        isNull,
      );
    });

    test("accepte un paiement qui solde exactement l'échéance", () {
      expect(
        validerMontantPaiement(montant: 15000, montantRestant: 15000),
        isNull,
      );
    });

    test('tolère un écart d\'arrondi négligeable (< 0.5 FCFA)', () {
      expect(
        validerMontantPaiement(montant: 15000.3, montantRestant: 15000),
        isNull,
      );
    });

    test('refuse un dépassement même minime au-delà de la tolérance', () {
      expect(
        validerMontantPaiement(montant: 15001, montantRestant: 15000),
        isNotNull,
      );
    });
  });
}
