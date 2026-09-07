class PermissionCatalogue {
  final String code;
  final String libelle;

  const PermissionCatalogue({
    required this.code,
    required this.libelle,
  });

  factory PermissionCatalogue.fromJson(Map<String, dynamic> json) {
    return PermissionCatalogue(
      code: json['code'] as String,
      libelle: json['libelle'] as String,
    );
  }
}