import 'package:supabase_flutter/supabase_flutter.dart';
import '../listings/listing_models.dart';
import '../listings/listing_repository.dart';

abstract interface class FavoritesRepository {
  String? get userId;
  Future<Set<String>> ids(String expectedUserId);
  Future<List<PublicListing>> visible(String expectedUserId, {int offset = 0});
  Future<void> add(String id, String expectedUserId);
  Future<void> remove(String id, String expectedUserId);
}

class SupabaseFavoritesRepository implements FavoritesRepository {
  SupabaseFavoritesRepository(this.client);
  final SupabaseClient client;
  @override
  String? get userId {
    final session = client.auth.currentSession;
    return session == null || session.isExpired ? null : session.user.id;
  }

  void _check(String expected) {
    if (userId == null || userId != expected) {
      throw StateError('Session modifiée.');
    }
  }

  @override
  Future<Set<String>> ids(String expectedUserId) async {
    final ids = <String>{};
    for (var offset = 0; ; offset += 500) {
      _check(expectedUserId);
      final rows = await client
          .from('favorites')
          .select('listing_id')
          .eq('user_id', expectedUserId)
          .order('listing_id')
          .range(offset, offset + 499);
      ids.addAll(rows.map((row) => row['listing_id'] as String));
      if (rows.length < 500) return ids;
    }
  }

  @override
  Future<List<PublicListing>> visible(
    String expectedUserId, {
    int offset = 0,
  }) async {
    _check(expectedUserId);
    final result = await readPublicProjection(
      (columns) => client
          .from('favorites')
          .select('listing:listings!inner($columns)')
          .eq('user_id', expectedUserId)
          .eq('listing.status', 'published')
          .order('created_at', ascending: false)
          .order('listing_id')
          .range(offset, offset + 19),
    );
    return result.data
        .map(
          (row) => PublicListing.fromJson(
            row['listing'] as Map<String, dynamic>,
            photosUnavailable: result.photosUnavailable,
          ),
        )
        .toList();
  }

  @override
  Future<void> add(String id, String expectedUserId) async {
    _check(expectedUserId);
    try {
      await client.from('favorites').insert({
        'user_id': expectedUserId,
        'listing_id': id,
      });
    } on PostgrestException catch (error) {
      // La seule unicité déployée est la clé composée : un ajout répété est idempotent.
      if (error.code != '23505') rethrow;
    }
  }

  @override
  Future<void> remove(String id, String expectedUserId) async {
    _check(expectedUserId);
    await client
        .from('favorites')
        .delete()
        .eq('user_id', expectedUserId)
        .eq('listing_id', id);
  }
}
