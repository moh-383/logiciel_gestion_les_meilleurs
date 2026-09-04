import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telephoneController = TextEditingController();
  final _motDePasseController = TextEditingController();
  bool _chargement = false;
  bool _masquerMotDePasse = true;

  @override
  void dispose() {
    _telephoneController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _connexion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _chargement = true);
    try {
      await ref.read(authServiceProvider).login(
            telephone: _telephoneController.text.trim(),
            motDePasse: _motDePasseController.text,
          );
      ref.invalidate(sessionProvider);
    } on DioException catch (error) {
      final data = error.response?.data;
      final message = data is Map && data['message'] is String
          ? data['message'] as String
          : 'Connexion impossible. Vérifie le serveur et le réseau.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.school, size: 56, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('Cours d\'appui les meilleurs', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text('Connectez-vous pour synchroniser les paiements.', textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _telephoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder()),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Le téléphone est obligatoire.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _motDePasseController,
                      obscureText: _masquerMotDePasse,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_masquerMotDePasse ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _masquerMotDePasse = !_masquerMotDePasse),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Le mot de passe est obligatoire.' : null,
                      onFieldSubmitted: (_) => _connexion(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _chargement ? null : _connexion,
                      child: _chargement
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Se connecter'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
