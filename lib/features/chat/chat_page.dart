import '../../core/widgets/kibo_app_bar.dart';
import 'dart:async';
import '../trust/report_target_page.dart';
import '../trust/trust_scope.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/kibo_state_panel.dart';
import '../auth/auth_controller.dart';
import 'chat_repository.dart';
import 'message_bubble.dart';
import '../../core/diagnostics/operation_id.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.repository,
    required this.ownerId,
    this.thread,
    this.listingId,
    this.sellerId,
  });
  final ChatRepository repository;
  final String ownerId;
  final ChatThread? thread;
  final String? listingId, sellerId;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final _draft = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  bool _newMessages = false,
      _foreground = true,
      _blocked = false,
      _blockedByMe = false;
  String? _sendId, _sendContent;
  final _threads = <ChatThread>[];
  final _messages = <ChatMessage>[];
  ChatThread? _thread;
  AuthController? _auth;
  StreamSubscription<void>? _updates;
  bool _invalid = false,
      _loading = false,
      _sending = false,
      _more = false,
      _started = false;
  bool _reloadPending = false;
  String? _error, _sendError;
  bool _actionsAvailable = false, _mutating = false;
  final _failedEdits = <String, String>{};
  bool get _current =>
      mounted && !_invalid && widget.repository.userId == widget.ownerId;
  bool get _conversation => _thread != null || widget.listingId != null;
  bool _peerDeleted = false;
  bool get _readOnly => _peerDeleted || _thread?.peerDeleted == true;
  @override
  void initState() {
    super.initState();
    _thread = widget.thread;
    _blocked = widget.thread?.blocked ?? false;
    _blockedByMe = widget.thread?.blockedByMe ?? false;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    if (!identical(auth, _auth)) {
      _auth?.removeListener(_sessionChanged);
      _auth = auth;
      _auth?.addListener(_sessionChanged);
    }
    _sessionChanged();
    if (!_started && _current) {
      _started = true;
      unawaited(_load());
    }
  }

  void _sessionChanged() {
    if (_auth?.identity?.id != widget.ownerId ||
        widget.repository.userId != widget.ownerId) {
      _invalid = true;
      _draft.clear();
      _threads.clear();
      _messages.clear();
      _failedEdits.clear();
      unawaited(_updates?.cancel());
      _updates = null;
      if (mounted) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && _current) {
      unawaited(_load());
      _listen();
    } else {
      unawaited(_updates?.cancel());
      _updates = null;
    }
  }

  void _listen() {
    if (_updates != null || !_current || !_foreground) return;
    _updates = widget.repository
        .changes(widget.ownerId, threadId: _thread?.id)
        .listen(
          (_) {
            if (_current) unawaited(_load());
          },
          onError: (Object error) {
            if (_current) {
              setState(() => _error = 'Actualisation interrompue. Réessayez.');
            }
          },
        );
  }

  Future<void> _load({bool older = false}) async {
    if (!_current || !_foreground) return;
    if (_loading) {
      if (!older) _reloadPending = true;
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_thread == null && widget.listingId != null) {
        final thread = await widget.repository.start(
          widget.ownerId,
          widget.listingId!,
          widget.sellerId!,
        );
        if (!_current) return;
        _thread = thread;
      }
      if (_thread != null) {
        final actions = widget.repository;
        if (actions is ChatMessageActions && !_readOnly) {
          _actionsAvailable = await (actions as ChatMessageActions)
              .messageActionsAvailable(widget.ownerId, _thread!.id)
              .timeout(const Duration(seconds: 20));
          if (!_current) return;
        }
        final enhanced = widget.repository;
        if (enhanced is ChatEnhancements) {
          final state = await (enhanced as ChatEnhancements)
              .threadState(widget.ownerId, _thread!.id)
              .timeout(const Duration(seconds: 20));
          if (!_current) return;
          _blocked = state['blocked'] == true;
          _blockedByMe = state['blocked_by_me'] == true;
          if (state['peer_deleted'] == true && !_peerDeleted) {
            _peerDeleted = true;
            _draft.clear();
            _messages.clear();
          }
        }
        final nearLatest = !_scroll.hasClients || _scroll.offset < 80;
        final oldExtent = _scroll.hasClients
                ? _scroll.position.maxScrollExtent
                : 0.0,
            oldOffset = _scroll.hasClients ? _scroll.offset : 0.0;
        final received = await widget.repository
            .messages(
              widget.ownerId,
              _thread!.id,
              offset: older ? _messages.length : 0,
            )
            .timeout(const Duration(seconds: 20));
        if (!_current) return;
        final rows = received
            .map(
              (message) => _readOnly && message.senderId != widget.ownerId
                  ? ChatMessage(
                      id: message.id,
                      senderId: null,
                      senderDeleted: true,
                      content: 'Message anonymisé',
                      createdAt: message.createdAt,
                      readAt: message.readAt,
                    )
                  : message,
            )
            .toList();
        final map = {for (final m in _messages) m.id: m};
        final hasNew = rows.any((m) => !map.containsKey(m.id));
        for (final m in rows) {
          map[m.id] = m;
        }
        _messages
          ..clear()
          ..addAll(map.values);
        _messages.sort((a, b) {
          final date = b.createdAt.compareTo(a.createdAt);
          return date == 0 ? b.id.compareTo(a.id) : date;
        });
        if (older || _messages.length <= 30) _more = rows.length == 30;
        if (!older && hasNew && !nearLatest) {
          _newMessages = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_current && _scroll.hasClients) {
              _scroll.jumpTo(
                (oldOffset + _scroll.position.maxScrollExtent - oldExtent)
                    .clamp(0.0, _scroll.position.maxScrollExtent),
              );
            }
          });
        }
        if (!older && nearLatest) await _markRead();
      } else {
        final rows = await widget.repository
            .threads(widget.ownerId, offset: older ? _threads.length : 0)
            .timeout(const Duration(seconds: 20));
        if (!_current) return;
        if (!older) {
          final ids = rows.map((t) => t.id).toSet();
          final old = _threads.where((t) => !ids.contains(t.id)).toList();
          _threads
            ..clear()
            ..addAll(rows)
            ..addAll(old);
        } else {
          final ids = _threads.map((t) => t.id).toSet();
          _threads.addAll(rows.where((t) => ids.add(t.id)));
        }
        if (older || _threads.length <= 20) _more = rows.length == 20;
      }
      _listen();
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Impossible de charger les échanges. Vérifiez votre connexion puis réessayez.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      if (_reloadPending && _current) {
        _reloadPending = false;
        unawaited(_load());
      }
    }
  }

  Future<void> _send() async {
    if (!_current ||
        _readOnly ||
        _blocked ||
        _sending ||
        _mutating ||
        _thread == null ||
        !_form.currentState!.validate()) {
      return;
    }
    final content = _draft.text;
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final repo = widget.repository;
      if (repo is ChatEnhancements) {
        if (_sendContent != content) {
          _sendId = newOperationId();
          _sendContent = content;
        }
        await (repo as ChatEnhancements)
            .sendOnce(widget.ownerId, _thread!.id, content, _sendId!)
            .timeout(const Duration(seconds: 30));
      } else {
        await repo
            .send(widget.ownerId, _thread!.id, content)
            .timeout(const Duration(seconds: 30));
      }
      if (!_current) return;
      _draft.clear();
      _sendId = null;
      _sendContent = null;
      if (_scroll.hasClients) _scroll.jumpTo(0);
      await _load();
    } catch (_) {
      if (_current) {
        setState(
          () => _sendError =
              'Envoi non confirmé. Votre texte est conservé. Actualisez avant de réessayer pour éviter un doublon.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _changeMessage(
    ChatMessage message, {
    bool delete = false,
  }) async {
    final actions = widget.repository;
    if (!_current ||
        !_actionsAvailable ||
        _readOnly ||
        _blocked ||
        _sending ||
        _mutating ||
        _thread == null ||
        actions is! ChatMessageActions ||
        message.senderId != widget.ownerId ||
        message.deletedAt != null ||
        message.senderDeleted) {
      return;
    }
    setState(() => _mutating = true);
    try {
      String? content;
      if (delete) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            icon: const Icon(Icons.delete_outline),
            title: const Text('Supprimer ce message ?'),
            content: const Text(
              'Son contenu sera remplacé par « Message supprimé » dans la conversation pour vous deux. Cette action est définitive. Un contenu déjà lu ou copié ne peut pas être rappelé.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      } else {
        content = await showDialog<String>(
          context: context,
          builder: (_) => EditMessageDialog(
            content: _failedEdits[message.id] ?? message.content,
            auth: _auth,
            ownerId: widget.ownerId,
          ),
        );
        if (content == null || content.trim() == message.content) return;
      }
      if (!_current || _readOnly || _blocked) return;
      if (!delete) {
        _failedEdits[message.id] = content!;
      }
      final changed = await (actions as ChatMessageActions)
          .changeMessage(
            widget.ownerId,
            _thread!.id,
            message,
            content: content,
            delete: delete,
          )
          .timeout(const Duration(seconds: 20));
      if (!_current) return;
      setState(() {
        _failedEdits.remove(message.id);
        final index = _messages.indexWhere((row) => row.id == changed.id);
        if (index >= 0) _messages[index] = changed;
      });
      await _load();
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Modification non confirmée. Actualisez la conversation avant de réessayer.',
        );
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _open(ChatThread thread) async {
    final auth = _auth!;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthScope(
          controller: auth,
          child: ChatPage(
            repository: widget.repository,
            ownerId: widget.ownerId,
            thread: thread,
          ),
        ),
      ),
    );
    if (_current) await _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth?.removeListener(_sessionChanged);
    unawaited(_updates?.cancel());
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    if (_readOnly) return;
    final repo = widget.repository;
    if (!_current ||
        !_foreground ||
        _messages.isEmpty ||
        _thread == null ||
        ModalRoute.of(context)?.isCurrent == false ||
        repo is! ChatEnhancements) {
      return;
    }
    try {
      await (repo as ChatEnhancements).markRead(
        widget.ownerId,
        _thread!.id,
        _messages.first.createdAt,
      );
    } catch (_) {
      /* La lecture des messages reste utilisable, sans faux accusé. */
    }
  }

  Future<void> _block() async {
    final repo = widget.repository;
    if (!_current ||
        _readOnly ||
        _thread == null ||
        repo is! ChatEnhancements) {
      return;
    }
    final value = !_blockedByMe;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          value
              ? 'Bloquer cet interlocuteur ?'
              : 'Débloquer cet interlocuteur ?',
        ),
        content: const Text(
          'Le blocage empêche les nouveaux messages KIBO entre vous. L’historique est conservé. Il ne peut pas retirer un numéro déjà obtenu ni bloquer WhatsApp ou les appels externes.',
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
    if (confirm != true || !_current) return;
    try {
      await (repo as ChatEnhancements).setBlocked(
        widget.ownerId,
        _thread!.id,
        value,
      );
      final state = await (repo as ChatEnhancements).threadState(
        widget.ownerId,
        _thread!.id,
      );
      if (_current) {
        setState(() {
          _blocked = state['blocked'] == true;
          _blockedByMe = state['blocked_by_me'] == true;
        });
      }
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Modification du blocage non confirmée. Actualisez avant de réessayer.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending && !_mutating,
    child: Scaffold(
      appBar: KiboAppBar(
        context,
        title: Text(_conversation ? 'Conversation' : 'Mes messages'),
        actions: [
          if (_thread != null &&
              !_readOnly &&
              widget.repository is ChatEnhancements)
            IconButton(
              tooltip: _blockedByMe
                  ? 'Débloquer cet interlocuteur'
                  : 'Bloquer cet interlocuteur',
              onPressed: _sending ? null : _block,
              icon: Icon(_blockedByMe ? Icons.lock_open : Icons.block),
            ),
          IconButton(
            tooltip: 'Actualiser les échanges',
            onPressed: _current && !_loading ? () => _load() : null,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: !_current
          ? const Center(
              child: Text('Session modifiée. Revenez depuis votre profil.'),
            )
          : SafeArea(
              child: Column(
                children: [
                  if (_readOnly)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Ce compte a été supprimé. Historique en lecture seule.',
                      ),
                    )
                  else if (_blocked)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Les nouveaux messages de cet échange sont bloqués.',
                      ),
                    ),
                  if (_newMessages)
                    TextButton(
                      onPressed: () {
                        setState(() => _newMessages = false);
                        if (_scroll.hasClients) _scroll.jumpTo(0);
                        _markRead();
                      },
                      child: const Text(
                        'Nouveaux messages · Revenir au plus récent',
                      ),
                    ),
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(_error!, semanticsLabel: _error),
                          TextButton(
                            onPressed: _loading ? null : () => _load(),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _conversation ? _messageList() : _threadList(),
                  ),
                  if (_conversation && _thread != null && !_readOnly)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_sendError != null)
                              Semantics(
                                liveRegion: true,
                                child: Text(_sendError!),
                              ),
                            TextFormField(
                              controller: _draft,
                              enabled: !_sending,
                              minLines: 1,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Votre message',
                              ),
                              validator: (value) =>
                                  validateMessage(value ?? ''),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: _sending || _mutating || _blocked
                                  ? null
                                  : _send,
                              icon: const Icon(Icons.send_outlined),
                              label: Text(_sending ? 'Envoi…' : 'Envoyer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    ),
  );
  Widget _threadList() => _threads.isEmpty && !_loading && _error == null
      ? Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: KiboStatePanel(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Aucune conversation.',
                message: 'Écrivez à un vendeur depuis une annonce.',
              ),
            ),
          ),
        )
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _threads.length + (_more ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _threads.length) {
              return TextButton(
                onPressed: _loading ? null : () => _load(older: true),
                child: const Text('Conversations suivantes'),
              );
            }
            final thread = _threads[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(thread.title ?? 'Annonce indisponible'),
                subtitle: Text(
                  '${thread.peerDeleted ? 'Compte supprimé · Lecture seule' : thread.peerName ?? (thread.buyerId == widget.ownerId ? 'Échange avec le vendeur' : 'Échange avec un acheteur')}${thread.peerDeleted || thread.lastContent == null ? '' : ' · ${thread.lastContent}'}${thread.lastAt == null ? '' : '\n${_threadDate(thread.lastAt!)}'}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: thread.unreadCount > 0
                    ? Badge(
                        label: Text(
                          thread.unreadCount > 99
                              ? '99+'
                              : '${thread.unreadCount}',
                        ),
                        child: const Icon(Icons.chevron_right),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => _open(thread),
              ),
            );
          },
        );
  Widget _messageList() => _messages.isEmpty && !_loading && _error == null
      ? const Center(
          child: SingleChildScrollView(
            child: KiboStatePanel(
              icon: Icons.waving_hand_outlined,
              title: 'Dites bonjour !',
              message: 'Posez votre question au vendeur.',
            ),
          ),
        )
      : ListView.builder(
          controller: _scroll,
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemCount: _messages.length + (_more ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _messages.length) {
              return TextButton(
                onPressed: _loading ? null : () => _load(older: true),
                child: const Text('Messages précédents'),
              );
            }
            final message = _messages[index];
            final canChange =
                _actionsAvailable &&
                !_mutating &&
                !_sending &&
                !_loading &&
                !_readOnly &&
                !_blocked &&
                message.senderId == widget.ownerId &&
                !message.senderDeleted &&
                message.deletedAt == null;
            return MessageBubble(
              message: message,
              mine: message.senderId == widget.ownerId,
              onReport:
                  TrustScope.maybeClient(context) != null &&
                      message.senderId != widget.ownerId &&
                      !message.senderDeleted &&
                      message.deletedAt == null &&
                      !_readOnly
                  ? () => openTargetReport(context, 'message', message.id)
                  : null,
              onEdit: canChange ? () => _changeMessage(message) : null,
              onDelete: canChange
                  ? () => _changeMessage(message, delete: true)
                  : null,
            );
          },
        );
  String _threadDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    return date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
