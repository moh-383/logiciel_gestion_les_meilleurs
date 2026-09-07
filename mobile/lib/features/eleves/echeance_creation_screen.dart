import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/import_service.dart';
import 'data/eleve_repository.dart';

class EcheanceCreationScreen extends ConsumerStatefulWidget {
  final EleveAffichable eleve;

  const EcheanceCreationScreen({super.key, required this.eleve});

  @override
  ConsumerState<EcheanceCreationScreen> createState() =>
      _EcheanceCreationScreenState();
}

class _EcheanceCreationScreenState
    extends ConsumerState<EcheanceCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  DateTime _dateEcheance = DateTime.now();
  bool _enregistrement = false;

  @override
  void dispose() {
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enregistrement = true);

    try {
      await ref
          .read(dioProvider)
          .post(
            '/eleves/${widget.eleve.idServeur}/echeances',
            data: {
              'montant_du': int.parse(_montantController.text.trim()),
              'date_echeance': _dateEcheance.toIso8601String().split('T').first,
            },
          );
      await ref.read(importServiceProvider).importerDonneesDuSite();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échéance créée avec succès.')),
      );
      Navigator.of(context).pop();
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      final message = _messageErreur(data, error.message);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      setState(() => _enregistrement = false);
    }
  }

  String _messageErreur(Object? data, String? messageParDefaut) {
    if (data is Map) {
      final message = data['message'] ?? data['detail'];
      if (message != null) return message.toString();
    }
    return messageParDefaut ?? 'Création impossible.';
  }

  Future<void> _choisirDate() async {
    final resultat = await showDatePicker(
      context: context,
      initialDate: _dateEcheance,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (resultat != null) setState(() => _dateEcheance = resultat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle échéance')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${widget.eleve.prenom} ${widget.eleve.nom}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _montantController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant dû',
                suffixText: 'FCFA',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final montant = int.tryParse(value?.trim() ?? '');
                return montant == null || montant <= 0
                    ? 'Saisis un montant entier supérieur à zéro.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _choisirDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                'Échéance : ${_dateEcheance.day.toString().padLeft(2, '0')}/'
                '${_dateEcheance.month.toString().padLeft(2, '0')}/'
                '${_dateEcheance.year}',
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
                  : const Text('Créer l\'échéance'),
            ),
          ],
        ),
      ),
    );
  }
}
