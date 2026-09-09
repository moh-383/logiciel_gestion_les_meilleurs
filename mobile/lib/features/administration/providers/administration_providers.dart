import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/administration/models/site.dart';

import '../../../core/api_client.dart';
import '../data/administration_repository.dart';
import '../models/permission_catalogue.dart';
import '../models/poste.dart';
import '../models/utilisateur_resume.dart';

final administrationRepositoryProvider =
    Provider<AdministrationRepository>((ref) {
  final dio = ref.watch(dioProvider);

  return AdministrationRepository(
    dio: dio,
  );
});

final postesProvider =
    FutureProvider.autoDispose<List<Poste>>((ref) {
  final repository =
      ref.watch(administrationRepositoryProvider);

  return repository.listerPostes();
});

final permissionsCatalogueProvider =
    FutureProvider.autoDispose<List<PermissionCatalogue>>((ref) {
  final repository =
      ref.watch(administrationRepositoryProvider);

  return repository.catalogueDesPermissions();
});

final posteDetailProvider =
    FutureProvider.autoDispose.family<Poste, String>(
  (ref, posteId) {
    final repository =
        ref.watch(administrationRepositoryProvider);

    return repository.obtenirPoste(posteId);
  },
);

/// Liste des utilisateurs filtrée par poste.
///
/// Si [posteId] est fourni, seuls les utilisateurs de ce poste
/// sont récupérés.
final utilisateursDuPosteProvider =
    FutureProvider.autoDispose
        .family<List<UtilisateurResume>, String>(
  (ref, posteId) {
    final repository =
        ref.watch(administrationRepositoryProvider);

    return repository.listerUtilisateurs(
      posteId: posteId,
    );
  },
);

/// Liste générale de tous les utilisateurs.
final utilisateursProvider =
    FutureProvider.autoDispose<List<UtilisateurResume>>((ref) {
  final repository =
      ref.watch(administrationRepositoryProvider);

  return repository.listerUtilisateurs();
});

/// Liste des sites.
final sitesProvider =
    FutureProvider.autoDispose<List<Site>>((ref) async {
  final dio = ref.read(dioProvider);

  final response = await dio.get('/sites');

  final data =
      (response.data['data'] as List)
          .cast<Map<String, dynamic>>();

  return data.map(Site.fromJson).toList();
});