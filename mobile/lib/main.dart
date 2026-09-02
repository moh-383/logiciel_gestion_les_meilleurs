import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/paiements/paiements_list_screen.dart';

void main() {
  // ProviderScope est requis à la racine dès qu'on utilise Riverpod.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion scolaire — Paiements',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const PaiementsListScreen(),
    );
  }
}