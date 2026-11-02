import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../safety/safety_repository.dart';
import 'trust_scope.dart';

Future<void> openTargetReport(
  BuildContext context,
  String kind,
  String id,
) async {
  final client = TrustScope.maybeClient(context);
  if (client == null || client.auth.currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connectez-vous pour signaler un abus.')),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReportTargetPage(client: client, kind: kind, target: id),
    ),
  );
}

class ReportTargetPage extends StatefulWidget {
  const ReportTargetPage({
    super.key,
    required this.client,
    required this.kind,
    required this.target,
  });
  final SupabaseClient client;
  final String kind, target;
  @override
  State<ReportTargetPage> createState() => _ReportTargetPageState();
}

class _ReportTargetPageState extends State<ReportTargetPage> {
  final _details = TextEditingController();
  final _form = GlobalKey<FormState>();
  late final String? _owner;
  StreamSubscription<AuthState>? _auth;
  String? _reason, _error;
  bool _busy = false, _done = false, _invalid = false;
  @override
  void initState() {
    super.initState();
    _owner = widget.client.auth.currentUser?.id;
    _invalid = _owner == null;
    _auth = widget.client.auth.onAuthStateChange.listen((event) {
      if (event.session?.user.id != _owner && mounted) {
        setState(() {
          _invalid = true;
          _details.clear();
          _reason = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _auth?.cancel();
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_invalid || _busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_owner == null || widget.client.auth.currentUser?.id != _owner) {
        throw StateError('session');
      }
      final value = await widget.client.rpc(
        'kibo_report_target',
        params: {
          'p_kind': widget.kind,
          'p_target': widget.target,
          'p_reason': _reason,
          'p_details': _details.text.trim(),
        },
      );
      if (!mounted ||
          _invalid ||
          widget.client.auth.currentUser?.id != _owner) {
        return;
      }
      if (value is! String || value.isEmpty) throw StateError('response');
      setState(() => _done = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Envoi non confirmé. Vérifiez votre connexion. Un signalement identique peut déjà être en cours.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.kind == 'message'
              ? 'Signaler le message'
              : 'Signaler le profil',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_invalid)
            const Text(
              'Session modifiée. Fermez cette page et reconnectez-vous.',
            )
          else if (_done) ...[
            const Text(
              'Signalement envoyé. Votre identité ne sera pas communiquée à la personne signalée.',
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ] else
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Le signalement sera examiné par la modération. Il ne bloque pas automatiquement la personne.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Motif'),
                    items: [
                      for (final reason in reportReasons)
                        DropdownMenuItem(value: reason, child: Text(reason)),
                    ],
                    onChanged: _busy ? null : (v) => _reason = v,
                    validator: (v) => v == null ? 'Choisissez un motif.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _details,
                    enabled: !_busy,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Précisions (facultatif)',
                    ),
                    validator: (v) => validateReportDetails(v ?? ''),
                  ),
                  if (_error != null) Text(_error!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _send,
                    child: Text(_busy ? 'Envoi…' : 'Envoyer le signalement'),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
