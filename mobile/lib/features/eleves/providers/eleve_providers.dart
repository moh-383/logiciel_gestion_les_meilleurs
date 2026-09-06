import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../paiements/paiements_list_screen.dart' show databaseProvider;
import '../data/eleve_repository.dart';

final eleveRepositoryProvider = Provider<EleveRepository>((ref) {
  return EleveRepository(ref.watch(databaseProvider));
});

final eleveSyncServiceProvider = Provider<EleveSyncService>((ref) {
  return EleveSyncService(
    repository: ref.watch(eleveRepositoryProvider),
    dio: ref.watch(dioProvider),
  );
});

class ResultatSyncEleves {
  final int nbEnvoyes;
  final int nbCrees;
  final int nbConflits;
  final String? erreur;

  ResultatSyncEleves({
    required this.nbEnvoyes,
    required this.nbCrees,
    required this.nbConflits,
    this.erreur,
  });
}

class EleveSyncService {
  final EleveRepository repository;
  final Dio dio;
  bool _syncEnCours = false;

  EleveSyncService({required this.repository, required this.dio});

  Future<ResultatSyncEleves> synchroniser() async {
    if (_syncEnCours) {
      return ResultatSyncEleves(nbEnvoyes: 0, nbCrees: 0, nbConflits: 0);
    }
    _syncEnCours = true;

    try {
      final enAttente = await repository.elevesEnAttenteDeSync();
      if (enAttente.isEmpty) {
        return ResultatSyncEleves(nbEnvoyes: 0, nbCrees: 0, nbConflits: 0);
      }

      final corps = enAttente
          .map(
            (eleve) => {
              'client_uuid': eleve.clientUuid,
              'nom': eleve.nom,
              'prenom': eleve.prenom,
              if (eleve.dateNaissance != null)
                'date_naissance': eleve.dateNaissance!
                    .toIso8601String()
                    .split('T')
                    .first,
              'sexe': eleve.sexe,
              'site_id': eleve.siteId,
              'classe': eleve.classe,
              'type_cours': eleve.typeCours,
              'contacts': [
                if (eleve.contactNom != null &&
                    eleve.contactNom!.isNotEmpty &&
                    eleve.contactTelephone != null)
                  {
                    'nom': eleve.contactNom,
                    'telephone': eleve.contactTelephone,
                    'lien': eleve.contactLien ?? 'parent',
                  },
              ],
            },
          )
          .toList();

      final reponse = await dio.post('/sync/eleves', data: corps);
      final resultats = (reponse.data['resultats'] as List).map(
        (item) => Map<String, dynamic>.from(item as Map),
      );

      int nbCrees = 0;
      int nbConflits = 0;

      for (final resultat in resultats) {
        await repository.appliquerResultatSyncEleve(
          clientUuid: resultat['client_uuid'] as String,
          statut: resultat['statut'] as String,
          idServeur: resultat['id'] as String?,
          raison: (resultat['raison'] ?? resultat['erreurs'])?.toString(),
        );
        if (resultat['statut'] == 'cree' ||
            resultat['statut'] == 'deja_existant') {
          nbCrees++;
        } else {
          nbConflits++;
        }
      }

      return ResultatSyncEleves(
        nbEnvoyes: enAttente.length,
        nbCrees: nbCrees,
        nbConflits: nbConflits,
      );
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      final data = error.response?.data;
      final message = data is Map && data['message'] is String
          ? data['message'] as String
          : error.message ?? 'Le serveur est inaccessible.';
      return ResultatSyncEleves(
        nbEnvoyes: 0,
        nbCrees: 0,
        nbConflits: 0,
        erreur: code == null ? message : '$message (HTTP $code)',
      );
    } finally {
      _syncEnCours = false;
    }
  }
}

final elevesProvider = StreamProvider<List<EleveAffichable>>((ref) {
  return ref.watch(eleveRepositoryProvider).watchTousLesEleves();
});

final echeancesDeLEleveProvider = StreamProvider.family((ref, String eleveId) {
  return ref.watch(eleveRepositoryProvider).watchEcheancesDeLEleve(eleveId);
});
