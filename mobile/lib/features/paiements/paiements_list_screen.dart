import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../core/sync_service.dart';
import 'encaissement_form_screen.dart';
import 'paiement_historique_screen.dart';
import 'demandes_validation_screen.dart';

/// Instance unique de la base locale, partagée par toute l'app.
/// (Sera injectée plus proprement plus tard si besoin de mock pour les tests.)
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

/// Flux réactif des échéances + solde, exposé à l'écran.
final echeancesProvider = StreamProvider<List<EcheanceAvecSolde>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchEcheancesAvecSolde();
});

class PaiementsListScreen extends ConsumerStatefulWidget {
  const PaiementsListScreen({super.key});

  @override
  ConsumerState<PaiementsListScreen> createState() =>
      _PaiementsListScreenState();
}

class _PaiementsListScreenState extends ConsumerState<PaiementsListScreen> {
  String recherche = '';
  String filtreStatut = 'tous';

  @override
  Widget build(BuildContext context) {
    final echeancesAsync = ref.watch(echeancesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pending_actions),
            tooltip: 'Demandes de validation',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DemandesValidationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: echeancesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur : $err')),
        data: (echeances) {
          // Filtrage local (recherche par nom + filtre de statut)
          final filtrees = echeances.where((e) {
            final texteRecherche = recherche.toLowerCase();
            final correspondNom =
                e.eleveNom.toLowerCase().contains(texteRecherche) ||
                e.matricule.toLowerCase().contains(texteRecherche);
            final correspondStatut =
                filtreStatut == 'tous' || e.statut == filtreStatut;
            return correspondNom && correspondStatut;
          }).toList();

          final collecte = echeances.fold<double>(
            0,
            (total, e) =>
                total +
                (e.montantDu - e.montantRestant).clamp(0, double.infinity),
          );
          final nbAttentionRequise = echeances
              .where((e) => e.statut == 'en_retard' || e.statut == 'partiel')
              .length;

          return Column(
            children: [
              _BandeauHorsLigne(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _CarteStat(label: 'Élèves', valeur: '${echeances.length}'),
                    const SizedBox(width: 10),
                    _CarteStat(
                      label: 'Collecté',
                      valeur: '${collecte.toStringAsFixed(0)} F',
                    ),
                    const SizedBox(width: 10),
                    _CarteStat(
                      label: 'Attention requise',
                      valeur: '$nbAttentionRequise',
                      alerte: nbAttentionRequise > 0,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Nom ou matricule...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (valeur) =>
                            setState(() => recherche = valeur),
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: filtreStatut,
                      items: const [
                        DropdownMenuItem(
                          value: 'tous',
                          child: Text('Tous les statuts'),
                        ),
                        DropdownMenuItem(
                          value: 'en_retard',
                          child: Text('En retard'),
                        ),
                        DropdownMenuItem(
                          value: 'partiel',
                          child: Text('Partiel'),
                        ),
                        DropdownMenuItem(value: 'solde', child: Text('Soldé')),
                        DropdownMenuItem(
                          value: 'avance',
                          child: Text('Avance'),
                        ),
                      ],
                      onChanged: (valeur) =>
                          setState(() => filtreStatut = valeur ?? 'tous'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtrees.isEmpty
                    ? const Center(child: Text('Aucun élève trouvé'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filtrees.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final e = filtrees[index];
                          return _LigneEcheance(echeance: e);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // La sélection se fait via la recherche déjà présente en haut
          // de la liste — pas besoin d'un écran séparé pour l'instant.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Recherche un élève ci-dessus, puis touche "Encaisser"',
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau paiement'),
      ),
    );
  }
}

class _BandeauHorsLigne extends ConsumerWidget {
  const _BandeauHorsLigne();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nbNonSyncAsync = ref.watch(nbNonSynchronisesProvider);

    return nbNonSyncAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (nb) {
        if (nb == 0) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: Colors.orange.shade50,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, size: 14, color: Colors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$nb paiement(s) en attente de synchronisation',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final resultat = await ref
                      .read(syncServiceProvider)
                      .synchroniser();
                  if (context.mounted) {
                    final message = resultat.erreurReseau != null
                        ? 'Synchronisation impossible pour le moment (pas de connexion au serveur)'
                        : '${resultat.nbCrees} synchronisé(s), ${resultat.nbConflits} conflit(s)';
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(message)));
                  }
                },
                child: const Text(
                  'Synchroniser',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final nbNonSynchronisesProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchNbPaiementsNonSynchronises();
});

class _CarteStat extends StatelessWidget {
  final String label;
  final String valeur;
  final bool alerte;

  const _CarteStat({
    required this.label,
    required this.valeur,
    this.alerte = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alerte ? Colors.red.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: alerte ? Colors.red.shade700 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              valeur,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: alerte ? Colors.red.shade700 : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneEcheance extends StatelessWidget {
  final EcheanceAvecSolde echeance;

  const _LigneEcheance({required this.echeance});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaiementHistoriqueScreen(
              echeanceId: echeance.echeanceId,
              eleveNom: echeance.eleveNom,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    echeance.eleveNom,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    echeance.statut == 'avance'
                        ? '${echeance.classe} — ${(-echeance.montantRestant).toStringAsFixed(0)} F d\'avance'
                        : '${echeance.classe} — reste ${echeance.montantRestant.toStringAsFixed(0)} F',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            _PastilleStatut(echeance: echeance),
            const SizedBox(width: 8),
            if (echeance.statut == 'en_retard' || echeance.statut == 'partiel')
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          EncaissementFormScreen(echeance: echeance),
                    ),
                  );
                },
                child: const Text('Encaisser'),
              )
            else
              Icon(
                Icons.check_circle,
                color: echeance.statut == 'avance' ? Colors.blue : Colors.green,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _PastilleStatut extends StatelessWidget {
  final EcheanceAvecSolde echeance;

  const _PastilleStatut({required this.echeance});

  @override
  Widget build(BuildContext context) {
    late Color couleurFond;
    late Color couleurTexte;
    late String texte;

    switch (echeance.statut) {
      case 'en_retard':
        couleurFond = Colors.red.shade50;
        couleurTexte = Colors.red.shade700;
        texte = 'En retard — ${echeance.joursRetard}j';
        break;
      case 'partiel':
        couleurFond = Colors.orange.shade50;
        couleurTexte = Colors.orange.shade700;
        texte = 'Partiel';
        break;
      case 'avance':
        couleurFond = Colors.blue.shade50;
        couleurTexte = Colors.blue.shade700;
        texte = 'Avance';
        break;
      default:
        couleurFond = Colors.green.shade50;
        couleurTexte = Colors.green.shade700;
        texte = 'Soldé';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleurFond,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(texte, style: TextStyle(fontSize: 11, color: couleurTexte)),
    );
  }
}
