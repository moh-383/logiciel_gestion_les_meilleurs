import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/sync_service.dart';
import 'package:mobile/data/database.dart';

void main() {
  late AppDatabase db;
  late Dio dio;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
  });

  tearDown(() => db.close());

  Future<void> ajouterPaiement(String uuid) {
    return db.into(db.paiements).insert(
          PaiementsCompanion.insert(
            clientUuid: uuid,
            echeanceId: 'echeance-$uuid',
            montant: 5000,
            modePaiement: 'especes',
            dateLocale: DateTime.utc(2026, 9, 11, 10),
          ),
        );
  }

  test('confirme chaque paiement local selon le résultat retourné par API',
      () async {
    await ajouterPaiement('uuid-cree');
    await ajouterPaiement('uuid-conflit');

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/sync/paiements');
          final paiements = (options.data['paiements'] as List);
          expect(paiements, hasLength(2));
          expect(paiements.first['date_locale'], endsWith('Z'));
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'resultats': [
                  {
                    'client_uuid': 'uuid-cree',
                    'statut': 'cree',
                    'paiement_id': 'serveur-1',
                  },
                  {
                    'client_uuid': 'uuid-conflit',
                    'statut': 'conflit',
                    'raison': 'echeance_deja_soldee',
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final resultat = await SyncService(db: db, dio: dio).synchroniser();

    expect(resultat.nbEnvoyes, 2);
    expect(resultat.nbCrees, 1);
    expect(resultat.nbConflits, 1);
    final cree = await (db.select(db.paiements)
          ..where((p) => p.clientUuid.equals('uuid-cree')))
        .getSingle();
    final conflit = await (db.select(db.paiements)
          ..where((p) => p.clientUuid.equals('uuid-conflit')))
        .getSingle();
    expect(cree.syncStatus, 'synchronise');
    expect(cree.id, 'serveur-1');
    expect(conflit.syncStatus, 'conflit');
    expect(conflit.syncRaison, 'echeance_deja_soldee');
  });

  test('conserve les paiements en attente en cas de session expirée', () async {
    await ajouterPaiement('uuid-401');
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: 401),
          ),
        ),
      ),
    );

    final resultat = await SyncService(db: db, dio: dio).synchroniser();

    expect(resultat.erreurAuthentification, isNotNull);
    final paiement = await (db.select(db.paiements)
          ..where((p) => p.clientUuid.equals('uuid-401')))
        .getSingle();
    expect(paiement.syncStatus, 'en_attente');
  });

  test('conserve les paiements en attente quand la permission est refusée',
      () async {
    await ajouterPaiement('uuid-403');
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 403,
              data: {'message': 'Permission refusée.'},
            ),
          ),
        ),
      ),
    );

    final resultat = await SyncService(db: db, dio: dio).synchroniser();

    expect(resultat.erreurMetier, 'Permission refusée.');
    final paiement = await (db.select(db.paiements)
          ..where((p) => p.clientUuid.equals('uuid-403')))
        .getSingle();
    expect(paiement.syncStatus, 'en_attente');
  });

  test('ne modifie pas la file si le serveur répond sans résultats', () async {
    await ajouterPaiement('uuid-reponse-invalide');
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response(requestOptions: options, data: const {'incorrect': true}),
        ),
      ),
    );

    final resultat = await SyncService(db: db, dio: dio).synchroniser();

    expect(resultat.erreurMetier, isNotNull);
    final paiement = await (db.select(db.paiements)
          ..where((p) => p.clientUuid.equals('uuid-reponse-invalide')))
        .getSingle();
    expect(paiement.syncStatus, 'en_attente');
  });

  test('ne renvoie pas un paiement déjà confirmé', () async {
    await ajouterPaiement('uuid-idempotent');
    var appels = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          appels++;
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'resultats': [
                  {
                    'client_uuid': 'uuid-idempotent',
                    'statut': 'cree',
                    'paiement_id': 'serveur-idempotent',
                  },
                ],
              },
            ),
          );
        },
      ),
    );
    final service = SyncService(db: db, dio: dio);

    await service.synchroniser();
    final secondeTentative = await service.synchroniser();

    expect(appels, 1);
    expect(secondeTentative.nbEnvoyes, 0);
  });
}
