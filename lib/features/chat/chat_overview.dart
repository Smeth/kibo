import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/auth_controller.dart';
import 'chat_repository.dart';

/// Reuses the participant-scoped summaries, including pages beyond the first 20.
Future<List<ChatThread>> allChatThreads(
  ChatRepository repository,
  String owner,
) async {
  final result = <String, ChatThread>{};
  for (var offset = 0; ; offset += 20) {
    if (repository.userId != owner) throw StateError('Session modifiée');
    final page = await repository
        .threads(owner, offset: offset)
        .timeout(const Duration(seconds: 20));
    if (repository.userId != owner) throw StateError('Session modifiée');
    final before = result.length;
    for (final thread in page) {
      result[thread.id] = thread;
    }
    if (page.length < 20) return result.values.toList();
    if (result.length == before) throw StateError('Pagination indisponible');
  }
}

class ChatEntry extends StatefulWidget {
  const ChatEntry({
    super.key,
    required this.repository,
    required this.onPressed,
    this.revision = 0,
    this.showLabel = true,
  });
  final ChatRepository repository;
  final VoidCallback onPressed;
  final int revision;
  final bool showLabel;
  @override
  State<ChatEntry> createState() => _ChatEntryState();
}

class _ChatEntryState extends State<ChatEntry> with WidgetsBindingObserver {
  AuthController? _auth;
  String? _owner;
  int _epoch = 0;
  int? _count;
  bool _foreground = true, _loading = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    if (!identical(auth, _auth)) {
      _auth?.removeListener(_changed);
      _auth = auth;
      _auth?.addListener(_changed);
    }
    _changed();
  }

  void _changed() {
    final owner = _auth?.identity?.id;
    if (owner == _owner) return;
    _owner = owner;
    _epoch++;
    _count = null;
    _loading = false;
    _restart();
    if (mounted) setState(() {});
  }

  void _restart() {
    _timer?.cancel();
    if (_foreground && _owner != null) {
      unawaited(_reload());
      _timer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => unawaited(_reload()),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _epoch++;
      _count = null;
      _loading = false;
    }
    _restart();
  }

  @override
  void didUpdateWidget(ChatEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision ||
        oldWidget.repository != widget.repository) {
      _epoch++;
      _loading = false;
      unawaited(_reload());
    }
  }

  Future<void> _reload() async {
    final owner = _owner, epoch = _epoch;
    if (!_foreground || _loading || owner == null) return;
    _loading = true;
    try {
      final repository = widget.repository;
      int count;
      if (repository is ChatUnreadCounter) {
        try {
          count = await (repository as ChatUnreadCounter)
              .unreadCount(owner)
              .timeout(const Duration(seconds: 20));
        } catch (_) {
          // Existing deployments can still provide a complete paginated count.
          final threads = await allChatThreads(repository, owner);
          count = threads.fold<int>(0, (n, thread) => n + thread.unreadCount);
        }
      } else {
        final threads = await allChatThreads(repository, owner);
        count = threads.fold<int>(0, (n, thread) => n + thread.unreadCount);
      }
      if (mounted && epoch == _epoch) {
        setState(() => _count = count);
      }
    } catch (_) {
      if (mounted && epoch == _epoch) {
        setState(() => _count = null);
      }
    } finally {
      if (epoch == _epoch) _loading = false;
    }
  }

  @override
  void dispose() {
    _epoch++;
    _timer?.cancel();
    _auth?.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Mes messages',
    child: Semantics(
      key: const ValueKey('chat-unread-state'),
      value: _owner == null
          ? 'Connexion requise'
          : _count == null
          ? 'Compteur indisponible'
          : '$_count message(s) non lu(s)',
      child: !widget.showLabel
          ? IconButton(
              onPressed: widget.onPressed,
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12 +
                    ((_count ?? 0) > 0
                        ? MediaQuery.textScalerOf(context).scale(12)
                        : 0),
                12,
              ),
              icon: Badge(
                isLabelVisible: (_count ?? 0) > 0,
                label: Text((_count ?? 0) > 99 ? '99+' : '$_count'),
                child: const Icon(Icons.chat_bubble_outline),
              ),
            )
          : TextButton.icon(
              onPressed: widget.onPressed,
              icon: Badge(
                isLabelVisible: (_count ?? 0) > 0,
                label: Text((_count ?? 0) > 99 ? '99+' : '$_count'),
                child: const Icon(Icons.chat_bubble_outline),
              ),
              label: const Text('Messages'),
            ),
    ),
  );
}
