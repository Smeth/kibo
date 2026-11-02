import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key, required this.client});
  final SupabaseClient client;
  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _code = TextEditingController();
  late final _owner = widget.client.auth.currentUser?.id;
  StreamSubscription<AuthState>? _auth;
  String? _factor, _secret, _error;
  bool _busy = true,
      _verified = false,
      _sessionLost = false,
      _showSecret = false;
  @override
  void initState() {
    super.initState();
    _auth = widget.client.auth.onAuthStateChange.listen((event) {
      if (event.session?.user.id != _owner && mounted) {
        setState(() {
          _sessionLost = true;
          _secret = null;
          _factor = null;
          _code.clear();
        });
      }
    });
    unawaited(_load());
  }

  bool get _current =>
      mounted &&
      !_sessionLost &&
      _owner != null &&
      widget.client.auth.currentUser?.id == _owner;
  Future<void> _load() async {
    try {
      if (!_current) return;
      final factors = await widget.client.auth.mfa.listFactors();
      if (!_current) return;
      if (factors.totp.isNotEmpty) {
        setState(() {
          _factor = factors.totp.first.id;
          _verified = true;
        });
      }
    } catch (_) {
      if (_current) {
        setState(() => _error = 'Impossible de charger la sécurité du compte.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enroll() async {
    if (_busy || !_current) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final factor = await widget.client.auth.mfa.enroll(
        factorType: FactorType.totp,
        issuer: 'KIBO',
      );
      if (!_current) return;
      setState(() {
        _factor = factor.id;
        _secret = factor.totp!.secret;
      });
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Activation impossible. Vérifiez la connexion et réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy || !_current || _factor == null) return;
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(
        () => _error =
            'Saisissez les six chiffres de votre application d’authentification.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.client.auth.mfa.challengeAndVerify(
        factorId: _factor!,
        code: _code.text.trim(),
      );
      if (!mounted || !_current) return;
      setState(() {
        _secret = null;
        _code.clear();
        _verified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vérification renforcée réussie.')),
      );
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Code refusé ou expiré. Vérifiez aussi l’heure de votre téléphone.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _auth?.cancel();
    _secret = null;
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sécurité du compte')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_sessionLost)
          const Text('Session modifiée. Fermez cette page et reconnectez-vous.')
        else ...[
          const Text(
            'Protégez votre compte avec une application d’authentification TOTP. '
            'Ce code est indépendant des SMS. Conservez l’accès à votre application '
            'et une copie sécurisée de sa sauvegarde ; ne partagez jamais sa clé secrète.',
          ),
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Text(_error!),
          if (_factor == null)
            FilledButton(
              onPressed: _busy ? null : _enroll,
              child: const Text('Ajouter une application d’authentification'),
            ),
          if (_secret != null) ...[
            const Text(
              'Ajoutez manuellement un compte TOTP nommé KIBO dans votre application, avec cette clé privée.',
            ),
            SwitchListTile(
              value: _showSecret,
              onChanged: (v) => setState(() => _showSecret = v),
              title: const Text('Afficher la clé privée sur ce téléphone'),
            ),
            if (_showSecret) SelectableText(_secret!),
          ],
          if (_factor != null) ...[
            if (_verified)
              const Text(
                'Application enregistrée. Validez un code pour renforcer cette session.',
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Code d’authentification',
              ),
            ),
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: const Text('Vérifier le code'),
            ),
          ],
        ],
      ],
    ),
  );
}
