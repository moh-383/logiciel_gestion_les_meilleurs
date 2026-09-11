import 'package:dio/dio.dart';

import '../models/affectation.dart';
import '../models/enseignant.dart';

class EnseignantRepository {
  final Dio dio;
  EnseignantRepository({required this.dio});
  Future<List<Enseignant>> listerEnseignants({String? siteId}) async {
    final response = await dio.get(
      '/enseignants',
      queryParameters: siteId == null ? null : {'site_id': siteId},
    );
    return List<dynamic>.from((response.data as Map)['data'] as List)
        .map(
          (item) => Enseignant.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<Enseignant> obtenirEnseignant(String id) async => Enseignant.fromJson(
    Map<String, dynamic>.from((await dio.get('/enseignants/$id')).data as Map),
  );
  Future<Affectation> creerAffectation({
    required String enseignantId,
    required String siteId,
    required String classe,
    required String matiere,
    required String anneeScolaire,
  }) async => Affectation.fromJson(
    Map<String, dynamic>.from(
      (await dio.post(
            '/enseignants/$enseignantId/affectations',
            data: {
              'site_id': siteId,
              'classe': classe,
              'matiere': matiere,
              'annee_scolaire': anneeScolaire,
            },
          )).data
          as Map,
    ),
  );
  Future<void> basculerActif(String id, bool actif) =>
      dio.patch('/affectations/$id', data: {'actif': actif});
  Future<void> supprimerAffectation(String id) =>
      dio.delete('/affectations/$id');
  Future<List<Creneau>> listerCreneaux(String affectationId) async {
    final data = (await dio.get('/affectations/$affectationId/creneaux')).data;
    final entries = data is Map
        ? data['data'] as List? ?? const []
        : data as List;
    return entries
        .map((item) => Creneau.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> creerCreneau({
    required String affectationId,
    required int jourSemaine,
    required String heureDebut,
    required String heureFin,
  }) => dio.post(
    '/affectations/$affectationId/creneaux',
    data: {
      'jour_semaine': jourSemaine,
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
    },
  );

  Future<void> basculerCreneau(String id, bool actif) =>
      dio.patch('/creneaux/$id', data: {'actif': actif});
}
