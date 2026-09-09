import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../data/enseignant_repository.dart';
import '../models/enseignant.dart';

final enseignantRepositoryProvider = Provider<EnseignantRepository>((ref) {
  return EnseignantRepository(dio: ref.watch(dioProvider));
});

final enseignantsProvider = FutureProvider.autoDispose<List<Enseignant>>((ref) {
  return ref.watch(enseignantRepositoryProvider).listerEnseignants();
});

final enseignantDetailProvider = FutureProvider.autoDispose.family<Enseignant, String>(
  (ref, enseignantId) {
    return ref.watch(enseignantRepositoryProvider).obtenirEnseignant(enseignantId);
  },
);