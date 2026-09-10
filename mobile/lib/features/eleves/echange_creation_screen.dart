import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/echange_providers.dart';

class EchangeCreationScreen extends ConsumerStatefulWidget {
  final String eleveId;

  const EchangeCreationScreen({super.key, required this.eleveId});

  @override
  ConsumerState<EchangeCreationScreen> createState() => _EchangeCreationScreenState();
}

class _EchangeCreationScreenState extends ConsumerState<EchangeCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _typeEchange = 'appel';
  DateTime _dateEchange = DateTime.now();
  bool _enregistrement = false;

  static const _types = {
    'appel': 'Appel téléphonique',
    'reunion': 'Réunion',
    'incident_discipline': 'Incident disciplinaire',
    'remarque': 'Remarque',
    'autre': 'Autre',
  };

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enregistrement = true);

    await ref.read(echangeRepositoryProvider).creerEchangeLocal(
          eleveId: widget.eleveId,
          typeEchange: _typeEchange,
          titre: _titreController.text.trim(),
          description: _descriptionController.text.trim(),
          dateEchange: _dateEchange,
        );

    final erreur = await ref.read(echangeSyncServiceProvider).synchroniser();

    if (!mounted) return;
    setState(() => _enregistrement = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          erreur != null
              ? 'Enregistré localement — sync différée ($erreur)'
              : 'Échange enregistré et synchronisé',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateEchange,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _dateEchange = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel échange')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _typeEchange,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: _types.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _typeEchange = v ?? 'appel'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titreController,
              decoration: const InputDecoration(labelText: 'Titre', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Détails (optionnel)', border: OutlineInputBorder()),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _choisirDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                '${_dateEchange.day.toString().padLeft(2, '0')}/${_dateEchange.month.toString().padLeft(2, '0')}/${_dateEchange.year}',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _enregistrement ? null : _enregistrer,
              child: _enregistrement
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}