import 'package:drift/drift.dart';

class Eleves extends Table {
  TextColumn get id => text()();
  TextColumn get matricule => text().withDefault(const Constant(''))();
  TextColumn get nom => text()();
  TextColumn get prenom => text()();
  TextColumn get classe => text()();
  TextColumn get siteId => text()();
  // Champs ajoutés en v6 pour enrichir le cache (fiche élève complète,
  // sans round-trip supplémentaire vers le serveur).
  DateTimeColumn get dateNaissance => dateTime().nullable()();
  TextColumn get sexe => text().withDefault(const Constant(''))();
  TextColumn get typeCours => text().withDefault(const Constant(''))();
  TextColumn get statut => text().withDefault(const Constant('actif'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Echeances extends Table {
  TextColumn get id => text()();
  TextColumn get eleveId => text()();
  RealColumn get montantDu => real()();
  DateTimeColumn get dateEcheance => dateTime()();
  TextColumn get statut =>
      text()(); // conservé pour compat, recalculé à la volée à l'affichage

  @override
  Set<Column> get primaryKey => {id};
}

class Paiements extends Table {
  TextColumn get id =>
      text().nullable()(); // id serveur, vide tant que non synchronisé
  TextColumn get clientUuid =>
      text()(); // généré localement, utilisé pour l'idempotence
  TextColumn get echeanceId => text()();
  RealColumn get montant => real()();
  TextColumn get modePaiement => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get dateLocale => dateTime()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('en_attente'))();
  TextColumn get syncRaison =>
      text().nullable()(); // renseigné si syncStatus = 'conflit'
  TextColumn get statut =>
      text().withDefault(const Constant('valide'))(); // valide / annule

  @override
  Set<Column> get primaryKey => {clientUuid};
}

@DataClassName('DemandeValidation')
class DemandesValidation extends Table {
  TextColumn get id => text().nullable()(); // id serveur
  TextColumn get clientUuid => text()();
  TextColumn get typeAction =>
      text().withDefault(const Constant('annulation_paiement'))();
  TextColumn get paiementClientUuid => text()();
  TextColumn get motif => text().nullable()();
  TextColumn get statut => text().withDefault(
    const Constant('en_attente'),
  )(); // en_attente / validee / rejetee
  DateTimeColumn get dateDemande => dateTime()();

  @override
  Set<Column> get primaryKey => {clientUuid};
}

/// Élèves créés hors ligne, pas encore confirmés par le serveur.
/// Distincte de `Eleves` (cache en lecture seule des données serveur) :
/// tant qu'un élève créé localement n'a pas de réponse de
/// `POST /sync/eleves`, il n'a pas d'`id` serveur et ne peut donc pas
/// vivre dans `Eleves` (dont `id` est la clé primaire, non nullable).
/// Ajoutée en v7.
@DataClassName('EleveEnAttente')
class ElevesEnAttente extends Table {
  TextColumn get id => text().nullable()(); // id serveur après confirmation
  TextColumn get clientUuid => text()(); // clé anti-doublon / idempotence
  TextColumn get matricule => text()();
  TextColumn get nom => text()();
  TextColumn get prenom => text()();
  DateTimeColumn get dateNaissance => dateTime().nullable()();
  TextColumn get sexe => text()();
  TextColumn get siteId => text()();
  TextColumn get classe => text()();
  TextColumn get typeCours => text()();
  // Contact parent unique pour le MVP (le formulaire de création n'en
  // maquette qu'un ; plusieurs contacts par élève reste un raffinement V2).
  TextColumn get contactNom => text().nullable()();
  TextColumn get contactTelephone => text().nullable()();
  TextColumn get contactLien => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('en_attente'))();
  TextColumn get syncRaison => text().nullable()();
  DateTimeColumn get dateCreationLocale => dateTime()();

  @override
  Set<Column> get primaryKey => {clientUuid};
}