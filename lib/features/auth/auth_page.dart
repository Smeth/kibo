import 'package:flutter/material.dart';
import '../../core/widgets/kibo_form_layout.dart';
import 'package:flutter/services.dart';

import 'auth_controller.dart';
import 'auth_validation.dart';
import 'auth_repository.dart';
import 'password_pages.dart';
import 'phone_auth_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.controller,
    this.registration = false,
    this.embedded = false,
  });
  final AuthController controller;
  final bool registration;
  final bool embedded;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  late bool _registration = widget.registration;
  bool _obscure = true;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSessionChanged);
  }

  void _onSessionChanged() {
    if (widget.controller.identity == null || widget.controller.busy) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _finishSignIn());
  }

  void _finishSignIn() {
    if (!mounted || _leaving || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _leaving = true;
    _password.clear();
    _confirmation.clear();
    TextInput.finishAutofillContext(shouldSave: false);
    if (!widget.embedded) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSessionChanged);
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.controller.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final connected = await widget.controller.submit(
      registration: _registration,
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    _password.clear();
    _confirmation.clear();
    if (connected) {
      _finishSignIn();
    }
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
    _password.clear();
    _confirmation.clear();
    TextInput.finishAutofillContext(shouldSave: false);
    await widget.controller.signInWithGoogle();
  }

  Future<void> _phoneSignIn(PhoneAuthRepository repository) async {
    FocusScope.of(context).unfocus();
    _password.clear();
    _confirmation.clear();
    TextInput.finishAutofillContext(shouldSave: false);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            PhoneAuthPage(auth: widget.controller, repository: repository),
      ),
    );
    if (mounted && widget.controller.identity != null) _finishSignIn();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final busy = widget.controller.busy;
      final body = SafeArea(
        child: SingleChildScrollView(
          primary: !widget.embedded,
          physics: widget.embedded
              ? const NeverScrollableScrollPhysics()
              : null,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                onDisposeAction: AutofillContextAction.cancel,
                child: Form(
                  key: _form,
                  child: KiboFormColumn(
                    children: [
                      if (!widget.embedded)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _registration
                                    ? Icons.person_add_alt_1_outlined
                                    : Icons.lock_open_rounded,
                                size: 36,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'KIBO',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                              Text(
                                'Le commerce, simplement.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        widget.embedded
                            ? (_registration
                                  ? 'Créer mon compte'
                                  : 'Connectez-vous à KIBO')
                            : 'Bienvenue sur KIBO',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      if (widget.controller.supportsGoogle) ...[
                        OutlinedButton.icon(
                          key: const ValueKey('auth-google'),
                          onPressed: busy ? null : _google,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1F1F1F),
                            side: const BorderSide(color: Color(0xFF747775)),
                          ),
                          icon: Image.asset(
                            'assets/branding/google-g.png',
                            width: 20,
                            height: 20,
                            excludeFromSemantics: true,
                          ),
                          label: const Text('Continuer avec Google'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (widget.controller.repository
                          is PhoneAuthRepository) ...[
                        Builder(
                          builder: (context) {
                            final phoneRepository =
                                widget.controller.repository
                                    as PhoneAuthRepository;
                            return OutlinedButton.icon(
                              key: const ValueKey('auth-phone'),
                              onPressed:
                                  busy || !phoneRepository.phoneOtpEnabled
                                  ? null
                                  : () => _phoneSignIn(phoneRepository),
                              icon: const Icon(Icons.phone_outlined),
                              label: Text(
                                phoneRepository.phoneOtpEnabled
                                    ? 'Continuer avec un numéro'
                                    : 'Téléphone · bientôt disponible',
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (widget.controller.supportsGoogle ||
                          widget.controller.repository
                              is PhoneAuthRepository) ...[
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('ou par email'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        key: const ValueKey('auth-email'),
                        controller: _email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        validator: validateEmail,
                        decoration: const InputDecoration(
                          labelText: 'Adresse email',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('auth-password'),
                        controller: _password,
                        enabled: !busy,
                        obscureText: _obscure,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: [
                          _registration
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        validator: (value) => validatePassword(
                          value,
                          registration: _registration,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Afficher le mot de passe'
                                : 'Masquer le mot de passe',
                            onPressed: busy
                                ? null
                                : () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      if (_registration) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('auth-confirmation'),
                          controller: _confirmation,
                          enabled: !busy,
                          obscureText: _obscure,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: const InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                          ),
                          validator: (value) =>
                              value == _password.text && value!.isNotEmpty
                              ? null
                              : 'Les mots de passe doivent être identiques.',
                        ),
                      ],
                      if (widget.controller.message != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(widget.controller.message!),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: busy ? null : _submit,
                        child: busy
                            ? Semantics(
                                label: 'Veuillez patienter',
                                child: const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Text(
                                _registration
                                    ? 'Créer mon compte'
                                    : 'Se connecter',
                              ),
                      ),
                      const SizedBox(height: 8),
                      if (!_registration &&
                          widget.controller.repository
                              is PasswordRecoveryRepository)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PasswordResetPage(
                                      repository:
                                          widget.controller.repository
                                              as PasswordRecoveryRepository,
                                    ),
                                  ),
                                ),
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                _registration = !_registration;
                                _password.clear();
                                _confirmation.clear();
                                widget.controller.message = null;
                                _form.currentState?.reset();
                              }),
                        child: Text(
                          _registration
                              ? 'J’ai déjà un compte'
                              : 'Créer un compte',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return widget.embedded
          ? body
          : Scaffold(
              appBar: AppBar(
                title: Text(_registration ? 'Créer mon compte' : 'Connexion'),
              ),
              body: body,
            );
    },
  );
}
