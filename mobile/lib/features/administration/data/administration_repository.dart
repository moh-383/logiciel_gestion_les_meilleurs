import 'package:dio/dio.dart';

import '../models/permission_catalogue.dart';
import '../models/poste.dart';
import '../models/site.dart';
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

  /// Crée un nouveau poste. `tous_sites` reste à `false` par défaut côté
  /// serveur (modèle `Poste`) — pas d'option dans l'UI actuelle pour le
  /// définir à la création, ce qui est cohérent avec le MVP : un poste de
  /// direction se configure ensuite, pas à la création rapide.
  Future<void> creerPoste({required String nom}) async {
    await dio.post('/postes', data: {'nom': nom});
  }

  /// Crée un nouveau site. `adresse`, `capacite`, `responsable` sont
  /// optionnels côté backend (voir `core/serializers.py::SiteSerializer`),
  /// donc `nom` seul suffit pour le formulaire rapide actuel.
  Future<Site> creerSite({required String nom}) async {
    final response = await dio.post('/sites', data: {'nom': nom});
    return Site.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// IMPORTANT : `mot_de_passe` n'est pas un champ déclaré du serializer
  /// (voir `accounts/serializers.py::UtilisateurSerializer.create`), il
  /// est lu directement depuis le corps brut de la requête — d'où son
  /// envoi tel quel ici plutôt que via un champ `password` classique.
  Future<void> creerUtilisateur({
    required String nom,
    required String telephone,
    required String motDePasse,
    String? posteId,
    String? siteId,
  }) async {
    await dio.post('/utilisateurs', data: {
      'nom': nom,
      'telephone': telephone,
      'mot_de_passe': motDePasse,
      'poste_id': ?posteId,
      'site_id': ?siteId,
    });
  }

  /// `motDePasse` vide = "ne pas changer le mot de passe" (cohérent avec
  /// le placeholder de l'écran de modification). On ne l'envoie que s'il
  /// est renseigné, pour ne jamais écraser silencieusement un mot de
  /// passe existant par une valeur vide.
  Future<void> modifierUtilisateur(
    String id, {
    required String nom,
    required String telephone,
    String? posteId,
    String? siteId,
    required bool actif,
    required String motDePasse,
  }) async {
    await dio.patch('/utilisateurs/$id', data: {
      'nom': nom,
      'telephone': telephone,
      'is_active': actif,
      'poste_id': ?posteId,
      'site_id': ?siteId,
      if (motDePasse.isNotEmpty) 'mot_de_passe': motDePasse,
    });
  }
}
