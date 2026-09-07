class Permission {
  final String id;
  final String code;
  final String libelle;

  const Permission({
    required this.id,
    required this.code,
    required this.libelle,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'].toString(),
      code: json['code'] as String,
      libelle: json['libelle'] as String,
    );
  }
}