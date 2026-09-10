import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/database.dart';

class EchangeAffichable {
  final String? idServeur;
  final String? clientUuidLocal;
  final String eleveId;
  final String typeEchange;
  final String titre;
  final String description;
  final String creeParNom;
  final DateTime dateEchange;
  final bool enAttenteDeSync;
  final String? syncRaison;

  EchangeAffichable({
    this.idServeur,
    this.clientUuidLocal,
    required this.eleveId,
    required this.typeEchange,
    required this.titre,
    required this.description,
    required this.creeParNom,
    required this.dateEchange,
    required this.enAttenteDeSync,
    this.syncRaison,
  });
}

class EchangeRepository {
  final AppDatabase db;

  EchangeRepository(this.db);

  Stream<List<EchangeAffichable>> watchEchangesDeLEleve(String eleveId) {
    final confirmesStream =
        (db.select(db.echanges)..where((e) => e.eleveId.equals(eleveId))).watch();
    final enAttenteStream = (db.select(db.echangesEnAttente)..where(
          (e) =>
              e.eleveId.equals(eleveId) &
              (e.syncStatus.equals('en_attente') | e.syncStatus.equals('conflit')),
        ))
        .watch();

    return Stream.multi((controller) {
      List<Echange>? confirmes;
      List<EchangeEnAttente>? enAttente;

      void publier() {
        if (confirmes == null || enAttente == null) return;
        final resultats = <EchangeAffichable>[
          ...confirmes!.map(
            (e) => EchangeAffichable(
              idServeur: e.id, eleveId: e.eleveId, typeEchange: e.typeEchange,
              titre: e.titre, description: e.description, creeParNom: e.creeParNom,
              dateEchange: e.dateEchange, enAttenteDeSync: false,
            ),
          ),
          ...enAttente!.map(
            (e) => EchangeAffichable(
              clientUuidLocal: e.clientUuid, eleveId: e.eleveId, typeEchange: e.typeEchange,
              titre: e.titre, description: e.description, creeParNom: 'Moi (non synchronisé)',
              dateEchange: e.dateEchange, enAttenteDeSync: true, syncRaison: e.syncRaison,
            ),
          ),
        ];
        resultats.sort((a, b) => b.dateEchange.compareTo(a.dateEchange));
        controller.add(resultats);
      }

      final abonnements = [
        confirmesStream.listen((v) { confirmes = v; publier(); }),
        enAttenteStream.listen((v) { enAttente = v; publier(); }),
      ];
      controller.onCancel = () async {
        for (final a in abonnements) { await a.cancel(); }
      };
    });
  }

  Future<void> creerEchangeLocal({
    required String eleveId,
    required String typeEchange,
    required String titre,
    required String description,
    required DateTime dateEchange,
  }) async {
    await db.into(db.echangesEnAttente).insert(
          EchangesEnAttenteCompanion.insert(
            clientUuid: const Uuid().v4(),
            eleveId: eleveId,
            typeEchange: typeEchange,
            titre: titre,
            description: Value(description),
            dateEchange: dateEchange,
            dateCreationLocale: DateTime.now(),
          ),
        );
  }

  Future<List<EchangeEnAttente>> echangesEnAttenteDeSync() {
    return (db.select(db.echangesEnAttente)..where((e) => e.syncStatus.equals('en_attente'))).get();
  }

  Future<void> appliquerResultatSyncEchange({
    required String clientUuid,
    required String statut,
    String? idServeur,
    String? raison,
  }) async {
    if (statut == 'cree' || statut == 'deja_existant') {
      await (db.update(db.echangesEnAttente)..where((e) => e.clientUuid.equals(clientUuid))).write(
        EchangesEnAttenteCompanion(
          id: Value(idServeur), syncStatus: const Value('synchronise'), syncRaison: const Value(null),
        ),
      );
    } else {
      await (db.update(db.echangesEnAttente)..where((e) => e.clientUuid.equals(clientUuid))).write(
        EchangesEnAttenteCompanion(syncStatus: const Value('conflit'), syncRaison: Value(raison)),
      );
    }
  }
}