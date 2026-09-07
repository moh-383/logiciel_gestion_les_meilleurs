import 'package:flutter_riverpod/flutter_riverpod.dart';

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