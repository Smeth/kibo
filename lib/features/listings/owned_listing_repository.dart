import 'package:supabase_flutter/supabase_flutter.dart';

import 'listing_models.dart';
import 'owned_listing_query.dart';
import 'listing_query.dart';
import 'listing_repository.dart' show discoveryV2Enabled;
import 'listing_photos.dart';

class OwnedListing {
  const OwnedListing({
    required this.id,
    required this.sellerId,
    required this.status,
    required this.updatedAt,
    required this.draft,
    this.photoPaths = const [],
  });
  final String id, sellerId, status, updatedAt;
  final ListingDraft draft;
  String get priceLabel => formatListingPrice(draft.price);
  final List<String> photoPaths;
  bool get canEdit => status == 'published' || status == 'draft';
  bool get canSell => status == 'published';
  bool get canArchive => status == 'published' || status == 'sold';
  String get statusLabel => switch (status) {
    'published' => 'Publiée',
    'sold' => 'Vendue',
    'archived' => 'Archivée',
    'draft' => 'Brouillon',
    'pending' => 'En attente',
    'rejected' => 'Refusée',
    _ => 'Indisponible',
  };
  factory OwnedListing.fromJson(Map<String, dynamic> row) => OwnedListing(
    id: row['id'] as String,
    sellerId: row['seller_id'] as String,
    status: row['status'] as String,
    updatedAt: row['updated_at'] as String,
    photoPaths: _photos(row['photos']),
    draft: ListingDraft(
      title: row['title'] as String,
      description: row['description'] as String,
      price: row['price']?.toString() ?? '',
      categoryId: row['category_id'] as String,
      city: row['city'] as String,
      neighborhood: row['neighborhood'] as String? ?? '',
      type: row['listing_type'] as String,
    ),
  );
  static List<String> _photos(Object? value) {
    if (value is! List) return const [];
    final rows =
        value
            .whereType<Map>()
            .where((r) => r['position'] is int && r['path'] is String)
            .toList()
          ..sort(
            (a, b) => (a['position'] as int).compareTo(b['position'] as int),
          );
    return rows.take(3).map((r) => r['path'] as String).toList();
  }
}

class ListingManagementConflict implements Exception {
  const ListingManagementConflict();
}

class ListingManagementUnconfirmed implements Exception {
  const ListingManagementUnconfirmed();
}

String listingManagementError(Object error) {
  if (error is ListingManagementUnconfirmed) {
    return 'L’enregistrement n’a pas pu être confirmé. Actualisez l’annonce avant de réessayer.';
  }
  if (error is ListingManagementConflict) {
    return 'Cette annonce a changé ou n’est plus accessible. Actualisez avant de réessayer.';
  }
  if (error is PostgrestException &&
      (error.code == '42501' || error.code == '22P02')) {
    return 'Cette action est refusée par le serveur. Les droits ou les transitions de statut doivent être vérifiés.';
  }
  if (error is StateError) {
    return 'Votre session a changé. Reconnectez-vous avant de continuer.';
  }
  return 'Impossible d’enregistrer. Vérifiez votre connexion puis actualisez l’annonce avant de réessayer.';
}

abstract interface class OwnedListingRepository {
  String? get userId;
  Future<List<OwnedListing>> mine(
    String ownerId, {
    int offset = 0,
    OwnedListingQuery query = const OwnedListingQuery(),
  });
  Future<void> edit(OwnedListing listing, ListingDraft draft);
  Future<void> transition(OwnedListing listing, String status);
}

class SupabaseOwnedListingRepository implements OwnedListingRepository {
  SupabaseOwnedListingRepository(
    this.client, {
    this.withPhotos = listingPhotosEnabled,
    this.enhancedDiscovery = discoveryV2Enabled,
  });
  final SupabaseClient client;
  final bool withPhotos;
  final bool enhancedDiscovery;
  static const columns =
      'id,seller_id,status,updated_at,title,description,price,category_id,city,neighborhood,listing_type';
  @override
  String? get userId {
    final session = client.auth.currentSession;
    return session == null || session.isExpired ? null : session.user.id;
  }

  void _check(String owner) {
    if (userId == null || userId != owner) {
      throw StateError('Session modifiée.');
    }
  }

  @override
  Future<List<OwnedListing>> mine(
    String ownerId, {
    int offset = 0,
    OwnedListingQuery query = const OwnedListingQuery(),
  }) async {
    _check(ownerId);
    if (offset < 0 || query.validationError != null) {
      throw ArgumentError('Critères invalides.');
    }
    if (enhancedDiscovery && query.text.trim().isNotEmpty) {
      try {
        final rows = await client.rpc(
          'kibo_search_owned',
          params: {
            'p_text': query.text.trim(),
            'p_status': query.status == OwnedListingStatus.all
                ? null
                : query.status.name,
            'p_offset': offset,
          },
        );
        _check(ownerId);
        final result = (rows as List)
            .map(
              (r) => OwnedListing.fromJson(Map<String, dynamic>.from(r as Map)),
            )
            .toList();
        if (result.any((r) => r.sellerId != ownerId)) {
          throw StateError('Propriétaire inattendu.');
        }
        return result;
      } on PostgrestException catch (error) {
        if (error.code != 'PGRST202') rethrow;
      }
    }
    var request = client
        .from('listings')
        .select(
          withPhotos
              ? '$columns,photos:kibo_listing_photos(path,position)'
              : columns,
        )
        .eq('seller_id', ownerId);
    if (query.status != OwnedListingStatus.all) {
      request = request.eq('status', query.status.name);
    }
    final prefix = listingPrefixQuery(query.text);
    if (prefix.isNotEmpty) {
      request = request.textSearch(
        'kibo_search_vector',
        prefix,
        config: 'french',
      );
    }
    final rows = await request
        .order('created_at', ascending: false)
        .order('id', ascending: true)
        .range(offset, offset + 19);
    _check(ownerId);
    if (rows.any((row) => row['seller_id'] != ownerId)) {
      throw StateError('Propriétaire inattendu.');
    }
    return rows.map(OwnedListing.fromJson).toList();
  }

  @override
  Future<void> edit(OwnedListing listing, ListingDraft draft) async {
    _check(listing.sellerId);
    if (!listing.canEdit) throw const ListingManagementConflict();
    validateDraft(draft);
    await _update(listing, {
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'price': listingPriceValue(draft.price),
      'category_id': draft.categoryId,
      'city': draft.city.trim(),
      'neighborhood': draft.neighborhood.trim().isEmpty
          ? null
          : draft.neighborhood.trim(),
      'listing_type': draft.type,
    });
  }

  @override
  Future<void> transition(OwnedListing listing, String status) async {
    _check(listing.sellerId);
    if (!(status == 'sold' && listing.canSell ||
        status == 'archived' && listing.canArchive)) {
      throw const ListingManagementConflict();
    }
    await _update(listing, {'status': status});
  }

  Future<void> _update(
    OwnedListing listing,
    Map<String, dynamic> values,
  ) async {
    _check(listing.sellerId);
    final rows = await client
        .from('listings')
        .update(values)
        .eq('id', listing.id)
        .eq('seller_id', listing.sellerId)
        .eq('status', listing.status)
        .eq('updated_at', listing.updatedAt)
        .select(columns);
    _check(listing.sellerId);
    if (rows.length != 1 || rows.single['id'] != listing.id) {
      throw const ListingManagementConflict();
    }
    final row = rows.single;
    if (row['seller_id'] != listing.sellerId ||
        row['status'] != (values['status'] ?? listing.status) ||
        DateTime.tryParse(row['updated_at']?.toString() ?? '') == null ||
        values.entries.any(
          (entry) => entry.key == 'price'
              ? !sameListingPrice(row[entry.key], entry.value)
              : row[entry.key] != entry.value,
        )) {
      throw const ListingManagementUnconfirmed();
    }
  }
}
