class UtilisateurResume {
  final String id;
  final String nom;
  final String telephone;
  final String? posteId;
  final String? siteId;
  final bool actif;

  const UtilisateurResume({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.posteId,
    required this.siteId,
    required this.actif,
  });

  factory UtilisateurResume.fromJson(Map<String, dynamic> json) {
    return UtilisateurResume(
      id: json['id'] as String,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String,
      posteId: json['poste_id'] as String?,
      siteId: json['site_id'] as String?,
      actif: json['is_active'] as bool? ?? true,
    );
  }
}