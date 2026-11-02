import '../../core/widgets/kibo_modal.dart';
import '../../core/widgets/kibo_app_bar.dart';
import 'package:flutter/material.dart';
import '../auth/auth_controller.dart';
import 'chat_repository.dart';
import 'chat_overview.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({
    super.key,
    required this.repository,
    required this.controller,
  });
  final ChatRepository repository;
  final AuthController controller;
  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  late final String? _owner;
  bool _invalid = false, _loading = true, _busy = false;
  String? _error;
  List<ChatThread> _rows = [];
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
      _rows = [];
      if (mounted) setState(() {});
    }
  }

  Future<void> _load() async {
    if (_invalid || _owner == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final threads = await allChatThreads(widget.repository, _owner);
      final peers = <String, ChatThread>{};
      for (final thread in threads.where((t) => t.blockedByMe)) {
        final peer = thread.buyerId == _owner
            ? thread.sellerId
            : thread.buyerId;
        if (peer != null && !thread.peerDeleted) peers[peer] = thread;
      }
      if (mounted && !_invalid) setState(() => _rows = peers.values.toList());
    } catch (_) {
      if (mounted && !_invalid) {
        setState(() => _error = 'Liste indisponible. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(ChatThread thread) async {
    if (_busy ||
        _invalid ||
        _owner == null ||
        widget.repository is! ChatEnhancements) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => KiboDialog(
        title: const Text('Débloquer cet interlocuteur ?'),
        content: const Text(
          'Vous pourrez de nouveau échanger sur KIBO. Un éventuel blocage de son côté reste actif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Débloquer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _invalid) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await (widget.repository as ChatEnhancements)
          .setBlocked(_owner, thread.id, false)
          .timeout(const Duration(seconds: 20));
      if (mounted && !_invalid) await _load();
    } catch (_) {
      if (mounted && !_invalid) {
        setState(
          () =>
              _error = 'Déblocage non confirmé. Actualisez avant de réessayer.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: KiboAppBar(context, title: const Text('Interlocuteurs bloqués')),
      body: _invalid
          ? const Center(
              child: Text('Session modifiée. Revenez depuis Profil.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Le blocage concerne les nouveaux échanges dans le chat KIBO. L’historique reste accessible ; les appels et WhatsApp sont indépendants.',
                ),
                if (_loading) const LinearProgressIndicator(),
                if (_error != null)
                  Semantics(liveRegion: true, child: Text(_error!)),
                if (!_loading && _error == null && _rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Aucun interlocuteur bloqué.'),
                  ),
                for (final row in _rows)
                  ListTile(
                    title: Text(row.peerName ?? 'Membre KIBO'),
                    trailing: TextButton(
                      onPressed: _busy || _loading ? null : () => _unblock(row),
                      child: const Text('Débloquer'),
                    ),
                  ),
                TextButton(
                  onPressed: _busy || _loading ? null : _load,
                  child: const Text('Actualiser'),
                ),
              ],
            ),
    ),
  );
}
