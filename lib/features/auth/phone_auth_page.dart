import '../../core/widgets/kibo_app_bar.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/widgets/kibo_form_layout.dart';
import 'package:flutter/services.dart';

import 'auth_controller.dart';
import 'auth_repository.dart';
import 'phone_auth_controller.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({
    super.key,
    required this.auth,
    required this.repository,
  });
  final AuthController auth;
  final PhoneAuthRepository repository;
  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  late final _controller = PhoneAuthController(widget.repository);
  final _phone = TextEditingController();
  final _code = TextEditingController();
  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_sessionChanged);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _sessionChanged() {
    if (widget.auth.identity == null) return;
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _leaving || ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      _leaving = true;
      _code.clear();
      Navigator.of(context).pop();
    });
  }

  Future<void> _send() async {
    if (widget.auth.identity != null || widget.auth.busy) return;
    FocusScope.of(context).unfocus();
    if (await _controller.send(_controller.sentPhone ?? _phone.text) &&
        mounted) {
      _code.clear();
    }
  }

  Future<void> _verify() async {
    if (widget.auth.identity != null || widget.auth.busy) return;
    FocusScope.of(context).unfocus();
    final code = _code.text;
    _code.clear();
    await _controller.verify(code);
    // Seul l'événement de session SDK confirme la connexion et ferme la route.
    _sessionChanged();
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.auth.removeListener(_sessionChanged);
    _controller.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final busy = _controller.busy;
      final sent = _controller.sentPhone != null;
      final wait = _controller.retrySeconds;
      return PopScope(
        canPop: !busy || widget.auth.identity != null,
        child: Scaffold(
          appBar: KiboAppBar(
            context,
            title: const Text('Connexion par téléphone'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: KiboFormColumn(
                    children: [
                      if (!widget.repository.phoneOtpEnabled)
                        const Text(
                          'La connexion par téléphone sera bientôt disponible. Utilisez Google ou votre email.',
                        )
                      else ...[
                        Text(
                          sent
                              ? 'Vérifiez votre numéro'
                              : 'Votre numéro de téléphone',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          sent
                              ? 'Saisissez le code à 6 chiffres envoyé au ${_controller.sentPhone}.'
                              : 'Recevez un code par SMS pour créer votre compte ou vous connecter, sans mot de passe.',
                        ),
                        const SizedBox(height: 24),
                        if (!sent)
                          TextField(
                            key: const ValueKey('phone-number'),
                            controller: _phone,
                            enabled: !busy,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Numéro de téléphone',
                              helperText:
                                  'Congo-Brazzaville (+242) · 9 chiffres',
                              hintText: '06 123 45 67',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          )
                        else
                          TextField(
                            key: const ValueKey('phone-code'),
                            controller: _code,
                            enabled: !busy,
                            keyboardType: TextInputType.number,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'Code SMS',
                            ),
                            onSubmitted: (_) => busy ? null : _verify(),
                          ),
                        if (_controller.message != null) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(_controller.message!),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: busy || (!sent && wait > 0)
                              ? null
                              : sent
                              ? _verify
                              : _send,
                          child: Text(
                            busy
                                ? 'Veuillez patienter…'
                                : sent
                                ? 'Vérifier le code'
                                : wait > 0
                                ? 'Réessayer dans ${wait}s'
                                : 'Recevoir un code SMS',
                          ),
                        ),
                        if (sent) ...[
                          TextButton(
                            onPressed: busy || wait > 0 ? null : _send,
                            child: Text(
                              wait > 0
                                  ? 'Renvoyer dans ${wait}s'
                                  : 'Renvoyer le code',
                            ),
                          ),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () {
                                    _code.clear();
                                    _controller.changeNumber();
                                  },
                            child: const Text('Modifier le numéro'),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text(
                          'Votre numéro de connexion reste privé. Il ne sera pas ajouté automatiquement aux coordonnées de vos annonces.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
