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

  Future<void> _ouvrirCreationAffectation(BuildContext context, WidgetRef ref) async {
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
                    .map((Site s) => DropdownMenuItem(value: s.id, child: Text(s.nom)))
                    .toList(),
                onChanged: (v) => setStateDialog(() => siteId = v),
              ),
              TextField(
                controller: classeController,
                decoration: const InputDecoration(labelText: 'Classe (ex : 3ème B)'),
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
    if (classeController.text.trim().isEmpty || anneeController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Classe et année scolaire sont obligatoires.')),
        );
      }
      return;
    }

    try {
      await ref.read(enseignantRepositoryProvider).creerAffectation(
            enseignantId: enseignantId,
            siteId: siteId!,
            classe: classeController.text.trim(),
            matiere: matiereController.text.trim(),
            anneeScolaire: anneeController.text.trim(),
          );
      ref.invalidate(enseignantDetailProvider(enseignantId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Affectation créée.')),
        );
      }
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Création impossible.';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _supprimer(BuildContext context, WidgetRef ref, Affectation affectation) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette affectation ?'),
        content: Text('${affectation.classe} — ${affectation.matiere}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirme != true) return;

    await ref.read(enseignantRepositoryProvider).supprimerAffectation(affectation.id);
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
            for (final s in sitesAsync.whenOrNull(data: (v) => v) ?? const <Site>[]) s.id: s.nom,
          };

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(enseignantDetailProvider(enseignantId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(enseignant.nom, style: Theme.of(context).textTheme.titleLarge),
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
                    child: Center(child: Text('Aucune affectation pour cet enseignant.')),
                  )
                else
                  ...enseignant.affectations.map(
                    (affectation) => Card(
                      child: ListTile(
                        title: Text('${affectation.classe} — ${affectation.matiere}'),
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
                                  .basculerActif(affectation.id, !affectation.actif);
                              ref.invalidate(enseignantDetailProvider(enseignantId));
                            } else if (valeur == 'supprimer') {
                              await _supprimer(context, ref, affectation);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(affectation.actif ? 'Désactiver' : 'Réactiver'),
                            ),
                            const PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
                          ],
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