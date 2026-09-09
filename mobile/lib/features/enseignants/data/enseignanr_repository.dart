import 'package:dio/dio.dart';

import '../models/affectation.dart';
import '../models/enseignant.dart';

class EnseignantRepository {
  final Dio dio;

  EnseignantRepository({required this.dio});

  Future<List<Enseignant>> listerEnseignants({String? siteId}) async {
    final response = await dio.get(
      '/enseignants',
      queryParameters: siteId != null ? {'site_id': siteId} : null,
    );
    final data = (response.data['data'] as List).cast<Map<String, dynamic>>();
    return data.map(Enseignant.fromJson).toList();
  }

  Future<Enseignant> obtenirEnseignant(String enseignantId) async {
    final response = await dio.get('/enseignants/$enseignantId');
    return Enseignant.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Affectation> creerAffectation({
    required String enseignantId,
    required String siteId,
    required String classe,
    required String matiere,
    required String anneeScolaire,
  }) async {
    final response = await dio.post(
      '/enseignants/$enseignantId/affectations',
      data: {
        'site_id': siteId,
        'classe': classe,
        'matiere': matiere,
        'annee_scolaire': anneeScolaire,
      },
    );
    return Affectation.fromJson(response.data as Map<String, dynamic>);
  }

  /// `actif: false` désactive une affectation sans la supprimer
  /// (historique conservé, cf. docs/schema-bdd.md).
  Future<void> basculerActif(String affectationId, bool actif) async {
    await dio.patch('/affectations/$affectationId', data: {'actif': actif});
  }

  Future<void> supprimerAffectation(String affectationId) async {
    await dio.delete('/affectations/$affectationId');
  }
}