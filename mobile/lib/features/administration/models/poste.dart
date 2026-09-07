class Poste {
  final String id;
  final String nom;
  final bool tousSites;
  final List<String> permissions;

  const Poste({
    required this.id,
    required this.nom,
    required this.tousSites,
    required this.permissions,
  });

  factory Poste.fromJson(Map<String, dynamic> json) {
    return Poste(
      id: json['id'] as String,
      nom: json['nom'] as String,
      tousSites: json['tous_sites'] as bool,
      permissions: (json['permissions'] as List).cast<String>(),
    );
  }

  Poste copyWith({
    List<String>? permissions,
  }) {
    return Poste(
      id: id,
      nom: nom,
      tousSites: tousSites,
      permissions: permissions ?? this.permissions,
    );
  }
}