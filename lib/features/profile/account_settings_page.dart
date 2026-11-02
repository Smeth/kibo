import '../../core/widgets/kibo_app_bar.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/kibo_form_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../auth/password_pages.dart';
import '../chat/chat_repository.dart';
import '../chat/blocked_users_page.dart';
import 'engagement_repository.dart';
import 'engagement_pages.dart';
import 'retained_history_page.dart';

abstract interface class AccountRequestsRepository {
  Future<String?> status(String owner);
  Future<void> request(String owner, {required bool cancel});
}

class SupabaseAccountRequestsRepository
    implements
        AccountRequestsRepository,
        AccountEngagementRepository,
        AccountDeletionExecutor,
        RetainedHistoryRepository {
  SupabaseAccountRequestsRepository(this.client);
  final SupabaseClient client;
  @override
  Future<List<Map<String, dynamic>>> retained(
    String owner,
    String kind, {
    String? thread,
    int offset = 0,
  }) => _run(owner, () async {
    if (!{'threads', 'messages', 'comments'}.contains(kind)) {
      throw ArgumentError('Historique invalide');
    }
    final rows = await client.rpc(
      'kibo_retained_$kind',
      params: {'p_offset': offset, if (kind == 'messages') 'p_thread': thread},
    );
    return (rows as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  });
  @override
  bool get deletionEnabled => accountDeletionEnabled;
  @override
  Future<bool> executeDeletion(String actor, Map<String, dynamic> request) =>
      _run(actor, () async {
        if (!deletionEnabled) throw StateError('Suppression non activée.');
        final response = await client.functions.invoke(
          'kibo-delete-account',
          body: {
            'subject': request['owner_id'],
            'version': request['version'],
            'confirmation': 'SUPPRIMER',
          },
        );
        if (response.data is! Map || response.data['ok'] != true) {
          throw StateError('Suppression non confirmée.');
        }
        return response.data['phase'] == 'completed';
      });
  Future<T> _run<T>(String owner, Future<T> Function() action) async {
    _check(owner);
    var invalid = false;
    final subscription = client.auth.onAuthStateChange.listen((event) {
      if (event.session?.user.id != owner) invalid = true;
    });
    try {
      final result = await action().timeout(const Duration(seconds: 20));
      _check(owner);
      if (invalid) throw StateError('Session modifiée');
      return result;
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<Map<String, dynamic>> preferences(
    String owner, {
    bool? messages,
    bool? comments,
  }) => _run(owner, () async {
    if ((messages == null) != (comments == null)) {
      throw ArgumentError('Deux choix requis');
    }
    return Map<String, dynamic>.from(
      await client.rpc(
            'kibo_notification_preferences',
            params: {'p_messages': messages, 'p_comments': comments},
          )
          as Map,
    );
  });
  @override
  Future<Map<String, dynamic>> tracking(String owner) => _run(
    owner,
    () async => Map<String, dynamic>.from(
      await client.rpc('kibo_account_tracking') as Map,
    ),
  );
  @override
  Future<bool> canReview(String owner) =>
      _run(owner, () async => await client.rpc('kibo_can_moderate') == true);
  @override
  Future<List<Map<String, dynamic>>> queue(
    String owner,
    String status, {
    int offset = 0,
  }) => _run(
    owner,
    () async =>
        (await client.rpc(
                  'kibo_account_queue',
                  params: {'p_status': status, 'p_offset': offset},
                )
                as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList(),
  );
  @override
  Future<void> review(
    String owner,
    Map<String, dynamic> request,
    String action,
    String note,
  ) => _run(owner, () async {
    if (!{'processing', 'needs_info', 'rejected'}.contains(action) ||
        note.trim().length < 3 ||
        note.runes.length > 1000) {
      throw ArgumentError('Décision invalide');
    }
    await client.rpc(
      'kibo_account_review',
      params: {
        'p_owner': request['owner_id'],
        'p_version': request['version'],
        'p_action': action,
        'p_note': note.trim(),
      },
    );
  });
  @override
  Future<void> reply(String owner, int version, String note) =>
      _run(owner, () async {
        if (note.trim().length < 3 || note.runes.length > 1000) {
          throw ArgumentError('Précisions requises');
        }
        await client.rpc(
          'kibo_account_reply',
          params: {'p_version': version, 'p_note': note.trim()},
        );
      });
  void _check(String owner) {
    final session = client.auth.currentSession;
    if (session == null || session.isExpired || session.user.id != owner) {
      throw StateError('Session modifiée');
    }
  }

  @override
  Future<String?> status(String owner) => _run(owner, () async {
    final rows = await client
        .from('kibo_account_requests')
        .select('status')
        .eq('owner_id', owner)
        .limit(1);
    return rows.isEmpty ? null : rows.single['status'] as String;
  });

  @override
  Future<void> request(String owner, {required bool cancel}) =>
      _run(owner, () async {
        await client.rpc('kibo_account_request', params: {'p_cancel': cancel});
      });
}

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({
    super.key,
    required this.controller,
    required this.repository,
    this.chats,
  });
  final AuthController controller;
  final AccountRequestsRepository repository;
  final ChatRepository? chats;
  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late final String? _owner;
  final _confirmation = TextEditingController();
  bool _invalid = false, _busy = false, _loading = true, _loaded = false;
  String? _status, _message;
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
      _confirmation.clear();
      if (mounted) setState(() {});
    }
  }

  Future<void> _load() async {
    if (_owner == null || _invalid) return;
    setState(() {
      _loading = true;
      _loaded = false;
      _message = null;
    });
    try {
      final status = await widget.repository.status(_owner);
      if (mounted && !_invalid) {
        setState(() {
          _status = status;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'État du compte indisponible. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _request(bool cancel) async {
    if (_busy || _invalid || !_loaded || _owner == null) return;
    if (!cancel && _confirmation.text.trim() != 'SUPPRIMER') {
      setState(() => _message = 'Écrivez SUPPRIMER pour confirmer la demande.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.repository.request(_owner, cancel: cancel);
      if (!mounted || _invalid) return;
      _confirmation.clear();
      await _load();
      if (mounted && !_invalid && !_loaded) {
        setState(
          () => _message =
              'Demande envoyée ; état actuel indisponible. Actualisez avant de réessayer.',
        );
        return;
      }
      if (mounted && !_invalid) {
        setState(
          () => _message = _status == null
              ? 'Aucune demande en attente.'
              : cancel
              ? 'La demande a évolué. L’annulation n’est pas confirmée ; consultez son suivi.'
              : 'Demande enregistrée. Le compte et les données ne sont pas encore supprimés.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Demande non confirmée. Actualisez avant de réessayer.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: KiboAppBar(context, title: const Text('Compte et données')),
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
                if (widget.repository is AccountEngagementRepository) ...[
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => EngagementPage(
                                controller: widget.controller,
                                repository:
                                    widget.repository
                                        as AccountEngagementRepository,
                                preferences: true,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('Préférences de notifications'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => EngagementPage(
                                  controller: widget.controller,
                                  repository:
                                      widget.repository
                                          as AccountEngagementRepository,
                                ),
                              ),
                            );
                            if (mounted && !_invalid) await _load();
                          },
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Suivi des demandes de compte'),
                  ),
                ],
                if (widget.repository
                    case final RetainedHistoryRepository history
                    when accountDeletionEnabled)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => RetainedHistoryPage(
                                auth: widget.controller,
                                repository: history,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.history_outlined),
                    label: const Text('Échanges conservés'),
                  ),
                if (widget.chats is ChatEnhancements)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => BlockedUsersPage(
                                repository: widget.chats!,
                                controller: widget.controller,
                              ),
                            ),
                          ),
                    icon: const Icon(Icons.block_outlined),
                    label: const Text('Interlocuteurs bloqués'),
                  ),
                const Text(
                  'Vos données sur KIBO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Nom et ville sont publics. Les coordonnées de contact sont distinctes de la connexion et partagées seulement selon vos choix. Les messages sont accessibles aux participants et aux administrateurs autorisés. Favoris visiteurs et brouillon : conservés localement sur cet appareil. Ne partagez pas vos codes ou liens de connexion.',
                ),
                if (widget.controller.repository is PasswordRecoveryRepository)
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PasswordChangePage(
                                controller: widget.controller,
                              ),
                            ),
                          ),
                    child: const Text('Changer mon mot de passe'),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Demander la suppression de mon compte',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (accountDeletionEnabled)
                  const Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 16),
                    child: Text(
                      'Après validation de votre demande, KIBO supprime définitivement votre profil, vos annonces, vos photos et votre accès. Les autres participants gardent leurs propres contributions en privé pendant 15 jours ; vos messages sont remplacés par « Message anonymisé ».',
                    ),
                  ),
                const Text(
                  'Cette demande doit être traitée par l’opérateur KIBO. Elle ne supprime immédiatement ni votre compte ni les échanges. Une vérification est nécessaire pour traiter les annonces, messages et obligations de conservation. Vous pouvez annuler une demande encore en attente. Aucun délai automatique n’est promis.',
                ),
                if (_loading)
                  const LinearProgressIndicator()
                else if (_loaded && _status == null) ...[
                  TextField(
                    controller: _confirmation,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Écrivez SUPPRIMER',
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _request(false),
                    child: const Text('Enregistrer ma demande'),
                  ),
                ] else if (_loaded) ...[
                  Text(
                    _status == 'pending'
                        ? 'Demande en attente de traitement.'
                        : accountRequestLabel(_status!),
                  ),
                  if (_status == 'pending' || _status == 'needs_info')
                    TextButton(
                      onPressed: _busy ? null : () => _request(true),
                      child: const Text('Annuler ma demande'),
                    ),
                ],
                if (_message != null)
                  Semantics(liveRegion: true, child: Text(_message!)),
                TextButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('Actualiser l’état'),
                ),
              ],
            ),
    ),
  );
}
