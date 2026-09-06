import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/eleves/providers/eleve_providers.dart';

import '../../core/import_service.dart';
import 'eleve_creation_screen.dart';
import 'eleve_fiche_screen.dart';

class ElevesListScreen extends ConsumerStatefulWidget {
  const ElevesListScreen({super.key});

  @override
  ConsumerState<ElevesListScreen> createState() => _ElevesListScreenState();
}

class _ElevesListScreenState extends ConsumerState<ElevesListScreen> {
  String recherche = '';

  @override
  Widget build(BuildContext context) {
    final elevesAsync = ref.watch(elevesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Élèves')),
      body: elevesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (eleves) {
          final filtres = eleves.where((e) {
            final q = recherche.toLowerCase();
            return e.nom.toLowerCase().contains(q) ||
                e.prenom.toLowerCase().contains(q) ||
                e.matricule.toLowerCase().contains(q);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(importServiceProvider).importerDonneesDuSite();
              final resultat = await ref
                  .read(eleveSyncServiceProvider)
                  .synchroniser();
              if (context.mounted && resultat.erreur != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Synchronisation élèves : ${resultat.erreur}',
                    ),
                  ),
                );
              }
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Nom, prénom ou matricule...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => recherche = v),
                  ),
                ),
                Expanded(
                  child: filtres.isEmpty
                      ? const Center(child: Text('Aucun élève trouvé'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filtres.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final e = filtres[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.shade100,
                                child: Text(
                                  e.nom.isNotEmpty ? e.nom[0] : '?',
                                  style: const TextStyle(color: Colors.teal),
                                ),
                              ),
                              title: Text('${e.prenom} ${e.nom}'),
                              subtitle: Text(e.classe),
                              trailing: e.enAttenteDeSync
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: e.syncRaison != null
                                            ? Colors.red.shade50
                                            : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        e.syncRaison != null
                                            ? 'Conflit'
                                            : 'En attente',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: e.syncRaison != null
                                              ? Colors.red
                                              : Colors.orange,
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EleveFicheScreen(eleve: e),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EleveCreationScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvel élève'),
      ),
    );
  }
}
