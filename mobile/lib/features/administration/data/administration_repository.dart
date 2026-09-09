import 'package:dio/dio.dart';

import '../models/permission_catalogue.dart';
import '../models/poste.dart';
import '../models/utilisateur_resume.dart';

class AdministrationRepository {
  final Dio dio;

  AdministrationRepository({
    required this.dio,
  });

  Future<List<Poste>> listerPostes() async {
    final response = await dio.get('/postes');

    final data =
        (response.data['data'] as List).cast<Map<String, dynamic>>();

    return data.map(Poste.fromJson).toList();
  }

  Future<Poste> obtenirPoste(String posteId) async {
    final response = await dio.get('/postes/$posteId');

    return Poste.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<PermissionCatalogue>>
      catalogueDesPermissions() async {
    final response = await dio.get('/permissions');

    final data =
        (response.data['data'] as List).cast<Map<String, dynamic>>();

    return data.map(PermissionCatalogue.fromJson).toList();
  }

  Future<Poste> definirPermissions({
    required String posteId,
    required List<String> codesPermission,
  }) async {
    final response = await dio.put(
      '/postes/$posteId/permissions',
      data: {
        'permissions': codesPermission,
      },
    );

    return Poste.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<UtilisateurResume>> listerUtilisateurs({
    String? posteId,
  }) async {
    final response = await dio.get(
      '/utilisateurs',
      queryParameters: posteId != null
          ? {'poste_id': posteId}
          : null,
    );

    final data =
        (response.data['data'] as List).cast<Map<String, dynamic>>();

    return data.map(UtilisateurResume.fromJson).toList();
  }

  Future<void> assignerPosteAUtilisateur({
    required String utilisateurId,
    required String posteId,
  }) async {
    await dio.patch(
      '/utilisateurs/$utilisateurId',
      data: {
        'poste_id': posteId,
      },
    );
  }

  Future<void> creerPoste({required String nom}) async {}

  Future<void> creerSite({required String nom}) async {}

  Future<void> modifierUtilisateur(String id, {required String nom, required String telephone, String? posteId, String? siteId, required bool actif, required String motDePasse}) async {}

  Future<void> creerUtilisateur({required String nom, required String telephone, required String motDePasse, String? posteId, String? siteId}) async {}
}