import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// URL de base de l'API — à adapter une fois le backend déployé.
/// En attendant, elle pointe vers une adresse locale qui échouera
/// proprement (voir SyncService, qui gère ce cas sans planter l'app).
const String apiBaseUrl = 'http://localhost:8000/api/v1';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  

  return dio;
});
