import 'package:flutter/material.dart';
import '../../core/widgets/kibo_form_layout.dart';
import '../auth/auth_controller.dart';
import 'comments_repository.dart';
import '../safety/safety_repository.dart';
import '../safety/safety_page.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({
    super.key,
    required this.listingId,
    required this.repository,
    this.parentId,
    this.safety,
  });
  final String listingId;
  final String? parentId;
  final CommentsRepository repository;
  final SafetyRepository? safety;
  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _text = TextEditingController();
  final _form = GlobalKey<FormState>();
  List<ListingComment> _rows = [];
  bool _loading = true, _more = false, _sending = false;
  String? _error, _message, _owner;
  int _request = 0, _session = 0;
  String _date(DateTime value) {
    final date = value.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final owner = AuthScope.maybeOf(context)?.identity?.id;
    if (owner != _owner) {
      _owner = owner;
      _session++;
      _text.clear();
      _sending = false;
      _message = null;
    }
  }

  Future<void> _load({bool append = false}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      if (!append) _rows = [];
    });
    try {
      final rows = await widget.repository.read(
        widget.listingId,
        parentId: widget.parentId,
        offset: append ? _rows.length : 0,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _rows = [..._rows, ...rows];
        _more = rows.length == 20;
      });
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = 'Impossible de charger cette discussion.');
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_sending ||
        _owner == null ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    final owner = _owner!, session = _session;
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await widget.repository.create(
        widget.listingId,
        _text.text,
        expectedUserId: owner,
        parentId: widget.parentId,
      );
      if (!mounted || session != _session || owner != _owner) return;
      _text.clear();
      setState(
        () => _message = widget.parentId == null
            ? 'Commentaire publié.'
            : 'Réponse publiée.',
      );
      await _load();
    } catch (_) {
      if (mounted && session == _session) {
        setState(
          () => _message =
              'Publication non confirmée. Actualisez la discussion avant de réessayer ; le texte est conservé.',
        );
      }
    } finally {
      if (mounted && session == _session) setState(() => _sending = false);
    }
  }

  Future<void> _replies(ListingComment row) async {
    final auth = AuthScope.maybeOf(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          Widget page = CommentsPage(
            safety: widget.safety,
            listingId: widget.listingId,
            repository: widget.repository,
            parentId: row.id,
          );
          return auth == null ? page : AuthScope(controller: auth, child: page);
        },
      ),
    );
    if (mounted) await _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.parentId == null ? 'Commentaires' : 'Réponses'),
      ),
      body: KiboFormListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_owner == null)
            const Text(
              'Connectez-vous depuis Profil pour participer à la discussion.',
            )
          else
            Form(
              key: _form,
              child: KiboFormColumn(
                children: [
                  TextFormField(
                    key: const ValueKey('comment-content'),
                    controller: _text,
                    enabled: !_sending,
                    minLines: 2,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: widget.parentId == null
                          ? 'Votre commentaire'
                          : 'Votre réponse',
                    ),
                    validator: validateComment,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: Text(
                      _sending
                          ? 'Publication…'
                          : widget.parentId == null
                          ? 'Publier le commentaire'
                          : 'Publier la réponse',
                    ),
                  ),
                ],
              ),
            ),
          if (_message != null)
            Semantics(liveRegion: true, child: Text(_message!)),
          TextButton.icon(
            onPressed: _sending || _loading ? null : () => _load(),
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
          ),
          if (!_loading && _error == null && _rows.isEmpty)
            const Text('Aucun message pour le moment.'),
          for (final row in _rows)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${row.authorDeleted
                          ? 'Compte supprimé'
                          : row.userId == _owner
                          ? 'Vous'
                          : 'Membre'} · ${_date(row.createdAt)}',
                    ),
                    const SizedBox(height: 8),
                    Text(row.content),
                    if (widget.safety != null)
                      TextButton.icon(
                        onPressed: () => openReportForm(
                          context,
                          widget.safety!,
                          commentId: row.id,
                        ),
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Signaler ce commentaire'),
                      ),
                    if (widget.parentId == null)
                      TextButton(
                        onPressed: () => _replies(row),
                        child: const Text('Voir les réponses'),
                      ),
                  ],
                ),
              ),
            ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) ...[
            Text(_error!),
            TextButton(
              onPressed: () => _load(),
              child: const Text('Réessayer'),
            ),
          ],
          if (_more && !_loading && _error == null)
            TextButton(
              onPressed: () => _load(append: true),
              child: const Text('Voir plus'),
            ),
        ],
      ),
    ),
  );
}
