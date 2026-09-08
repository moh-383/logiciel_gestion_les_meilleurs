import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../data/database.dart';
import '../paiements_list_screen.dart' show databaseProvider;

class DemandeValidationSyncService {
  final AppDatabase db;
  final Dio dio;
  bool _enCours = false;

  DemandeValidationSyncService({required this.db, required this.dio});

  Future<void> synchroniser() async {
    if (_enCours) return;
    _enCours = true;
    try {
      await _synchroniserCreations();
      await _reconcilierDemandesTraitees();
    } finally {
      _enCours = false;
    }
  }

  Future<void> _synchroniserCreations() async {
    final demandes = await db.demandesEnAttenteDeSyncCreation();
    for (final demande in demandes) {
      await _pousserUneDemande(demande);
    }
  }

  Future<void> _pousserUneDemande(DemandeValidation demande) async {
    final paiement =
        await (db.select(db.paiements)
              ..where((p) => p.clientUuid.equals(demande.paiementClientUuid)))
            .getSingleOrNull();
    if (paiement == null || paiement.id == null) return;

    try {
      final reponse = await dio.post(
        '/paiements/${paiement.id}/demande-annulation',
        data: {'motif': demande.motif ?? ''},
      );
      final data = Map<String, dynamic>.from(reponse.data as Map);
      await db.appliquerResultatCreationDemande(
        clientUuid: demande.clientUuid,
        succes: true,
        idServeur: data['id'] as String?,
        statutServeur: data['statut'] as String?,
      );
    } on DioException catch (error) {
      final message = _messageErreur(error);
      final dejaExistante =
          error.response?.statusCode == 400 &&
          message.toLowerCase().contains('déjà en attente');
      if (dejaExistante) {
        await db.appliquerResultatCreationDemande(
          clientUuid: demande.clientUuid,
          succes: true,
          statutServeur: 'en_attente',
        );
        return;
      }
      debugPrint('Sync demande annulation échouée : $message');
      await db.appliquerResultatCreationDemande(
        clientUuid: demande.clientUuid,
        succes: false,
        raison: message,
      );
    }
  }

  Future<void> _reconcilierDemandesTraitees() async {
    final demandes = await db.demandesAvecIdServeurNonTraiteesLocalement();
    for (final demande in demandes) {
      try {
        final reponse = await dio.get('/demandes-validation/${demande.id}');
        final data = Map<String, dynamic>.from(reponse.data as Map);
        final statut = data['statut'] as String;
        if (statut != 'en_attente') {
          await db.appliquerTraitementDepuisServeur(
            clientUuid: demande.clientUuid,
            statutServeur: statut,
            approuve: statut == 'validee',
          );
        }
      } on DioException catch (error) {
        debugPrint('Réconciliation demande échouée : ${error.message}');
      }
    }
  }

  String _messageErreur(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final detail = data['message'] ?? data['detail'] ?? data['motif'];
      if (detail != null) return detail.toString();
    }
    return data?.toString() ?? error.message ?? 'Le serveur est inaccessible.';
  }
}

final demandeValidationSyncServiceProvider =
    Provider<DemandeValidationSyncService>((ref) {
      return DemandeValidationSyncService(
        db: ref.watch(databaseProvider),
        dio: ref.watch(dioProvider),
      );
    });
