import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/import_service.dart';
import 'data/eleve_repository.dart';
import 'providers/eleve_providers.dart';

class EleveEditScreen extends ConsumerStatefulWidget {
  final EleveAffichable eleve;

  const EleveEditScreen({super.key, required this.eleve});

  @override
  ConsumerState<EleveEditScreen> createState() => _EleveEditScreenState();
}

class _EleveEditScreenState extends ConsumerState<EleveEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prenomController;
  late final TextEditingController _nomController;
  late final TextEditingController _classeController;
  late DateTime? _dateNaissance;
  late String _sexe;
  late String _typeCours;
  late String _statut;
  bool _enregistrement = false;

  bool get _estEnAttente => widget.eleve.enAttenteDeSync;

  @override
  void initState() {
    super.initState();
    _prenomController = TextEditingController(text: widget.eleve.prenom);
    _nomController = TextEditingController(text: widget.eleve.nom);
    _classeController = TextEditingController(text: widget.eleve.classe);
    _dateNaissance = widget.eleve.dateNaissance;
    _sexe = widget.eleve.sexe == 'F' ? 'F' : 'M';
    _typeCours = widget.eleve.typeCours.isEmpty
        ? 'renforcement_regulier'
        : widget.eleve.typeCours;
    _statut = widget.eleve.statut == 'inactif' ? 'inactif' : 'actif';
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _classeController.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enregistrement = true);

    if (_estEnAttente) {
      await ref
          .read(eleveRepositoryProvider)
          .modifierEleveEnAttente(
            clientUuid: widget.eleve.clientUuidLocal!,
            nom: _nomController.text.trim(),
            prenom: _prenomController.text.trim(),
            sexe: _sexe,
            classe: _classeController.text.trim(),
            typeCours: _typeCours,
            dateNaissance: _dateNaissance,
          );
      final resultat = await ref.read(eleveSyncServiceProvider).synchroniser();
      if (resultat.erreur == null) {
        await ref.read(importServiceProvider).importerDonneesDuSite();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultat.erreur != null
                ? 'Corrigé localement — sync différée (${resultat.erreur})'
                : 'Élève corrigé et synchronisé',
          ),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    try {
      await ref
          .read(dioProvider)
          .patch(
            '/eleves/${widget.eleve.idServeur}',
            data: {
              'prenom': _prenomController.text.trim(),
              'nom': _nomController.text.trim(),
              'date_naissance': _dateNaissance
                  ?.toIso8601String()
                  .split('T')
                  .first,
              'sexe': _sexe,
              'site_id': widget.eleve.siteId,
              'classe': _classeController.text.trim(),
              'type_cours': _typeCours,
              'statut': _statut,
            },
          );
      await ref.read(importServiceProvider).importerDonneesDuSite();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informations de l\'élève modifiées.')),
      );
      Navigator.of(context).pop();
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : error.message ?? 'Modification impossible.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      setState(() => _enregistrement = false);
    }
  }

  Future<void> _choisirDateNaissance() async {
    final resultat = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime(2012, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (resultat != null) setState(() => _dateNaissance = resultat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier l\'élève')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(),
                    ),
                    validator: _obligatoire,
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
                    validator: _obligatoire,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_estEnAttente) ...[
              Text(
                'Matricule : ${widget.eleve.matricule}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
            ],
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
                    onChanged: (value) => setState(() => _sexe = value ?? 'M'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _statut,
              decoration: const InputDecoration(
                labelText: 'Statut de l’élève',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'actif', child: Text('Actif')),
                DropdownMenuItem(
                  value: 'inactif',
                  child: Text('Inactif — dossier conservé'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _statut = value ?? 'actif'),
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
                    validator: _obligatoire,
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
                    onChanged: (value) => setState(
                      () => _typeCours = value ?? 'renforcement_regulier',
                    ),
                  ),
                ),
              ],
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
                  : const Text('Enregistrer les modifications'),
            ),
          ],
        ),
      ),
    );
  }

  String? _obligatoire(String? value) {
    return value == null || value.trim().isEmpty ? 'Obligatoire' : null;
  }
}
