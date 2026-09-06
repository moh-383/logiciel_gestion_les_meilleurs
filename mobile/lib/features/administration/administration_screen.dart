import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

class AdministrationScreen extends ConsumerStatefulWidget {
  const AdministrationScreen({super.key});

  @override
  ConsumerState<AdministrationScreen> createState() =>
      _AdministrationScreenState();
}

class _AdministrationScreenState extends ConsumerState<AdministrationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _chargement = true;
  String? _erreur;
  List<Map<String, dynamic>> _sites = [];
  List<Map<String, dynamic>> _postes = [];
  List<Map<String, dynamic>> _permissions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final reponses = await Future.wait([
        dio.get('/sites', queryParameters: {'limit': 100}),
        dio.get('/postes', queryParameters: {'limit': 100}),
        dio.get('/permissions', queryParameters: {'limit': 100}),
      ]);
      if (!mounted) return;
      setState(() {
        _sites = _liste(reponses[0].data);
        _postes = _liste(reponses[1].data);
        _permissions = _liste(reponses[2].data);
        _chargement = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = _messageErreur(error);
      });
    }
  }

  List<Map<String, dynamic>> _liste(Object? data) {
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    if (data is List) {
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return [];
  }

  String _messageErreur(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return error.message ?? 'Impossible de charger l’administration.';
  }

  Future<void> _creerPoste() async {
    final nom = await _demanderTexte('Nouveau poste', 'Nom du poste');
    if (nom == null || nom.trim().isEmpty) return;
    try {
      await ref
          .read(dioProvider)
          .post(
            '/postes',
            data: {
              'nom': nom.trim(),
              'tous_sites': false,
              'permissions': const <String>[],
            },
          );
      await _charger();
    } on DioException catch (error) {
      _afficherErreur(_messageErreur(error));
    }
  }

  Future<void> _creerSite() async {
    final nom = await _demanderTexte('Nouveau site', 'Nom du site');
    if (nom == null || nom.trim().isEmpty) return;
    try {
      await ref.read(dioProvider).post('/sites', data: {'nom': nom.trim()});
      await _charger();
    } on DioException catch (error) {
      _afficherErreur(_messageErreur(error));
    }
  }

  Future<String?> _demanderTexte(String titre, String label) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titre),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _afficherErreur(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sites'),
            Tab(text: 'Postes'),
            Tab(text: 'Permissions'),
          ],
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
          ? Center(child: Text(_erreur!))
          : RefreshIndicator(
              onRefresh: _charger,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ListeAdministration(
                    items: _sites,
                    titre: (item) => item['nom']?.toString() ?? '',
                    sousTitre: (item) =>
                        item['adresse']?.toString() ?? 'Adresse non renseignée',
                  ),
                  _ListeAdministration(
                    items: _postes,
                    titre: (item) => item['nom']?.toString() ?? '',
                    sousTitre: (item) => (item['tous_sites'] == true)
                        ? 'Accès multi-sites'
                        : 'Accès limité au site',
                  ),
                  _ListeAdministration(
                    items: _permissions,
                    titre: (item) => item['libelle']?.toString() ?? '',
                    sousTitre: (item) => item['code']?.toString() ?? '',
                  ),
                ],
              ),
            ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) => FloatingActionButton.extended(
          onPressed: _tabController.index == 0
              ? _creerSite
              : _tabController.index == 1
              ? _creerPoste
              : null,
          icon: const Icon(Icons.add),
          label: Text(
            _tabController.index == 0 ? 'Nouveau site' : 'Nouveau poste',
          ),
        ),
      ),
    );
  }
}

class _ListeAdministration extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) titre;
  final String Function(Map<String, dynamic>) sousTitre;

  const _ListeAdministration({
    required this.items,
    required this.titre,
    required this.sousTitre,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180, child: Center(child: Text('Aucun élément'))),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.tune)),
        title: Text(titre(items[index])),
        subtitle: Text(sousTitre(items[index])),
      ),
    );
  }
}
