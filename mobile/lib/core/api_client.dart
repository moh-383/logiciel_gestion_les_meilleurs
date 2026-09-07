import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'auth_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: const {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(dio: dio, tokenStore: ref.read(tokenStoreProvider)),
  );
  return dio;
});
