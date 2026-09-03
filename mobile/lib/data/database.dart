import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'dart:io';

import 'tables.dart';

part 'database.g.dart';

/// Modèle d'affichage : une échéance combinée à l'élève concerné
/// et au solde déjà réglé, calculé à partir des paiements locaux.
class EcheanceAvecSolde {
  final String echeanceId;
  final String eleveNom;
  final String matricule;
  final String classe;
  final double montantDu;
  final double montantRestant; // négatif si avance
  final String statut; // en_retard / partiel / solde / avance
  final int joursRetard;

  EcheanceAvecSolde({
    required this.echeanceId,
    required this.eleveNom,
    required this.matricule,
    required this.classe,
    required this.montantDu,
    required this.montantRestant,
    required this.statut,
    required this.joursRetard,
  });
}

@DriftDatabase(tables: [Eleves, Echeances, Paiements, DemandesValidation])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4; // v2 : matricule · v3 : statut paiement + demandes · v4 : sync_raison

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(eleves, eleves.matricule);
        }
        if (from < 3) {
          await m.addColumn(paiements, paiements.statut);
          await m.createTable(demandesValidation);
        }
        if (from < 4) {
          await m.addColumn(paiements, paiements.syncRaison);
        }
      },
    );
  }

  /// Flux réactif : se met à jour automatiquement dès qu'un paiement
  /// est ajouté (ex. juste après un encaissement), sans rien recharger
  /// manuellement côté UI.
  Stream<List<EcheanceAvecSolde>> watchEcheancesAvecSolde() {
    final totalPaye = paiements.montant.sum();

    final query =
        select(echeances).join([
            innerJoin(eleves, eleves.id.equalsExp(echeances.eleveId)),
            leftOuterJoin(
              paiements,
              paiements.echeanceId.equalsExp(echeances.id) &
                  paiements.statut.equals('valide'),
            ),
          ])
          ..addColumns([totalPaye])
          ..groupBy([echeances.id]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final echeance = row.readTable(echeances);
        final eleve = row.readTable(eleves);
        final paye = row.read(totalPaye) ?? 0.0;
        final restant = echeance.montantDu - paye;
        final joursRetard = DateTime.now()
            .difference(echeance.dateEcheance)
            .inDays;

        String statut;
        if (restant < 0) {
          statut = 'avance'; // le parent a payé plus que ce qui était dû
        } else if (restant == 0) {
          statut = 'solde';
        } else if (paye > 0) {
          statut = 'partiel';
        } else if (joursRetard > 0) {
          statut = 'en_retard';
        } else {
          statut = 'solde'; // échéance future, pas encore due, rien payé
        }

        return EcheanceAvecSolde(
          echeanceId: echeance.id,
          eleveNom: '${eleve.prenom} ${eleve.nom}',
          matricule: eleve.matricule,
          classe: eleve.classe,
          montantDu: echeance.montantDu,
          montantRestant: restant,
          statut: statut,
          joursRetard: joursRetard,
        );
      }).toList();
    });
  }

  /// Liste des paiements enregistrés pour une échéance donnée,
  /// avec le statut de demande d'annulation en cours s'il y en a une.
  Stream<List<PaiementAvecDemande>> watchPaiementsDeLEcheance(
    String echeanceId,
  ) {
    final query = select(paiements)
      ..where((p) => p.echeanceId.equals(echeanceId))
      ..orderBy([(p) => OrderingTerm.desc(p.dateLocale)]);

    return query.watch().asyncMap((liste) async {
      final resultats = <PaiementAvecDemande>[];
      for (final paiement in liste) {
        final demande =
            await (select(demandesValidation)..where(
                  (d) =>
                      d.paiementClientUuid.equals(paiement.clientUuid) &
                      d.statut.equals('en_attente'),
                ))
                .getSingleOrNull();
        resultats.add(
          PaiementAvecDemande(
            paiement: paiement,
            demandeEnAttente: demande != null,
          ),
        );
      }
      return resultats;
    });
  }

  /// Soumet une demande d'annulation pour un paiement — n'annule rien
  /// directement, le paiement reste valide jusqu'à validation du
  /// responsable de site (voir docs/schema-bdd.md, DEMANDE_VALIDATION).
  Future<void> demanderAnnulationPaiement({
    required String paiementClientUuid,
    required String motif,
  }) async {
    await into(demandesValidation).insert(
      DemandesValidationCompanion.insert(
        clientUuid: const Uuid().v4(),
        paiementClientUuid: paiementClientUuid,
        motif: Value(motif),
        dateDemande: DateTime.now(),
      ),
    );
  }

  /// Flux des demandes en attente, avec le paiement concerné —
  /// destiné à l'écran de validation (responsable de site).
  Stream<List<DemandeAvecPaiement>> watchDemandesEnAttente() {
    final query =
        select(demandesValidation).join([
            innerJoin(
              paiements,
              paiements.clientUuid.equalsExp(
                demandesValidation.paiementClientUuid,
              ),
            ),
          ])
          ..where(demandesValidation.statut.equals('en_attente'))
          ..orderBy([OrderingTerm.desc(demandesValidation.dateDemande)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => DemandeAvecPaiement(
              demande: row.readTable(demandesValidation),
              paiement: row.readTable(paiements),
            ),
          )
          .toList(),
    );
  }

  /// Approuve ou rejette une demande. En cas d'approbation, le paiement
  /// concerné passe au statut "annule" et sort du calcul des soldes.
  Future<void> traiterDemande({
    required String demandeClientUuid,
    required bool approuver,
  }) async {
    final demande = await (select(
      demandesValidation,
    )..where((d) => d.clientUuid.equals(demandeClientUuid))).getSingle();

    await (update(
      demandesValidation,
    )..where((d) => d.clientUuid.equals(demandeClientUuid))).write(
      DemandesValidationCompanion(
        statut: Value(approuver ? 'validee' : 'rejetee'),
      ),
    );

    if (approuver) {
      await (update(paiements)
            ..where((p) => p.clientUuid.equals(demande.paiementClientUuid)))
          .write(const PaiementsCompanion(statut: Value('annule')));
    }
  }

  /// Paiements pas encore confirmés par le serveur — ceux qu'il faut
  /// envoyer lors de la prochaine synchronisation.
  Future<List<Paiement>> paiementsEnAttenteDeSync() {
    return (select(
      paiements,
    )..where((p) => p.syncStatus.equals('en_attente'))).get();
  }

  /// Applique le résultat de /sync/paiements renvoyé par le serveur
  /// à un paiement local donné (voir docs/api-contract.md, §6).
  Future<void> appliquerResultatSync({
    required String clientUuid,
    required String statut, // 'cree' ou 'conflit'
    String? paiementIdServeur,
    String? raison,
  }) async {
    if (statut == 'cree') {
      await (update(
        paiements,
      )..where((p) => p.clientUuid.equals(clientUuid))).write(
        PaiementsCompanion(
          id: Value(paiementIdServeur),
          syncStatus: const Value('synchronise'),
          syncRaison: const Value(null),
        ),
      );
    } else {
      // 'conflit' : le paiement reste en local, visible pour arbitrage
      // manuel — on ne le supprime jamais silencieusement.
      await (update(
        paiements,
      )..where((p) => p.clientUuid.equals(clientUuid))).write(
        PaiementsCompanion(
          syncStatus: const Value('conflit'),
          syncRaison: Value(raison),
        ),
      );
    }
  }

  /// Nombre de paiements pas encore synchronisés (en attente + en conflit)
  /// — sert au badge affiché en haut de la liste.
  Stream<int> watchNbPaiementsNonSynchronises() {
    final query = selectOnly(paiements)
      ..addColumns([paiements.clientUuid.count()])
      ..where(paiements.syncStatus.isIn(['en_attente', 'conflit']));
    return query
        .map((row) => row.read(paiements.clientUuid.count()) ?? 0)
        .watchSingle();
  }
}

class PaiementAvecDemande {
  final Paiement paiement;
  final bool demandeEnAttente;

  PaiementAvecDemande({required this.paiement, required this.demandeEnAttente});
}

class DemandeAvecPaiement {
  final DemandeValidation demande;
  final Paiement paiement;

  DemandeAvecPaiement({required this.demande, required this.paiement});
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'gestion_scolaire.sqlite'));
    return NativeDatabase(file);
  });
}
