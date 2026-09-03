import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../../data/database.dart';
import 'paiements_list_screen.dart' show databaseProvider;

class EncaissementFormScreen extends ConsumerStatefulWidget {
  final EcheanceAvecSolde echeance;

  const EncaissementFormScreen({super.key, required this.echeance});

  @override
  ConsumerState<EncaissementFormScreen> createState() =>
      _EncaissementFormScreenState();
}

class _EncaissementFormScreenState
    extends ConsumerState<EncaissementFormScreen> {
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String modePaiement = 'especes';
  bool enregistrement = false;

  @override
  void dispose() {
    _montantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _definirMontant(double montant) {
    setState(() {
      _montantController.text = montant.toStringAsFixed(0);
    });
  }

  Future<void> _enregistrerPaiement() async {
    final montant = double.tryParse(_montantController.text.trim());
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entre un montant valide')));
      return;
    }

    setState(() => enregistrement = true);

    final db = ref.read(databaseProvider);
    final clientUuid = const Uuid().v4();

    await db
        .into(db.paiements)
        .insertOnConflictUpdate(
          PaiementsCompanion.insert(
            clientUuid: clientUuid,
            echeanceId: widget.echeance.echeanceId,
            montant: montant,
            modePaiement: modePaiement,
            note: _noteController.text.trim().isEmpty
                ? const Value.absent()
                : Value(_noteController.text.trim()),
            dateLocale: DateTime.now(),
          ),
        );

    if (!mounted) return;
    setState(() => enregistrement = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Paiement enregistré')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.echeance;
    final resteAffiche = e.montantRestant.clamp(0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('Enregistrer un paiement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte élève / échéance concernée
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      e.eleveNom.isNotEmpty ? e.eleveNom[0] : '?',
                      style: const TextStyle(color: Colors.teal),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.eleveNom,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          e.classe,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Reste à payer',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${resteAffiche.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'MONTANT REÇU',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _montantController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 22),
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: 'FCFA',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _definirMontant(5000),
                  child: const Text('5 000 FCFA'),
                ),
                OutlinedButton(
                  onPressed: () => _definirMontant(10000),
                  child: const Text('10 000 FCFA'),
                ),
                OutlinedButton(
                  onPressed: () => _definirMontant(
                    resteAffiche > 0 ? resteAffiche.toDouble() : 0,
                  ),
                  child: const Text('Tout payer'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Text(
              'MODE DE PAIEMENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            _OptionModePaiement(
              titre: 'Espèces',
              sousTitre: 'Paiement en liquide',
              couleur: Colors.green,
              valeur: 'especes',
              groupe: modePaiement,
              onChanged: (v) => setState(() => modePaiement = v),
            ),
            _OptionModePaiement(
              titre: 'Orange Money',
              sousTitre: 'Mobile money Orange',
              couleur: Colors.orange,
              valeur: 'orange_money',
              groupe: modePaiement,
              onChanged: (v) => setState(() => modePaiement = v),
            ),
            _OptionModePaiement(
              titre: 'Moov Money',
              sousTitre: 'Mobile money Moov',
              couleur: Colors.blue,
              valeur: 'moov_money',
              groupe: modePaiement,
              onChanged: (v) => setState(() => modePaiement = v),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optionnel)',
                hintText: 'Ex : paiement partiel',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.cloud_off, size: 14, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  'Sera synchronisé dès le retour de la connexion',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: enregistrement ? null : _enregistrerPaiement,
                child: enregistrement
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionModePaiement extends StatelessWidget {
  final String titre;
  final String sousTitre;
  final Color couleur;
  final String valeur;
  final String groupe;
  final ValueChanged<String> onChanged;

  const _OptionModePaiement({
    required this.titre,
    required this.sousTitre,
    required this.couleur,
    required this.valeur,
    required this.groupe,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectionne = groupe == valeur;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => onChanged(valeur),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: selectionne ? couleur : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: couleur),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      sousTitre,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: valeur,
                // ignore: deprecated_member_use
                groupValue: groupe,
                // ignore: deprecated_member_use
                onChanged: (v) => onChanged(v!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
