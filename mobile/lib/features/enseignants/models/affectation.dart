class Affectation {
  final String id;
  final String siteId;
  final String classe;
  final String matiere;
  final String anneeScolaire;
  final bool actif;

  const Affectation({
    required this.id,
    required this.siteId,
    required this.classe,
    required this.matiere,
    required this.anneeScolaire,
    required this.actif,
  });

  factory Affectation.fromJson(Map<String, dynamic> json) {
    return Affectation(
      id: json['id'] as String,
      siteId: json['site_id'] as String,
      classe: json['classe'] as String,
      matiere: json['matiere'] as String? ?? '',
      anneeScolaire: json['annee_scolaire'] as String,
      actif: json['actif'] as bool? ?? true,
    );
  }
}