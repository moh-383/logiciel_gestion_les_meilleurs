import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../features/paiements/paiements_list_screen.dart' show databaseProvider;
import 'api_client.dart';
import 'auth_service.dart';

/// Résultat d'un import, pour affichage éventuel dans l'UI.
class ResultatImport {
  final int nbEleves;
  final int nbEcheances;
  final String? erreur;

  ResultatImport({required this.nbEleves, required this.nbEcheances, this.erreur});

  bool get succes => erreur == null;
}

/// Récupère les élèves et échéances du site de l'utilisateur connecté
/// (`GET /eleves`, `GET /sites/{id}/echeances`) et les upsert dans Drift.
///
/// IMPORTANT : ceci ne fait JAMAIS de suppression locale. Un paiement ou
/// une demande d'annulation créés hors ligne référencent un `eleveId` /
/// `echeanceId` — les effacer silencieusement casserait ces références
/// avant même la synchronisation des paiements. On upsert uniquement.
class ImportService {
  final AppDatabase db;
  final Dio dio;
  final TokenStore tokenStore;

  ImportService({required this.db, required this.dio, required this.tokenStore});

  Future<ResultatImport> importerDonneesDuSite() async {
    try {
      final session = await tokenStore.readSession();
      if (session == null) {
        return ResultatImport(nbEleves: 0, nbEcheances: 0, erreur: 'Non connecté.');
      }
      final siteId = session.siteId;
      if (siteId == null) {
        // Poste "tous_sites" (direction) : hors scope mobile secrétaire/
        // responsable de site pour l'instant — pas d'import automatique.
        return ResultatImport(nbEleves: 0, nbEcheances: 0);
      }

      final eleves = await _recupererTousLesEleves();
      await db.upsertEleves(eleves);

      final echeances = await _recupererEcheancesDuSite(siteId);
      await db.upsertEcheances(echeances);

      return ResultatImport(nbEleves: eleves.length, nbEcheances: echeances.length);
    } on DioException catch (e) {
      return ResultatImport(nbEleves: 0, nbEcheances: 0, erreur: _messageErreur(e));
    }
  }

  Future<List<ElevesCompanion>> _recupererTousLesEleves() async {
    final resultats = <ElevesCompanion>[];
    int page = 1;
    const limit = 100;
    while (true) {
      final reponse = await dio.get('/eleves', queryParameters: {'page': page, 'limit': limit});
      final data = reponse.data as Map;
      final items = (data['data'] as List).cast<Map>();

      for (final item in items) {
        resultats.add(ElevesCompanion.insert(
          id: item['id'] as String,
          matricule: Value((item['matricule'] as String?) ?? ''),
          nom: item['nom'] as String,
          prenom: item['prenom'] as String,
          classe: item['classe'] as String,
          siteId: item['site_id'] as String,
        ));
      }

      final total = data['total'] as int;
      if (items.isEmpty || page * limit >= total) break;
      page++;
    }
    return resultats;
  }

  Future<List<EcheancesCompanion>> _recupererEcheancesDuSite(String siteId) async {
    final resultats = <EcheancesCompanion>[];
    int page = 1;
    const limit = 200;
    while (true) {
      final reponse = await dio.get(
        '/sites/$siteId/echeances',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = reponse.data as Map;
      final items = (data['data'] as List).cast<Map>();

      for (final item in items) {
        resultats.add(EcheancesCompanion.insert(
          id: item['id'] as String,
          eleveId: item['eleve'] as String,
          montantDu: double.parse(item['montant_du'].toString()),
          dateEcheance: DateTime.parse(item['date_echeance'] as String),
          statut: item['statut'] as String,
        ));
      }

      final total = data['total'] as int;
      if (items.isEmpty || page * limit >= total) break;
      page++;
    }
    return resultats;
  }

  String _messageErreur(DioException erreur) {
    final data = erreur.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    return erreur.message ?? "Import impossible : serveur inaccessible.";
  }
}

final importServiceProvider = Provider<ImportService>((ref) {
  final db = ref.watch(databaseProvider);
  final dio = ref.watch(dioProvider);
  final tokenStore = ref.watch(tokenStoreProvider);
  return ImportService(db: db, dio: dio, tokenStore: tokenStore);
});