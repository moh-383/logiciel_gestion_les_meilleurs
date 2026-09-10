import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../paiements/paiements_list_screen.dart' show databaseProvider;
import '../data/echange_repository.dart';

final echangeRepositoryProvider = Provider<EchangeRepository>((ref) {
  return EchangeRepository(ref.watch(databaseProvider));
});

final echangesDeLEleveProvider = StreamProvider.family((ref, String eleveId) {
  return ref.watch(echangeRepositoryProvider).watchEchangesDeLEleve(eleveId);
});

class EchangeSyncService {
  final EchangeRepository repository;
  final Dio dio;
  bool _enCours = false;

  EchangeSyncService({required this.repository, required this.dio});

  /// Retourne un message d'erreur si la sync a échoué, sinon null.
  Future<String?> synchroniser() async {
    if (_enCours) return null;
    _enCours = true;
    try {
      final enAttente = await repository.echangesEnAttenteDeSync();
      if (enAttente.isEmpty) return null;

      final corps = enAttente
          .map((e) => {
                'client_uuid': e.clientUuid,
                'eleve_id': e.eleveId,
                'type_echange': e.typeEchange,
                'titre': e.titre,
                'description': e.description,
                'date_echange': e.dateEchange.toUtc().toIso8601String(),
              })
          .toList();

      final reponse = await dio.post('/sync/echanges', data: corps);
      final resultats = (reponse.data['resultats'] as List).map((r) => Map<String, dynamic>.from(r as Map));

      for (final r in resultats) {
        await repository.appliquerResultatSyncEchange(
          clientUuid: r['client_uuid'] as String,
          statut: r['statut'] as String,
          idServeur: r['id'] as String?,
          raison: r['raison']?.toString(),
        );
      }
      return null;
    } on DioException catch (e) {
      return e.message ?? 'Le serveur est inaccessible.';
    } finally {
      _enCours = false;
    }
  }
}

final echangeSyncServiceProvider = Provider<EchangeSyncService>((ref) {
  return EchangeSyncService(repository: ref.watch(echangeRepositoryProvider), dio: ref.watch(dioProvider));
});