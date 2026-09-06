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
  final String eleveId;
  final String echeanceId;
  final String eleveNom;
  final String matricule;
  final String classe;
  final double montantDu;
  final double montantRestant; // négatif si avance
  final String statut; // en_retard / partiel / solde / avance
  final int joursRetard;

  EcheanceAvecSolde({
    required this.eleveId,
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

/// Vérifie si une colonne existe réellement dans le fichier SQLite, avant
/// de tenter un `ALTER TABLE ... ADD COLUMN`. Sans ce garde-fou, un appareil
/// dont la base a déjà reçu la colonne par un autre chemin plante avec
/// `duplicate column name` au démarrage (bug rencontré sur `note`, v5).
Future<bool> _colonneExiste(
  GeneratedDatabase db,
  String table,
  String colonne,
) async {
  final lignes = await db.customSelect("PRAGMA table_info('$table')").get();
  return lignes.any((row) => row.data['name'] == colonne);
}

@DriftDatabase(
  tables: [Eleves, Echeances, Paiements, DemandesValidation, ElevesEnAttente],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructeur réservé aux tests : permet d'injecter un exécuteur en
  /// mémoire (`NativeDatabase.memory()`) sans jamais toucher au chemin de
  /// production ci-dessus (fichier SQLite réel sur l'appareil).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion =>
      7; // v2 : matricule · v3 : statut paiement + demandes · v4 : sync_raison
      // v5 : note · v6 : cache élèves enrichi · v7 : file d'attente élèves

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
        if (from < 5) {
          if (!await _colonneExiste(this, 'paiements', 'note')) {
            await m.addColumn(paiements, paiements.note);
          }
        }
        if (from < 6) {
          if (!await _colonneExiste(this, 'eleves', 'date_naissance')) {
            await m.addColumn(eleves, eleves.dateNaissance);
          }
          if (!await _colonneExiste(this, 'eleves', 'sexe')) {
            await m.addColumn(eleves, eleves.sexe);
          }
          if (!await _colonneExiste(this, 'eleves', 'type_cours')) {
            await m.addColumn(eleves, eleves.typeCours);
          }
          if (!await _colonneExiste(this, 'eleves', 'statut')) {
            await m.addColumn(eleves, eleves.statut);
          }
        }
        if (from < 7) {
          await m.createTable(elevesEnAttente);
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
          statut = 'avance';
        } else if (restant == 0) {
          statut = 'solde';
        } else if (paye > 0) {
          statut = 'partiel';
        } else if (joursRetard > 0) {
          statut = 'en_retard';
        } else {
          statut = 'solde';
        }

        return EcheanceAvecSolde(
          eleveId: eleve.id,
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

  Future<List<Paiement>> paiementsEnAttenteDeSync() {
    return (select(
      paiements,
    )..where((p) => p.syncStatus.equals('en_attente'))).get();
  }

  Future<void> appliquerResultatSync({
    required String clientUuid,
    required String statut,
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

  Stream<int> watchNbPaiementsNonSynchronises() {
    final query = selectOnly(paiements)
      ..addColumns([paiements.clientUuid.count()])
      ..where(paiements.syncStatus.isIn(['en_attente', 'conflit']));
    return query
        .map((row) => row.read(paiements.clientUuid.count()) ?? 0)
        .watchSingle();
  }

  /// Importe (upsert) les élèves reçus du backend. Ne supprime jamais un
  /// élève local absent de la réponse.
  Future<void> upsertEleves(List<ElevesCompanion> liste) async {
    if (liste.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(eleves, liste);
    });
  }

  Future<void> upsertEcheances(List<EcheancesCompanion> liste) async {
    if (liste.isEmpty) return;
    await batch((b) {
      b.insertAllOnConflictUpdate(echeances, liste);
    });
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