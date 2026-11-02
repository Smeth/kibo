import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/diagnostics/operation_id.dart';

String? validateMessage(String value) =>
    value.trim().runes.isEmpty || value.trim().runes.length > 5000
    ? 'Écrivez entre 1 et 5 000 caractères.'
    : null;

class ChatThread {
  const ChatThread({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    this.title,
    this.peerName,
    this.lastContent,
    this.lastAt,
    this.unreadCount = 0,
    this.blocked = false,
    this.blockedByMe = false,
    this.peerDeleted = false,
  });
  final String? title;
  final String? peerName, lastContent, lastAt;
  final int unreadCount;
  final bool blocked, blockedByMe, peerDeleted;
  final String id;
  final String? listingId, buyerId, sellerId;
  factory ChatThread.fromJson(Map<String, dynamic> row) {
    final deleted = row['peer_deleted'] == true;
    if (deleted && ((row['buyer_id'] == null) == (row['seller_id'] == null))) {
      throw const FormatException('Historique sans destinataire unique');
    }
    if (!deleted &&
        (row['buyer_id'] == null ||
            row['seller_id'] == null ||
            row['listing_id'] == null)) {
      throw const FormatException('Conversation incomplète');
    }
    return ChatThread(
      id: row['id'] as String,
      listingId: deleted ? null : row['listing_id'] as String?,
      buyerId: row['buyer_id'] as String?,
      sellerId: row['seller_id'] as String?,
      title: deleted
          ? 'Annonce retirée'
          : row['title'] as String? ??
                (row['listing'] as Map<String, dynamic>?)?['title'] as String?,
      peerName: deleted ? 'Compte supprimé' : row['peer_name'] as String?,
      lastContent: deleted ? null : row['last_content'] as String?,
      lastAt: row['last_at'] as String?,
      unreadCount: deleted ? 0 : (row['unread_count'] as num?)?.toInt() ?? 0,
      blocked: deleted || row['blocked'] == true,
      blockedByMe: !deleted && row['blocked_by_me'] == true,
      peerDeleted: deleted,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.readAt,
    this.senderDeleted = false,
    this.editedAt,
    this.deletedAt,
  });
  final String id, content;
  final String? senderId;
  final bool senderDeleted;
  final DateTime createdAt;
  final String? editedAt, deletedAt;
  final String? readAt;
  factory ChatMessage.fromJson(Map<String, dynamic> row) {
    final deleted = row['sender_deleted'] == true;
    if (deleted != (row['sender_id'] == null)) {
      throw const FormatException('Auteur incohérent');
    }
    return ChatMessage(
      id: row['id'] as String,
      senderId: row['sender_id'] as String?,
      content: deleted
          ? 'Message anonymisé'
          : row['deleted_at'] != null
          ? 'Message supprimé'
          : row['content'] as String,
      editedAt: row['edited_at'] as String?,
      deletedAt: row['deleted_at'] as String?,
      senderDeleted: deleted,
      createdAt: DateTime.parse(row['created_at'] as String),
      readAt: row['read_at'] as String?,
    );
  }
}

abstract interface class ChatRepository {
  String? get userId;
  Future<List<ChatThread>> threads(String owner, {int offset = 0});
  Future<ChatThread> start(String owner, String listingId, String sellerId);
  Future<List<ChatMessage>> messages(
    String owner,
    String threadId, {
    int offset = 0,
  });
  Future<void> send(String owner, String threadId, String content);
  Stream<void> changes(String owner, {String? threadId});
}

abstract interface class ChatEnhancements {
  Future<Map<String, dynamic>> threadState(String owner, String threadId);
  Future<void> markRead(String owner, String threadId, DateTime through);
  Future<void> setBlocked(String owner, String threadId, bool blocked);
  Future<void> sendOnce(
    String owner,
    String threadId,
    String content,
    String operationId,
  );
}

abstract interface class ChatUnreadCounter {
  Future<int> unreadCount(String owner);
}

abstract interface class ChatMessageActions {
  Future<bool> messageActionsAvailable(String owner, String threadId);
  Future<ChatMessage> changeMessage(
    String owner,
    String threadId,
    ChatMessage message, {
    String? content,
    bool delete = false,
  });
}

class SupabaseChatRepository
    implements
        ChatRepository,
        ChatEnhancements,
        ChatUnreadCounter,
        ChatMessageActions {
  SupabaseChatRepository(this.client) {
    _owner = userId;
    _auth = client.auth.onAuthStateChange.listen((event) {
      final owner = event.session?.user.id;
      if (owner != _owner) {
        _owner = owner;
        _epoch++;
        _messageActions = false;
      }
    });
  }
  late final StreamSubscription<AuthState> _auth;
  String? _owner;
  int _epoch = 0;
  bool _messageActions = false;
  Future<void> dispose() => _auth.cancel();
  final SupabaseClient client;
  static const threadColumns =
      'id,listing_id,buyer_id,seller_id,listing:listings(title)';
  static const messageColumns =
      'id,conversation_id,sender_id,content,message_type,created_at,read_at';
  @override
  String? get userId {
    final session = client.auth.currentSession;
    return session == null || session.isExpired ? null : session.user.id;
  }

  void _check(String owner, [int? epoch]) {
    if (owner.isEmpty ||
        userId != owner ||
        (epoch != null && epoch != _epoch)) {
      throw StateError('Session modifiée.');
    }
  }

  Future<void> _participant(String owner, String id, int epoch) async {
    _check(owner, epoch);
    final rows = await client
        .from('conversations')
        .select(threadColumns)
        .eq('id', id)
        .or('buyer_id.eq.$owner,seller_id.eq.$owner')
        .limit(1);
    _check(owner, epoch);
    if (rows.length != 1) throw StateError('Conversation indisponible.');
  }

  @override
  Future<List<ChatThread>> threads(String owner, {int offset = 0}) async {
    final epoch = _epoch;
    _check(owner);
    if (offset < 0) throw ArgumentError('Pagination invalide.');
    final rows = await client.rpc(
      'kibo_chat_summaries',
      params: {'p_offset': offset},
    );
    _check(owner, epoch);
    return (rows as List)
        .map(
          (row) => ChatThread.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  @override
  Future<int> unreadCount(String owner) async {
    final epoch = _epoch;
    _check(owner, epoch);
    final count = await client.rpc('kibo_chat_unread_count');
    _check(owner, epoch);
    return (count as num).toInt();
  }

  @override
  Future<ChatThread> start(
    String owner,
    String listingId,
    String sellerId,
  ) async {
    final epoch = _epoch;
    _check(owner);
    if (sellerId == owner) {
      throw StateError('Conversation avec soi-même interdite.');
    }
    Future<List<Map<String, dynamic>>> existing() => client
        .from('conversations')
        .select(threadColumns)
        .eq('listing_id', listingId)
        .eq('buyer_id', owner)
        .eq('seller_id', sellerId)
        .limit(1);
    var rows = await existing();
    _check(owner, epoch);
    if (rows.isEmpty) {
      try {
        rows = await client
            .from('conversations')
            .insert({
              'listing_id': listingId,
              'buyer_id': owner,
              'seller_id': sellerId,
            })
            .select(threadColumns);
      } on PostgrestException catch (e) {
        _check(owner, epoch);
        if (e.code != '23505') rethrow;
        rows = await existing();
      }
    }
    _check(owner, epoch);
    if (rows.length != 1) throw StateError('Conversation indisponible.');
    final thread = ChatThread.fromJson(rows.single);
    if (thread.buyerId != owner ||
        thread.sellerId != sellerId ||
        thread.listingId != listingId) {
      throw StateError('Conversation invalide.');
    }
    return thread;
  }

  @override
  Future<List<ChatMessage>> messages(
    String owner,
    String threadId, {
    int offset = 0,
  }) async {
    final epoch = _epoch;
    if (offset < 0) throw ArgumentError('Pagination invalide.');
    await _participant(owner, threadId, epoch);
    final rows = await client
        .from('messages')
        .select(
          _messageActions
              ? '$messageColumns,edited_at,deleted_at'
              : messageColumns,
        )
        .eq('conversation_id', threadId)
        .eq('message_type', 'text')
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + 29);
    _check(owner, epoch);
    return rows.map(ChatMessage.fromJson).toList();
  }

  @override
  Future<bool> messageActionsAvailable(String owner, String threadId) async {
    final epoch = _epoch;
    _check(owner, epoch);
    _messageActions = false;
    try {
      final result = await client.rpc(
        'kibo_chat_message_actions',
        params: {'p_thread': threadId},
      );
      _check(owner, epoch);
      return _messageActions = result == true;
    } on PostgrestException catch (error) {
      _check(owner, epoch);
      if (error.code == 'PGRST202' || error.code == '42883') return false;
      rethrow;
    }
  }

  @override
  Future<ChatMessage> changeMessage(
    String owner,
    String threadId,
    ChatMessage message, {
    String? content,
    bool delete = false,
  }) async {
    final epoch = _epoch;
    _check(owner, epoch);
    if (!_messageActions ||
        message.senderId != owner ||
        message.senderDeleted ||
        message.deletedAt != null ||
        (!delete && validateMessage(content ?? '') != null)) {
      throw StateError('Modification indisponible.');
    }
    final result = await client.rpc(
      'kibo_chat_change_message',
      params: {
        'p_thread': threadId,
        'p_message': message.id,
        'p_content': delete ? null : content!.trim(),
        'p_delete': delete,
        'p_expected_content': message.content,
        'p_expected_edited_at': message.editedAt,
      },
    );
    _check(owner, epoch);
    final row = Map<String, dynamic>.from(result as Map);
    if (row['id'] != message.id ||
        row['sender_id'] != owner ||
        row['conversation_id'] != threadId ||
        (delete
            ? row['deleted_at'] == null
            : row['content'] != content!.trim() ||
                  row['edited_at'] == null ||
                  row['deleted_at'] != null)) {
      throw StateError('Modification non confirmée.');
    }
    return ChatMessage.fromJson(row);
  }

  @override
  Future<void> send(String owner, String threadId, String content) async {
    await _send(owner, threadId, content);
  }

  Future<void> _send(
    String owner,
    String threadId,
    String content, {
    String? operationId,
  }) async {
    final epoch = _epoch;
    _check(owner);
    if (validateMessage(content) != null) {
      throw ArgumentError('Message invalide.');
    }
    await _participant(owner, threadId, epoch);
    List<Map<String, dynamic>> rows;
    try {
      rows = await client
          .from('messages')
          .insert({
            'id': ?operationId,
            'conversation_id': threadId,
            'sender_id': owner,
            'content': content.trim(),
            'message_type': 'text',
          })
          .select(messageColumns);
    } on PostgrestException catch (error) {
      _check(owner, epoch);
      if (error.code != '23505' || operationId == null) rethrow;
      rows = await client
          .from('messages')
          .select(messageColumns)
          .eq('id', operationId)
          .eq('conversation_id', threadId)
          .eq('sender_id', owner)
          .limit(1);
      if (rows.length != 1 || rows.single['content'] != content.trim()) {
        throw StateError('Conflit de message');
      }
    }
    _check(owner, epoch);
    if (rows.length != 1 ||
        (operationId != null && rows.single['id'] != operationId) ||
        rows.single['sender_id'] != owner ||
        rows.single['conversation_id'] != threadId) {
      throw StateError('Envoi non confirmé.');
    }
  }

  @override
  Future<void> sendOnce(
    String owner,
    String threadId,
    String content,
    String operationId,
  ) async {
    if (!isOperationId(operationId)) {
      throw ArgumentError('Identifiant invalide');
    }
    await _send(owner, threadId, content, operationId: operationId);
  }

  @override
  Stream<void> changes(String owner, {String? threadId}) {
    _check(owner);
    late StreamController<void> controller;
    RealtimeChannel? channel;
    Timer? fallback;
    void invalidate() {
      if (!controller.isClosed && userId == owner) controller.add(null);
    }

    controller = StreamController<void>(
      onListen: () {
        channel = client
            .channel('kibo-chat-${DateTime.now().microsecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: threadId == null ? 'conversations' : 'messages',
              filter: threadId == null
                  ? null
                  : PostgresChangeFilter(
                      type: PostgresChangeFilterType.eq,
                      column: 'conversation_id',
                      value: threadId,
                    ),
              callback: (_) => invalidate(),
            )
            .subscribe((status, error) {
              if (status == RealtimeSubscribeStatus.subscribed) invalidate();
            });
        // Maintient la réception même si la réplication n'est pas activée ou le socket est interrompu.
        fallback = Timer.periodic(
          const Duration(seconds: 15),
          (_) => invalidate(),
        );
      },
      onCancel: () async {
        fallback?.cancel();
        if (channel != null) await client.removeChannel(channel!);
      },
    );
    return controller.stream;
  }

  @override
  Future<Map<String, dynamic>> threadState(
    String owner,
    String threadId,
  ) async {
    final epoch = _epoch;
    _check(owner, epoch);
    final result = await client.rpc(
      'kibo_chat_thread_state',
      params: {'p_thread': threadId},
    );
    _check(owner, epoch);
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<void> markRead(String owner, String threadId, DateTime through) async {
    final epoch = _epoch;
    _check(owner, epoch);
    await client.rpc(
      'kibo_chat_mark_read',
      params: {
        'p_thread': threadId,
        'p_through': through.toUtc().toIso8601String(),
      },
    );
    _check(owner, epoch);
  }

  @override
  Future<void> setBlocked(String owner, String threadId, bool blocked) async {
    final epoch = _epoch;
    _check(owner, epoch);
    await client.rpc(
      'kibo_chat_set_block',
      params: {'p_thread': threadId, 'p_blocked': blocked},
    );
    _check(owner, epoch);
  }
}
