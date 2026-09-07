import 'permission.dart';

class Poste {
  final String id;
  final String nom;
  final bool tousSites;
  final List<Permission> permissions;

  const Poste({
    required this.id,
    required this.nom,
    required this.tousSites,
    required this.permissions,
  });

  factory Poste.fromJson(Map<String, dynamic> json) {
    final permissionsJson = json['permissions'] as List<dynamic>? ?? [];

    return Poste(
      id: json['id'].toString(),
      nom: json['nom'] as String,
      tousSites: json['tous_sites'] as bool? ?? false,
      permissions: permissionsJson
          .whereType<String>()
          .map(
            (code) => Permission(
              id: code,
              code: code,
              libelle: code,
            ),
          )
          .toList(),
    );
  }
}