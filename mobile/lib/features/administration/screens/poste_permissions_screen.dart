import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/permission_catalogue.dart';
import '../providers/administration_providers.dart';

/// Écran explicite d'affectation : le catalogue n'est pas un menu de modules,
/// ce sont les droits que l'on accorde au poste sélectionné.
class PostePermissionsScreen extends ConsumerStatefulWidget {
  final String posteId;
  final String posteNom;

  const PostePermissionsScreen({
    super.key,
    required this.posteId,
    required this.posteNom,
  });

  @override
  ConsumerState<PostePermissionsScreen> createState() =>
      _PostePermissionsScreenState();
}

class _PostePermissionsScreenState
    extends ConsumerState<PostePermissionsScreen> {
  Set<String>? _selection;
  bool _enregistrement = false;

  Future<void> _enregistrer() async {
    final selection = _selection;
    if (selection == null) return;
    setState(() => _enregistrement = true);
    try {
      await ref.read(administrationRepositoryProvider).definirPermissions(
            posteId: widget.posteId,
            codesPermission: selection.toList()..sort(),
          );
      ref.invalidate(postesProvider);
      ref.invalidate(posteDetailProvider(widget.posteId));
      await ref.read(postesProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions enregistrées.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enregistrement impossible : $error')),
      );
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poste = ref.watch(posteDetailProvider(widget.posteId));
    final catalogue = ref.watch(permissionsCatalogueProvider);
    if (_selection == null && poste.hasValue) {
      _selection = {...poste.requireValue.permissions};
    }

    return Scaffold(
      appBar: AppBar(title: Text('Permissions - ${widget.posteNom}')),
      body: poste.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (_) => catalogue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Erreur : $error')),
          data: (permissions) => ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Coche les droits accordés à ce poste. Ils sont appliqués côté serveur.',
                ),
              ),
              ...permissions.map(_lignePermission),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _selection == null || _enregistrement ? null : _enregistrer,
          icon: _enregistrement
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_enregistrement ? 'Enregistrement...' : 'Enregistrer'),
        ),
      ),
    );
  }

  Widget _lignePermission(PermissionCatalogue permission) {
    final selection = _selection!;
    return CheckboxListTile(
      value: selection.contains(permission.code),
      title: Text(permission.libelle),
      subtitle: Text(permission.code),
      onChanged: (actif) => setState(() {
        actif == true
            ? selection.add(permission.code)
            : selection.remove(permission.code);
      }),
    );
  }
}
