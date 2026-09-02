// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ElevesTable extends Eleves with TableInfo<$ElevesTable, Eleve> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ElevesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matriculeMeta = const VerificationMeta(
    'matricule',
  );
  @override
  late final GeneratedColumn<String> matricule = GeneratedColumn<String>(
    'matricule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nomMeta = const VerificationMeta('nom');
  @override
  late final GeneratedColumn<String> nom = GeneratedColumn<String>(
    'nom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prenomMeta = const VerificationMeta('prenom');
  @override
  late final GeneratedColumn<String> prenom = GeneratedColumn<String>(
    'prenom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _classeMeta = const VerificationMeta('classe');
  @override
  late final GeneratedColumn<String> classe = GeneratedColumn<String>(
    'classe',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    matricule,
    nom,
    prenom,
    classe,
    siteId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eleves';
  @override
  VerificationContext validateIntegrity(
    Insertable<Eleve> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('matricule')) {
      context.handle(
        _matriculeMeta,
        matricule.isAcceptableOrUnknown(data['matricule']!, _matriculeMeta),
      );
    }
    if (data.containsKey('nom')) {
      context.handle(
        _nomMeta,
        nom.isAcceptableOrUnknown(data['nom']!, _nomMeta),
      );
    } else if (isInserting) {
      context.missing(_nomMeta);
    }
    if (data.containsKey('prenom')) {
      context.handle(
        _prenomMeta,
        prenom.isAcceptableOrUnknown(data['prenom']!, _prenomMeta),
      );
    } else if (isInserting) {
      context.missing(_prenomMeta);
    }
    if (data.containsKey('classe')) {
      context.handle(
        _classeMeta,
        classe.isAcceptableOrUnknown(data['classe']!, _classeMeta),
      );
    } else if (isInserting) {
      context.missing(_classeMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Eleve map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Eleve(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      matricule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matricule'],
      )!,
      nom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom'],
      )!,
      prenom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prenom'],
      )!,
      classe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}classe'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
    );
  }

  @override
  $ElevesTable createAlias(String alias) {
    return $ElevesTable(attachedDatabase, alias);
  }
}

class Eleve extends DataClass implements Insertable<Eleve> {
  final String id;
  final String matricule;
  final String nom;
  final String prenom;
  final String classe;
  final String siteId;
  const Eleve({
    required this.id,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.classe,
    required this.siteId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['matricule'] = Variable<String>(matricule);
    map['nom'] = Variable<String>(nom);
    map['prenom'] = Variable<String>(prenom);
    map['classe'] = Variable<String>(classe);
    map['site_id'] = Variable<String>(siteId);
    return map;
  }

  ElevesCompanion toCompanion(bool nullToAbsent) {
    return ElevesCompanion(
      id: Value(id),
      matricule: Value(matricule),
      nom: Value(nom),
      prenom: Value(prenom),
      classe: Value(classe),
      siteId: Value(siteId),
    );
  }

  factory Eleve.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Eleve(
      id: serializer.fromJson<String>(json['id']),
      matricule: serializer.fromJson<String>(json['matricule']),
      nom: serializer.fromJson<String>(json['nom']),
      prenom: serializer.fromJson<String>(json['prenom']),
      classe: serializer.fromJson<String>(json['classe']),
      siteId: serializer.fromJson<String>(json['siteId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'matricule': serializer.toJson<String>(matricule),
      'nom': serializer.toJson<String>(nom),
      'prenom': serializer.toJson<String>(prenom),
      'classe': serializer.toJson<String>(classe),
      'siteId': serializer.toJson<String>(siteId),
    };
  }

  Eleve copyWith({
    String? id,
    String? matricule,
    String? nom,
    String? prenom,
    String? classe,
    String? siteId,
  }) => Eleve(
    id: id ?? this.id,
    matricule: matricule ?? this.matricule,
    nom: nom ?? this.nom,
    prenom: prenom ?? this.prenom,
    classe: classe ?? this.classe,
    siteId: siteId ?? this.siteId,
  );
  Eleve copyWithCompanion(ElevesCompanion data) {
    return Eleve(
      id: data.id.present ? data.id.value : this.id,
      matricule: data.matricule.present ? data.matricule.value : this.matricule,
      nom: data.nom.present ? data.nom.value : this.nom,
      prenom: data.prenom.present ? data.prenom.value : this.prenom,
      classe: data.classe.present ? data.classe.value : this.classe,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Eleve(')
          ..write('id: $id, ')
          ..write('matricule: $matricule, ')
          ..write('nom: $nom, ')
          ..write('prenom: $prenom, ')
          ..write('classe: $classe, ')
          ..write('siteId: $siteId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, matricule, nom, prenom, classe, siteId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Eleve &&
          other.id == this.id &&
          other.matricule == this.matricule &&
          other.nom == this.nom &&
          other.prenom == this.prenom &&
          other.classe == this.classe &&
          other.siteId == this.siteId);
}

class ElevesCompanion extends UpdateCompanion<Eleve> {
  final Value<String> id;
  final Value<String> matricule;
  final Value<String> nom;
  final Value<String> prenom;
  final Value<String> classe;
  final Value<String> siteId;
  final Value<int> rowid;
  const ElevesCompanion({
    this.id = const Value.absent(),
    this.matricule = const Value.absent(),
    this.nom = const Value.absent(),
    this.prenom = const Value.absent(),
    this.classe = const Value.absent(),
    this.siteId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ElevesCompanion.insert({
    required String id,
    this.matricule = const Value.absent(),
    required String nom,
    required String prenom,
    required String classe,
    required String siteId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nom = Value(nom),
       prenom = Value(prenom),
       classe = Value(classe),
       siteId = Value(siteId);
  static Insertable<Eleve> custom({
    Expression<String>? id,
    Expression<String>? matricule,
    Expression<String>? nom,
    Expression<String>? prenom,
    Expression<String>? classe,
    Expression<String>? siteId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matricule != null) 'matricule': matricule,
      if (nom != null) 'nom': nom,
      if (prenom != null) 'prenom': prenom,
      if (classe != null) 'classe': classe,
      if (siteId != null) 'site_id': siteId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ElevesCompanion copyWith({
    Value<String>? id,
    Value<String>? matricule,
    Value<String>? nom,
    Value<String>? prenom,
    Value<String>? classe,
    Value<String>? siteId,
    Value<int>? rowid,
  }) {
    return ElevesCompanion(
      id: id ?? this.id,
      matricule: matricule ?? this.matricule,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      classe: classe ?? this.classe,
      siteId: siteId ?? this.siteId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (matricule.present) {
      map['matricule'] = Variable<String>(matricule.value);
    }
    if (nom.present) {
      map['nom'] = Variable<String>(nom.value);
    }
    if (prenom.present) {
      map['prenom'] = Variable<String>(prenom.value);
    }
    if (classe.present) {
      map['classe'] = Variable<String>(classe.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ElevesCompanion(')
          ..write('id: $id, ')
          ..write('matricule: $matricule, ')
          ..write('nom: $nom, ')
          ..write('prenom: $prenom, ')
          ..write('classe: $classe, ')
          ..write('siteId: $siteId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EcheancesTable extends Echeances
    with TableInfo<$EcheancesTable, Echeance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EcheancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eleveIdMeta = const VerificationMeta(
    'eleveId',
  );
  @override
  late final GeneratedColumn<String> eleveId = GeneratedColumn<String>(
    'eleve_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montantDuMeta = const VerificationMeta(
    'montantDu',
  );
  @override
  late final GeneratedColumn<double> montantDu = GeneratedColumn<double>(
    'montant_du',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateEcheanceMeta = const VerificationMeta(
    'dateEcheance',
  );
  @override
  late final GeneratedColumn<DateTime> dateEcheance = GeneratedColumn<DateTime>(
    'date_echeance',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eleveId,
    montantDu,
    dateEcheance,
    statut,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'echeances';
  @override
  VerificationContext validateIntegrity(
    Insertable<Echeance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('eleve_id')) {
      context.handle(
        _eleveIdMeta,
        eleveId.isAcceptableOrUnknown(data['eleve_id']!, _eleveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eleveIdMeta);
    }
    if (data.containsKey('montant_du')) {
      context.handle(
        _montantDuMeta,
        montantDu.isAcceptableOrUnknown(data['montant_du']!, _montantDuMeta),
      );
    } else if (isInserting) {
      context.missing(_montantDuMeta);
    }
    if (data.containsKey('date_echeance')) {
      context.handle(
        _dateEcheanceMeta,
        dateEcheance.isAcceptableOrUnknown(
          data['date_echeance']!,
          _dateEcheanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateEcheanceMeta);
    }
    if (data.containsKey('statut')) {
      context.handle(
        _statutMeta,
        statut.isAcceptableOrUnknown(data['statut']!, _statutMeta),
      );
    } else if (isInserting) {
      context.missing(_statutMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Echeance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Echeance(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eleveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}eleve_id'],
      )!,
      montantDu: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}montant_du'],
      )!,
      dateEcheance: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_echeance'],
      )!,
      statut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut'],
      )!,
    );
  }

  @override
  $EcheancesTable createAlias(String alias) {
    return $EcheancesTable(attachedDatabase, alias);
  }
}

class Echeance extends DataClass implements Insertable<Echeance> {
  final String id;
  final String eleveId;
  final double montantDu;
  final DateTime dateEcheance;
  final String statut;
  const Echeance({
    required this.id,
    required this.eleveId,
    required this.montantDu,
    required this.dateEcheance,
    required this.statut,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['eleve_id'] = Variable<String>(eleveId);
    map['montant_du'] = Variable<double>(montantDu);
    map['date_echeance'] = Variable<DateTime>(dateEcheance);
    map['statut'] = Variable<String>(statut);
    return map;
  }

  EcheancesCompanion toCompanion(bool nullToAbsent) {
    return EcheancesCompanion(
      id: Value(id),
      eleveId: Value(eleveId),
      montantDu: Value(montantDu),
      dateEcheance: Value(dateEcheance),
      statut: Value(statut),
    );
  }

  factory Echeance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Echeance(
      id: serializer.fromJson<String>(json['id']),
      eleveId: serializer.fromJson<String>(json['eleveId']),
      montantDu: serializer.fromJson<double>(json['montantDu']),
      dateEcheance: serializer.fromJson<DateTime>(json['dateEcheance']),
      statut: serializer.fromJson<String>(json['statut']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eleveId': serializer.toJson<String>(eleveId),
      'montantDu': serializer.toJson<double>(montantDu),
      'dateEcheance': serializer.toJson<DateTime>(dateEcheance),
      'statut': serializer.toJson<String>(statut),
    };
  }

  Echeance copyWith({
    String? id,
    String? eleveId,
    double? montantDu,
    DateTime? dateEcheance,
    String? statut,
  }) => Echeance(
    id: id ?? this.id,
    eleveId: eleveId ?? this.eleveId,
    montantDu: montantDu ?? this.montantDu,
    dateEcheance: dateEcheance ?? this.dateEcheance,
    statut: statut ?? this.statut,
  );
  Echeance copyWithCompanion(EcheancesCompanion data) {
    return Echeance(
      id: data.id.present ? data.id.value : this.id,
      eleveId: data.eleveId.present ? data.eleveId.value : this.eleveId,
      montantDu: data.montantDu.present ? data.montantDu.value : this.montantDu,
      dateEcheance: data.dateEcheance.present
          ? data.dateEcheance.value
          : this.dateEcheance,
      statut: data.statut.present ? data.statut.value : this.statut,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Echeance(')
          ..write('id: $id, ')
          ..write('eleveId: $eleveId, ')
          ..write('montantDu: $montantDu, ')
          ..write('dateEcheance: $dateEcheance, ')
          ..write('statut: $statut')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, eleveId, montantDu, dateEcheance, statut);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Echeance &&
          other.id == this.id &&
          other.eleveId == this.eleveId &&
          other.montantDu == this.montantDu &&
          other.dateEcheance == this.dateEcheance &&
          other.statut == this.statut);
}

class EcheancesCompanion extends UpdateCompanion<Echeance> {
  final Value<String> id;
  final Value<String> eleveId;
  final Value<double> montantDu;
  final Value<DateTime> dateEcheance;
  final Value<String> statut;
  final Value<int> rowid;
  const EcheancesCompanion({
    this.id = const Value.absent(),
    this.eleveId = const Value.absent(),
    this.montantDu = const Value.absent(),
    this.dateEcheance = const Value.absent(),
    this.statut = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EcheancesCompanion.insert({
    required String id,
    required String eleveId,
    required double montantDu,
    required DateTime dateEcheance,
    required String statut,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eleveId = Value(eleveId),
       montantDu = Value(montantDu),
       dateEcheance = Value(dateEcheance),
       statut = Value(statut);
  static Insertable<Echeance> custom({
    Expression<String>? id,
    Expression<String>? eleveId,
    Expression<double>? montantDu,
    Expression<DateTime>? dateEcheance,
    Expression<String>? statut,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eleveId != null) 'eleve_id': eleveId,
      if (montantDu != null) 'montant_du': montantDu,
      if (dateEcheance != null) 'date_echeance': dateEcheance,
      if (statut != null) 'statut': statut,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EcheancesCompanion copyWith({
    Value<String>? id,
    Value<String>? eleveId,
    Value<double>? montantDu,
    Value<DateTime>? dateEcheance,
    Value<String>? statut,
    Value<int>? rowid,
  }) {
    return EcheancesCompanion(
      id: id ?? this.id,
      eleveId: eleveId ?? this.eleveId,
      montantDu: montantDu ?? this.montantDu,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      statut: statut ?? this.statut,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eleveId.present) {
      map['eleve_id'] = Variable<String>(eleveId.value);
    }
    if (montantDu.present) {
      map['montant_du'] = Variable<double>(montantDu.value);
    }
    if (dateEcheance.present) {
      map['date_echeance'] = Variable<DateTime>(dateEcheance.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EcheancesCompanion(')
          ..write('id: $id, ')
          ..write('eleveId: $eleveId, ')
          ..write('montantDu: $montantDu, ')
          ..write('dateEcheance: $dateEcheance, ')
          ..write('statut: $statut, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaiementsTable extends Paiements
    with TableInfo<$PaiementsTable, Paiement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaiementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _echeanceIdMeta = const VerificationMeta(
    'echeanceId',
  );
  @override
  late final GeneratedColumn<String> echeanceId = GeneratedColumn<String>(
    'echeance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montantMeta = const VerificationMeta(
    'montant',
  );
  @override
  late final GeneratedColumn<double> montant = GeneratedColumn<double>(
    'montant',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modePaiementMeta = const VerificationMeta(
    'modePaiement',
  );
  @override
  late final GeneratedColumn<String> modePaiement = GeneratedColumn<String>(
    'mode_paiement',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateLocaleMeta = const VerificationMeta(
    'dateLocale',
  );
  @override
  late final GeneratedColumn<DateTime> dateLocale = GeneratedColumn<DateTime>(
    'date_locale',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('valide'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUuid,
    echeanceId,
    montant,
    modePaiement,
    note,
    dateLocale,
    statut,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paiements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Paiement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('echeance_id')) {
      context.handle(
        _echeanceIdMeta,
        echeanceId.isAcceptableOrUnknown(data['echeance_id']!, _echeanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_echeanceIdMeta);
    }
    if (data.containsKey('montant')) {
      context.handle(
        _montantMeta,
        montant.isAcceptableOrUnknown(data['montant']!, _montantMeta),
      );
    } else if (isInserting) {
      context.missing(_montantMeta);
    }
    if (data.containsKey('mode_paiement')) {
      context.handle(
        _modePaiementMeta,
        modePaiement.isAcceptableOrUnknown(
          data['mode_paiement']!,
          _modePaiementMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_modePaiementMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('date_locale')) {
      context.handle(
        _dateLocaleMeta,
        dateLocale.isAcceptableOrUnknown(data['date_locale']!, _dateLocaleMeta),
      );
    } else if (isInserting) {
      context.missing(_dateLocaleMeta);
    }
    if (data.containsKey('statut')) {
      context.handle(
        _statutMeta,
        statut.isAcceptableOrUnknown(data['statut']!, _statutMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  Paiement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Paiement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      echeanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}echeance_id'],
      )!,
      montant: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}montant'],
      )!,
      modePaiement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode_paiement'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      dateLocale: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_locale'],
      )!,
      statut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut'],
      )!,
    );
  }

  @override
  $PaiementsTable createAlias(String alias) {
    return $PaiementsTable(attachedDatabase, alias);
  }
}

class Paiement extends DataClass implements Insertable<Paiement> {
  final String? id;
  final String clientUuid;
  final String echeanceId;
  final double montant;
  final String modePaiement;
  final String? note;
  final DateTime dateLocale;
  final String statut;
  const Paiement({
    this.id,
    required this.clientUuid,
    required this.echeanceId,
    required this.montant,
    required this.modePaiement,
    this.note,
    required this.dateLocale,
    required this.statut,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['client_uuid'] = Variable<String>(clientUuid);
    map['echeance_id'] = Variable<String>(echeanceId);
    map['montant'] = Variable<double>(montant);
    map['mode_paiement'] = Variable<String>(modePaiement);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['date_locale'] = Variable<DateTime>(dateLocale);
    map['statut'] = Variable<String>(statut);
    return map;
  }

  PaiementsCompanion toCompanion(bool nullToAbsent) {
    return PaiementsCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      clientUuid: Value(clientUuid),
      echeanceId: Value(echeanceId),
      montant: Value(montant),
      modePaiement: Value(modePaiement),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      dateLocale: Value(dateLocale),
      statut: Value(statut),
    );
  }

  factory Paiement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Paiement(
      id: serializer.fromJson<String?>(json['id']),
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      echeanceId: serializer.fromJson<String>(json['echeanceId']),
      montant: serializer.fromJson<double>(json['montant']),
      modePaiement: serializer.fromJson<String>(json['modePaiement']),
      note: serializer.fromJson<String?>(json['note']),
      dateLocale: serializer.fromJson<DateTime>(json['dateLocale']),
      statut: serializer.fromJson<String>(json['statut']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'clientUuid': serializer.toJson<String>(clientUuid),
      'echeanceId': serializer.toJson<String>(echeanceId),
      'montant': serializer.toJson<double>(montant),
      'modePaiement': serializer.toJson<String>(modePaiement),
      'note': serializer.toJson<String?>(note),
      'dateLocale': serializer.toJson<DateTime>(dateLocale),
      'statut': serializer.toJson<String>(statut),
    };
  }

  Paiement copyWith({
    Value<String?> id = const Value.absent(),
    String? clientUuid,
    String? echeanceId,
    double? montant,
    String? modePaiement,
    Value<String?> note = const Value.absent(),
    DateTime? dateLocale,
    String? statut,
  }) => Paiement(
    id: id.present ? id.value : this.id,
    clientUuid: clientUuid ?? this.clientUuid,
    echeanceId: echeanceId ?? this.echeanceId,
    montant: montant ?? this.montant,
    modePaiement: modePaiement ?? this.modePaiement,
    note: note.present ? note.value : this.note,
    dateLocale: dateLocale ?? this.dateLocale,
    statut: statut ?? this.statut,
  );
  Paiement copyWithCompanion(PaiementsCompanion data) {
    return Paiement(
      id: data.id.present ? data.id.value : this.id,
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      echeanceId: data.echeanceId.present
          ? data.echeanceId.value
          : this.echeanceId,
      montant: data.montant.present ? data.montant.value : this.montant,
      modePaiement: data.modePaiement.present
          ? data.modePaiement.value
          : this.modePaiement,
      note: data.note.present ? data.note.value : this.note,
      dateLocale: data.dateLocale.present
          ? data.dateLocale.value
          : this.dateLocale,
      statut: data.statut.present ? data.statut.value : this.statut,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Paiement(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('echeanceId: $echeanceId, ')
          ..write('montant: $montant, ')
          ..write('modePaiement: $modePaiement, ')
          ..write('note: $note, ')
          ..write('dateLocale: $dateLocale, ')
          ..write('statut: $statut')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUuid,
    echeanceId,
    montant,
    modePaiement,
    note,
    dateLocale,
    statut,
  );

  get syncStatus => null;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Paiement &&
          other.id == this.id &&
          other.clientUuid == this.clientUuid &&
          other.echeanceId == this.echeanceId &&
          other.montant == this.montant &&
          other.modePaiement == this.modePaiement &&
          other.note == this.note &&
          other.dateLocale == this.dateLocale &&
          other.statut == this.statut);
}

class PaiementsCompanion extends UpdateCompanion<Paiement> {
  final Value<String?> id;
  final Value<String> clientUuid;
  final Value<String> echeanceId;
  final Value<double> montant;
  final Value<String> modePaiement;
  final Value<String?> note;
  final Value<DateTime> dateLocale;
  final Value<String> statut;
  final Value<int> rowid;
  const PaiementsCompanion({
    this.id = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.echeanceId = const Value.absent(),
    this.montant = const Value.absent(),
    this.modePaiement = const Value.absent(),
    this.note = const Value.absent(),
    this.dateLocale = const Value.absent(),
    this.statut = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaiementsCompanion.insert({
    this.id = const Value.absent(),
    required String clientUuid,
    required String echeanceId,
    required double montant,
    required String modePaiement,
    this.note = const Value.absent(),
    required DateTime dateLocale,
    this.statut = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientUuid = Value(clientUuid),
       echeanceId = Value(echeanceId),
       montant = Value(montant),
       modePaiement = Value(modePaiement),
       dateLocale = Value(dateLocale);
  static Insertable<Paiement> custom({
    Expression<String>? id,
    Expression<String>? clientUuid,
    Expression<String>? echeanceId,
    Expression<double>? montant,
    Expression<String>? modePaiement,
    Expression<String>? note,
    Expression<DateTime>? dateLocale,
    Expression<String>? statut,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (echeanceId != null) 'echeance_id': echeanceId,
      if (montant != null) 'montant': montant,
      if (modePaiement != null) 'mode_paiement': modePaiement,
      if (note != null) 'note': note,
      if (dateLocale != null) 'date_locale': dateLocale,
      if (statut != null) 'statut': statut,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaiementsCompanion copyWith({
    Value<String?>? id,
    Value<String>? clientUuid,
    Value<String>? echeanceId,
    Value<double>? montant,
    Value<String>? modePaiement,
    Value<String?>? note,
    Value<DateTime>? dateLocale,
    Value<String>? statut,
    Value<int>? rowid,
  }) {
    return PaiementsCompanion(
      id: id ?? this.id,
      clientUuid: clientUuid ?? this.clientUuid,
      echeanceId: echeanceId ?? this.echeanceId,
      montant: montant ?? this.montant,
      modePaiement: modePaiement ?? this.modePaiement,
      note: note ?? this.note,
      dateLocale: dateLocale ?? this.dateLocale,
      statut: statut ?? this.statut,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (echeanceId.present) {
      map['echeance_id'] = Variable<String>(echeanceId.value);
    }
    if (montant.present) {
      map['montant'] = Variable<double>(montant.value);
    }
    if (modePaiement.present) {
      map['mode_paiement'] = Variable<String>(modePaiement.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (dateLocale.present) {
      map['date_locale'] = Variable<DateTime>(dateLocale.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaiementsCompanion(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('echeanceId: $echeanceId, ')
          ..write('montant: $montant, ')
          ..write('modePaiement: $modePaiement, ')
          ..write('note: $note, ')
          ..write('dateLocale: $dateLocale, ')
          ..write('statut: $statut, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DemandesValidationTable extends DemandesValidation
    with TableInfo<$DemandesValidationTable, DemandeValidation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DemandesValidationTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientUuidMeta = const VerificationMeta(
    'clientUuid',
  );
  @override
  late final GeneratedColumn<String> clientUuid = GeneratedColumn<String>(
    'client_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeActionMeta = const VerificationMeta(
    'typeAction',
  );
  @override
  late final GeneratedColumn<String> typeAction = GeneratedColumn<String>(
    'type_action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('annulation_paiement'),
  );
  static const VerificationMeta _paiementClientUuidMeta =
      const VerificationMeta('paiementClientUuid');
  @override
  late final GeneratedColumn<String> paiementClientUuid =
      GeneratedColumn<String>(
        'paiement_client_uuid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _motifMeta = const VerificationMeta('motif');
  @override
  late final GeneratedColumn<String> motif = GeneratedColumn<String>(
    'motif',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en_attente'),
  );
  static const VerificationMeta _dateDemandeMeta = const VerificationMeta(
    'dateDemande',
  );
  @override
  late final GeneratedColumn<DateTime> dateDemande = GeneratedColumn<DateTime>(
    'date_demande',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientUuid,
    typeAction,
    paiementClientUuid,
    motif,
    statut,
    dateDemande,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'demandes_validation';
  @override
  VerificationContext validateIntegrity(
    Insertable<DemandeValidation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_uuid')) {
      context.handle(
        _clientUuidMeta,
        clientUuid.isAcceptableOrUnknown(data['client_uuid']!, _clientUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_clientUuidMeta);
    }
    if (data.containsKey('type_action')) {
      context.handle(
        _typeActionMeta,
        typeAction.isAcceptableOrUnknown(data['type_action']!, _typeActionMeta),
      );
    }
    if (data.containsKey('paiement_client_uuid')) {
      context.handle(
        _paiementClientUuidMeta,
        paiementClientUuid.isAcceptableOrUnknown(
          data['paiement_client_uuid']!,
          _paiementClientUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paiementClientUuidMeta);
    }
    if (data.containsKey('motif')) {
      context.handle(
        _motifMeta,
        motif.isAcceptableOrUnknown(data['motif']!, _motifMeta),
      );
    }
    if (data.containsKey('statut')) {
      context.handle(
        _statutMeta,
        statut.isAcceptableOrUnknown(data['statut']!, _statutMeta),
      );
    }
    if (data.containsKey('date_demande')) {
      context.handle(
        _dateDemandeMeta,
        dateDemande.isAcceptableOrUnknown(
          data['date_demande']!,
          _dateDemandeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dateDemandeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUuid};
  @override
  DemandeValidation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DemandeValidation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      clientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_uuid'],
      )!,
      typeAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_action'],
      )!,
      paiementClientUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paiement_client_uuid'],
      )!,
      motif: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motif'],
      ),
      statut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut'],
      )!,
      dateDemande: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_demande'],
      )!,
    );
  }

  @override
  $DemandesValidationTable createAlias(String alias) {
    return $DemandesValidationTable(attachedDatabase, alias);
  }
}

class DemandeValidation extends DataClass
    implements Insertable<DemandeValidation> {
  final String? id;
  final String clientUuid;
  final String typeAction;
  final String paiementClientUuid;
  final String? motif;
  final String statut;
  final DateTime dateDemande;
  const DemandeValidation({
    this.id,
    required this.clientUuid,
    required this.typeAction,
    required this.paiementClientUuid,
    this.motif,
    required this.statut,
    required this.dateDemande,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['client_uuid'] = Variable<String>(clientUuid);
    map['type_action'] = Variable<String>(typeAction);
    map['paiement_client_uuid'] = Variable<String>(paiementClientUuid);
    if (!nullToAbsent || motif != null) {
      map['motif'] = Variable<String>(motif);
    }
    map['statut'] = Variable<String>(statut);
    map['date_demande'] = Variable<DateTime>(dateDemande);
    return map;
  }

  DemandesValidationCompanion toCompanion(bool nullToAbsent) {
    return DemandesValidationCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      clientUuid: Value(clientUuid),
      typeAction: Value(typeAction),
      paiementClientUuid: Value(paiementClientUuid),
      motif: motif == null && nullToAbsent
          ? const Value.absent()
          : Value(motif),
      statut: Value(statut),
      dateDemande: Value(dateDemande),
    );
  }

  factory DemandeValidation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DemandeValidation(
      id: serializer.fromJson<String?>(json['id']),
      clientUuid: serializer.fromJson<String>(json['clientUuid']),
      typeAction: serializer.fromJson<String>(json['typeAction']),
      paiementClientUuid: serializer.fromJson<String>(
        json['paiementClientUuid'],
      ),
      motif: serializer.fromJson<String?>(json['motif']),
      statut: serializer.fromJson<String>(json['statut']),
      dateDemande: serializer.fromJson<DateTime>(json['dateDemande']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'clientUuid': serializer.toJson<String>(clientUuid),
      'typeAction': serializer.toJson<String>(typeAction),
      'paiementClientUuid': serializer.toJson<String>(paiementClientUuid),
      'motif': serializer.toJson<String?>(motif),
      'statut': serializer.toJson<String>(statut),
      'dateDemande': serializer.toJson<DateTime>(dateDemande),
    };
  }

  DemandeValidation copyWith({
    Value<String?> id = const Value.absent(),
    String? clientUuid,
    String? typeAction,
    String? paiementClientUuid,
    Value<String?> motif = const Value.absent(),
    String? statut,
    DateTime? dateDemande,
  }) => DemandeValidation(
    id: id.present ? id.value : this.id,
    clientUuid: clientUuid ?? this.clientUuid,
    typeAction: typeAction ?? this.typeAction,
    paiementClientUuid: paiementClientUuid ?? this.paiementClientUuid,
    motif: motif.present ? motif.value : this.motif,
    statut: statut ?? this.statut,
    dateDemande: dateDemande ?? this.dateDemande,
  );
  DemandeValidation copyWithCompanion(DemandesValidationCompanion data) {
    return DemandeValidation(
      id: data.id.present ? data.id.value : this.id,
      clientUuid: data.clientUuid.present
          ? data.clientUuid.value
          : this.clientUuid,
      typeAction: data.typeAction.present
          ? data.typeAction.value
          : this.typeAction,
      paiementClientUuid: data.paiementClientUuid.present
          ? data.paiementClientUuid.value
          : this.paiementClientUuid,
      motif: data.motif.present ? data.motif.value : this.motif,
      statut: data.statut.present ? data.statut.value : this.statut,
      dateDemande: data.dateDemande.present
          ? data.dateDemande.value
          : this.dateDemande,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DemandeValidation(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('typeAction: $typeAction, ')
          ..write('paiementClientUuid: $paiementClientUuid, ')
          ..write('motif: $motif, ')
          ..write('statut: $statut, ')
          ..write('dateDemande: $dateDemande')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientUuid,
    typeAction,
    paiementClientUuid,
    motif,
    statut,
    dateDemande,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DemandeValidation &&
          other.id == this.id &&
          other.clientUuid == this.clientUuid &&
          other.typeAction == this.typeAction &&
          other.paiementClientUuid == this.paiementClientUuid &&
          other.motif == this.motif &&
          other.statut == this.statut &&
          other.dateDemande == this.dateDemande);
}

class DemandesValidationCompanion extends UpdateCompanion<DemandeValidation> {
  final Value<String?> id;
  final Value<String> clientUuid;
  final Value<String> typeAction;
  final Value<String> paiementClientUuid;
  final Value<String?> motif;
  final Value<String> statut;
  final Value<DateTime> dateDemande;
  final Value<int> rowid;
  const DemandesValidationCompanion({
    this.id = const Value.absent(),
    this.clientUuid = const Value.absent(),
    this.typeAction = const Value.absent(),
    this.paiementClientUuid = const Value.absent(),
    this.motif = const Value.absent(),
    this.statut = const Value.absent(),
    this.dateDemande = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DemandesValidationCompanion.insert({
    this.id = const Value.absent(),
    required String clientUuid,
    this.typeAction = const Value.absent(),
    required String paiementClientUuid,
    this.motif = const Value.absent(),
    this.statut = const Value.absent(),
    required DateTime dateDemande,
    this.rowid = const Value.absent(),
  }) : clientUuid = Value(clientUuid),
       paiementClientUuid = Value(paiementClientUuid),
       dateDemande = Value(dateDemande);
  static Insertable<DemandeValidation> custom({
    Expression<String>? id,
    Expression<String>? clientUuid,
    Expression<String>? typeAction,
    Expression<String>? paiementClientUuid,
    Expression<String>? motif,
    Expression<String>? statut,
    Expression<DateTime>? dateDemande,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientUuid != null) 'client_uuid': clientUuid,
      if (typeAction != null) 'type_action': typeAction,
      if (paiementClientUuid != null)
        'paiement_client_uuid': paiementClientUuid,
      if (motif != null) 'motif': motif,
      if (statut != null) 'statut': statut,
      if (dateDemande != null) 'date_demande': dateDemande,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DemandesValidationCompanion copyWith({
    Value<String?>? id,
    Value<String>? clientUuid,
    Value<String>? typeAction,
    Value<String>? paiementClientUuid,
    Value<String?>? motif,
    Value<String>? statut,
    Value<DateTime>? dateDemande,
    Value<int>? rowid,
  }) {
    return DemandesValidationCompanion(
      id: id ?? this.id,
      clientUuid: clientUuid ?? this.clientUuid,
      typeAction: typeAction ?? this.typeAction,
      paiementClientUuid: paiementClientUuid ?? this.paiementClientUuid,
      motif: motif ?? this.motif,
      statut: statut ?? this.statut,
      dateDemande: dateDemande ?? this.dateDemande,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientUuid.present) {
      map['client_uuid'] = Variable<String>(clientUuid.value);
    }
    if (typeAction.present) {
      map['type_action'] = Variable<String>(typeAction.value);
    }
    if (paiementClientUuid.present) {
      map['paiement_client_uuid'] = Variable<String>(paiementClientUuid.value);
    }
    if (motif.present) {
      map['motif'] = Variable<String>(motif.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (dateDemande.present) {
      map['date_demande'] = Variable<DateTime>(dateDemande.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DemandesValidationCompanion(')
          ..write('id: $id, ')
          ..write('clientUuid: $clientUuid, ')
          ..write('typeAction: $typeAction, ')
          ..write('paiementClientUuid: $paiementClientUuid, ')
          ..write('motif: $motif, ')
          ..write('statut: $statut, ')
          ..write('dateDemande: $dateDemande, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ElevesTable eleves = $ElevesTable(this);
  late final $EcheancesTable echeances = $EcheancesTable(this);
  late final $PaiementsTable paiements = $PaiementsTable(this);
  late final $DemandesValidationTable demandesValidation =
      $DemandesValidationTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    eleves,
    echeances,
    paiements,
    demandesValidation,
  ];
}

typedef $$ElevesTableCreateCompanionBuilder = ElevesCompanion Function({
  required String id,
  Value<String> matricule,
  required String nom,
  required String prenom,
  required String classe,
  required String siteId,
  Value<int> rowid,
});
typedef $$ElevesTableUpdateCompanionBuilder = ElevesCompanion Function({
  Value<String> id,
  Value<String> matricule,
  Value<String> nom,
  Value<String> prenom,
  Value<String> classe,
  Value<String> siteId,
  Value<int> rowid,
});

class $$ElevesTableFilterComposer
    extends Composer<_$AppDatabase, $ElevesTable> {
  $$ElevesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matricule => $composableBuilder(
    column: $table.matricule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prenom => $composableBuilder(
    column: $table.prenom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get classe => $composableBuilder(
    column: $table.classe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ElevesTableOrderingComposer
    extends Composer<_$AppDatabase, $ElevesTable> {
  $$ElevesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matricule => $composableBuilder(
    column: $table.matricule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prenom => $composableBuilder(
    column: $table.prenom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get classe => $composableBuilder(
    column: $table.classe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ElevesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ElevesTable> {
  $$ElevesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get matricule =>
      $composableBuilder(column: $table.matricule, builder: (column) => column);

  GeneratedColumn<String> get nom =>
      $composableBuilder(column: $table.nom, builder: (column) => column);

  GeneratedColumn<String> get prenom =>
      $composableBuilder(column: $table.prenom, builder: (column) => column);

  GeneratedColumn<String> get classe =>
      $composableBuilder(column: $table.classe, builder: (column) => column);

  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);
}

class $$ElevesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ElevesTable,
          Eleve,
          $$ElevesTableFilterComposer,
          $$ElevesTableOrderingComposer,
          $$ElevesTableAnnotationComposer,
          $$ElevesTableCreateCompanionBuilder,
          $$ElevesTableUpdateCompanionBuilder,
          (Eleve, BaseReferences<_$AppDatabase, $ElevesTable, Eleve>),
          Eleve,
          PrefetchHooks Function()
        > {
  $$ElevesTableTableManager(_$AppDatabase db, $ElevesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ElevesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ElevesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ElevesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> matricule = const Value.absent(),
                Value<String> nom = const Value.absent(),
                Value<String> prenom = const Value.absent(),
                Value<String> classe = const Value.absent(),
                Value<String> siteId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ElevesCompanion(
                id: id,
                matricule: matricule,
                nom: nom,
                prenom: prenom,
                classe: classe,
                siteId: siteId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> matricule = const Value.absent(),
                required String nom,
                required String prenom,
                required String classe,
                required String siteId,
                Value<int> rowid = const Value.absent(),
              }) => ElevesCompanion.insert(
                id: id,
                matricule: matricule,
                nom: nom,
                prenom: prenom,
                classe: classe,
                siteId: siteId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ElevesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ElevesTable,
      Eleve,
      $$ElevesTableFilterComposer,
      $$ElevesTableOrderingComposer,
      $$ElevesTableAnnotationComposer,
      $$ElevesTableCreateCompanionBuilder,
      $$ElevesTableUpdateCompanionBuilder,
      (Eleve, BaseReferences<_$AppDatabase, $ElevesTable, Eleve>),
      Eleve,
      PrefetchHooks Function()
    >;
typedef $$EcheancesTableCreateCompanionBuilder = EcheancesCompanion Function({
  required String id,
  required String eleveId,
  required double montantDu,
  required DateTime dateEcheance,
  required String statut,
  Value<int> rowid,
});
typedef $$EcheancesTableUpdateCompanionBuilder = EcheancesCompanion Function({
  Value<String> id,
  Value<String> eleveId,
  Value<double> montantDu,
  Value<DateTime> dateEcheance,
  Value<String> statut,
  Value<int> rowid,
});

class $$EcheancesTableFilterComposer
    extends Composer<_$AppDatabase, $EcheancesTable> {
  $$EcheancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eleveId => $composableBuilder(
    column: $table.eleveId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montantDu => $composableBuilder(
    column: $table.montantDu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateEcheance => $composableBuilder(
    column: $table.dateEcheance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EcheancesTableOrderingComposer
    extends Composer<_$AppDatabase, $EcheancesTable> {
  $$EcheancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eleveId => $composableBuilder(
    column: $table.eleveId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montantDu => $composableBuilder(
    column: $table.montantDu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateEcheance => $composableBuilder(
    column: $table.dateEcheance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EcheancesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EcheancesTable> {
  $$EcheancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eleveId =>
      $composableBuilder(column: $table.eleveId, builder: (column) => column);

  GeneratedColumn<double> get montantDu =>
      $composableBuilder(column: $table.montantDu, builder: (column) => column);

  GeneratedColumn<DateTime> get dateEcheance => $composableBuilder(
    column: $table.dateEcheance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);
}

class $$EcheancesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EcheancesTable,
          Echeance,
          $$EcheancesTableFilterComposer,
          $$EcheancesTableOrderingComposer,
          $$EcheancesTableAnnotationComposer,
          $$EcheancesTableCreateCompanionBuilder,
          $$EcheancesTableUpdateCompanionBuilder,
          (Echeance, BaseReferences<_$AppDatabase, $EcheancesTable, Echeance>),
          Echeance,
          PrefetchHooks Function()
        > {
  $$EcheancesTableTableManager(_$AppDatabase db, $EcheancesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EcheancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EcheancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EcheancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eleveId = const Value.absent(),
                Value<double> montantDu = const Value.absent(),
                Value<DateTime> dateEcheance = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EcheancesCompanion(
                id: id,
                eleveId: eleveId,
                montantDu: montantDu,
                dateEcheance: dateEcheance,
                statut: statut,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eleveId,
                required double montantDu,
                required DateTime dateEcheance,
                required String statut,
                Value<int> rowid = const Value.absent(),
              }) => EcheancesCompanion.insert(
                id: id,
                eleveId: eleveId,
                montantDu: montantDu,
                dateEcheance: dateEcheance,
                statut: statut,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EcheancesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EcheancesTable,
      Echeance,
      $$EcheancesTableFilterComposer,
      $$EcheancesTableOrderingComposer,
      $$EcheancesTableAnnotationComposer,
      $$EcheancesTableCreateCompanionBuilder,
      $$EcheancesTableUpdateCompanionBuilder,
      (Echeance, BaseReferences<_$AppDatabase, $EcheancesTable, Echeance>),
      Echeance,
      PrefetchHooks Function()
    >;
typedef $$PaiementsTableCreateCompanionBuilder = PaiementsCompanion Function({
  Value<String?> id,
  required String clientUuid,
  required String echeanceId,
  required double montant,
  required String modePaiement,
  Value<String?> note,
  required DateTime dateLocale,
  Value<String> statut,
  Value<int> rowid,
});
typedef $$PaiementsTableUpdateCompanionBuilder = PaiementsCompanion Function({
  Value<String?> id,
  Value<String> clientUuid,
  Value<String> echeanceId,
  Value<double> montant,
  Value<String> modePaiement,
  Value<String?> note,
  Value<DateTime> dateLocale,
  Value<String> statut,
  Value<int> rowid,
});

class $$PaiementsTableFilterComposer
    extends Composer<_$AppDatabase, $PaiementsTable> {
  $$PaiementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get echeanceId => $composableBuilder(
    column: $table.echeanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montant => $composableBuilder(
    column: $table.montant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modePaiement => $composableBuilder(
    column: $table.modePaiement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateLocale => $composableBuilder(
    column: $table.dateLocale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaiementsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaiementsTable> {
  $$PaiementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get echeanceId => $composableBuilder(
    column: $table.echeanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montant => $composableBuilder(
    column: $table.montant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modePaiement => $composableBuilder(
    column: $table.modePaiement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateLocale => $composableBuilder(
    column: $table.dateLocale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaiementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaiementsTable> {
  $$PaiementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get echeanceId => $composableBuilder(
    column: $table.echeanceId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get montant =>
      $composableBuilder(column: $table.montant, builder: (column) => column);

  GeneratedColumn<String> get modePaiement => $composableBuilder(
    column: $table.modePaiement,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get dateLocale => $composableBuilder(
    column: $table.dateLocale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);
}

class $$PaiementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaiementsTable,
          Paiement,
          $$PaiementsTableFilterComposer,
          $$PaiementsTableOrderingComposer,
          $$PaiementsTableAnnotationComposer,
          $$PaiementsTableCreateCompanionBuilder,
          $$PaiementsTableUpdateCompanionBuilder,
          (Paiement, BaseReferences<_$AppDatabase, $PaiementsTable, Paiement>),
          Paiement,
          PrefetchHooks Function()
        > {
  $$PaiementsTableTableManager(_$AppDatabase db, $PaiementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaiementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaiementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaiementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> clientUuid = const Value.absent(),
                Value<String> echeanceId = const Value.absent(),
                Value<double> montant = const Value.absent(),
                Value<String> modePaiement = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> dateLocale = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaiementsCompanion(
                id: id,
                clientUuid: clientUuid,
                echeanceId: echeanceId,
                montant: montant,
                modePaiement: modePaiement,
                note: note,
                dateLocale: dateLocale,
                statut: statut,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String clientUuid,
                required String echeanceId,
                required double montant,
                required String modePaiement,
                Value<String?> note = const Value.absent(),
                required DateTime dateLocale,
                Value<String> statut = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaiementsCompanion.insert(
                id: id,
                clientUuid: clientUuid,
                echeanceId: echeanceId,
                montant: montant,
                modePaiement: modePaiement,
                note: note,
                dateLocale: dateLocale,
                statut: statut,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaiementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaiementsTable,
      Paiement,
      $$PaiementsTableFilterComposer,
      $$PaiementsTableOrderingComposer,
      $$PaiementsTableAnnotationComposer,
      $$PaiementsTableCreateCompanionBuilder,
      $$PaiementsTableUpdateCompanionBuilder,
      (Paiement, BaseReferences<_$AppDatabase, $PaiementsTable, Paiement>),
      Paiement,
      PrefetchHooks Function()
    >;
typedef $$DemandesValidationTableCreateCompanionBuilder =
    DemandesValidationCompanion Function({
      Value<String?> id,
      required String clientUuid,
      Value<String> typeAction,
      required String paiementClientUuid,
      Value<String?> motif,
      Value<String> statut,
      required DateTime dateDemande,
      Value<int> rowid,
    });
typedef $$DemandesValidationTableUpdateCompanionBuilder =
    DemandesValidationCompanion Function({
      Value<String?> id,
      Value<String> clientUuid,
      Value<String> typeAction,
      Value<String> paiementClientUuid,
      Value<String?> motif,
      Value<String> statut,
      Value<DateTime> dateDemande,
      Value<int> rowid,
    });

class $$DemandesValidationTableFilterComposer
    extends Composer<_$AppDatabase, $DemandesValidationTable> {
  $$DemandesValidationTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typeAction => $composableBuilder(
    column: $table.typeAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paiementClientUuid => $composableBuilder(
    column: $table.paiementClientUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motif => $composableBuilder(
    column: $table.motif,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateDemande => $composableBuilder(
    column: $table.dateDemande,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DemandesValidationTableOrderingComposer
    extends Composer<_$AppDatabase, $DemandesValidationTable> {
  $$DemandesValidationTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeAction => $composableBuilder(
    column: $table.typeAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paiementClientUuid => $composableBuilder(
    column: $table.paiementClientUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motif => $composableBuilder(
    column: $table.motif,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateDemande => $composableBuilder(
    column: $table.dateDemande,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DemandesValidationTableAnnotationComposer
    extends Composer<_$AppDatabase, $DemandesValidationTable> {
  $$DemandesValidationTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientUuid => $composableBuilder(
    column: $table.clientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get typeAction => $composableBuilder(
    column: $table.typeAction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paiementClientUuid => $composableBuilder(
    column: $table.paiementClientUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motif =>
      $composableBuilder(column: $table.motif, builder: (column) => column);

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<DateTime> get dateDemande => $composableBuilder(
    column: $table.dateDemande,
    builder: (column) => column,
  );
}

class $$DemandesValidationTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DemandesValidationTable,
          DemandeValidation,
          $$DemandesValidationTableFilterComposer,
          $$DemandesValidationTableOrderingComposer,
          $$DemandesValidationTableAnnotationComposer,
          $$DemandesValidationTableCreateCompanionBuilder,
          $$DemandesValidationTableUpdateCompanionBuilder,
          (
            DemandeValidation,
            BaseReferences<
              _$AppDatabase,
              $DemandesValidationTable,
              DemandeValidation
            >,
          ),
          DemandeValidation,
          PrefetchHooks Function()
        > {
  $$DemandesValidationTableTableManager(
    _$AppDatabase db,
    $DemandesValidationTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DemandesValidationTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DemandesValidationTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DemandesValidationTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> clientUuid = const Value.absent(),
                Value<String> typeAction = const Value.absent(),
                Value<String> paiementClientUuid = const Value.absent(),
                Value<String?> motif = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<DateTime> dateDemande = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DemandesValidationCompanion(
                id: id,
                clientUuid: clientUuid,
                typeAction: typeAction,
                paiementClientUuid: paiementClientUuid,
                motif: motif,
                statut: statut,
                dateDemande: dateDemande,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String clientUuid,
                Value<String> typeAction = const Value.absent(),
                required String paiementClientUuid,
                Value<String?> motif = const Value.absent(),
                Value<String> statut = const Value.absent(),
                required DateTime dateDemande,
                Value<int> rowid = const Value.absent(),
              }) => DemandesValidationCompanion.insert(
                id: id,
                clientUuid: clientUuid,
                typeAction: typeAction,
                paiementClientUuid: paiementClientUuid,
                motif: motif,
                statut: statut,
                dateDemande: dateDemande,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DemandesValidationTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DemandesValidationTable,
      DemandeValidation,
      $$DemandesValidationTableFilterComposer,
      $$DemandesValidationTableOrderingComposer,
      $$DemandesValidationTableAnnotationComposer,
      $$DemandesValidationTableCreateCompanionBuilder,
      $$DemandesValidationTableUpdateCompanionBuilder,
      (
        DemandeValidation,
        BaseReferences<
          _$AppDatabase,
          $DemandesValidationTable,
          DemandeValidation
        >,
      ),
      DemandeValidation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ElevesTableTableManager get eleves =>
      $$ElevesTableTableManager(_db, _db.eleves);
  $$EcheancesTableTableManager get echeances =>
      $$EcheancesTableTableManager(_db, _db.echeances);
  $$PaiementsTableTableManager get paiements =>
      $$PaiementsTableTableManager(_db, _db.paiements);
  $$DemandesValidationTableTableManager get demandesValidation =>
      $$DemandesValidationTableTableManager(_db, _db.demandesValidation);
}
