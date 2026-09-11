import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/eleve_repository.dart';
import 'echeance_creation_screen.dart';
import 'eleve_edit_screen.dart';
import 'providers/eleve_providers.dart';
import 'providers/echange_providers.dart';
import 'echange_creation_screen.dart';

/// Fiche élève avec les onglets Infos, Paiements et Historique.
class EleveFicheScreen extends ConsumerWidget {
  final EleveAffichable eleve;

  const EleveFicheScreen({super.key, required this.eleve});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
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
              Tab(text: 'Historique'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OngletInfos(eleve: eleve),
            _OngletPaiements(eleve: eleve, ref: ref),
            _OngletHistorique(eleve: eleve),
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
          _ligne(
            'Nom complet',
            '${eleve.prenom} ${eleve.nom}',
          ),
          _ligne(
            'Matricule',
            eleve.matricule.isEmpty
                ? 'En attente d\'attribution'
                : eleve.matricule,
          ),
          _ligne(
            'Sexe',
            eleve.sexe == 'F' ? 'Féminin' : 'Masculin',
          ),
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
          _ligne(
            'Statut',
            eleve.statut == 'inactif' ? 'Inactif' : 'Actif',
          ),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            valeur,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _OngletPaiements extends StatelessWidget {
  final EleveAffichable eleve;
  final WidgetRef ref;

  const _OngletPaiements({
    required this.eleve,
    required this.ref,
  });

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
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, _) => Center(
        child: Text('Erreur : $err'),
      ),
      data: (echeances) {
        if (echeances.isEmpty) {
          return const Center(
            child: Text('Aucune échéance pour cet élève'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: echeances.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final e = echeances[index];

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${e.montantDu.toStringAsFixed(0)} FCFA dû',
              ),
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

class _OngletHistorique extends ConsumerWidget {
  final EleveAffichable eleve;

  const _OngletHistorique({
    required this.eleve,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (eleve.enAttenteDeSync) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'L\'historique sera disponible une fois l\'élève confirmé par le serveur.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final echangesAsync = ref.watch(
      echangesDeLEleveProvider(eleve.idNavigation),
    );

    return Scaffold(
      body: echangesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Text('Erreur : $err'),
        ),
        data: (echanges) {
          if (echanges.isEmpty) {
            return const Center(
              child: Text('Aucun échange enregistré'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: echanges.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = echanges[index];

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_iconePour(e.typeEchange)),
                title: Text(e.titre),
                subtitle: Text(
                  '${_libelle(e.typeEchange)} · ${e.creeParNom} · '
                  '${e.dateEchange.day.toString().padLeft(2, '0')}/'
                  '${e.dateEchange.month.toString().padLeft(2, '0')}/'
                  '${e.dateEchange.year}'
                  '${e.enAttenteDeSync ? ' · non synchronisé' : ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EchangeCreationScreen(
                eleveId: eleve.idNavigation,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Ajouter'),
      ),
    );
  }

  String _libelle(String type) => const {
        'appel': 'Appel',
        'reunion': 'Réunion',
        'incident_discipline': 'Incident',
        'remarque': 'Remarque',
        'autre': 'Autre',
      }[type] ??
      type;

  IconData _iconePour(String type) => switch (type) {
        'appel' => Icons.call_outlined,
        'reunion' => Icons.groups_outlined,
        'incident_discipline' => Icons.warning_amber_outlined,
        'remarque' => Icons.sticky_note_2_outlined,
        _ => Icons.chat_bubble_outline,
      };
}
