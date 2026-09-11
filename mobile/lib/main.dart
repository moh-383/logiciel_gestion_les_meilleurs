import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/auth_service.dart';

import 'core/sync_service.dart';
import 'core/fcm_service.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(gestionnaireArrierePlanFcm);
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(syncServiceProvider).demarrerEcouteConnexion();
      await ref.read(fcmServiceProvider).initialiser();
      // Session déjà active (app relancée) : on renvoie le token courant.
      final session = await ref.read(tokenStoreProvider).readSession();
      if (session != null) {
        await ref.read(fcmServiceProvider).enregistrerTokenCourant();
      }
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
