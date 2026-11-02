import '../../core/widgets/kibo_app_bar.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/kibo_form_layout.dart';
import '../../core/widgets/congo_city_field.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'profile_validation.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.controller,
    required this.profile,
  });

  final AuthController controller;
  final KiboProfile profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName ?? '');
  late final _city = TextEditingController(text: widget.profile.city);

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (widget.controller.busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final saved = await widget.controller.updateProfile(
      expectedUserId: widget.profile.id,
      fullName: _name.text,
      city: _city.text,
    );
    if (mounted && saved && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final busy = widget.controller.busy;
      final sameAccount = widget.controller.identity?.id == widget.profile.id;
      return PopScope(
        canPop: !busy,
        child: Scaffold(
          appBar: KiboAppBar(context, title: const Text('Modifier mon profil')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: !sameAccount
                      ? Semantics(
                          liveRegion: true,
                          child: const Text(
                            'Votre session a changé. Revenez au profil pour continuer.',
                          ),
                        )
                      : Form(
                          key: _form,
                          child: KiboFormColumn(
                            children: [
                              const Text(
                                'Votre nom affiché et votre ville sont publics.',
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const ValueKey('profile-full-name'),
                                controller: _name,
                                enabled: !busy,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Nom affiché',
                                  helperText: 'Facultatif',
                                ),
                              ),
                              const SizedBox(height: 16),
                              CongoCityField(
                                fieldKey: const ValueKey('profile-city'),
                                controller: _city,
                                enabled: !busy,
                                textInputAction: TextInputAction.done,
                                validator: validateProfileCity,
                                onFieldSubmitted: busy ? null : (_) => _save(),
                              ),
                              if (widget.controller.message != null) ...[
                                const SizedBox(height: 16),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(widget.controller.message!),
                                ),
                              ],
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: busy ? null : _save,
                                child: Text(
                                  busy ? 'Enregistrement…' : 'Enregistrer',
                                ),
                              ),
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: const Text('Annuler'),
                              ),
                            ],
                          ),
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
