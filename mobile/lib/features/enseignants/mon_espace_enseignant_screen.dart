import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'models/affectation.dart';

class MonEspaceEnseignantScreen extends ConsumerStatefulWidget {
  const MonEspaceEnseignantScreen({super.key});

  @override
  ConsumerState<MonEspaceEnseignantScreen> createState() => _MonEspaceEnseignantScreenState();
}

class _MonEspaceEnseignantScreenState extends ConsumerState<MonEspaceEnseignantScreen> {
  late Future<_DonneesEnseignant> _future;

  @override
  void initState() { super.initState(); _future = _charger(); }

  Future<_DonneesEnseignant> _charger() async {
    final dio = ref.read(dioProvider);
    final mois = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final responses = await Future.wait([
      dio.get('/mes-affectations'),
      dio.get('/mes-seances'),
      dio.get('/mon-rapport-mensuel', queryParameters: {'mois': mois}),
    ]);
    List<dynamic> liste(Response r) => r.data is Map ? List<dynamic>.from((r.data as Map)['data'] as List? ?? const []) : List<dynamic>.from(r.data as List);
    return _DonneesEnseignant(
      affectations: liste(responses[0]).map((x) => Affectation.fromJson(Map<String, dynamic>.from(x as Map))).toList(),
      seances: liste(responses[1]).map((x) => Map<String, dynamic>.from(x as Map)).toList(),
      rapport: Map<String, dynamic>.from(responses[2].data as Map),
    );
  }

  Future<void> _refresh() async { setState(() => _future = _charger()); await _future; }

  Future<void> _declarer(Affectation affectation) async {
    final value = await showDialog<_SeanceSaisie>(context: context, builder: (_) => const _SeanceDialog());
    if (value == null) return;
    try {
      await ref.read(dioProvider).post('/seances', data: {
        'affectation_id': affectation.id,
        'date_seance': value.date.toIso8601String().split('T').first,
        'statut': value.annulee ? 'annulee' : 'tenue',
        if (!value.annulee) 'nb_presents': value.presents,
        if (!value.annulee) 'nb_absents': value.absents,
        'commentaire': value.commentaire,
      });
      await _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Séance enregistrée.')));
    } on DioException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_erreur(error))));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mon espace enseignant')),
    body: FutureBuilder<_DonneesEnseignant>(future: _future, builder: (context, snapshot) {
      if (snapshot.hasError) return _Erreur(onRetry: _refresh, message: snapshot.error.toString());
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final data = snapshot.data!;
      final taux = data.rapport['taux_presence_moyen'];
      return RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Rapport du mois', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _Indicateur(label: 'Séances tenues', value: '${data.rapport['nb_seances_tenues']}'),
          _Indicateur(label: 'Annulées', value: '${data.rapport['nb_seances_annulees']}'),
          _Indicateur(label: 'Présence', value: taux == null ? '—' : '${(num.parse(taux.toString()) * 100).round()} %'),
        ]))),
        const SizedBox(height: 20),
        Text('Mes affectations', style: Theme.of(context).textTheme.titleLarge),
        if (data.affectations.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 28), child: Text('Aucune affectation active. Contactez la direction.')),
        ...data.affectations.map((a) => Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.menu_book_outlined)),
          title: Text(a.classe), subtitle: Text('${a.matiere.isEmpty ? 'Matière générale' : a.matiere} · ${a.anneeScolaire}'),
          trailing: FilledButton.tonal(onPressed: () => _declarer(a), child: const Text('Séance')),
        ))),
        const SizedBox(height: 16),
        Text('Dernières séances', style: Theme.of(context).textTheme.titleLarge),
        ...data.seances.take(8).map((s) => ListTile(leading: Icon(s['statut'] == 'annulee' ? Icons.event_busy_outlined : Icons.event_available_outlined), title: Text('${s['date_seance']} · ${s['statut'] == 'annulee' ? 'Annulée' : 'Tenue'}'), subtitle: s['statut'] == 'annulee' ? null : Text('${s['nb_presents'] ?? 0} présents · ${s['nb_absents'] ?? 0} absents'))),
      ]));
    }),
  );
}

class _DonneesEnseignant { final List<Affectation> affectations; final List<Map<String, dynamic>> seances; final Map<String, dynamic> rapport; const _DonneesEnseignant({required this.affectations, required this.seances, required this.rapport}); }
class _Indicateur extends StatelessWidget { final String label, value; const _Indicateur({required this.label, required this.value}); @override Widget build(BuildContext context) => Column(children: [Text(value, style: Theme.of(context).textTheme.titleLarge), Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)]); }
class _Erreur extends StatelessWidget { final Future<void> Function() onRetry; final String message; const _Erreur({required this.onRetry, required this.message}); @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Impossible de charger votre espace.\n$message', textAlign: TextAlign.center), const SizedBox(height: 12), OutlinedButton(onPressed: onRetry, child: const Text('Réessayer'))]))); }
class _SeanceSaisie { final DateTime date; final int presents, absents; final bool annulee; final String commentaire; const _SeanceSaisie({required this.date, required this.presents, required this.absents, required this.annulee, required this.commentaire}); }
class _SeanceDialog extends StatefulWidget { const _SeanceDialog(); @override State<_SeanceDialog> createState() => _SeanceDialogState(); }
class _SeanceDialogState extends State<_SeanceDialog> { final form = GlobalKey<FormState>(); final presents = TextEditingController(text: '0'), absents = TextEditingController(text: '0'), commentaire = TextEditingController(); DateTime date = DateTime.now(); bool annulee = false; @override void dispose() { presents.dispose(); absents.dispose(); commentaire.dispose(); super.dispose(); } @override Widget build(BuildContext context) => AlertDialog(title: const Text('Déclarer une séance'), content: Form(key: form, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) setState(() => date = d); }, icon: const Icon(Icons.event), label: Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}')), SwitchListTile(title: const Text('Séance annulée'), value: annulee, onChanged: (v) => setState(() => annulee = v)), if (!annulee) ...[TextFormField(controller: presents, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Présents'), validator: (v) => int.tryParse(v ?? '') == null ? 'Nombre requis' : null), TextFormField(controller: absents, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Absents'), validator: (v) => int.tryParse(v ?? '') == null ? 'Nombre requis' : null)], TextField(controller: commentaire, maxLines: 2, decoration: const InputDecoration(labelText: 'Commentaire (facultatif)'))]))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(context, _SeanceSaisie(date: date, presents: int.tryParse(presents.text) ?? 0, absents: int.tryParse(absents.text) ?? 0, annulee: annulee, commentaire: commentaire.text.trim())); }, child: const Text('Enregistrer'))]); }
String _erreur(DioException error) { final d = error.response?.data; return d is Map ? (d['message']?.toString() ?? d['detail']?.toString() ?? 'Enregistrement impossible.') : 'Connexion au serveur impossible.'; }
