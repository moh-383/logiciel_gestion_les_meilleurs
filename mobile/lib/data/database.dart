import 'package:drift/drift.dart'; 
import 'package:drift/native.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'package:path/path.dart' as p; 
import 'tables.dart'; 
import 'dart:io';
part 'database.g.dart'; 
@DriftDatabase(tables: [Eleves, Echeances, Paiements]) 
class AppDatabase extends _$AppDatabase { 
  AppDatabase() : super(_openConnection()); 
  @override int get schemaVersion => 1; 
  } 
  LazyDatabase _openConnection() { 
    return LazyDatabase(() async { 
      final dir = await getApplicationDocumentsDirectory(); 
      final file = File(p.join(dir.path, 'gestion_scolaire.sqlite')); 
      return NativeDatabase(file); }); 
      }