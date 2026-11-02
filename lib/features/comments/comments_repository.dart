import 'package:supabase_flutter/supabase_flutter.dart';

String? validateComment(String? value) {
  final length = (value ?? '').trim().runes.length;
  return length < 1 || length > 2000
      ? 'Écrivez entre 1 et 2 000 caractères.'
      : null;
}

class ListingComment {
  const ListingComment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.parentId,
    this.authorDeleted = false,
  });
  final String id, content;
  final String? userId;
  final bool authorDeleted;
  final String? parentId;
  final DateTime createdAt;
  factory ListingComment.fromJson(Map<String, dynamic> row) {
    if (row['status'] != 'published' || row['deleted_at'] != null) {
      throw StateError('Commentaire indisponible.');
    }
    final deleted = row['author_deleted'] == true;
    if (deleted != (row['user_id'] == null)) {
      throw const FormatException('Auteur incohérent');
    }
    return ListingComment(
      id: row['id'] as String,
      userId: row['user_id'] as String?,
      content: deleted ? 'Commentaire anonymisé' : row['content'] as String,
      authorDeleted: deleted,
      parentId: row['parent_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

abstract interface class CommentsRepository {
  String? get userId;
  Future<List<ListingComment>> read(
    String listingId, {
    String? parentId,
    int offset = 0,
  });
  Future<void> create(
    String listingId,
    String content, {
    required String expectedUserId,
    String? parentId,
  });
}

class SupabaseCommentsRepository implements CommentsRepository {
  SupabaseCommentsRepository(this.client);
  final SupabaseClient client;
  static const columns =
      'id,listing_id,user_id,parent_id,content,status,deleted_at,created_at';
  @override
  String? get userId {
    final session = client.auth.currentSession;
    return session == null || session.isExpired ? null : session.user.id;
  }

  void _check(String expected) {
    if (userId != expected || userId == null) {
      throw StateError('Session modifiée.');
    }
  }

  Future<void> _parent(String listingId, String parentId) async {
    final rows = await client
        .from('listing_comments')
        .select('$columns,listing:listings!inner(status)')
        .eq('listing_id', listingId)
        .eq('id', parentId)
        .eq('status', 'published')
        .isFilter('deleted_at', null)
        .isFilter('parent_id', null)
        .eq('listing.status', 'published')
        .limit(1);
    if (rows.length != 1) throw StateError('Discussion indisponible.');
  }

  @override
  Future<List<ListingComment>> read(
    String listingId, {
    String? parentId,
    int offset = 0,
  }) async {
    if (offset < 0) throw ArgumentError('Pagination invalide.');
    if (parentId != null) await _parent(listingId, parentId);
    var request = client
        .from('listing_comments')
        .select('$columns,listing:listings!inner(status)')
        .eq('listing_id', listingId)
        .eq('status', 'published')
        .isFilter('deleted_at', null)
        .eq('listing.status', 'published');
    request = parentId == null
        ? request.isFilter('parent_id', null)
        : request.eq('parent_id', parentId);
    final rows = await request
        .order('created_at', ascending: parentId != null)
        .order('id', ascending: true)
        .range(offset, offset + 19);
    if (rows.any(
      (r) => r['listing_id'] != listingId || r['parent_id'] != parentId,
    )) {
      throw StateError('Discussion inattendue.');
    }
    return rows.map(ListingComment.fromJson).toList();
  }

  @override
  Future<void> create(
    String listingId,
    String content, {
    required String expectedUserId,
    String? parentId,
  }) async {
    _check(expectedUserId);
    if (validateComment(content) != null) {
      throw ArgumentError('Texte invalide.');
    }
    if (parentId != null) await _parent(listingId, parentId);
    _check(expectedUserId);
    final rows = await client
        .from('listing_comments')
        .insert({
          'listing_id': listingId,
          'user_id': expectedUserId,
          'content': content.trim(),
          'parent_id': ?parentId,
        })
        .select(columns);
    _check(expectedUserId);
    if (rows.length != 1 ||
        rows.single['listing_id'] != listingId ||
        rows.single['user_id'] != expectedUserId ||
        rows.single['parent_id'] != parentId ||
        rows.single['content'] != content.trim()) {
      throw StateError('Publication non confirmée.');
    }
    ListingComment.fromJson(rows.single);
  }
}
