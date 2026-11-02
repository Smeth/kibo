import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../chat/chat_repository.dart';

class AppNotice {
  const AppNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    this.readAt,
  });
  final String id, title, body;
  final Map<String, dynamic> data;
  final String? readAt;
  factory AppNotice.fromJson(Map<String, dynamic> row) => AppNotice(
    id: row['id'] as String,
    title: row['title'] as String,
    body: row['body'] as String,
    data: Map<String, dynamic>.from(row['data'] as Map),
    readAt: row['read_at'] as String?,
  );
}

class ContentReport {
  const ContentReport({
    required this.id,
    required this.reason,
    required this.status,
    this.details,
    this.listingId,
    this.commentId,
    this.messageId,
    this.reportedUserId,
  });
  final String id, reason, status;
  final String? details, listingId, commentId;
  final String? messageId, reportedUserId;
  factory ContentReport.fromJson(Map<String, dynamic> row) => ContentReport(
    id: row['id'] as String,
    reason: row['reason'] as String,
    status: row['status'] as String,
    details: row['details'] as String?,
    listingId: row['listing_id'] as String?,
    commentId: row['comment_id'] as String?,
    messageId: row['message_id'] as String?,
    reportedUserId: row['reported_user_id'] as String?,
  );
}

class ModerationRecord {
  const ModerationRecord({
    required this.action,
    required this.reason,
    required this.date,
  });
  final String action, reason, date;
  factory ModerationRecord.fromJson(Map<String, dynamic> row) =>
      ModerationRecord(
        action: row['action'] as String,
        reason: row['reason'] as String,
        date: row['created_at'] as String,
      );
}

const reportReasons = [
  'Arnaque présumée',
  'Contenu interdit',
  'Harcèlement ou propos offensants',
  'Annonce trompeuse',
  'Autre motif',
];
String? validateReportDetails(String value) =>
    value.trim().runes.length > 2000 ? 'Maximum 2 000 caractères.' : null;
String? validateDecision(String value) =>
    value.trim().runes.length < 3 || value.trim().runes.length > 1000
    ? 'Indiquez un motif de 3 à 1 000 caractères.'
    : null;

abstract interface class SafetyRepository {
  String? get userId;
  Future<List<AppNotice>> notifications(
    String owner, {
    int offset = 0,
    bool unreadOnly = false,
  });
  Future<int> unreadCount(String owner);
  Future<void> markRead(String owner, String id);
  Future<void> report(
    String owner, {
    String? listingId,
    String? commentId,
    required String reason,
    required String details,
  });
  Future<bool> canModerate(String owner);
  Future<List<ContentReport>> reports(
    String owner, {
    required String status,
    int offset = 0,
  });
  Future<List<ModerationRecord>> history(String owner, String reportId);
  Future<Map<String, dynamic>?> content(String owner, String reportId);
  Future<void> review(String owner, String id, String action, String reason);
  Future<ChatThread?> conversation(String owner, String id);
}

class SupabaseSafetyRepository implements SafetyRepository {
  SupabaseSafetyRepository(this.client) {
    _owner = userId;
    _auth = client.auth.onAuthStateChange.listen((event) {
      final next = event.session?.user.id;
      if (next != _owner) {
        _owner = next;
        _epoch++;
      }
    });
  }
  final SupabaseClient client;
  late final StreamSubscription<AuthState> _auth;
  String? _owner;
  int _epoch = 0;
  Future<void> dispose() => _auth.cancel();
  @override
  String? get userId {
    final session = client.auth.currentSession;
    return session == null || session.isExpired ? null : session.user.id;
  }

  void _check(String owner, int epoch) {
    if (owner.isEmpty || userId != owner || _epoch != epoch) {
      throw StateError('Session modifiée.');
    }
  }

  Future<T> _run<T>(
    String owner,
    Future<T> Function(void Function()) operation,
  ) async {
    final epoch = _epoch;
    void check() => _check(owner, epoch);
    check();
    final value = await operation(check);
    check();
    return value;
  }

  @override
  Future<List<AppNotice>> notifications(
    String owner, {
    int offset = 0,
    bool unreadOnly = false,
  }) => _run(owner, (check) async {
    if (offset < 0) throw ArgumentError('Pagination invalide');
    var query = client
        .from('notifications')
        .select('id,title,body,data,read_at,created_at')
        .eq('user_id', owner);
    if (unreadOnly) query = query.isFilter('read_at', null);
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + 19);
    return rows.map(AppNotice.fromJson).toList();
  });
  @override
  Future<int> unreadCount(String owner) => _run(
    owner,
    (check) async =>
        (await client
                .from('notifications')
                .select('id')
                .eq('user_id', owner)
                .isFilter('read_at', null)
                .limit(100))
            .length,
  );
  @override
  Future<void> markRead(String owner, String id) => _run(owner, (check) async {
    await client.rpc('kibo_mark_notification_read', params: {'p_id': id});
  });
  @override
  Future<void> report(
    String owner, {
    String? listingId,
    String? commentId,
    required String reason,
    required String details,
  }) => _run(owner, (check) async {
    if ((listingId == null) == (commentId == null) ||
        !reportReasons.contains(reason) ||
        validateReportDetails(details) != null) {
      throw ArgumentError('Signalement invalide');
    }
    final rows = await client
        .from('reports')
        .insert({
          'reporter_id': owner,
          'listing_id': ?listingId,
          'comment_id': ?commentId,
          'reason': reason,
          'details': details.trim().isEmpty ? null : details.trim(),
        })
        .select('id,reporter_id');
    if (rows.length != 1 || rows.single['reporter_id'] != owner) {
      throw StateError('Envoi non confirmé');
    }
  });
  @override
  Future<bool> canModerate(String owner) => _run(
    owner,
    (check) async => (await client.rpc('kibo_can_moderate')) == true,
  );
  Future<void> _admin(String owner, void Function() check) async {
    if (!await canModerate(owner)) throw StateError('Accès refusé');
    check();
  }

  @override
  Future<List<ContentReport>> reports(
    String owner, {
    required String status,
    int offset = 0,
  }) => _run(owner, (check) async {
    if (!['pending', 'reviewed', 'resolved', 'dismissed'].contains(status) ||
        offset < 0) {
      throw ArgumentError('Filtre invalide');
    }
    await _admin(owner, check);
    final rows = await client
        .from('reports')
        .select(
          'id,listing_id,comment_id,message_id,reported_user_id,reason,details,status',
        )
        .eq('status', status)
        .order('created_at', ascending: false)
        .order('id')
        .range(offset, offset + 19);
    return rows.map(ContentReport.fromJson).toList();
  });
  @override
  Future<List<ModerationRecord>> history(String owner, String reportId) =>
      _run(owner, (check) async {
        await _admin(owner, check);
        final rows = await client
            .from('kibo_moderation_log')
            .select('action,reason,created_at')
            .eq('report_id', reportId)
            .order('created_at', ascending: false)
            .limit(50);
        return rows.map(ModerationRecord.fromJson).toList();
      });
  @override
  Future<void> review(String owner, String id, String action, String reason) =>
      _run(owner, (check) async {
        if (!['dismiss', 'resolve', 'hide'].contains(action) ||
            validateDecision(reason) != null) {
          throw ArgumentError('Décision invalide');
        }
        await _admin(owner, check);
        await client.rpc(
          'kibo_review_report',
          params: {'p_id': id, 'p_action': action, 'p_reason': reason.trim()},
        );
      });
  @override
  Future<Map<String, dynamic>?> content(String owner, String reportId) =>
      _run(owner, (check) async {
        await _admin(owner, check);
        final row = await client.rpc(
          'kibo_report_content',
          params: {'p_id': reportId},
        );
        return row == null ? null : Map<String, dynamic>.from(row as Map);
      });
  @override
  Future<ChatThread?> conversation(String owner, String id) =>
      _run(owner, (check) async {
        final rows = await client
            .from('conversations')
            .select(SupabaseChatRepository.threadColumns)
            .eq('id', id)
            .or('buyer_id.eq.$owner,seller_id.eq.$owner')
            .limit(1);
        return rows.isEmpty ? null : ChatThread.fromJson(rows.single);
      });
}
