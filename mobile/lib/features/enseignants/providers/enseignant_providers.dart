import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../data/enseignant_repository.dart';
import '../models/enseignant.dart';
final enseignantRepositoryProvider = Provider<EnseignantRepository>((ref) => EnseignantRepository(dio: ref.watch(dioProvider)));
final enseignantsProvider = FutureProvider.autoDispose<List<Enseignant>>((ref) => ref.watch(enseignantRepositoryProvider).listerEnseignants());
final enseignantDetailProvider = FutureProvider.autoDispose.family<Enseignant, String>((ref, id) => ref.watch(enseignantRepositoryProvider).obtenirEnseignant(id));
