import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/permission_catalogue.dart';
import 'models/poste.dart';
import 'models/site.dart';
import 'models/utilisateur_resume.dart';
import 'providers/administration_providers.dart';
import 'screens/utilisateur_creation_screen.dart';
import 'screens/utilisateur_modification_screen.dart';
import 'screens/poste_permissions_screen.dart';

class AdministrationScreen extends ConsumerStatefulWidget {
  const AdministrationScreen({super.key});

  @override
  ConsumerState<AdministrationScreen> createState() =>
      _AdministrationScreenState();
}

class _AdministrationScreenState
    extends ConsumerState<AdministrationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _actualiser() async {
    ref.invalidate(sitesProvider);
    ref.invalidate(postesProvider);
    ref.invalidate(permissionsCatalogueProvider);
    ref.invalidate(utilisateursProvider);
  }

  Future<void> _creerPoste() async {
    final nom = await _demanderTexte(
      'Nouveau poste',
      'Nom du poste',
    );

    if (nom == null || nom.trim().isEmpty) {
      return;
    }

    try {
      await ref.read(administrationRepositoryProvider).creerPoste(
            nom: nom.trim(),
          );

      ref.invalidate(postesProvider);

      if (mounted) {
        _afficherMessage('Poste créé avec succès.');
      }
    } catch (error) {
      if (mounted) {
        _afficherErreur(error.toString());
      }
    }
  }

  Future<void> _creerSite() async {
    final nom = await _demanderTexte(
      'Nouveau site',
      'Nom du site',
    );

    if (nom == null || nom.trim().isEmpty) {
      return;
    }

    try {
      await ref.read(administrationRepositoryProvider).creerSite(
            nom: nom.trim(),
          );

      ref.invalidate(sitesProvider);
      // Le succès n'est annoncé qu'après la lecture de la liste qui contient
      // désormais le site créé. Si cette étape échoue, l'utilisateur ne reçoit
      // pas un faux positif alors que l'état de l'écran est incohérent.
      await ref.read(sitesProvider.future);

      if (mounted) {
        _afficherMessage('Site créé avec succès.');
      }
    } catch (error) {
      if (mounted) {
        _afficherErreur(error.toString());
      }
    }
  }

  Future<String?> _demanderTexte(
    String titre,
    String label,
  ) {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titre),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                controller.text,
              );
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _afficherMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _afficherErreur(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _ouvrirModificationUtilisateur(
    UtilisateurResume utilisateur,
  ) async {
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UtilisateurModificationScreen(
          utilisateur: utilisateur,
        ),
      ),
    );

    ref.invalidate(utilisateursProvider);
  }

  Future<void> _ouvrirCreationUtilisateur() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UtilisateurCreationScreen(),
      ),
    );

    ref.invalidate(utilisateursProvider);
  }

  Future<void> _ouvrirPermissionsPoste(Poste poste) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostePermissionsScreen(
          posteId: poste.id,
          posteNom: poste.nom,
        ),
      ),
    );
    ref.invalidate(postesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final sites = ref.watch(sitesProvider);
    final postes = ref.watch(postesProvider);
    final permissions = ref.watch(permissionsCatalogueProvider);
    final utilisateurs = ref.watch(utilisateursProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sites'),
            Tab(text: 'Postes'),
            Tab(text: 'Permissions'),
            Tab(text: 'Utilisateurs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ============================================================
          // SITES
          // ============================================================
          _ConstruireListe<Site>(
            asyncValue: sites,
            titre: (site) => site.nom,
            sousTitre: (site) => site.adresse.isEmpty
                ? 'Adresse non renseignée'
                : site.adresse,
            icone: Icons.location_on,
            onRefresh: _actualiser,
          ),

          // ============================================================
          // POSTES
          // ============================================================
          _ConstruireListe<Poste>(
            asyncValue: postes,
            titre: (poste) => poste.nom,
            sousTitre: (poste) => poste.tousSites
                ? 'Accès multi-sites'
                : 'Accès limité au site',
            icone: Icons.badge,
            onRefresh: _actualiser,
            onTap: _ouvrirPermissionsPoste,
          ),

          // ============================================================
          // PERMISSIONS
          // ============================================================
          _CataloguePermissions(asyncValue: permissions, onRefresh: _actualiser),

          // ============================================================
          // UTILISATEURS
          // ============================================================
          utilisateurs.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => RefreshIndicator(
              onRefresh: _actualiser,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Erreur : $error',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _actualiser,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(
                        height: 300,
                        child: Center(
                          child: Text(
                            'Aucun utilisateur',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _actualiser,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final utilisateur = items[index];

                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          utilisateur.isActive
                              ? Icons.person
                              : Icons.person_off,
                        ),
                      ),
                      title: Text(
                        utilisateur.nom,
                      ),
                      subtitle: Text(
                        '${utilisateur.telephone} • '
                        '${utilisateur.isActive ? 'Actif' : 'Inactif'}',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () =>
                          _ouvrirModificationUtilisateur(utilisateur),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),

      // ================================================================
      // BOUTON D'ACTION
      // ================================================================
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          final index = _tabController.index;

          // Pas de bouton pour l'onglet Permissions.
          if (index == 2) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: index == 0
                ? _creerSite
                : index == 1
                    ? _creerPoste
                    : _ouvrirCreationUtilisateur,
            icon: const Icon(Icons.add),
            label: Text(
              index == 0
                  ? 'Nouveau site'
                  : index == 1
                      ? 'Nouveau poste'
                      : 'Nouvel utilisateur',
            ),
          );
        },
      ),
    );
  }
}

class _CataloguePermissions extends StatelessWidget {
  final AsyncValue<List<PermissionCatalogue>> asyncValue;
  final Future<void> Function() onRefresh;

  const _CataloguePermissions({required this.asyncValue, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Erreur : $error')),
      data: (permissions) => RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('Ce catalogue décrit les droits disponibles. Pour les attribuer, ouvrez un poste dans l’onglet Postes.'),
              ),
            ),
            const SizedBox(height: 8),
            ...permissions.map((permission) => ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(permission.libelle),
              subtitle: Text(permission.code),
            )),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET GÉNÉRIQUE POUR AFFICHER UNE LISTE
// ============================================================================

class _ConstruireListe<T> extends StatelessWidget {
  final AsyncValue<List<T>> asyncValue;
  final String Function(T item) titre;
  final String Function(T item) sousTitre;
  final IconData icone;
  final Future<void> Function() onRefresh;
  final void Function(T item)? onTap;

  const _ConstruireListe({
    required this.asyncValue,
    required this.titre,
    required this.sousTitre,
    required this.icone,
    required this.onRefresh,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Erreur : $error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Text(
                      'Aucun élément',
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
            ),
            itemBuilder: (context, index) {
              final item = items[index];

              return ListTile(
                leading: CircleAvatar(
                  child: Icon(icone),
                ),
                title: Text(
                  titre(item),
                ),
                subtitle: Text(
                  sousTitre(item),
                ),
                trailing: onTap == null ? null : const Icon(Icons.chevron_right),
                onTap: onTap == null ? null : () => onTap!(item),
              );
            },
          ),
        );
      },
    );
  }
}
