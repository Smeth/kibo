import '../../core/widgets/kibo_modal.dart';
import '../../core/widgets/kibo_app_bar.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/kibo_form_layout.dart';
import '../auth/auth_controller.dart';
import 'engagement_repository.dart';

class EngagementPage extends StatefulWidget {
  const EngagementPage({
    super.key,
    required this.controller,
    required this.repository,
    this.preferences = false,
    this.operatorOnly = false,
  });
  final AuthController controller;
  final AccountEngagementRepository repository;
  final bool preferences;
  final bool operatorOnly;
  @override
  State<EngagementPage> createState() => _EngagementPageState();
}

class _EngagementPageState extends State<EngagementPage> {
  Future<void> _delete(Map<String, dynamic> request) async {
    final repository = widget.repository;
    if (!_current || _busy || repository is! AccountDeletionExecutor) return;
    final confirmation = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => KiboDialog(
        destructive: true,
        title: const Text('Supprimer définitivement ce compte ?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request['name'] as String? ?? 'Compte KIBO'),
              const SizedBox(height: 16),
              const Text(
                'Le profil, les annonces, les photos et l’accès au compte seront supprimés. Les autres participants conserveront une copie privée de leurs échanges pendant 15 jours, avec les messages de ce compte anonymisés. Cette action est irréversible. Une connexion administrateur datant de moins de 10 minutes est requise.',
              ),
              const SizedBox(height: 20),
              TextField(
                controller: confirmation,
                decoration: const InputDecoration(
                  labelText: 'Saisissez SUPPRIMER',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, confirmation.text.trim() == 'SUPPRIMER'),
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );
    Future<void>.delayed(
      const Duration(milliseconds: 400),
      confirmation.dispose,
    );
    if (accepted != true || !_current) return;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final completed = await (repository as AccountDeletionExecutor)
          .executeDeletion(_owner!, request);
      if (_current) {
        setState(
          () => _success = completed
              ? 'Compte supprimé et suppression vérifiée.'
              : 'Suppression commencée. Actualisez puis reprenez la même demande pour terminer les fichiers restants.',
        );
      }
    } catch (_) {
      if (mounted && _current) {
        setState(
          () => _error =
              'Suppression non confirmée. Reconnectez-vous comme administrateur puis actualisez et reprenez cette demande. Si un envoi photo reste actif, une vérification opérateur est nécessaire.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Suppression non confirmée. Consultez le message en haut de l’écran.',
            ),
          ),
        );
      }
      return;
    } finally {
      if (_current) setState(() => _busy = false);
    }
    if (_current) await _load();
  }

  late final String? _owner;
  bool _invalid = false, _loading = true, _busy = false, _allowed = false;
  bool _messages = true, _comments = true, _loaded = false, _more = false;
  String? _error, _success;
  Map<String, dynamic>? _request;
  List<Map<String, dynamic>> _events = [], _queue = [];
  String _status = 'pending';
  final _reply = TextEditingController();
  int _generation = 0;
  bool get _current => mounted && !_invalid;
  @override
  void initState() {
    super.initState();
    _owner = widget.controller.identity?.id;
    widget.controller.addListener(_changed);
    _load();
  }

  void _changed() {
    if (widget.controller.identity?.id != _owner) {
      _invalid = true;
      _generation++;
      _request = null;
      _events = [];
      _queue = [];
      _reply.clear();
      if (mounted) setState(() {});
    }
  }

  Future<void> _load({bool more = false}) async {
    if (_owner == null || _invalid || _busy) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.preferences) {
        final data = await widget.repository.preferences(_owner);
        if (!_current || generation != _generation) return;
        _messages = data['messages'] == true;
        _comments = data['comments'] == true;
      } else {
        final data = widget.operatorOnly
            ? <String, dynamic>{'request': null, 'events': <dynamic>[]}
            : await widget.repository.tracking(_owner);
        final allowed = await widget.repository.canReview(_owner);
        if (!_current || generation != _generation) return;
        _request = data['request'] == null
            ? null
            : Map<String, dynamic>.from(data['request'] as Map);
        _events = (data['events'] as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _allowed = allowed;
        if (allowed) {
          final rows = await widget.repository.queue(
            _owner,
            _status,
            offset: more ? _queue.length : 0,
          );
          if (!_current || generation != _generation) return;
          _queue = more ? [..._queue, ...rows] : rows;
          _more = rows.length == 20;
        }
      }
      if (_current && generation == _generation) setState(() => _loaded = true);
    } catch (_) {
      if (_current && generation == _generation) {
        setState(
          () => _error =
              'Service indisponible. Vos données et choix sont conservés. Réessayez.',
        );
      }
    } finally {
      if (_current && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _savePreferences() async {
    if (!_loaded || _busy || _invalid || _owner == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      await widget.repository.preferences(
        _owner,
        messages: _messages,
        comments: _comments,
      );
      if (_current) {
        setState(
          () => _success =
              'Préférences enregistrées pour les futures notifications.',
        );
      }
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Enregistrement non confirmé. Vos choix restent affichés ; réessayez.',
        );
      }
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  Future<void> _sendReply() async {
    if (_busy || _invalid || _owner == null || _request == null) return;
    if (_reply.text.trim().runes.length < 3 ||
        _reply.text.runes.length > 1000) {
      setState(() => _error = 'Saisissez entre 3 et 1 000 caractères.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    var saved = false;
    try {
      await widget.repository.reply(
        _owner,
        (_request!['version'] as num).toInt(),
        _reply.text,
      );
      if (_current) {
        _reply.clear();
        saved = true;
      }
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Réponse non confirmée. Actualisez l’état avant de réessayer.',
        );
      }
    } finally {
      if (_current) setState(() => _busy = false);
    }
    if (saved && _current) await _load();
  }

  Future<void> _review(Map<String, dynamic> request) async {
    if (_busy || _loading || _invalid) return;
    final decision = await showDialog<({String action, String note})>(
      context: context,
      builder: (_) => _ReviewDialog(controller: widget.controller),
    );
    if (decision == null || !_current) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    var saved = false;
    try {
      await widget.repository.review(
        _owner!,
        request,
        decision.action,
        decision.note,
      );
      if (_current) saved = true;
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Décision non confirmée ou demande modifiée. Actualisez avant de réessayer.',
        );
      }
    } finally {
      if (_current) setState(() => _busy = false);
    }
    if (saved && _current) await _load();
  }

  @override
  void dispose() {
    _generation++;
    widget.controller.removeListener(_changed);
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: KiboAppBar(
        context,
        title: Text(
          widget.preferences
              ? 'Préférences de notifications'
              : 'Demandes de compte',
        ),
      ),
      body: _invalid
          ? const Center(
              child: Text('Session modifiée. Revenez depuis Profil.'),
            )
          : KiboFormListView(
              onRefresh: () async {
                if (!_busy && !_loading) await _load();
              },
              padding: const EdgeInsets.all(16),
              children: [
                if (_loading) const LinearProgressIndicator(),
                if (_error != null)
                  Semantics(liveRegion: true, child: Text(_error!)),
                if (_success != null)
                  Semantics(liveRegion: true, child: Text(_success!)),
                if (widget.preferences) ...[
                  const Text(
                    'Ces choix concernent les futures notifications dans KIBO, sur tous vos appareils connectés. Les messages et commentaires restent accessibles. Les notifications de sécurité et de traitement du compte restent actives. Les notifications système du téléphone ne sont pas encore disponibles.',
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Nouveaux messages'),
                    value: _messages,
                    onChanged: !_loaded || _loading || _busy
                        ? null
                        : (value) => setState(() {
                            _messages = value;
                            _success = null;
                          }),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Commentaires et réponses'),
                    value: _comments,
                    onChanged: !_loaded || _loading || _busy
                        ? null
                        : (value) => setState(() {
                            _comments = value;
                            _success = null;
                          }),
                  ),
                  FilledButton(
                    onPressed: !_loaded || _loading || _busy
                        ? null
                        : _savePreferences,
                    child: const Text('Enregistrer les préférences'),
                  ),
                ] else if (_loaded) ...[
                  if (!widget.operatorOnly) ...[
                    const Text(
                      'Votre demande doit être examinée par l’opérateur KIBO. Ce suivi ne réalise aucune suppression automatique du compte ou des échanges.',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _request == null
                          ? 'Aucune demande en cours.'
                          : accountRequestLabel(_request!['status'] as String),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_request?['requested_at'] != null)
                      Text(
                        'Demandée le ${_date(_request!['requested_at'] as String)}',
                      ),
                    if (_request?['operator_note'] != null)
                      Text('Message de KIBO : ${_request!['operator_note']}'),
                    if (_request?['owner_note'] != null)
                      Text('Vos précisions : ${_request!['owner_note']}'),
                    if (_request?['status'] == 'needs_info') ...[
                      TextField(
                        controller: _reply,
                        enabled: !_busy && !_loading,
                        maxLength: 1000,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Vos précisions',
                          helperText:
                              'Ne transmettez aucun mot de passe ou code de connexion.',
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy || _loading ? null : _sendReply,
                        child: const Text('Envoyer mes précisions'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Historique récent',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_events.isEmpty)
                      const Text('Aucun événement enregistré.'),
                    for (final event in _events)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(switch (event['action']) {
                          'requested' => 'Demande enregistrée',
                          'cancelled' => 'Demande annulée',
                          'reply' => 'Précisions transmises',
                          final String status => accountRequestLabel(status),
                          _ => 'Événement',
                        }),
                        subtitle: Text(
                          '${_date(event['created_at'] as String)}${event['note'] == null ? '' : '\n${event['note']}'}',
                        ),
                      ),
                  ],
                  if (widget.operatorOnly && !_allowed)
                    const Text('Accès administrateur requis.'),
                  if (_allowed) ...[
                    const Divider(height: 32),
                    const Text(
                      'Espace opérateur',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      accountDeletionEnabled
                          ? 'Les notes sont visibles par le demandeur. Après examen, passez la demande en cours de traitement puis confirmez la suppression définitive. Une opération interrompue peut être reprise.'
                          : 'Les notes sont visibles par le demandeur. La suppression effective nécessite une procédure distincte et vérifiée.',
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'État des demandes',
                      ),
                      items:
                          [
                                'pending',
                                'processing',
                                'needs_info',
                                'rejected',
                                'completed',
                              ]
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    accountRequestLabel(s),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: _busy || _loading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _status = value;
                                  _queue = [];
                                });
                                _load();
                              }
                            },
                    ),
                    if (_queue.isEmpty)
                      const Text('Aucune demande dans cet état.'),
                    for (final row in _queue)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row['name'] as String? ?? 'Membre KIBO',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Demande du ${_date(row['requested_at'] as String)}',
                              ),
                              if (row['owner_note'] != null)
                                Text('Précisions : ${row['owner_note']}'),
                              if (row['operator_note'] != null)
                                Text('Dernière note : ${row['operator_note']}'),
                              if ([
                                'pending',
                                'processing',
                                'needs_info',
                              ].contains(row['status']))
                                TextButton(
                                  onPressed: _busy || _loading
                                      ? null
                                      : () => _review(row),
                                  child: const Text('Examiner la demande'),
                                ),
                              if (widget.repository
                                  case final AccountDeletionExecutor executor
                                  when executor.deletionEnabled &&
                                      row['status'] == 'processing') ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _busy || _loading
                                      ? null
                                      : () => _delete(row),
                                  icon: const Icon(
                                    Icons.delete_forever_outlined,
                                  ),
                                  label: const Text('Supprimer définitivement'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (_more)
                      TextButton(
                        onPressed: _busy || _loading
                            ? null
                            : () => _load(more: true),
                        child: const Text('Charger la suite'),
                      ),
                  ],
                ],
                TextButton(
                  onPressed: _busy || _loading ? null : _load,
                  child: const Text('Actualiser'),
                ),
              ],
            ),
    ),
  );
}

String _date(String value) {
  final date = DateTime.tryParse(value)?.toLocal();
  return date == null
      ? 'date indisponible'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.controller});
  final AuthController controller;
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late final String? _owner;
  bool _invalid = false;
  final _note = TextEditingController();
  final _form = GlobalKey<FormState>();
  String _action = 'processing';
  @override
  void initState() {
    super.initState();
    _owner = widget.controller.identity?.id;
    widget.controller.addListener(_changed);
  }

  void _changed() {
    if (widget.controller.identity?.id != _owner) {
      _invalid = true;
      _note.clear();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KiboDialog(
    title: const Text('Examiner la demande'),
    content: _invalid
        ? const Text('Session modifiée. Fermez cette fenêtre.')
        : SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'La décision et votre note seront communiquées au demandeur. Aucun compte ne sera supprimé par cette action.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _action,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Décision'),
                    items: ['processing', 'needs_info', 'rejected']
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              accountRequestLabel(s),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _action = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _note,
                    maxLength: 1000,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Note visible par le demandeur',
                    ),
                    validator: (value) => (value ?? '').trim().runes.length < 3
                        ? 'Saisissez au moins 3 caractères.'
                        : null,
                  ),
                ],
              ),
            ),
          ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: _invalid
            ? null
            : () {
                if (_form.currentState!.validate()) {
                  Navigator.pop(context, (
                    action: _action,
                    note: _note.text.trim(),
                  ));
                }
              },
        child: const Text('Confirmer la décision'),
      ),
    ],
  );
}
