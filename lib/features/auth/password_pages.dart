import 'package:flutter/material.dart';
import '../../core/widgets/kibo_form_layout.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';
import 'auth_validation.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key, required this.repository});
  final PasswordRecoveryRepository repository;
  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _form = GlobalKey<FormState>(),
      _emailKey = GlobalKey<FormFieldState<String>>();
  final _email = TextEditingController();
  bool _busy = false;
  String? _message;
  Future<void> _send() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.repository.sendPasswordReset(_email.text.trim());
      if (mounted) {
        setState(
          () => _message =
              'Si un compte correspond à cette adresse, vous recevrez un lien. Ouvrez-le sur ce téléphone puis choisissez un nouveau mot de passe.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Demande non confirmée. Vérifiez votre connexion ou réessayez plus tard.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mot de passe oublié')),
    body: KiboFormListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Indiquez votre adresse email. Ne partagez jamais le lien reçu ni votre code de confirmation.',
        ),
        const SizedBox(height: 24),
        Form(
          key: _form,
          child: TextFormField(
            key: _emailKey,
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Adresse email'),
            validator: validateEmail,
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 16),
          Semantics(liveRegion: true, child: Text(_message!)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _send,
          child: Text(_busy ? 'Demande…' : 'Recevoir le lien'),
        ),
      ],
    ),
  );
}

class PasswordChangePage extends StatefulWidget {
  const PasswordChangePage({
    super.key,
    required this.controller,
    this.recovery = false,
  });
  final AuthController controller;
  final bool recovery;
  @override
  State<PasswordChangePage> createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends State<PasswordChangePage> {
  final _form = GlobalKey<FormState>(),
      _password = TextEditingController(),
      _confirmation = TextEditingController();
  late final String? _owner;
  bool _busy = false, _invalid = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _owner = widget.controller.identity?.id;
    widget.controller.addListener(_changed);
  }

  void _changed() {
    if (widget.controller.identity?.id != _owner) {
      _invalid = true;
      _password.clear();
      _confirmation.clear();
      if (mounted) setState(() {});
    }
  }

  Future<void> _save() async {
    final repo = widget.controller.repository;
    if (_busy ||
        _invalid ||
        _owner == null ||
        repo is! PasswordRecoveryRepository ||
        !_form.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    try {
      await (repo as PasswordRecoveryRepository).changePassword(
        _owner,
        _password.text,
      );
      if (!mounted || _invalid) return;
      _password.clear();
      _confirmation.clear();
      widget.controller.finishPasswordRecovery();
      if (widget.recovery) return;
      setState(() => _message = 'Mot de passe mis à jour.');
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Modification non confirmée. Vérifiez votre session puis réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: _invalid
          ? const Center(
              child: Text('Session modifiée. Revenez depuis Profil.'),
            )
          : KiboFormListView(
              padding: const EdgeInsets.all(24),
              children: [
                Form(
                  key: _form,
                  child: KiboFormColumn(
                    children: [
                      TextFormField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Nouveau mot de passe',
                        ),
                        validator: (value) =>
                            validatePassword(value, registration: true),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmation,
                        enabled: !_busy,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Confirmer le nouveau mot de passe',
                        ),
                        validator: (value) => value == _password.text
                            ? null
                            : 'Les mots de passe doivent être identiques.',
                      ),
                    ],
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: const Text('Mettre à jour le mot de passe'),
                ),
              ],
            ),
    ),
  );
}
