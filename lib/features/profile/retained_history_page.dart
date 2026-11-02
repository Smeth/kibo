import 'package:flutter/material.dart';
import '../auth/auth_controller.dart';

abstract interface class RetainedHistoryRepository {
  Future<List<Map<String, dynamic>>> retained(
    String owner,
    String kind, {
    String? thread,
    int offset = 0,
  });
}

class RetainedHistoryPage extends StatefulWidget {
  const RetainedHistoryPage({
    super.key,
    required this.auth,
    required this.repository,
    this.thread,
  });
  final AuthController auth;
  final RetainedHistoryRepository repository;
  final String? thread;
  @override
  State<RetainedHistoryPage> createState() => _RetainedHistoryPageState();
}

class _RetainedHistoryPageState extends State<RetainedHistoryPage> {
  late final String? _owner = widget.auth.identity?.id;
  bool _invalid = false, _busy = false, _more = false;
  String _kind = 'threads';
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_changed);
    _load();
  }

  void _changed() {
    if (widget.auth.identity?.id != _owner) {
      _invalid = true;
      if (mounted) setState(() => _rows = []);
    }
  }

  @override
  void dispose() {
    widget.auth.removeListener(_changed);
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    if (_busy || _invalid || _owner == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rows = await widget.repository.retained(
        _owner,
        widget.thread == null ? _kind : 'messages',
        thread: widget.thread,
        offset: append ? _rows.length : 0,
      );
      if (mounted && !_invalid) {
        setState(() {
          _rows = append ? [..._rows, ...rows] : rows;
          _more = rows.length == (widget.thread == null ? 20 : 30);
        });
      }
    } catch (_) {
      if (mounted && !_invalid) {
        setState(
          () => _error = 'Impossible de charger les échanges conservés.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.thread == null ? 'Échanges conservés' : 'Conversation archivée',
      ),
    ),
    body: RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Text(
            'Après la suppression d’un compte, vos contributions restent privées et consultables pendant 15 jours. Les messages de l’ancien compte sont anonymisés. Aucune réponse ne peut être envoyée.',
          ),
          const SizedBox(height: 24),
          if (widget.thread == null)
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'threads', label: Text('Messages')),
                ButtonSegment(value: 'comments', label: Text('Commentaires')),
              ],
              selected: {_kind},
              onSelectionChanged: _busy
                  ? null
                  : (values) {
                      setState(() {
                        _kind = values.first;
                        _rows = [];
                      });
                      _load();
                    },
            ),
          const SizedBox(height: 20),
          if (_invalid)
            const Text('Session modifiée.')
          else ...[
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (!_busy && _rows.isEmpty && _error == null)
              const Text('Aucun échange conservé.'),
            if (_error != null) ...[
              Text(_error!),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _load(),
                child: const Text('Réessayer'),
              ),
            ],
            for (final row in _rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    title: Text(
                      widget.thread == null && _kind == 'threads'
                          ? 'Compte supprimé'
                          : row['content'] as String? ?? 'Message anonymisé',
                    ),
                    subtitle: Text(
                      widget.thread == null && _kind == 'threads'
                          ? 'Conversation en lecture seule'
                          : row['sender_deleted'] == true
                          ? 'Compte supprimé'
                          : 'Votre contribution',
                    ),
                    trailing: widget.thread == null && _kind == 'threads'
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: widget.thread == null && _kind == 'threads'
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => RetainedHistoryPage(
                                auth: widget.auth,
                                repository: widget.repository,
                                thread: row['id'] as String,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            if (_more && !_busy)
              OutlinedButton(
                onPressed: () => _load(append: true),
                child: const Text('Charger la suite'),
              ),
          ],
        ],
      ),
    ),
  );
}
