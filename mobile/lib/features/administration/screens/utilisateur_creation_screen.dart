import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/poste.dart';
import '../models/site.dart';
import '../providers/administration_providers.dart';

class UtilisateurCreationScreen extends ConsumerStatefulWidget {
  const UtilisateurCreationScreen({super.key});

  @override
  ConsumerState<UtilisateurCreationScreen> createState() =>
      _UtilisateurCreationScreenState();
}

class _UtilisateurCreationScreenState
    extends ConsumerState<UtilisateurCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _motDePasseController = TextEditingController();

  String? _posteId;
  String? _siteId;
  bool _creationEnCours = false;
  bool _motDePasseVisible = false;

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _creerUtilisateur() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _creationEnCours = true;
    });

    try {
      await ref.read(administrationRepositoryProvider).creerUtilisateur(
            nom: _nomController.text.trim(),
            telephone: _telephoneController.text.trim(),
            motDePasse: _motDePasseController.text,
            posteId: _posteId,
            siteId: _siteId,
          );

      ref.invalidate(utilisateursProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur créé avec succès.'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creationEnCours = false;
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
        title: const Text('Nouvel utilisateur'),
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
                labelText: 'Mot de passe',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _motDePasseVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _motDePasseVisible = !_motDePasseVisible;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le mot de passe est obligatoire.';
                }

                if (value.length < 6) {
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

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed:
                  _creationEnCours ? null : _creerUtilisateur,
              icon: _creationEnCours
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.person_add),
              label: Text(
                _creationEnCours
                    ? 'Création...'
                    : 'Créer l’utilisateur',
              ),
            ),
          ],
        ),
      ),
    );
  }
}