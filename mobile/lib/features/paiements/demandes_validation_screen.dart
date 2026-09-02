import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import 'paiements_list_screen.dart' show databaseProvider;

class DemandesValidationScreen extends ConsumerWidget {
  const DemandesValidationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Demandes de validation')),
      body: StreamBuilder<List<DemandeAvecPaiement>>(
        stream: db.watchDemandesEnAttente(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final demandes = snapshot.data!;
          if (demandes.isEmpty) {
            return const Center(child: Text('Aucune demande en attente'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: demandes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = demandes[index];
              return _CarteDemande(
                item: item,
                onApprouver: () => _traiter(context, ref, item, true),
                onRejeter: () => _traiter(context, ref, item, false),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _traiter(BuildContext context, WidgetRef ref,
      DemandeAvecPaiement item, bool approuver) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approuver ? 'Approuver la demande ?' : 'Rejeter la demande ?'),
        content: Text(approuver
            ? 'Le paiement de ${item.paiement.montant.toStringAsFixed(0)} FCFA sera marqué comme annulé.'
            : 'Le paiement reste valide, la demande est classée comme rejetée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    final db = ref.read(databaseProvider);
    await db.traiterDemande(
      demandeClientUuid: item.demande.clientUuid,
      approuver: approuver,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approuver ? 'Demande approuvée' : 'Demande rejetée')),
      );
    }
  }
}

class _CarteDemande extends StatelessWidget {
  final DemandeAvecPaiement item;
  final VoidCallback onApprouver;
  final VoidCallback onRejeter;

  const _CarteDemande({
    required this.item,
    required this.onApprouver,
    required this.onRejeter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${item.paiement.montant.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('En attente',
                    style: TextStyle(fontSize: 11, color: Colors.orange)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Motif : ${item.demande.motif ?? "—"}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRejeter,
                  child: const Text('Rejeter'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onApprouver,
                  child: const Text('Approuver'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
