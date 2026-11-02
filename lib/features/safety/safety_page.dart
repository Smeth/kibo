import '../../core/widgets/kibo_app_bar.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/widgets/kibo_form_layout.dart';
import '../auth/auth_controller.dart';
import 'safety_repository.dart';

enum SafetyScreen { notifications, report, moderation }

class SafetyPage extends StatefulWidget {
  const SafetyPage({
    super.key,
    required this.repository,
    required this.ownerId,
    required this.screen,
    this.listingId,
    this.commentId,
    this.onOpenNotice,
    this.onOpenReport,
    this.onPreferences,
  });
  final SafetyRepository repository;
  final String ownerId;
  final SafetyScreen screen;
  final String? listingId, commentId;
  final Future<void> Function(AppNotice)? onOpenNotice;
  final Future<void> Function(ContentReport)? onOpenReport;
  final VoidCallback? onPreferences;
  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  final _text = TextEditingController();
  final _form = GlobalKey<FormState>();
  AuthController? _auth;
  bool _invalid = false,
      _started = false,
      _loading = false,
      _busy = false,
      _more = false,
      _unread = false,
      _allowed = false,
      _done = false;
  int _request = 0;
  String? _error, _reason;
  String _status = 'pending', _action = 'dismiss';
  final _notices = <AppNotice>[];
  final _reports = <ContentReport>[];
  List<ModerationRecord> _history = [];
  ContentReport? _selected;
  Map<String, dynamic>? _content;
  bool get _current =>
      mounted && !_invalid && widget.repository.userId == widget.ownerId;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    if (!identical(_auth, auth)) {
      _auth?.removeListener(_changed);
      _auth = auth;
      _auth?.addListener(_changed);
    }
    _changed();
    if (!_started && _current) {
      _started = true;
      unawaited(_load());
    }
  }

  void _changed() {
    if (_auth?.identity?.id != widget.ownerId ||
        widget.repository.userId != widget.ownerId) {
      _invalid = true;
      _request++;
      _text.clear();
      _notices.clear();
      _reports.clear();
      _history = [];
      _selected = null;
      _content = null;
      if (mounted) setState(() {});
    }
  }

  Future<void> _load({bool append = false}) async {
    if (!_current || widget.screen == SafetyScreen.report) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.screen == SafetyScreen.notifications) {
        final rows = await widget.repository.notifications(
          widget.ownerId,
          offset: append ? _notices.length : 0,
          unreadOnly: _unread,
        );
        if (!_current || request != _request) return;
        if (!append) _notices.clear();
        _notices.addAll(rows);
        _more = rows.length == 20;
      } else {
        final allowed = await widget.repository.canModerate(widget.ownerId);
        if (!_current || request != _request) return;
        _allowed = allowed;
        if (!allowed) {
          _reports.clear();
          _selected = null;
          _history = [];
          _content = null;
          return;
        }
        if (_selected != null) {
          final history = await widget.repository.history(
            widget.ownerId,
            _selected!.id,
          );
          if (!_current || request != _request) return;
          _history = history;
          final content = await widget.repository.content(
            widget.ownerId,
            _selected!.id,
          );
          if (!_current || request != _request) return;
          _content = content;
        } else {
          final rows = await widget.repository.reports(
            widget.ownerId,
            status: _status,
            offset: append ? _reports.length : 0,
          );
          if (!_current || request != _request) return;
          if (!append) _reports.clear();
          _reports.addAll(rows);
          _more = rows.length == 20;
        }
      }
    } catch (_) {
      if (_current && request == _request) {
        setState(
          () => _error =
              'Chargement impossible. Vérifiez votre connexion ou vos droits puis réessayez.',
        );
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _notice(AppNotice notice) async {
    if (!_current || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (notice.readAt == null) {
        await widget.repository.markRead(widget.ownerId, notice.id);
      }
      if (!_current) return;
      await widget.onOpenNotice?.call(notice);
      if (_current) await _load();
    } catch (_) {
      if (_current) {
        setState(
          () => _error = 'Ouverture ou lecture non confirmée. Réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_current || _busy || !(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.report(
        widget.ownerId,
        listingId: widget.listingId,
        commentId: widget.commentId,
        reason: _reason!,
        details: _text.text,
      );
      if (_current) {
        setState(() {
          _done = true;
          _text.clear();
        });
      }
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Signalement non confirmé ou déjà en cours. Vos précisions sont conservées ; aucun renvoi automatique.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review() async {
    if (!_current ||
        _busy ||
        _selected == null ||
        !_allowed ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final report = _selected!, action = _action, reason = _text.text;
    setState(() => _busy = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer la décision'),
          content: Text(
            action == 'hide'
                ? 'Le contenu sera masqué et le signalement clôturé. Le motif sera communiqué à son auteur et inscrit au journal.'
                : 'Le signalement sera clôturé et la décision inscrite au journal. Le contenu restera visible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
      if (confirmed != true || !_current) return;
      await widget.repository.review(widget.ownerId, report.id, action, reason);
      if (!_current) return;
      setState(() {
        _selected = null;
        _history = [];
        _text.clear();
      });
      await _load();
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Décision non confirmée. Actualisez avant de réessayer ; le motif est conservé.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_changed);
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: KiboAppBar(
        context,
        title: Text(switch (widget.screen) {
          SafetyScreen.notifications => 'Notifications',
          SafetyScreen.report => 'Signaler un contenu',
          SafetyScreen.moderation => 'Modération',
        }),
        actions: [
          if (widget.screen == SafetyScreen.notifications &&
              widget.onPreferences != null)
            IconButton(
              tooltip: 'Préférences de notifications',
              onPressed: _current && !_busy ? widget.onPreferences : null,
              icon: const Icon(Icons.tune),
            ),
          if (widget.screen != SafetyScreen.report)
            IconButton(
              tooltip: 'Actualiser',
              onPressed: _current && !_busy && !_loading ? () => _load() : null,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: !_current
          ? const Center(
              child: Text('Session modifiée. Revenez depuis votre profil.'),
            )
          : widget.screen == SafetyScreen.notifications
          ? _notificationList()
          : KiboFormListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_loading) const LinearProgressIndicator(),
                if (_error != null) ...[
                  Semantics(liveRegion: true, child: Text(_error!)),
                  if (widget.screen != SafetyScreen.report)
                    TextButton(
                      onPressed: _busy ? null : () => _load(),
                      child: const Text('Réessayer'),
                    ),
                ],
                ...switch (widget.screen) {
                  SafetyScreen.notifications => _notificationWidgets(),
                  SafetyScreen.report => _reportWidgets(),
                  SafetyScreen.moderation => _moderationWidgets(),
                },
              ],
            ),
    ),
  );
  List<Widget> _notificationWidgets() => [
    SwitchListTile(
      title: const Text('Non lues uniquement'),
      value: _unread,
      onChanged: _busy
          ? null
          : (value) {
              setState(() {
                _unread = value;
                _notices.clear();
              });
              _load();
            },
    ),
    if (_notices.isEmpty && !_loading && _error == null)
      const Text('Aucune notification pour le moment.'),
  ];
  Widget _notificationList() => RefreshIndicator(
    onRefresh: () async {
      if (_current && !_loading && !_busy) await _load();
    },
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList.list(
            children: [
              if (_loading) const LinearProgressIndicator(),
              if (_error != null) ...[
                Semantics(liveRegion: true, child: Text(_error!)),
                TextButton(
                  onPressed: _busy ? null : () => _load(),
                  child: const Text('Réessayer'),
                ),
              ],
              ..._notificationWidgets(),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: _notices.length,
            itemBuilder: (context, index) {
              final notice = _notices[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    notice.readAt == null
                        ? Icons.mark_email_unread_outlined
                        : Icons.drafts_outlined,
                  ),
                  title: Text(notice.title),
                  subtitle: Text(notice.body),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _busy ? null : () => _notice(notice),
                ),
              );
            },
          ),
        ),
        if (_more && !_loading)
          SliverToBoxAdapter(
            child: TextButton(
              onPressed: _busy ? null : () => _load(append: true),
              child: const Text('Notifications suivantes'),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    ),
  );
  List<Widget> _reportWidgets() => _done
      ? [
          const Icon(Icons.check_circle_outline),
          const Text('Signalement envoyé. Il sera examiné par la modération.'),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ]
      : [
          const Text(
            'Signalez un contenu qui enfreint les règles. Le signalement ne masque pas automatiquement le contenu. Votre identité n’est pas communiquée à son auteur.',
          ),
          const SizedBox(height: 16),
          Form(
            key: _form,
            child: KiboFormColumn(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _reason,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Motif'),
                  items: [
                    for (final reason in reportReasons)
                      DropdownMenuItem(value: reason, child: Text(reason)),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _reason = value),
                  validator: (value) =>
                      value == null ? 'Choisissez un motif.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _text,
                  enabled: !_busy,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Précisions (facultatif)',
                  ),
                  validator: (value) => validateReportDetails(value ?? ''),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? 'Envoi…' : 'Envoyer le signalement'),
                ),
              ],
            ),
          ),
        ];
  List<Widget> _moderationWidgets() {
    if (!_allowed) {
      return [
        if (!_loading && _error == null)
          const Text('Accès réservé aux administrateurs autorisés.'),
      ];
    }
    final selected = _selected;
    if (selected != null) {
      return [
        TextButton(
          onPressed: _busy
              ? null
              : () {
                  setState(() {
                    _selected = null;
                    _text.clear();
                    _history = [];
                  });
                  _load();
                },
          child: const Text('Retour aux signalements'),
        ),
        Text(selected.reason, style: Theme.of(context).textTheme.titleLarge),
        if (selected.details != null) Text(selected.details!),
        if (_content != null) ...[
          Text(_content!['title'] as String? ?? 'Contenu signalé'),
          SelectableText(_content!['content'] as String? ?? ''),
          Text('État : ${_content!['status']}'),
        ] else if (!_loading)
          const Text('Contenu indisponible.'),
        Text(
          selected.messageId != null
              ? 'Message signalé'
              : selected.reportedUserId != null
              ? 'Profil signalé'
              : selected.commentId != null
              ? 'Commentaire signalé'
              : 'Annonce signalée',
        ),
        if (selected.listingId != null)
          OutlinedButton(
            onPressed: _busy
                ? null
                : () async {
                    try {
                      await widget.onOpenReport?.call(selected);
                    } catch (_) {
                      if (_current) {
                        setState(() => _error = 'Contenu indisponible.');
                      }
                    }
                  },
            child: const Text('Ouvrir la fiche annonce'),
          ),
        if (['pending', 'reviewed'].contains(selected.status))
          Form(
            key: _form,
            child: KiboFormColumn(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _action,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Décision'),
                  items: [
                    const DropdownMenuItem(
                      value: 'dismiss',
                      child: Text('Rejeter le signalement'),
                    ),
                    const DropdownMenuItem(
                      value: 'resolve',
                      child: Text('Clôturer sans masquer'),
                    ),
                    if (selected.messageId == null &&
                        selected.reportedUserId == null)
                      const DropdownMenuItem(
                        value: 'hide',
                        child: Text('Masquer le contenu'),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _action = value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _text,
                  enabled: !_busy,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Motif de la décision',
                  ),
                  validator: (value) => validateDecision(value ?? ''),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy || _loading ? null : _review,
                  child: const Text('Appliquer la décision'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        const Text('Journal des décisions'),
        if (_history.isEmpty && !_loading)
          const Text('Aucune décision enregistrée.'),
        for (final entry in _history)
          ListTile(
            title: Text(entry.reason),
            subtitle: Text('${decisionLabel(entry.action)} · ${entry.date}'),
          ),
      ];
    }
    return [
      DropdownButtonFormField<String>(
        initialValue: _status,
        decoration: const InputDecoration(labelText: 'État des signalements'),
        items: const [
          DropdownMenuItem(value: 'pending', child: Text('À traiter')),
          DropdownMenuItem(value: 'reviewed', child: Text('En examen')),
          DropdownMenuItem(value: 'resolved', child: Text('Résolus')),
          DropdownMenuItem(value: 'dismissed', child: Text('Rejetés')),
        ],
        onChanged: _busy
            ? null
            : (value) {
                setState(() {
                  _status = value!;
                  _reports.clear();
                });
                _load();
              },
      ),
      if (_reports.isEmpty && !_loading && _error == null)
        const Text('Aucun signalement dans cet état.'),
      for (final report in _reports)
        Card(
          child: ListTile(
            title: Text(report.reason),
            subtitle: Text(
              report.messageId != null
                  ? 'Message'
                  : report.reportedUserId != null
                  ? 'Profil'
                  : report.commentId != null
                  ? 'Commentaire'
                  : 'Annonce',
            ),
            onTap: _busy
                ? null
                : () {
                    setState(() {
                      _selected = report;
                      _action = 'dismiss';
                      _content = null;
                      _history = [];
                      _text.clear();
                    });
                    _load();
                  },
          ),
        ),
      if (_more && !_loading)
        TextButton(
          onPressed: () => _load(append: true),
          child: const Text('Signalements suivants'),
        ),
    ];
  }
}

String decisionLabel(String action) => switch (action) {
  'dismiss' => 'Signalement rejeté',
  'resolve' => 'Clôturé sans masquage',
  'hide' => 'Contenu masqué',
  _ => 'Décision',
};

Future<void> openReportForm(
  BuildContext context,
  SafetyRepository repository, {
  String? listingId,
  String? commentId,
}) async {
  final auth = AuthScope.maybeOf(context),
      owner = AuthScope.maybeOf(context)?.identity?.id;
  if (auth == null || owner == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connectez-vous depuis Profil pour signaler ce contenu.'),
      ),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AuthScope(
        controller: auth,
        child: SafetyPage(
          repository: repository,
          ownerId: owner,
          screen: SafetyScreen.report,
          listingId: listingId,
          commentId: commentId,
        ),
      ),
    ),
  );
}
