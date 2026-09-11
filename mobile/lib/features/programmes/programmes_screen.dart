import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';

typedef Json = Map<String, dynamic>;

List<Json> _list(dynamic raw) {
  final data = raw is Map ? raw['data'] ?? raw['results'] ?? const [] : raw;
  return data is List ? data.map((x) => Json.from(x as Map)).toList() : const [];
}
String _s(dynamic value) => value?.toString() ?? '';
String _status(dynamic value) => {
  'brouillon': 'Brouillon', 'ouvert': 'Ouvert', 'complet': 'Complet',
  'cloture': 'Clôturé', 'termine': 'Terminé', 'archive': 'Archivé',
  'annule': 'Annulé', 'confirmee': 'Confirmée',
}[value] ?? _s(value);
String _type(dynamic value) => {'vacances': 'Vacances', 'bac': 'Préparation Bac', 'bepc': 'Préparation BEPC'}[value] ?? _s(value);
String _error(DioException e) { final d = e.response?.data; return d is Map ? _s(d['detail'] ?? d['message'] ?? 'Enregistrement impossible.') : 'Connexion au serveur impossible.'; }
void _notice(BuildContext c, String text) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(text)));

class ProgrammesScreen extends ConsumerStatefulWidget {
  final bool peutGerer;
  const ProgrammesScreen({super.key, required this.peutGerer});
  @override ConsumerState<ProgrammesScreen> createState() => _ProgrammesScreenState();
}

class _ProgrammesScreenState extends ConsumerState<ProgrammesScreen> {
  late Future<List<Json>> _items;
  @override void initState() { super.initState(); _items = _load(); }
  Future<List<Json>> _load() async => _list((await ref.read(dioProvider).get('/programmes')).data);
  Future<void> _refresh() async { setState(() => _items = _load()); await _items; }
  Future<void> _newProgramme() async {
    final data = await programmeForm(context); if (data == null) return;
    try { await ref.read(dioProvider).post('/programmes', data: data); await _refresh(); if (mounted) _notice(context, 'Programme créé. Ajoutez ensuite une session.'); }
    on DioException catch (e) { if (mounted) _notice(context, _error(e)); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Programmes spéciaux')),
    floatingActionButton: widget.peutGerer ? FloatingActionButton.extended(onPressed: _newProgramme, icon: const Icon(Icons.add), label: const Text('Programme')) : null,
    body: FutureBuilder<List<Json>>(future: _items, builder: (context, snap) {
      if (snap.hasError) return Retry(onRetry: _refresh, error: snap.error!);
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      if (snap.data!.isEmpty) return RefreshIndicator(onRefresh: _refresh, child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: const [SizedBox(height: 240), Center(child: Text('Aucun programme configuré.'))]));
      return RefreshIndicator(onRefresh: _refresh, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: snap.data!.length, separatorBuilder: (_, _) => const SizedBox(height: 10), itemBuilder: (_, i) { final p = snap.data![i]; return Card(child: ListTile(leading: CircleAvatar(child: Icon(p['type'] == 'vacances' ? Icons.beach_access_outlined : Icons.workspace_premium_outlined)), title: Text(_s(p['nom'])), subtitle: Text('${_type(p['type'])} · ${_s(p['annee_scolaire'])} · ${_status(p['statut'])}'), trailing: const Icon(Icons.chevron_right), onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => ProgrammeDetail(programme: p, peutGerer: widget.peutGerer))); await _refresh(); })); }));
    }),
  );
}

class ProgrammeDetail extends ConsumerStatefulWidget { final Json programme; final bool peutGerer; const ProgrammeDetail({super.key, required this.programme, required this.peutGerer}); @override ConsumerState<ProgrammeDetail> createState() => _ProgrammeDetailState(); }
class _ProgrammeDetailState extends ConsumerState<ProgrammeDetail> {
  late Future<List<Json>> _sessions;
  @override void initState() { super.initState(); _sessions = _load(); }
  Future<List<Json>> _load() async => _list((await ref.read(dioProvider).get('/programmes/${widget.programme['id']}/sessions')).data);
  Future<void> _refresh() async { setState(() => _sessions = _load()); await _sessions; }
  Future<void> _newSession() async {
    try {
      final sites = _list((await ref.read(dioProvider).get('/sites?limit=100')).data);
      if (!mounted) return;
      final data = await sessionForm(context, sites); if (data == null) return;
      await ref.read(dioProvider).post('/programmes/${widget.programme['id']}/sessions', data: data); await _refresh(); if (mounted) _notice(context, 'Session créée.');
    } on DioException catch (e) { if (mounted) _notice(context, _error(e)); }
  }
  Future<void> _open() async { try { await ref.read(dioProvider).post('/programmes/${widget.programme['id']}/ouvrir'); if (mounted) _notice(context, 'Programme ouvert : les inscriptions sont possibles.'); } on DioException catch (e) { if (mounted) _notice(context, _error(e)); } }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_s(widget.programme['nom'])), actions: [if (widget.peutGerer && widget.programme['statut'] != 'ouvert') IconButton(onPressed: _open, tooltip: 'Ouvrir le programme', icon: const Icon(Icons.lock_open_outlined)), if (widget.programme['type'] != 'vacances') IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultatsScreen(programme: widget.programme))), tooltip: 'Résultats et statistiques', icon: const Icon(Icons.bar_chart_outlined))]),
    floatingActionButton: widget.peutGerer ? FloatingActionButton.extended(onPressed: _newSession, icon: const Icon(Icons.add), label: const Text('Session')) : null,
    body: FutureBuilder<List<Json>>(future: _sessions, builder: (context, snap) { if (snap.hasError) return Retry(onRetry: _refresh, error: snap.error!); if (!snap.hasData) return const Center(child: CircularProgressIndicator()); return RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.all(16), children: [Text('${_type(widget.programme['type'])} · ${_s(widget.programme['annee_scolaire'])}', style: Theme.of(context).textTheme.titleMedium), if ((widget.programme['matieres'] as List? ?? []).isNotEmpty) Text('Matières : ${(widget.programme['matieres'] as List).join(', ')}'), const SizedBox(height: 20), Text('Sessions', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), if (snap.data!.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Aucune session sur les sites accessibles.'))), ...snap.data!.map((s) => Card(child: ListTile(leading: const Icon(Icons.calendar_month_outlined), title: Text(_s(s['intitule'])), subtitle: Text('${_s(s['date_debut'])} → ${_s(s['date_fin'])}\n${s['effectif_confirme']}/${s['capacite']} inscrits · ${_status(s['statut'])}'), isThreeLine: true, trailing: const Icon(Icons.chevron_right), onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => SessionDetail(session: s, peutGerer: widget.peutGerer))); await _refresh(); }))) ])); }),
  );
}

class SessionDetail extends ConsumerStatefulWidget { final Json session; final bool peutGerer; const SessionDetail({super.key, required this.session, required this.peutGerer}); @override ConsumerState<SessionDetail> createState() => _SessionDetailState(); }
class _SessionDetailState extends ConsumerState<SessionDetail> with SingleTickerProviderStateMixin {
  late TabController _tabs; late Future<List<Json>> _groupes;
  @override void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this)..addListener(() { if (!_tabs.indexIsChanging) setState(() {}); }); _groupes = _load(); }
  @override void dispose() { _tabs.dispose(); super.dispose(); }
  Future<List<Json>> _load() async => _list((await ref.read(dioProvider).get('/sessions-programmes/${widget.session['id']}/groupes')).data);
  Future<void> _refresh() async { setState(() => _groupes = _load()); await _groupes; }
  Future<void> _newGroup() async { final data = await groupForm(context); if (data == null) return; try { await ref.read(dioProvider).post('/sessions-programmes/${widget.session['id']}/groupes', data: data); await _refresh(); if (mounted) _notice(context, 'Groupe créé. Définissez maintenant son tarif.'); } on DioException catch (e) { if (mounted) _notice(context, _error(e)); } }
  Future<void> _transition(String action) async { try { await ref.read(dioProvider).post('/sessions-programmes/${widget.session['id']}/$action'); if (mounted) _notice(context, 'Statut mis à jour.'); } on DioException catch (e) { if (mounted) _notice(context, _error(e)); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(_s(widget.session['intitule'])), bottom: TabBar(controller: _tabs, tabs: const [Tab(text: 'Groupes'), Tab(text: 'Inscriptions'), Tab(text: 'Bilan')])), floatingActionButton: widget.peutGerer && _tabs.index == 0 ? FloatingActionButton.extended(onPressed: _newGroup, icon: const Icon(Icons.group_add_outlined), label: const Text('Groupe')) : null, persistentFooterButtons: widget.peutGerer ? [PopupMenuButton<String>(onSelected: _transition, itemBuilder: (_) => const [PopupMenuItem(value: 'ouvrir', child: Text('Ouvrir')), PopupMenuItem(value: 'cloturer', child: Text('Clôturer')), PopupMenuItem(value: 'terminer', child: Text('Terminer')), PopupMenuItem(value: 'annuler', child: Text('Annuler la session'))], child: const Padding(padding: EdgeInsets.all(8), child: Text('Actions sur la session')))] : null, body: TabBarView(controller: _tabs, children: [GroupsTab(groups: _groupes, session: widget.session, peutGerer: widget.peutGerer, refresh: _refresh), InscriptionsTab(session: widget.session, peutGerer: widget.peutGerer), DashboardTab(sessionId: _s(widget.session['id']))]));
}

class GroupsTab extends StatelessWidget {
  final Future<List<Json>> groups;
  final Json session;
  final bool peutGerer;
  final Future<void> Function() refresh;

  const GroupsTab({super.key, required this.groups, required this.session, required this.peutGerer, required this.refresh});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Json>>(
    future: groups,
    builder: (context, snap) {
      if (snap.hasError) return Retry(onRetry: refresh, error: snap.error!);
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      if (snap.data!.isEmpty) return const Center(child: Text('Créez un groupe pour commencer les inscriptions.'));
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: snap.data!.map((g) => Card(
            child: ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text('${_s(g['niveau'])}${g['matiere'] == null ? '' : ' · ${g['matiere']}'}'),
              subtitle: Text('${g['effectif_confirme']}/${g['capacite']} inscrits · Tarif : ${g['tarif_actif'] == null ? 'à définir' : '${g['tarif_actif']} F'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupeDetail(groupe: g, session: session, peutGerer: peutGerer))),
            ),
          )).toList(),
        ),
      );
    },
  );
}

class GroupeDetail extends ConsumerStatefulWidget { final Json groupe, session; final bool peutGerer; const GroupeDetail({super.key, required this.groupe, required this.session, required this.peutGerer}); @override ConsumerState<GroupeDetail> createState() => _GroupeDetailState(); }
class _GroupeDetailState extends ConsumerState<GroupeDetail> { late Future<List<Json>> _seances; @override void initState() { super.initState(); _seances = _load(); } Future<List<Json>> _load() async => _list((await ref.read(dioProvider).get('/groupes-programmes/${widget.groupe['id']}/seances')).data); Future<void> _refresh() async { setState(() => _seances = _load()); await _seances; }
  Future<void> _tarif() async { final data = await tarifForm(context); if (data == null) return; data.addAll({'site': widget.session['site_id'], 'groupe': widget.groupe['id']}); try { await ref.read(dioProvider).post('/tarifs-programmes', data: data); if (mounted) _notice(context, 'Tarif enregistré.'); } on DioException catch (e) { if (mounted) _notice(context, _error(e)); } }
  Future<void> _seance() async { final data = await seanceForm(context); if (data == null) return; try { await ref.read(dioProvider).post('/groupes-programmes/${widget.groupe['id']}/seances', data: data); await _refresh(); if (mounted) _notice(context, 'Séance enregistrée.'); } on DioException catch (e) { if (mounted) _notice(context, _error(e)); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('Groupe ${_s(widget.groupe['niveau'])}')), floatingActionButton: widget.peutGerer ? FloatingActionButton.extended(onPressed: _seance, icon: const Icon(Icons.add_task), label: const Text('Séance')) : null, body: FutureBuilder<List<Json>>(future: _seances, builder: (context, snap) { if (snap.hasError) return Retry(onRetry: _refresh, error: snap.error!); if (!snap.hasData) return const Center(child: CircularProgressIndicator()); return ListView(padding: const EdgeInsets.all(16), children: [Card(child: ListTile(title: Text(widget.groupe['matiere']?.toString() ?? 'Groupe général'), subtitle: Text('Capacité ${widget.groupe['capacite']} · ${widget.groupe['effectif_confirme']} confirmé(s)'))), if (widget.peutGerer) OutlinedButton.icon(onPressed: _tarif, icon: const Icon(Icons.sell_outlined), label: const Text('Définir un tarif')), const SizedBox(height: 14), Text('Séances', style: Theme.of(context).textTheme.titleLarge), if (snap.data!.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Aucune séance déclarée.')), ...snap.data!.map((s) => ListTile(leading: const Icon(Icons.event_available), title: Text(_s(s['date_seance'])), subtitle: Text('${s['nb_presents']} présents · ${s['nb_absents']} absents${s['commentaire'] == null ? '' : '\n${s['commentaire']}'}')))]); })); }
class InscriptionsTab extends ConsumerStatefulWidget { final Json session; final bool peutGerer; const InscriptionsTab({super.key, required this.session, required this.peutGerer}); @override ConsumerState<InscriptionsTab> createState() => _InscriptionsTabState(); }
class _InscriptionsTabState extends ConsumerState<InscriptionsTab> { late Future<List<Json>> _inscriptions; late Future<List<Json>> _groupes; @override void initState() { super.initState(); _inscriptions = _load(); _groupes = _loadGroups(); } Future<List<Json>> _load() async => _list((await ref.read(dioProvider).get('/inscriptions-programmes')).data); Future<List<Json>> _loadGroups() async => _list((await ref.read(dioProvider).get('/sessions-programmes/${widget.session['id']}/groupes')).data); Future<void> _refresh() async { setState(() { _inscriptions = _load(); _groupes = _loadGroups(); }); await _inscriptions; }
  Future<void> _newInscription() async { try { final groups = await _groupes; final students = _list((await ref.read(dioProvider).get('/eleves?limit=200')).data); if (!mounted) return; final data = await inscriptionForm(context, groups, students); if (data == null) return; await ref.read(dioProvider).post('/inscriptions-programmes', data: data); await _refresh(); if (mounted) _notice(context, 'Brouillon créé. Confirmez-le pour générer l’échéance.'); } on DioException catch (e) { if (mounted) _notice(context, _error(e)); } }
  Future<void> _change(String id, String action) async { try { await ref.read(dioProvider).post('/inscriptions-programmes/$id/$action'); await _refresh(); if (mounted) _notice(context, action == 'confirmer' ? 'Inscription confirmée et échéance créée.' : 'Inscription annulée.'); } on DioException catch (e) { if (mounted) _notice(context, _error(e)); } }
  @override Widget build(BuildContext context) => Scaffold(floatingActionButton: widget.peutGerer ? FloatingActionButton.extended(onPressed: _newInscription, icon: const Icon(Icons.person_add_alt), label: const Text('Inscrire')) : null, body: FutureBuilder<List<Json>>(future: _inscriptions, builder: (context, snap) { if (snap.hasError) return Retry(onRetry: _refresh, error: snap.error!); if (!snap.hasData) return const Center(child: CircularProgressIndicator()); return FutureBuilder<List<Json>>(future: _groupes, builder: (_, groupSnap) { final ids = (groupSnap.data ?? const <Json>[]).map((g) => _s(g['id'])).toSet(); final items = snap.data!.where((x) => ids.contains(_s(x['groupe']))).toList(); if (items.isEmpty) return const Center(child: Text('Aucune inscription pour cette session.')); return RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.all(16), children: items.map((x) => Card(child: ListTile(title: Text(_s(x['eleve_nom'])), subtitle: Text('${_s(x['groupe_libelle'])}\n${_status(x['statut'])} · ${x['tarif_fixe'] ?? 'tarif à confirmer'} F'), isThreeLine: true, trailing: widget.peutGerer && x['statut'] == 'brouillon' ? PopupMenuButton<String>(onSelected: (v) => _change(_s(x['id']), v), itemBuilder: (_) => const [PopupMenuItem(value: 'confirmer', child: Text('Confirmer')), PopupMenuItem(value: 'annuler', child: Text('Annuler'))]) : null))).toList())); }); })); }
class DashboardTab extends ConsumerStatefulWidget { final String sessionId; const DashboardTab({super.key, required this.sessionId}); @override ConsumerState<DashboardTab> createState() => _DashboardTabState(); }
class _DashboardTabState extends ConsumerState<DashboardTab> { late Future<Json> _data; @override void initState(){super.initState();_data=_load();} Future<Json> _load() async => Json.from((await ref.read(dioProvider).get('/sessions-programmes/${widget.sessionId}/tableau-bord')).data as Map); Future<void> _refresh() async {setState(()=>_data=_load());await _data;} @override Widget build(BuildContext context)=>FutureBuilder<Json>(future:_data,builder:(context,snap){if(snap.hasError)return Retry(onRetry:_refresh,error:snap.error!);if(!snap.hasData)return const Center(child:CircularProgressIndicator());final x=snap.data!;return RefreshIndicator(onRefresh:_refresh,child:ListView(padding:const EdgeInsets.all(18),children:[metric('Effectif','${x['effectif_inscrit']}/${x['capacite']}'),metric('Montant attendu','${x['montant_attendu']} F'),metric('Montant encaissé','${x['montant_encaisse']} F'),metric('Reste à encaisser','${x['montant_restant']} F'),metric('Séances tenues',_s(x['seances_tenues'])),metric('Présence',x['taux_presence_agrege']==null?'Pas encore de séance':'${((x['taux_presence_agrege'] as num)*100).round()} %')]));}); }
Widget metric(String title,String value)=>Card(child:ListTile(title:Text(title),trailing:Text(value,style:const TextStyle(fontWeight:FontWeight.bold))));

class ResultatsScreen extends ConsumerStatefulWidget { final Json programme; const ResultatsScreen({super.key,required this.programme}); @override ConsumerState<ResultatsScreen> createState()=>_ResultatsScreenState(); }
class _ResultatsScreenState extends ConsumerState<ResultatsScreen> { late Future<List<Json>> _items; @override void initState(){super.initState();_items=_load();} Future<List<Json>> _load()async=>_list((await ref.read(dioProvider).get('/resultats-examens',queryParameters:{'programme_id':widget.programme['id']})).data); Future<void> _refresh()async{setState(()=>_items=_load());await _items;}
  Future<void> _newResult() async { try { final inscriptions = _list((await ref.read(dioProvider).get('/inscriptions-programmes', queryParameters: {'programme_id': widget.programme['id'], 'statut': 'confirmee'})).data); if (!mounted) return; final data = await resultatForm(context, inscriptions); if (data == null) return; await ref.read(dioProvider).post('/resultats-examens', data: data); await _refresh(); if (mounted) _notice(context, 'Résultat enregistré.'); } on DioException catch (e) { if (mounted) _notice(context, _error(e)); } }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Résultats et réussite')),floatingActionButton:FloatingActionButton.extended(onPressed:_newResult,icon:const Icon(Icons.add),label:const Text('Résultat')),body:FutureBuilder<List<Json>>(future:_items,builder:(context,snap){if(snap.hasError)return Retry(onRetry:_refresh,error:snap.error!);if(!snap.hasData)return const Center(child:CircularProgressIndicator());return ListView(padding:const EdgeInsets.all(16),children:[FutureBuilder<Json>(future:ref.read(dioProvider).get('/programmes/${widget.programme['id']}/statistiques-examens').then((r)=>Json.from(r.data as Map)),builder:(_,stats)=>stats.hasData?Card(child:ListTile(title:const Text('Statistiques'),subtitle:Text('${stats.data!['resultats_saisis']} saisie(s) · ${stats.data!['admis']} admis · moyenne ${stats.data!['moyenne'] ?? '—'}'))):const SizedBox.shrink()),...snap.data!.map((x)=>Card(child:ListTile(title:Text(_s(x['eleve_nom'])),subtitle:Text('${_s(x['matiere'])} · ${x['note']}/20'),trailing:Text(x['admis']==true?'Admis':'Ajourné'))))]);})); }

class Retry extends StatelessWidget { final Future<void> Function() onRetry; final Object error; const Retry({super.key,required this.onRetry,required this.error}); @override Widget build(BuildContext context)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Text('Impossible de charger les données.\n$error',textAlign:TextAlign.center),const SizedBox(height:12),OutlinedButton(onPressed:onRetry,child:const Text('Réessayer'))]))); }

class Field { final String key,label,initial; final bool number; const Field(this.key,this.label,{this.initial='',this.number=false}); }
class Choice { final String key,label; final List<String> values; final Map<String,String> labels; const Choice(this.key,this.label,this.values,[this.labels=const {}]); }
Future<Json?> form(BuildContext context,String title,List<Object> fields,Json Function(Json) convert) async { final controllers=<String,TextEditingController>{}; final values=<String,dynamic>{}; for(final f in fields){if(f is Field)controllers[f.key]=TextEditingController(text:f.initial);if(f is Choice&&f.values.isNotEmpty)values[f.key]=f.values.first;} final result=await showDialog<Json>(context:context,builder:(c)=>StatefulBuilder(builder:(c,setState)=>AlertDialog(title:Text(title),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:fields.map((f){if(f is Field)return TextField(controller:controllers[f.key],keyboardType:f.number?TextInputType.number:null,decoration:InputDecoration(labelText:f.label));final x=f as Choice;return DropdownButtonFormField<String>(initialValue:values[x.key],decoration:InputDecoration(labelText:x.label),items:x.values.map((v)=>DropdownMenuItem(value:v,child:Text(x.labels[v]??v))).toList(),onChanged:(v)=>setState(()=>values[x.key]=v));}).toList())),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annuler')),FilledButton(onPressed:(){for(final e in controllers.entries){values[e.key]=e.value.text.trim();}Navigator.pop(c,convert(values));},child:const Text('Enregistrer'))]))); for(final x in controllers.values){x.dispose();} return result; }
Future<Json?> programmeForm(BuildContext c)=>form(c,'Nouveau programme',[const Choice('type','Type',['vacances','bac','bepc']),const Field('nom','Intitulé'),Field('annee_scolaire','Année scolaire',initial:'${DateTime.now().year}-${DateTime.now().year+1}'),const Field('matieres','Matières (Bac/BEPC, séparées par virgules)')],(v)=>{...v,'matieres':_s(v['matieres']).split(',').map((x)=>x.trim()).where((x)=>x.isNotEmpty).toList()});
Future<Json?> sessionForm(BuildContext c,List<Json> sites)=>form(c,'Nouvelle session',[Choice('site_id','Site',sites.map((x)=>_s(x['id'])).toList(),{for(final x in sites)_s(x['id']):_s(x['nom'])}),const Field('intitule','Intitulé'),const Field('date_debut','Début (AAAA-MM-JJ)'),const Field('date_fin','Fin (AAAA-MM-JJ)'),const Field('capacite','Capacité',number:true)],(v)=>{...v,'capacite':int.tryParse(_s(v['capacite']))??0});
Future<Json?> groupForm(BuildContext c)=>form(c,'Nouveau groupe',[const Field('niveau','Niveau / classe'),const Field('matiere','Matière (facultatif)'),const Field('capacite','Capacité',number:true)],(v)=>{...v,'capacite':int.tryParse(_s(v['capacite']))??0});
Future<Json?> tarifForm(BuildContext c)=>form(c,'Nouveau tarif',[const Field('montant','Montant FCFA',number:true),Field('debut_validite','Début (AAAA-MM-JJ)',initial:DateTime.now().toIso8601String().substring(0,10))],(v)=>{...v,'montant':int.tryParse(_s(v['montant']))??0});
Future<Json?> seanceForm(BuildContext c)=>form(c,'Déclarer une séance',[Field('date_seance','Date (AAAA-MM-JJ)',initial:DateTime.now().toIso8601String().substring(0,10)),const Field('nb_presents','Présents',number:true),const Field('nb_absents','Absents',number:true),const Field('commentaire','Commentaire')],(v)=>{...v,'nb_presents':int.tryParse(_s(v['nb_presents']))??0,'nb_absents':int.tryParse(_s(v['nb_absents']))??0});
Future<Json?> inscriptionForm(BuildContext c,List<Json> groups,List<Json> students)=>form(c,'Nouvelle inscription',[Choice('groupe','Groupe',groups.map((x)=>_s(x['id'])).toList(),{for(final x in groups)_s(x['id']):'${_s(x['niveau'])} ${x['matiere']??''}'}),Choice('eleve','Élève',students.map((x)=>_s(x['id'])).toList(),{for(final x in students)_s(x['id']):'${_s(x['prenom'])} ${_s(x['nom'])}'}),const Field('remise','Remise FCFA (facultatif)',number:true),const Field('motif_remise','Motif de remise')],(v)=>{...v,'remise':int.tryParse(_s(v['remise']))??0});
Future<Json?> resultatForm(BuildContext c,List<Json> inscriptions)=>form(c,'Saisir un résultat',[Choice('inscription','Élève / matière',inscriptions.map((x)=>_s(x['id'])).toList(),{for(final x in inscriptions)_s(x['id']):'${_s(x['eleve_nom'])} · ${_s(x['groupe_libelle'])}'}),const Field('note','Note sur 20',number:true),const Field('observation','Observation')],(v)=>{...v,'note':double.tryParse(_s(v['note']))??-1});
