import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../data/administration_repository.dart';
import '../models/permission.dart';
import '../models/poste.dart';
import '../models/site.dart';
import '../models/utilisateur.dart';

final administrationRepositoryProvider =
    Provider<AdministrationRepository>((ref) {
  return AdministrationRepository(
    ref.watch(dioProvider),
  );
});

final permissionsProvider =
    FutureProvider<List<Permission>>((ref) async {
  final repository = ref.watch(
    administrationRepositoryProvider,
  );

  return repository.getPermissions();
});

final postesProvider =
    FutureProvider<List<Poste>>((ref) async {
  final repository = ref.watch(
    administrationRepositoryProvider,
  );

  return repository.getPostes();
});

final sitesProvider =
    FutureProvider<List<Site>>((ref) async {
  final repository = ref.watch(
    administrationRepositoryProvider,
  );

  return repository.getSites();
});

final utilisateursProvider =
    FutureProvider<List<Utilisateur>>((ref) async {
  final repository = ref.watch(
    administrationRepositoryProvider,
  );

  return repository.getUtilisateurs();
});