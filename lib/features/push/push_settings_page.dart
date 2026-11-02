import '../../core/widgets/kibo_app_bar.dart';
import '../../core/widgets/kibo_form_layout.dart';
import '../../core/widgets/kibo_state_panel.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'push_registration.dart';

class PushSettingsPage extends StatefulWidget {
  const PushSettingsPage({super.key, required this.client});
  final SupabaseClient client;
  @override
  State<PushSettingsPage> createState() => _PushSettingsPageState();
}

class _PushSettingsPageState extends State<PushSettingsPage> {
  late final _registration = PushRegistration(widget.client);
  bool _busy = false;
  String? _message;
  Future<void> _change(bool enabled) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final accepted = enabled ? await _registration.enable() : true;
      if (!enabled) await _registration.disable();
      if (mounted) {
        setState(
          () => _message = !accepted
              ? 'Notifications refusées. Vous pouvez les autoriser dans les réglages Android.'
              : enabled
              ? 'Notifications activées sur ce téléphone.'
              : 'Notifications désactivées sur ce téléphone.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Modification non confirmée. Vérifiez votre connexion puis réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _registration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: KiboAppBar(
      context,
      title: const Text('Notifications sur ce téléphone'),
    ),
    body: KiboFormListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Recevez une alerte quand une nouvelle activité vous concerne. '
          'Le texte des conversations ne sera pas affiché sur l’écran verrouillé. '
          'Vos préférences de messages et commentaires restent respectées.',
        ),
        const SizedBox(height: 16),
        if (!pushConfigured)
          const KiboStatePanel(
            icon: Icons.notifications_paused_outlined,
            title: 'Alertes Android bientôt disponibles',
            message:
                'Les alertes Android sont en préparation. '
                'Vos notifications restent disponibles dans KIBO.',
          )
        else ...[
          FilledButton(
            onPressed: _busy ? null : () => _change(true),
            child: const Text('Activer sur ce téléphone'),
          ),
          TextButton(
            onPressed: _busy ? null : () => _change(false),
            child: const Text('Désactiver sur ce téléphone'),
          ),
        ],
        if (_busy) const LinearProgressIndicator(),
        if (_message != null) Text(_message!),
      ],
    ),
  );
}
