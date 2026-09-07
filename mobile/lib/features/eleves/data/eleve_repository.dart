import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/database.dart';

/// Élève tel qu'affiché en liste : soit une donnée confirmée du cache
/// serveur (`Eleves`), soit une création locale pas encore synchronisée
/// (`ElevesEnAttente`) — visible immédiatement, sans attendre le réseau.
class EleveAffichable {
  final String? idServeur;
  final String? clientUuidLocal;
  final String matricule;
  final String nom;
  final String prenom;
  final String classe;
  final String siteId;
  final String sexe;
  final DateTime? dateNaissance;
  final String typeCours;
  final String statut;
  final bool enAttenteDeSync;
  final String? syncRaison;

  EleveAffichable({
    this.idServeur,
    this.clientUuidLocal,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.classe,
    required this.siteId,
    required this.sexe,
    this.dateNaissance,
    required this.typeCours,
    required this.statut,
    required this.enAttenteDeSync,
    this.syncRaison,
  });

  /// Identifiant à utiliser pour naviguer vers la fiche élève : l'id
  /// serveur si confirmé, sinon le client_uuid local.
  String get idNavigation => idServeur ?? clientUuidLocal!;
}

class EleveRepository {
  final AppDatabase db;

  EleveRepository(this.db);

  /// Fusionne cache serveur et file d'attente locale, triés par nom.
  Stream<List<EleveAffichable>> watchTousLesEleves() {
    final confirmesStream = db.select(db.eleves).watch();
    final enAttenteStream =
        (db.select(db.elevesEnAttente)..where(
              (e) =>
                  e.syncStatus.equals('en_attente') |
                  e.syncStatus.equals('conflit'),
            ))
            .watch();

    return Stream.multi((controller) {
      List<Eleve>? confirmes;
      List<EleveEnAttente>? enAttente;

      void publier() {
        if (confirmes == null || enAttente == null) return;
        final elevesConfirmes = confirmes!;
        final elevesEnAttente = enAttente!;
        final resultats = <EleveAffichable>[
          ...elevesConfirmes.map(
            (e) => EleveAffichable(
              idServeur: e.id,
              matricule: e.matricule,
              nom: e.nom,
              prenom: e.prenom,
              classe: e.classe,
              siteId: e.siteId,
              sexe: e.sexe,
              dateNaissance: e.dateNaissance,
              typeCours: e.typeCours,
              statut: e.statut,
              enAttenteDeSync: false,
            ),
          ),
          ...elevesEnAttente.map(
            (e) => EleveAffichable(
              clientUuidLocal: e.clientUuid,
              matricule: e.matricule,
              nom: e.nom,
              prenom: e.prenom,
              classe: e.classe,
              siteId: e.siteId,
              sexe: e.sexe,
              dateNaissance: e.dateNaissance,
              typeCours: e.typeCours,
              statut: 'actif',
              enAttenteDeSync: true,
              syncRaison: e.syncRaison,
            ),
          ),
        ];
        resultats.sort((a, b) => a.nom.compareTo(b.nom));
        controller.add(resultats);
      }

      final abonnements = [
        confirmesStream.listen((valeur) {
          confirmes = valeur;
          publier();
        }),
        enAttenteStream.listen((valeur) {
          enAttente = valeur;
          publier();
        }),
      ];
      controller.onCancel = () async {
        for (final abonnement in abonnements) {
          await abonnement.cancel();
        }
      };
    });
  }

  /// Échéances d'un élève donné (via le cache `Echeances`, importé par
  /// ImportService). Vide tant que l'élève n'est pas confirmé serveur —
  /// c'est normal, à afficher explicitement dans la fiche élève.
  Stream<List<EcheanceAvecSolde>> watchEcheancesDeLEleve(String eleveId) {
    return db.watchEcheancesAvecSolde().map(
      (liste) => liste.where((e) => e.eleveId == eleveId).toList(),
    );
  }

  /// Crée un élève localement (hors ligne ou en ligne, peu importe) —
  /// EleveSyncService se charge de l'envoi dès que possible. Ne touche
  /// jamais au cache `Eleves`, réservé aux données confirmées serveur.
  Future<String> creerEleveLocal({
    required String nom,
    required String prenom,
    required String sexe,
    required String siteId,
    required String classe,
    required String typeCours,
    DateTime? dateNaissance,
    String? contactNom,
    String? contactTelephone,
    String? contactLien,
  }) async {
    final clientUuid = const Uuid().v4();
    await db
        .into(db.elevesEnAttente)
        .insert(
          ElevesEnAttenteCompanion.insert(
            clientUuid: clientUuid,
            matricule: '',
            nom: nom,
            prenom: prenom,
            sexe: sexe,
            siteId: siteId,
            classe: classe,
            typeCours: typeCours,
            dateNaissance: Value(dateNaissance),
            contactNom: Value(contactNom),
            contactTelephone: Value(contactTelephone),
            contactLien: Value(contactLien),
            dateCreationLocale: DateTime.now(),
          ),
        );
    return clientUuid;
  }

  Future<void> modifierEleveEnAttente({
    required String clientUuid,
    required String nom,
    required String prenom,
    required String sexe,
    required String classe,
    required String typeCours,
    DateTime? dateNaissance,
  }) async {
    await (db.update(
      db.elevesEnAttente,
    )..where((e) => e.clientUuid.equals(clientUuid))).write(
      ElevesEnAttenteCompanion(
        nom: Value(nom),
        prenom: Value(prenom),
        sexe: Value(sexe),
        classe: Value(classe),
        typeCours: Value(typeCours),
        dateNaissance: Value(dateNaissance),
        syncStatus: const Value('en_attente'),
        syncRaison: const Value(null),
      ),
    );
  }

  Future<List<EleveEnAttente>> elevesEnAttenteDeSync() {
    return (db.select(
      db.elevesEnAttente,
    )..where((e) => e.syncStatus.equals('en_attente'))).get();
  }

  /// Applique le résultat de /sync/eleves à un élève local donné
  /// (voir docs/api-contract.md, section synchronisation élèves).
  Future<void> appliquerResultatSyncEleve({
    required String clientUuid,
    required String statut, // cree / deja_existant / conflit / erreur
    String? idServeur,
    String? raison,
  }) async {
    if (statut == 'cree' || statut == 'deja_existant') {
      await (db.update(
        db.elevesEnAttente,
      )..where((e) => e.clientUuid.equals(clientUuid))).write(
        ElevesEnAttenteCompanion(
          id: Value(idServeur),
          syncStatus: const Value('synchronise'),
          syncRaison: const Value(null),
        ),
      );
    } else {
      // 'conflit' ou 'erreur' : l'élève reste visible en local pour
      // arbitrage manuel — jamais de suppression silencieuse.
      await (db.update(
        db.elevesEnAttente,
      )..where((e) => e.clientUuid.equals(clientUuid))).write(
        ElevesEnAttenteCompanion(
          syncStatus: const Value('conflit'),
          syncRaison: Value(raison),
        ),
      );
    }
  }
}
