import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_service.dart';
import 'data/demande_validation_remote_service.dart';
import 'data/demande_validation_sync_service.dart';

/// Écran de traitement des demandes de validation — réservé aux postes
/// ayant `valider_actions_sensibles` (contrôlé aussi côté serveur, cet
/// écran ne fait que refléter cette exigence pour l'UX).
/// Vue directe sur l'API (pas de cache Drift) : voir
/// DemandeValidationRemoteService pour la justification.
class DemandesValidationScreen extends ConsumerStatefulWidget {
  const DemandesValidationScreen({super.key});

  @override
  ConsumerState<DemandesValidationScreen> createState() =>
      _DemandesValidationScreenState();
}

class _DemandesValidationScreenState
    extends ConsumerState<DemandesValidationScreen> {
  late Future<List<DemandeValidationServeur>> _futureDemandes;

  @override
  void initState() {
    super.initState();
    _futureDemandes = _charger();
  }

  Future<List<DemandeValidationServeur>> _charger() {
    return ref.read(demandeValidationRemoteServiceProvider).listerEnAttente();
  }

  Future<void> _rafraichir() async {
    // Pousse d'abord les demandes créées hors ligne sur cet appareil,
    // pour qu'elles apparaissent immédiatement dans la liste serveur.
    await ref.read(demandeValidationSyncServiceProvider).synchroniser();
    setState(() => _futureDemandes = _charger());
    await _futureDemandes;
  }

  Future<void> _traiter(DemandeValidationServeur demande, bool approuver) async {
    final commentaireController = TextEditingController();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approuver ? 'Approuver la demande ?' : 'Rejeter la demande ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              approuver
                  ? 'Le paiement de ${demande.montant.toStringAsFixed(0)} FCFA sera marqué comme annulé.'
                  : 'Le paiement reste valide, la demande est classée comme rejetée.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentaireController,
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
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

    try {
      await ref.read(demandeValidationRemoteServiceProvider).traiter(
            demandeId: demande.id,
            approuver: approuver,
            commentaire: commentaireController.text.trim(),
          );
      setState(() => _futureDemandes = _charger());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approuver ? 'Demande approuvée' : 'Demande rejetée')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec du traitement : $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).whenOrNull(data: (v) => v);
    final autorise = session?.permissions.contains('valider_actions_sensibles') == true;

    if (!autorise) {
      return Scaffold(
        appBar: AppBar(title: const Text('Demandes de validation')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              "Ton poste n'a pas la permission de traiter les demandes de validation.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Demandes de validation')),
      body: RefreshIndicator(
        onRefresh: _rafraichir,
        child: FutureBuilder<List<DemandeValidationServeur>>(
          future: _futureDemandes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Erreur : ${snapshot.error}', textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ],
              );
            }
            final demandes = snapshot.data ?? const [];
            if (demandes.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(child: Text('Aucune demande en attente')),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: demandes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = demandes[index];
                return _CarteDemande(
                  item: item,
                  onApprouver: () => _traiter(item, true),
                  onRejeter: () => _traiter(item, false),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CarteDemande extends StatelessWidget {
  final DemandeValidationServeur item;
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
              Expanded(
                child: Text(
                  item.eleveNom,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'En attente',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${item.montant.toStringAsFixed(0)} FCFA — ${item.modePaiement}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 2),
          Text(
            'Motif : ${item.motif ?? "—"}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: onRejeter, child: const Text('Rejeter')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(onPressed: onApprouver, child: const Text('Approuver')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}