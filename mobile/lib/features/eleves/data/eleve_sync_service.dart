import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'eleve_repository.dart';

/// Envoie les élèves créés hors ligne vers `POST /sync/eleves`
/// (voir docs/api-contract.md). Contrairement à `/sync/paiements`, le
/// corps est une liste brute (pas un objet enveloppant).
class EleveSyncService {
  final EleveRepository repository;
  final Dio dio;

  EleveSyncService({required this.repository, required this.dio});

  Future<void> synchroniser() async {
    final enAttente = await repository.elevesEnAttenteDeSync();
    if (enAttente.isEmpty) return;

    final corps = enAttente
        .map(
          (e) => {
            'client_uuid': e.clientUuid,
            'matricule': e.matricule,
            'nom': e.nom,
            'prenom': e.prenom,
            'sexe': e.sexe,
            'site_id': e.siteId,
            'classe': e.classe,
            'type_cours': e.typeCours,
            if (e.dateNaissance != null)
              'date_naissance':
                  e.dateNaissance!.toIso8601String().split('T').first,
            if (e.contactNom != null &&
                e.contactNom!.isNotEmpty &&
                e.contactTelephone != null)
              'contacts': [
                {
                  'nom': e.contactNom,
                  'telephone': e.contactTelephone,
                  'lien': e.contactLien ?? '',
                },
              ],
          },
        )
        .toList();

    try {
      final reponse = await dio.post('/sync/eleves', data: corps);
      final resultats = (reponse.data['resultats'] as List)
          .map((r) => Map<String, dynamic>.from(r as Map));

      for (final r in resultats) {
        await repository.appliquerResultatSyncEleve(
          clientUuid: r['client_uuid'] as String,
          statut: r['statut'] as String,
          idServeur: r['id'] as String?,
          raison: r['raison']?.toString(),
        );
      }
    } on DioException catch (e) {
      // Panne réseau/serveur ou 4xx : les élèves restent en local en
      // attente, on réessaiera à la prochaine reconnexion — jamais de
      // perte silencieuse, comme pour les paiements.
      debugPrint('Synchronisation élèves échouée : ${e.message}');
    }
  }
}
