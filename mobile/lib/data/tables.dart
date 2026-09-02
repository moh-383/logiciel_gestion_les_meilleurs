import 'package:drift/drift.dart';

class Eleves extends Table {
  TextColumn get id => text()();
  TextColumn get matricule => text().withDefault(const Constant(''))();
  TextColumn get nom => text()();
  TextColumn get prenom => text()();
  TextColumn get classe => text()();
  TextColumn get siteId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Echeances extends Table {
  TextColumn get id => text()();
  TextColumn get eleveId => text()();
  RealColumn get montantDu => real()();
  DateTimeColumn get dateEcheance => dateTime()();
  TextColumn get statut => text()(); // conservé pour compat, recalculé à la volée à l'affichage

  @override
  Set<Column> get primaryKey => {id};
}

class Paiements extends Table {
  TextColumn get id => text().nullable()(); // id serveur, vide tant que non synchronisé
  TextColumn get clientUuid => text()(); // généré localement, utilisé pour l'idempotence
  TextColumn get echeanceId => text()();
  RealColumn get montant => real()();
  TextColumn get modePaiement => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get dateLocale => dateTime()();
  ColumnBuilder<String> get syncStatus => text().withDefault(const Constant('en_attente'));
  TextColumn get statut => text().withDefault(const Constant('valide'))(); // valide / annule

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
  TextColumn get statut =>
      text().withDefault(const Constant('en_attente'))(); // en_attente / validee / rejetee
  DateTimeColumn get dateDemande => dateTime()();

  @override
  Set<Column> get primaryKey => {clientUuid};
}
