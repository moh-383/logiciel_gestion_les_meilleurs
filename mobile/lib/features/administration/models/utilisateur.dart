class Utilisateur {
  final String id;
  final String nom;
  final String telephone;
  final String? posteId;
  final String? siteId;
  final bool isActive;

  const Utilisateur({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.posteId,
    required this.siteId,
    required this.isActive,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'].toString(),
      nom: json['nom'] as String,
      telephone: json['telephone'] as String,
      posteId: json['poste_id']?.toString(),
      siteId: json['site_id']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}