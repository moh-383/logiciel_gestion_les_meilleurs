class Site {
  final String id;
  final String nom;
  final String adresse;
  final int? capacite;
  final String? responsable;

  const Site({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.capacite,
    required this.responsable,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['id'].toString(),
      nom: json['nom'] as String,
      adresse: json['adresse'] as String? ?? '',
      capacite: json['capacite'] as int?,
      responsable: json['responsable']?.toString(),
    );
  }
}