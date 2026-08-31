import 'package:drift/drift.dart'; 
class Eleves extends Table { 
  TextColumn get id => text()(); 
  TextColumn get nom => text()(); 
  TextColumn get prenom => text()(); 
  TextColumn get classe => text()(); 
  TextColumn get siteId => text()(); 
  @override Set<Column> get primaryKey => {id}; 
  } 
  class Echeances extends Table { 
    TextColumn get id => text()(); 
    TextColumn get eleveId => text()(); 
    RealColumn get montantDu => real()(); 
    DateTimeColumn get dateEcheance => dateTime()(); 
    TextColumn get statut => text()(); // a_jour / partiel / en_retard 
    @override Set<Column> get primaryKey => {id}; 
  } 
  class Paiements extends Table { 
    TextColumn get id => text().nullable()(); // <-- ajoute .nullable() 
    TextColumn get clientUuid => text()(); 
    TextColumn get echeanceId => text()(); 
    RealColumn get montant => real()(); 
    TextColumn get modePaiement => text()(); 
    TextColumn get note => text().nullable()(); 
    DateTimeColumn get dateLocale => dateTime()(); 
    ColumnBuilder<String> get syncStatus => text().withDefault(const Constant('en_attente')); 
    @override Set<Column> get primaryKey => {clientUuid}; 
  } 