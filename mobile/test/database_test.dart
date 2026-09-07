import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/database.dart';

/// Tests de la couche Drift, isolés de tout widget : on injecte un
/// exécuteur en mémoire via `AppDatabase.forTesting(...)`, sans jamais
/// toucher au chemin de production (`AppDatabase()` → fichier SQLite réel).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Calcul du solde des échéances', () {
    test(
      'une échéance sans paiement et en retard est bien signalée',
      () async {
        await db.into(db.eleves).insert(
              ElevesCompanion.insert(
                id: 'eleve-1',
                nom: 'Kaboré',
                prenom: 'Adama',
                classe: '3ème B',
                siteId: 'site-1',
              ),
            );
        await db.into(db.echeances).insert(
              EcheancesCompanion.insert(
                id: 'echeance-1',
                eleveId: 'eleve-1',
                montantDu: 15000,
                dateEcheance: DateTime.now().subtract(
                  const Duration(days: 10),
                ),
                statut: 'a_jour',
              ),
            );

        final resultats = await db.watchEcheancesAvecSolde().first;

        expect(resultats, hasLength(1));
        expect(resultats.first.statut, 'en_retard');
        expect(resultats.first.montantRestant, 15000);
      },
    );

    test('un paiement partiel valide met à jour le solde restant', () async {
      await db.into(db.eleves).insert(
            ElevesCompanion.insert(
              id: 'eleve-1',
              nom: 'Kaboré',
              prenom: 'Adama',
              classe: '3ème B',
              siteId: 'site-1',
            ),
          );
      await db.into(db.echeances).insert(
            EcheancesCompanion.insert(
              id: 'echeance-1',
              eleveId: 'eleve-1',
              montantDu: 15000,
              dateEcheance: DateTime.now().add(const Duration(days: 5)),
              statut: 'a_jour',
            ),
          );
      await db.into(db.paiements).insert(
            PaiementsCompanion.insert(
              clientUuid: 'client-1',
              echeanceId: 'echeance-1',
              montant: 5000,
              modePaiement: 'especes',
              dateLocale: DateTime.now(),
            ),
          );

      final resultats = await db.watchEcheancesAvecSolde().first;

      expect(resultats.first.statut, 'partiel');
      expect(resultats.first.montantRestant, 10000);
    });

    test('une échéance soldée sort du calcul du retard', () async {
      await db.into(db.eleves).insert(
            ElevesCompanion.insert(
              id: 'eleve-1',
              nom: 'Ouédraogo',
              prenom: 'Salimata',
              classe: 'Terminale D',
              siteId: 'site-1',
            ),
          );
      await db.into(db.echeances).insert(
            EcheancesCompanion.insert(
              id: 'echeance-1',
              eleveId: 'eleve-1',
              montantDu: 15000,
              dateEcheance: DateTime.now().subtract(const Duration(days: 3)),
              statut: 'a_jour',
            ),
          );
      await db.into(db.paiements).insert(
            PaiementsCompanion.insert(
              clientUuid: 'client-1',
              echeanceId: 'echeance-1',
              montant: 15000,
              modePaiement: 'especes',
              dateLocale: DateTime.now(),
            ),
          );

      final resultats = await db.watchEcheancesAvecSolde().first;

      expect(resultats.first.statut, 'solde');
      expect(resultats.first.montantRestant, 0);
    });
  });

  group('Workflow de validation (annulation de paiement)', () {
    Future<void> creerEleveEcheancePaiement(AppDatabase db) async {
      await db.into(db.eleves).insert(
            ElevesCompanion.insert(
              id: 'eleve-1',
              nom: 'Sawadogo',
              prenom: 'Boureima',
              classe: '2nde C',
              siteId: 'site-1',
            ),
          );
      await db.into(db.echeances).insert(
            EcheancesCompanion.insert(
              id: 'echeance-1',
              eleveId: 'eleve-1',
              montantDu: 15000,
              dateEcheance: DateTime.now(),
              statut: 'a_jour',
            ),
          );
      await db.into(db.paiements).insert(
            PaiementsCompanion.insert(
              clientUuid: 'paiement-1',
              echeanceId: 'echeance-1',
              montant: 15000,
              modePaiement: 'especes',
              dateLocale: DateTime.now(),
            ),
          );
    }

    test('approuver une demande annule le paiement concerné', () async {
      await creerEleveEcheancePaiement(db);

      await db.demanderAnnulationPaiement(
        paiementClientUuid: 'paiement-1',
        motif: 'Erreur de saisie',
      );

      final demandes = await db.watchDemandesEnAttente().first;
      expect(demandes, hasLength(1));

      await db.traiterDemande(
        demandeClientUuid: demandes.first.demande.clientUuid,
        approuver: true,
      );

      final paiement = await (db.select(
        db.paiements,
      )..where((p) => p.clientUuid.equals('paiement-1'))).getSingle();
      expect(paiement.statut, 'annule');

      // Le paiement annulé sort du calcul du solde de l'échéance.
      final resultats = await db.watchEcheancesAvecSolde().first;
      expect(resultats.first.montantRestant, 15000);
    });

    test('rejeter une demande laisse le paiement valide', () async {
      await creerEleveEcheancePaiement(db);

      await db.demanderAnnulationPaiement(
        paiementClientUuid: 'paiement-1',
        motif: 'Test',
      );
      final demandes = await db.watchDemandesEnAttente().first;

      await db.traiterDemande(
        demandeClientUuid: demandes.first.demande.clientUuid,
        approuver: false,
      );

      final paiement = await (db.select(
        db.paiements,
      )..where((p) => p.clientUuid.equals('paiement-1'))).getSingle();
      expect(paiement.statut, 'valide');
    });
  });
}
