import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../features/paiements/paiements_list_screen.dart' show databaseProvider;
import 'api_client.dart';

/// Résultat d'une tentative de synchronisation, pour affichage éventuel
/// dans l'UI (nombre envoyé, nombre en échec, etc.)
class ResultatSync {
  final int nbEnvoyes;
  final int nbCrees;
  final int nbConflits;
  final String? erreurReseau;

  ResultatSync({
    required this.nbEnvoyes,
    required this.nbCrees,
    required this.nbConflits,
    this.erreurReseau,
  });
}

/// Gère l'envoi des paiements en attente vers /sync/paiements
/// (voir docs/api-contract.md, §6) et l'écoute de la reconnexion réseau.
class SyncService {
  final AppDatabase db;
  final Dio dio;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _syncEnCours = false;

  SyncService({required this.db, required this.dio});

  /// À appeler une fois au démarrage de l'app : synchronise dès que
  /// la connexion revient, sans action de l'utilisateur.
  void demarrerEcouteConnexion() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> resultats,
    ) {
      final connecte = resultats.any((r) => r != ConnectivityResult.none);
      if (connecte) {
        synchroniser();
      }
    });
  }

  void arreterEcoute() {
    _connectivitySub?.cancel();
  }

  /// Envoie en une fois tous les paiements locaux pas encore confirmés
  /// par le serveur. Peut aussi être déclenché manuellement (bouton
  /// "Synchroniser maintenant" pour les tests, ou en cas de doute).
  Future<ResultatSync> synchroniser() async {
    if (_syncEnCours) {
      return ResultatSync(nbEnvoyes: 0, nbCrees: 0, nbConflits: 0);
    }
    _syncEnCours = true;

    try {
      final enAttente = await db.paiementsEnAttenteDeSync();
      if (enAttente.isEmpty) {
        return ResultatSync(nbEnvoyes: 0, nbCrees: 0, nbConflits: 0);
      }

      final corps = {
        'paiements': enAttente
            .map(
              (p) => {
                'client_uuid': p.clientUuid,
                'echeance_id': p.echeanceId,
                'montant': p.montant,
                'mode_paiement': p.modePaiement,
                'date_locale': p.dateLocale.toIso8601String(),
              },
            )
            .toList(),
      };

      final reponse = await dio.post('/sync/paiements', data: corps);
      final resultats = (reponse.data['resultats'] as List)
          .cast<Map<String, dynamic>>();

      int nbCrees = 0;
      int nbConflits = 0;

      for (final r in resultats) {
        final statut = r['statut'] as String;
        await db.appliquerResultatSync(
          clientUuid: r['client_uuid'] as String,
          statut: statut,
          paiementIdServeur: r['paiement_id'] as String?,
          raison: r['raison'] as String?,
        );
        if (statut == 'cree') {
          nbCrees++;
        } else {
          nbConflits++;
        }
      }

      return ResultatSync(
        nbEnvoyes: enAttente.length,
        nbCrees: nbCrees,
        nbConflits: nbConflits,
      );
    } on DioException catch (e) {
      // Backend injoignable, timeout, etc. — normal tant qu'il n'existe
      // pas encore. Les paiements restent "en_attente" en local, rien
      // n'est perdu, on retentera à la prochaine reconnexion détectée.
      debugPrint('⚠️ Synchronisation impossible pour le moment : ${e.message}');
      return ResultatSync(
        nbEnvoyes: 0,
        nbCrees: 0,
        nbConflits: 0,
        erreurReseau: e.message,
      );
    } finally {
      _syncEnCours = false;
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final dio = ref.watch(dioProvider);
  return SyncService(db: db, dio: dio);
});
