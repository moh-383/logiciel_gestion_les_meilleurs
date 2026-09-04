import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/sync_service.dart';
import 'features/auth/auth_gate.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Démarre l'écoute de connexion dès le lancement de l'app : dès que
    // le réseau revient, les paiements en attente sont envoyés au
    // serveur automatiquement, sans action de l'utilisateur.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).demarrerEcouteConnexion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion scolaire — Paiements',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}
