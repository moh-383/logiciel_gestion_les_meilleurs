import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../administration/models/site.dart';
import '../administration/providers/administration_providers.dart';
import 'models/affectation.dart';
import 'providers/enseignant_providers.dart';

class EnseignantFicheScreen extends ConsumerWidget {
  final String enseignantId;

  const EnseignantFicheScreen({super.key, required this.enseignantId});

  Future<void> _ouvrirCreationAffectation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final sites = await ref.read(sitesProvider.future);
    if (!context.mounted) return;

    final classeController = TextEditingController();
    final matiereController = TextEditingController();
    final anneeController = TextEditingController(text: '2026-2027');
    String? siteId = sites.isNotEmpty ? sites.first.id : null;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nouvelle affectation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: siteId,
                decoration: const InputDecoration(labelText: 'Site'),
                items: sites
                    .map(
                      (Site s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.nom)),
                    )
                    .toList(),
                onChanged: (v) => setStateDialog(() => siteId = v),
              ),
              TextField(
                controller: classeController,
                decoration: const InputDecoration(
                  labelText: 'Classe (ex : 3ème B)',
                ),
              ),
              TextField(
                controller: matiereController,
                decoration: const InputDecoration(labelText: 'Matière'),
              ),
              TextField(
                controller: anneeController,
                decoration: const InputDecoration(labelText: 'Année scolaire'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    if (confirme != true || siteId == null) return;
    if (classeController.text.trim().isEmpty ||
        anneeController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classe et année scolaire sont obligatoires.'),
          ),
        );
      }
      return;
    }

    try {
      await ref
          .read(enseignantRepositoryProvider)
          .creerAffectation(
            enseignantId: enseignantId,
            siteId: siteId!,
            classe: classeController.text.trim(),
            matiere: matiereController.text.trim(),
            anneeScolaire: anneeController.text.trim(),
          );
      ref.invalidate(enseignantDetailProvider(enseignantId));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Affectation créée.')));
      }
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Création impossible.';
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _supprimer(
    BuildContext context,
    WidgetRef ref,
    Affectation affectation,
  ) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette affectation ?'),
        content: Text('${affectation.classe} — ${affectation.matiere}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    await ref
        .read(enseignantRepositoryProvider)
        .supprimerAffectation(affectation.id);
    ref.invalidate(enseignantDetailProvider(enseignantId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enseignantAsync = ref.watch(enseignantDetailProvider(enseignantId));
    final sitesAsync = ref.watch(sitesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Fiche enseignant')),
      body: enseignantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (enseignant) {
          final sitesParId = {
            for (final s
                in sitesAsync.whenOrNull(data: (v) => v) ?? const <Site>[])
              s.id: s.nom,
          };

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(enseignantDetailProvider(enseignantId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  enseignant.nom,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  enseignant.telephone,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Affectations',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: () => _ouvrirCreationAffectation(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
                if (enseignant.affectations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Aucune affectation pour cet enseignant.'),
                    ),
                  )
                else
                  ...enseignant.affectations.map(
                    (affectation) => Card(
                      child: ListTile(
                        title: Text(
                          '${affectation.classe} — ${affectation.matiere}',
                        ),
                        subtitle: Text(
                          '${sitesParId[affectation.siteId] ?? 'Site inconnu'} · '
                          '${affectation.anneeScolaire}'
                          '${affectation.actif ? '' : ' · inactive'}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (valeur) async {
                            if (valeur == 'toggle') {
                              await ref
                                  .read(enseignantRepositoryProvider)
                                  .basculerActif(
                                    affectation.id,
                                    !affectation.actif,
                                  );
                              ref.invalidate(
                                enseignantDetailProvider(enseignantId),
                              );
                            } else if (valeur == 'supprimer') {
                              await _supprimer(context, ref, affectation);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(
                                affectation.actif ? 'Désactiver' : 'Réactiver',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'supprimer',
                              child: Text('Supprimer'),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _PlanningAffectationScreen(
                              affectation: affectation,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlanningAffectationScreen extends ConsumerStatefulWidget {
  final Affectation affectation;

  const _PlanningAffectationScreen({required this.affectation});

  @override
  ConsumerState<_PlanningAffectationScreen> createState() =>
      _PlanningAffectationScreenState();
}

class _PlanningAffectationScreenState
    extends ConsumerState<_PlanningAffectationScreen> {
  late Future<List<Creneau>> _chargement;

  @override
  void initState() {
    super.initState();
    _chargement = _charger();
  }

  Future<List<Creneau>> _charger() => ref
      .read(enseignantRepositoryProvider)
      .listerCreneaux(widget.affectation.id);

  Future<void> _rafraichir() async {
    setState(() => _chargement = _charger());
    await _chargement;
  }

  Future<void> _ajouter() async {
    final proposition = await showDialog<_NouveauCreneau>(
      context: context,
      builder: (_) => const _CreneauDialog(),
    );
    if (proposition == null) return;
    try {
      await ref
          .read(enseignantRepositoryProvider)
          .creerCreneau(
            affectationId: widget.affectation.id,
            jourSemaine: proposition.jourSemaine,
            heureDebut: proposition.heureDebut,
            heureFin: proposition.heureFin,
          );
      await _rafraichir();
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_apiMessage(error, 'Créneau impossible à créer.')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Planning de l’affectation')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _ajouter,
      icon: const Icon(Icons.add),
      label: const Text('Créneau'),
    ),
    body: FutureBuilder<List<Creneau>>(
      future: _chargement,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: OutlinedButton(
              onPressed: _rafraichir,
              child: const Text('Réessayer'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final creneaux = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _rafraichir,
          child: creneaux.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 220),
                    Center(child: Text('Aucun créneau planifié.')),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: creneaux.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final creneau = creneaux[index];
                    return ListTile(
                      leading: const Icon(Icons.schedule_outlined),
                      title: Text(jourLibelle(creneau.jourSemaine)),
                      subtitle: Text(
                        '${creneau.heureDebut} – ${creneau.heureFin}'
                        '${creneau.actif ? '' : ' · Inactif'}',
                      ),
                      trailing: IconButton(
                        tooltip: creneau.actif ? 'Désactiver' : 'Réactiver',
                        icon: Icon(
                          creneau.actif
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                        ),
                        onPressed: () async {
                          await ref
                              .read(enseignantRepositoryProvider)
                              .basculerCreneau(creneau.id, !creneau.actif);
                          await _rafraichir();
                        },
                      ),
                    );
                  },
                ),
        );
      },
    ),
  );
}

class _NouveauCreneau {
  final int jourSemaine;
  final String heureDebut;
  final String heureFin;

  const _NouveauCreneau(this.jourSemaine, this.heureDebut, this.heureFin);
}

class _CreneauDialog extends StatefulWidget {
  const _CreneauDialog();

  @override
  State<_CreneauDialog> createState() => _CreneauDialogState();
}

class _CreneauDialogState extends State<_CreneauDialog> {
  int _jour = 0;
  final _debut = TextEditingController(text: '08:00');
  final _fin = TextEditingController(text: '10:00');

  @override
  void dispose() {
    _debut.dispose();
    _fin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nouveau créneau'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _jour,
          decoration: const InputDecoration(labelText: 'Jour'),
          items: List.generate(
            7,
            (index) =>
                DropdownMenuItem(value: index, child: Text(jourLibelle(index))),
          ),
          onChanged: (value) => setState(() => _jour = value ?? 0),
        ),
        TextField(
          controller: _debut,
          decoration: const InputDecoration(labelText: 'Début (HH:MM)'),
        ),
        TextField(
          controller: _fin,
          decoration: const InputDecoration(labelText: 'Fin (HH:MM)'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () {
          final heure = RegExp(r'^([01]\\d|2[0-3]):[0-5]\\d$');
          if (!heure.hasMatch(_debut.text) || !heure.hasMatch(_fin.text)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Utilisez le format HH:MM.')),
            );
            return;
          }
          Navigator.pop(
            context,
            _NouveauCreneau(_jour, _debut.text, _fin.text),
          );
        },
        child: const Text('Enregistrer'),
      ),
    ],
  );
}

String jourLibelle(int value) => const [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
][value];

String _apiMessage(DioException error, String fallback) {
  final data = error.response?.data;
  return data is Map
      ? (data['message']?.toString() ?? data['detail']?.toString() ?? fallback)
      : fallback;
}
