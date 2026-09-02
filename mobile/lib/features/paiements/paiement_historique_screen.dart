import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import 'paiements_list_screen.dart' show databaseProvider;

class PaiementHistoriqueScreen extends ConsumerWidget {
  final String echeanceId;
  final String eleveNom;

  const PaiementHistoriqueScreen({
    super.key,
    required this.echeanceId,
    required this.eleveNom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Paiements — $eleveNom')),
      body: StreamBuilder<List<PaiementAvecDemande>>(
        stream: db.watchPaiementsDeLEcheance(echeanceId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final paiements = snapshot.data!;
          if (paiements.isEmpty) {
            return const Center(child: Text('Aucun paiement enregistré'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: paiements.length,
            separatorBuilder: (_,_) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = paiements[index];
              final p = item.paiement;
              final annule = p.statut == 'annule';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${p.montant.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    decoration: annule ? TextDecoration.lineThrough : null,
                    color: annule ? Colors.grey : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${_libelleMode(p.modePaiement)} · ${_formatDate(p.dateLocale)}'
                  '${p.syncStatus == 'en_attente' ? ' · non synchronisé' : ''}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: _actionPourPaiement(context, ref, item, annule),
              );
            },
          );
        },
      ),
    );
  }

  Widget _actionPourPaiement(BuildContext context, WidgetRef ref,
      PaiementAvecDemande item, bool annule) {
    if (annule) {
      return const Text('Annulé',
          style: TextStyle(fontSize: 12, color: Colors.red));
    }
    if (item.demandeEnAttente) {
      return const Text('Demande en attente',
          style: TextStyle(fontSize: 12, color: Colors.orange));
    }
    return TextButton(
      onPressed: () => _ouvrirDialogueAnnulation(context, ref, item.paiement),
      child: const Text('Demander annulation'),
    );
  }

  Future<void> _ouvrirDialogueAnnulation(
      BuildContext context, WidgetRef ref, Paiement paiement) async {
    final motifController = TextEditingController();

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demander une annulation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Paiement de ${paiement.montant.toStringAsFixed(0)} FCFA du ${_formatDate(paiement.dateLocale)}.'),
            const SizedBox(height: 8),
            const Text(
              'Cette demande sera soumise au responsable de site. '
              'Le paiement reste valide tant qu\'elle n\'est pas approuvée.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motifController,
              decoration: const InputDecoration(
                labelText: 'Motif',
                hintText: 'Ex : erreur de saisie sur le montant',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Envoyer la demande'),
          ),
        ],
      ),
    );

    if (confirme != true) return;
    if (motifController.text.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le motif est obligatoire')),
        );
      }
      return;
    }

    final db = ref.read(databaseProvider);
    await db.demanderAnnulationPaiement(
      paiementClientUuid: paiement.clientUuid,
      motif: motifController.text.trim(),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée au responsable de site')),
      );
    }
  }

  String _libelleMode(String mode) {
    switch (mode) {
      case 'orange_money':
        return 'Orange Money';
      case 'moov_money':
        return 'Moov Money';
      default:
        return 'Espèces';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
