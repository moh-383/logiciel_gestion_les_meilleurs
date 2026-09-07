import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/poste.dart';
import '../models/site.dart';
import '../models/utilisateur.dart';
import '../providers/administration_providers.dart';

class UtilisateurModificationScreen extends ConsumerStatefulWidget {
  final Utilisateur utilisateur;

  const UtilisateurModificationScreen({
    super.key,
    required this.utilisateur,
  });

  @override
  ConsumerState<UtilisateurModificationScreen> createState() =>
      _UtilisateurModificationScreenState();
}

class _UtilisateurModificationScreenState
    extends ConsumerState<UtilisateurModificationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomController;
  late final TextEditingController _telephoneController;
  final _motDePasseController = TextEditingController();

  String? _posteId;
  String? _siteId;
  late bool _actif;

  bool _modificationEnCours = false;
  bool _motDePasseVisible = false;

  @override
  void initState() {
    super.initState();

    _nomController = TextEditingController(
      text: widget.utilisateur.nom,
    );

    _telephoneController = TextEditingController(
      text: widget.utilisateur.telephone,
    );

    _posteId = widget.utilisateur.posteId;
    _siteId = widget.utilisateur.siteId;
    _actif = widget.utilisateur.isActive;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _modifierUtilisateur() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _modificationEnCours = true;
    });

    try {
      await ref
          .read(administrationRepositoryProvider)

.modifierUtilisateur(
  widget.utilisateur.id,
  nom: _nomController.text.trim(),
  telephone: _telephoneController.text.trim(),
  posteId: _posteId,
  siteId: _siteId,
  actif: _actif,
  motDePasse: _motDePasseController.text,
);

      ref.invalidate(utilisateursProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Utilisateur modifié avec succès.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur : $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _modificationEnCours = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postesAsync = ref.watch(postesProvider);
    final sitesAsync = ref.watch(sitesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modifier l’utilisateur',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le téléphone est obligatoire.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _motDePasseController,
              obscureText: !_motDePasseVisible,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                hintText: 'Laisser vide pour conserver l’actuel',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _motDePasseVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _motDePasseVisible =
                          !_motDePasseVisible;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    value.length < 6) {
                  return 'Le mot de passe doit contenir au moins 6 caractères.';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            postesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(
                'Impossible de charger les postes : $error',
              ),
              data: (postes) {
                return DropdownButtonFormField<String>(
                  value: _posteId,
                  decoration: const InputDecoration(
                    labelText: 'Poste',
                    border: OutlineInputBorder(),
                  ),
                  items: postes.map((Poste poste) {
                    return DropdownMenuItem<String>(
                      value: poste.id,
                      child: Text(poste.nom),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _posteId = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            sitesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(
                'Impossible de charger les sites : $error',
              ),
              data: (sites) {
                return DropdownButtonFormField<String>(
                  value: _siteId,
                  decoration: const InputDecoration(
                    labelText: 'Site',
                    border: OutlineInputBorder(),
                  ),
                  items: sites.map((Site site) {
                    return DropdownMenuItem<String>(
                      value: site.id,
                      child: Text(site.nom),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _siteId = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Compte actif',
              ),
              subtitle: Text(
                _actif
                    ? 'L’utilisateur peut se connecter.'
                    : 'L’utilisateur ne peut plus se connecter.',
              ),
              value: _actif,
              onChanged: (value) {
                setState(() {
                  _actif = value;
                });
              },
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _modificationEnCours
                  ? null
                  : _modifierUtilisateur,
              icon: _modificationEnCours
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _modificationEnCours
                    ? 'Enregistrement...'
                    : 'Enregistrer les modifications',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
