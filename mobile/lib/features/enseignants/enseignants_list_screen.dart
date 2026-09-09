import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'enseignant_fiche_screen.dart';
import 'providers/enseignant_providers.dart';

/// Liste des enseignants — réservé aux postes ayant `gerer_enseignants`
/// (vérifié côté serveur ; l'écran ne fait que refléter cette exigence).
/// Online-only, pas de cache Drift : même choix que l'admin Rôles (Sprint 4),
/// cohérence + sécurité, ce type d'écran n'a pas de besoin terrain hors-ligne.
class EnseignantsListScreen extends ConsumerStatefulWidget {
  const EnseignantsListScreen({super.key});

  @override
  ConsumerState<EnseignantsListScreen> createState() => _EnseignantsListScreenState();
}

class _EnseignantsListScreenState extends ConsumerState<EnseignantsListScreen> {
  String recherche = '';

  @override
  Widget build(BuildContext context) {
    final enseignantsAsync = ref.watch(enseignantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Enseignants')),
      body: enseignantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(enseignantsProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 300,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Erreur : $error', textAlign: TextAlign.center),
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (enseignants) {
          final filtres = enseignants.where((e) {
            final q = recherche.toLowerCase();
            return e.nom.toLowerCase().contains(q) || e.telephone.contains(q);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(enseignantsProvider),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Nom ou téléphone...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => recherche = v),
                  ),
                ),
                Expanded(
                  child: filtres.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(
                              height: 200,
                              child: Center(child: Text('Aucun enseignant trouvé')),
                            ),
                          ],
                        )
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
                              title: Text(e.nom),
                              subtitle: Text(
                                '${e.telephone} · ${e.affectations.length} affectation(s)',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EnseignantFicheScreen(enseignantId: e.id),
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
    );
  }
}