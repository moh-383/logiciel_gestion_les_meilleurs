import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/eleve_repository.dart';
import 'echeance_creation_screen.dart';
import 'eleve_edit_screen.dart';
import 'providers/eleve_providers.dart';

/// Fiche élève (maquette écran 3), version MVP : onglets Infos et
/// Paiements uniquement. Présence/Historique dépendent du module
/// Enseignants (V2, Sprint 8) et ne sont pas encore branchés.
class EleveFicheScreen extends ConsumerWidget {
  final EleveAffichable eleve;

  const EleveFicheScreen({super.key, required this.eleve});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${eleve.prenom} ${eleve.nom}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier l\'élève',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EleveEditScreen(eleve: eleve),
                  ),
                );
              },
            ),
            if (!eleve.enAttenteDeSync)
              IconButton(
                icon: const Icon(Icons.add_card_outlined),
                tooltip: 'Nouvelle échéance',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EcheanceCreationScreen(eleve: eleve),
                    ),
                  );
                },
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Infos'),
              Tab(text: 'Paiements'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OngletInfos(eleve: eleve),
            _OngletPaiements(eleve: eleve, ref: ref),
          ],
        ),
      ),
    );
  }
}

class _OngletInfos extends StatelessWidget {
  final EleveAffichable eleve;
  const _OngletInfos({required this.eleve});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (eleve.enAttenteDeSync)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: eleve.syncRaison != null
                  ? Colors.red.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              eleve.syncRaison != null
                  ? 'Conflit de synchronisation : ${eleve.syncRaison}'
                  : 'En attente de synchronisation avec le serveur.',
              style: TextStyle(
                fontSize: 12,
                color: eleve.syncRaison != null
                    ? Colors.red.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ),
        _section('Informations personnelles', [
          _ligne('Nom complet', '${eleve.prenom} ${eleve.nom}'),
          _ligne(
            'Matricule',
            eleve.matricule.isEmpty
                ? 'En attente d\'attribution'
                : eleve.matricule,
          ),
          _ligne('Sexe', eleve.sexe == 'F' ? 'Féminin' : 'Masculin'),
          if (eleve.dateNaissance != null)
            _ligne(
              'Date de naissance',
              '${eleve.dateNaissance!.day.toString().padLeft(2, '0')}/${eleve.dateNaissance!.month.toString().padLeft(2, '0')}/${eleve.dateNaissance!.year}',
            ),
        ]),
        const SizedBox(height: 16),
        _section('Scolarité', [
          _ligne('Classe', eleve.classe),
          _ligne('Type de cours', eleve.typeCours),
        ]),
      ],
    );
  }

  Widget _section(String titre, List<Widget> lignes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titre,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(children: lignes),
        ),
      ],
    );
  }

  Widget _ligne(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(valeur, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _OngletPaiements extends StatelessWidget {
  final EleveAffichable eleve;
  final WidgetRef ref;
  const _OngletPaiements({required this.eleve, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (eleve.enAttenteDeSync) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Les échéances apparaîtront ici une fois l\'élève confirmé par le serveur.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final echeancesAsync = ref.watch(
      echeancesDeLEleveProvider(eleve.idNavigation),
    );

    return echeancesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur : $err')),
      data: (echeances) {
        if (echeances.isEmpty) {
          return const Center(child: Text('Aucune échéance pour cet élève'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: echeances.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final e = echeances[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${e.montantDu.toStringAsFixed(0)} FCFA dû'),
              subtitle: Text(
                'Reste : ${e.montantRestant.toStringAsFixed(0)} FCFA',
              ),
              trailing: Text(e.statut),
            );
          },
        );
      },
    );
  }
}
