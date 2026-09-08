import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

class DemandeValidationServeur {
  final String id;
  final String paiementId;
  final double montant;
  final String modePaiement;
  final String eleveNom;
  final String statut;
  final String? motif;
  final String? commentaire;
  final DateTime dateDemande;

  DemandeValidationServeur({
    required this.id,
    required this.paiementId,
    required this.montant,
    required this.modePaiement,
    required this.eleveNom,
    required this.statut,
    this.motif,
    this.commentaire,
    required this.dateDemande,
  });

  factory DemandeValidationServeur.fromJson(Map<String, dynamic> json) {
    return DemandeValidationServeur(
      id: json['id'] as String,
      paiementId: json['paiement_id'] as String,
      montant: double.parse(json['montant'].toString()),
      modePaiement: json['mode_paiement'] as String? ?? '',
      eleveNom: json['eleve_nom'] as String? ?? '',
      statut: json['statut'] as String,
      motif: json['motif'] as String?,
      commentaire: json['commentaire'] as String?,
      dateDemande: DateTime.parse(json['date_demande'] as String),
    );
  }
}

class DemandeValidationRemoteService {
  final Dio dio;

  DemandeValidationRemoteService({required this.dio});

  Future<List<DemandeValidationServeur>> listerEnAttente() async {
    final reponse = await dio.get(
      '/demandes-validation',
      queryParameters: {'statut': 'en_attente'},
    );
    final payload = reponse.data;
    final rawItems = payload is Map ? payload['data'] : payload;
    final items = (rawItems as List).cast<Map>();
    return items
        .map(
          (json) => DemandeValidationServeur.fromJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }

  Future<void> traiter({
    required String demandeId,
    required bool approuver,
    String? commentaire,
  }) async {
    await dio.patch(
      '/demandes-validation/$demandeId',
      data: {
        'statut': approuver ? 'validee' : 'rejetee',
        if (commentaire != null && commentaire.isNotEmpty)
          'commentaire': commentaire,
      },
    );
  }
}

final demandeValidationRemoteServiceProvider =
    Provider<DemandeValidationRemoteService>((ref) {
      return DemandeValidationRemoteService(dio: ref.watch(dioProvider));
    });
