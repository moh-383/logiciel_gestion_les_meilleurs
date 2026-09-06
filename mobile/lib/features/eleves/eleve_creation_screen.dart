import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/eleves/providers/eleve_providers.dart';

import '../../core/auth_service.dart';
import '../../core/import_service.dart';

/// Écran de création d'élève (maquette écran 4). Le site est
/// automatiquement celui de l'utilisateur connecté — cohérent avec le
/// cloisonnement par site imposé côté serveur, on ne laisse pas le
/// client choisir un autre site.
class EleveCreationScreen extends ConsumerStatefulWidget {
  const EleveCreationScreen({super.key});

  @override
  ConsumerState<EleveCreationScreen> createState() =>
      _EleveCreationScreenState();
}

class _EleveCreationScreenState extends ConsumerState<EleveCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _classeController = TextEditingController();
  final _contactNomController = TextEditingController();
  final _contactTelephoneController = TextEditingController();
  DateTime? _dateNaissance;
  String _sexe = 'M';
  String _typeCours = 'renforcement_regulier';
  bool _enregistrement = false;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _classeController.dispose();
    _contactNomController.dispose();
    _contactTelephoneController.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enregistrement = true);

    final session = await ref.read(tokenStoreProvider).readSession();
    final siteId = session?.siteId;
    if (siteId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aucun site associé à ton compte : impossible de créer l\'élève.',
            ),
          ),
        );
        setState(() => _enregistrement = false);
      }
      return;
    }

    await ref
        .read(eleveRepositoryProvider)
        .creerEleveLocal(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          sexe: _sexe,
          siteId: siteId,
          classe: _classeController.text.trim(),
          typeCours: _typeCours,
          dateNaissance: _dateNaissance,
          contactNom: _contactNomController.text.trim().isEmpty
              ? null
              : _contactNomController.text.trim(),
          contactTelephone: _contactTelephoneController.text.trim().isEmpty
              ? null
              : _contactTelephoneController.text.trim(),
          contactLien: 'parent',
        );

    // Attend la réponse pour distinguer une création synchronisée d'une
    // création locale qui sera retentée plus tard.
    final resultatSync = await ref
        .read(eleveSyncServiceProvider)
        .synchroniser();
    if (resultatSync.erreur == null) {
      await ref.read(importServiceProvider).importerDonneesDuSite();
    }

    if (!mounted) return;
    setState(() => _enregistrement = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resultatSync.erreur != null
              ? 'Élève créé localement — sync différée (${resultatSync.erreur})'
              : 'Élève créé et synchronisé avec le serveur',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _choisirDateNaissance() async {
    final resultat = await showDatePicker(
      context: context,
      initialDate: DateTime(2012, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (resultat != null) setState(() => _dateNaissance = resultat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel élève')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'INFORMATIONS PERSONNELLES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _choisirDateNaissance,
                    child: Text(
                      _dateNaissance == null
                          ? 'Date de naissance'
                          : '${_dateNaissance!.day.toString().padLeft(2, '0')}/${_dateNaissance!.month.toString().padLeft(2, '0')}/${_dateNaissance!.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sexe,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sexe',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('Masculin')),
                      DropdownMenuItem(value: 'F', child: Text('Féminin')),
                    ],
                    onChanged: (v) => setState(() => _sexe = v ?? 'M'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'SCOLARITÉ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Le matricule sera attribué automatiquement par le serveur.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _classeController,
                    decoration: const InputDecoration(
                      labelText: 'Classe / Groupe',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _typeCours,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Type de cours',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'renforcement_regulier',
                        child: Text(
                          'Renforcement régulier',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'vacances',
                        child: Text('Vacances'),
                      ),
                    ],
                    onChanged: (v) => setState(
                      () => _typeCours = v ?? 'renforcement_regulier',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'CONTACT PARENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contactNomController,
              decoration: const InputDecoration(
                labelText: 'Nom du parent',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactTelephoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _enregistrement ? null : _enregistrer,
              child: _enregistrement
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer l\'élève'),
            ),
          ],
        ),
      ),
    );
  }
}
