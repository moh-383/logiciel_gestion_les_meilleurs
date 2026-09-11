import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_service.dart';
import '../administration/administration_screen.dart';
import '../eleves/eleves_list_screen.dart';
import '../enseignants/enseignants_list_screen.dart';
import '../enseignants/mon_espace_enseignant_screen.dart';
import '../paiements/demandes_validation_screen.dart';
import '../paiements/paiements_list_screen.dart';
import '../programmes/programmes_screen.dart';

/// Point d'entrée après connexion. Les droits restent vérifiés par l'API ;
/// cette page rend simplement les modules accessibles et compréhensibles.
class HomeScreen extends ConsumerWidget {
  final UserSession session;

  const HomeScreen({super.key, required this.session});

  bool get _peutAdministrer => session.permissions.contains('gerer_comptes');
  bool get _peutGererEnseignants => session.permissions.contains('gerer_enseignants');
  bool get _peutVoirPedagogie => session.permissions.contains('voir_pedagogie');
  bool get _peutValider => session.permissions.contains('valider_actions_sensibles');
  bool get _peutVoirProgrammes => session.permissions.contains('voir_programmes') ||
      session.permissions.contains('gerer_programmes');
  bool get _peutGererProgrammes => session.permissions.contains('gerer_programmes');

  Future<void> _deconnexion(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).logout();
    ref.invalidate(sessionProvider);
  }

  void _ouvrir(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/branding/logo-mark.png', height: 30, width: 30),
            const SizedBox(width: 10),
            const Text('Les Meilleurs'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => _deconnexion(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Image.asset(
              'assets/branding/logo-full.png',
              height: 82,
              fit: BoxFit.contain,
              semanticLabel: 'Logo Les Meilleurs',
            ),
          ),
          const SizedBox(height: 12),
          Text('Bienvenue ${session.nom}', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Bienvenue dans le logiciel de gestion de votre école. Choisissez votre espace de travail.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _ModuleCard(
            icon: Icons.payments_outlined,
            title: 'Paiements',
            description: 'Encaisser, consulter les échéances et synchroniser.',
            onTap: () => _ouvrir(context, const PaiementsListScreen()),
          ),
          if (_peutVoirProgrammes)
            _ModuleCard(
              icon: Icons.auto_stories_outlined,
              title: 'Programmes spéciaux',
              description: 'Sessions vacances, préparation Bac/BEPC, groupes et suivi.',
              onTap: () => _ouvrir(
                context,
                ProgrammesScreen(peutGerer: _peutGererProgrammes),
              ),
            ),
          _ModuleCard(
            icon: Icons.groups_outlined,
            title: 'Élèves',
            description: 'Créer, rechercher et mettre à jour les dossiers élèves.',
            onTap: () => _ouvrir(context, const ElevesListScreen()),
          ),
          if (_peutValider)
            _ModuleCard(
              icon: Icons.fact_check_outlined,
              title: 'Demandes de validation',
              description: 'Approuver ou rejeter les annulations de paiement.',
              onTap: () => _ouvrir(context, const DemandesValidationScreen()),
            ),
          if (_peutAdministrer)
            _ModuleCard(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Administration',
              description: 'Sites, postes, droits et utilisateurs.',
              onTap: () => _ouvrir(context, const AdministrationScreen()),
            ),
          if (_peutGererEnseignants)
            _ModuleCard(
              icon: Icons.school_outlined,
              title: 'Enseignants',
              description: 'Affectations, planning et suivi des séances.',
              onTap: () => _ouvrir(context, const EnseignantsListScreen()),
            ),
          if (_peutVoirPedagogie)
            _ModuleCard(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Mon espace enseignant',
              description: 'Déclarer vos séances et consulter votre rapport mensuel.',
              onTap: () => _ouvrir(context, const MonEspaceEnseignantScreen()),
            ),
          const SizedBox(height: 12),
          Text(
            'Les modules absents ne sont pas autorisés pour votre poste.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ModuleCard({required this.icon, required this.title, required this.description, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title),
          subtitle: Text(description),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
