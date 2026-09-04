import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_config.dart';

class UserSession {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String nom;
  final String? siteId;
  final List<String> permissions;

  const UserSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.nom,
    required this.siteId,
    required this.permissions,
  });

  factory UserSession.fromLoginResponse(Map<String, dynamic> json) {
    final utilisateur = Map<String, dynamic>.from(json['utilisateur'] as Map);
    final poste = utilisateur['poste'] is Map
        ? Map<String, dynamic>.from(utilisateur['poste'] as Map)
        : const <String, dynamic>{};
    return UserSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      userId: utilisateur['id'] as String,
      nom: utilisateur['nom'] as String,
      siteId: utilisateur['site_id'] as String?,
      permissions: List<String>.from(poste['permissions'] as List? ?? const []),
    );
  }

  Map<String, String> toStorage() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user_id': userId,
        'nom': nom,
        'site_id': siteId ?? '',
        'permissions': jsonEncode(permissions),
      };
}

class TokenStore {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _nomKey = 'nom';
  static const _siteIdKey = 'site_id';
  static const _permissionsKey = 'permissions';
  final FlutterSecureStorage _storage;

  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<UserSession?> readSession() async {
    final values = await _storage.readAll();
    final access = values[_accessTokenKey];
    final refresh = values[_refreshTokenKey];
    final userId = values[_userIdKey];
    final nom = values[_nomKey];
    if (access == null || refresh == null || userId == null || nom == null) {
      return null;
    }
    return UserSession(
      accessToken: access,
      refreshToken: refresh,
      userId: userId,
      nom: nom,
      siteId: values[_siteIdKey]?.isEmpty ?? true ? null : values[_siteIdKey],
      permissions: List<String>.from(
        jsonDecode(values[_permissionsKey] ?? '[]') as List,
      ),
    );
  }

  Future<void> save(UserSession session) => _storage.writeAll(session.toStorage());
  Future<String?> accessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> refreshToken() => _storage.read(key: _refreshTokenKey);
  Future<void> updateTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }
  Future<void> clear() => _storage.deleteAll();
}

extension on FlutterSecureStorage {
  Future<void> writeAll(Map<String, String> storage) async {}
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

class AuthService {
  final Dio _anonymousDio;
  final TokenStore _tokenStore;

  AuthService({required this._tokenStore})
      : _anonymousDio = Dio(
          BaseOptions(baseUrl: apiBaseUrl, headers: const {'Accept': 'application/json'}),
        );

  Future<UserSession> login({
    required String telephone,
    required String motDePasse,
  }) async {
    final response = await _anonymousDio.post('/auth/login', data: {
      'telephone': telephone,
      'mot_de_passe': motDePasse,
    });
    final session = UserSession.fromLoginResponse(
      Map<String, dynamic>.from(response.data as Map),
    );
    await _tokenStore.save(session);
    return session;
  }

  Future<void> logout() async {
    final refresh = await _tokenStore.refreshToken();
    if (refresh != null) {
      try {
        await _anonymousDio.post('/auth/logout', data: {'refresh_token': refresh});
      } on DioException {
        // Hors connexion, on doit quand même effacer la session locale.
      }
    }
    await _tokenStore.clear();
  }
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(tokenStore: ref.read(tokenStoreProvider)),
);
final sessionProvider = FutureProvider<UserSession?>(
  (ref) => ref.read(tokenStoreProvider).readSession(),
);

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStore _tokenStore;
  bool _refreshing = false;

  AuthInterceptor({required this._dio, required this._tokenStore});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStore.accessToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        options.extra['retry_after_refresh'] == true ||
        _refreshing) {
      handler.next(err);
      return;
    }
    final refresh = await _tokenStore.refreshToken();
    if (refresh == null) {
      handler.next(err);
      return;
    }
    _refreshing = true;
    try {
      final refreshResponse = await Dio(BaseOptions(baseUrl: apiBaseUrl)).post(
        '/auth/refresh',
        data: {'refresh': refresh},
      );
      final access = refreshResponse.data['access'] as String;
      await _tokenStore.updateTokens(
        accessToken: access,
        refreshToken: refreshResponse.data['refresh'] as String?,
      );
      options.headers['Authorization'] = 'Bearer $access';
      options.extra['retry_after_refresh'] = true;
      handler.resolve(await _dio.fetch(options));
    } on DioException {
      await _tokenStore.clear();
      handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}
