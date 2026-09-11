import 'affectation.dart';
class Enseignant {
  final String id;
  final String nom;
  final String telephone;
  final List<Affectation> affectations;
  const Enseignant({required this.id, required this.nom, required this.telephone, required this.affectations});
  factory Enseignant.fromJson(Map<String, dynamic> json) => Enseignant(id: json['id'] as String, nom: json['nom'] as String, telephone: json['telephone'] as String, affectations: (json['affectations'] as List<dynamic>? ?? const []).map((item) => Affectation.fromJson(Map<String, dynamic>.from(item as Map))).toList());
}
