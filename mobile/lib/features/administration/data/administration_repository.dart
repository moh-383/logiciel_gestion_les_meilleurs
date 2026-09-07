import 'package:dio/dio.dart';

import '../models/permission.dart';
import '../models/poste.dart';
import '../models/site.dart';
import '../models/utilisateur.dart';

class AdministrationRepository {
  final Dio dio;

  AdministrationRepository(this.dio);

  List<dynamic> _extraireListe(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final liste = data['data'];

      if (liste is List) {
        return liste;
      }
    }

    return [];
  }

  Future<List<Permission>> getPermissions() async {
    final response = await dio.get('/permissions?limit=100');

    return _extraireListe(response.data)
        .map(
          (json) => Permission.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  Future<List<Poste>> getPostes() async {
    final response = await dio.get('/postes?limit=100');

    return _extraireListe(response.data)
        .map(
          (json) => Poste.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  Future<List<Site>> getSites() async {
    final response = await dio.get('/sites?limit=100');

    return _extraireListe(response.data)
        .map(
          (json) => Site.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  Future<List<Utilisateur>> getUtilisateurs({
    String? siteId,
    String? posteId,
    bool? actif,
  }) async {
    final queryParameters = <String, dynamic>{
      'limit': 100,
    };

    if (siteId != null) {
      queryParameters['site_id'] = siteId;
    }

    if (posteId != null) {
      queryParameters['poste_id'] = posteId;
    }

    if (actif != null) {
      queryParameters['actif'] = actif;
    }

    final response = await dio.get(
      '/utilisateurs',
      queryParameters: queryParameters,
    );

    return _extraireListe(response.data)
        .map(
          (json) => Utilisateur.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  Future<Poste> creerPoste({
    required String nom,
    bool tousSites = false,
  }) async {
    final response = await dio.post(
      '/postes',
      data: {
        'nom': nom,
        'tous_sites': tousSites,
      },
    );

    return Poste.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Site> creerSite({
    required String nom,
    String adresse = '',
    int? capacite,
  }) async {
    final data = <String, dynamic>{
      'nom': nom,
      'adresse': adresse,
    };

    if (capacite != null) {
      data['capacite'] = capacite;
    }

    final response = await dio.post(
      '/sites',
      data: data,
    );

    return Site.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Poste> modifierPoste(
    String posteId, {
    String? nom,
    bool? tousSites,
  }) async {
    final data = <String, dynamic>{};

    if (nom != null) {
      data['nom'] = nom;
    }

    if (tousSites != null) {
      data['tous_sites'] = tousSites;
    }

    final response = await dio.patch(
      '/postes/$posteId',
      data: data,
    );

    return Poste.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Poste> definirPermissions(
    String posteId,
    List<String> permissions,
  ) async {
    final response = await dio.put(
      '/postes/$posteId/permissions',
      data: {
        'permissions': permissions,
      },
    );

    return Poste.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

Future<Utilisateur> modifierUtilisateur(
  String utilisateurId, {
  String? nom,
  String? telephone,
  String? posteId,
  String? siteId,
  bool? actif,
  String? motDePasse,
}) async {
  final data = <String, dynamic>{};

  if (nom != null) {
    data['nom'] = nom;
  }

  if (telephone != null) {
    data['telephone'] = telephone;
  }

  if (posteId != null) {
    data['poste_id'] = posteId;
  }

  if (siteId != null) {
    data['site_id'] = siteId;
  }

  if (actif != null) {
    data['is_active'] = actif;
  }

  if (motDePasse != null && motDePasse.isNotEmpty) {
    data['mot_de_passe'] = motDePasse;
  }

  final response = await dio.patch(
    '/utilisateurs/$utilisateurId',
    data: data,
  );

  return Utilisateur.fromJson(
    Map<String, dynamic>.from(response.data as Map),
  );
}

    Future<Utilisateur> creerUtilisateur({
    required String nom,
    required String telephone,
    required String motDePasse,
    String? posteId,
    String? siteId,
  }) async {
    final data = <String, dynamic>{
      'nom': nom,
      'telephone': telephone,
      'mot_de_passe': motDePasse,
    };

    if (posteId != null) {
      data['poste_id'] = posteId;
    }

    if (siteId != null) {
      data['site_id'] = siteId;
    }

    final response = await dio.post(
      '/utilisateurs',
      data: data,
    );

    return Utilisateur.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}