import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'listing_models.dart';
import 'listing_photos.dart';
import 'listing_query.dart';
import '../../core/diagnostics/operation_id.dart';

abstract interface class ListingRepository {
  String? get userId;
  Future<List<ListingCategory>> categories();
  Future<String> create(ListingDraft draft, {required String expectedUserId});
  Future<List<PublicListing>> published({
    int offset = 0,
    ListingQuery query = const ListingQuery(),
  });
  Future<PublicListing?> detail(String id);
}

class SearchSuggestion {
  const SearchSuggestion(this.text, {this.correction = false});
  final String text;
  final bool correction;
}

abstract interface class CatalogueDiscoveryRepository {
  Future<List<SearchSuggestion>> suggestions(ListingQuery query);
}

const discoveryV2Enabled = bool.fromEnvironment('KIBO_DISCOVERY_V2_ENABLED');

const basePublicListingColumns =
    'id,seller_id,title,description,price,currency,city,neighborhood,listing_type,status,published_at,category:categories(name)';
const publicListingColumns =
    '$basePublicListingColumns'
    '${listingPhotosEnabled ? ',photos:kibo_listing_photos(path,position)' : ''}';

/// Une relation optionnelle absente ne doit pas rendre les annonces illisibles.
/// Ne jamais contourner une erreur de droits ou une autre relation manquante.
Future<({T data, bool photosUnavailable})> readPublicProjection<T>(
  Future<T> Function(String columns) read,
) async {
  try {
    return (data: await read(publicListingColumns), photosUnavailable: false);
  } on PostgrestException catch (error) {
    if (!listingPhotosEnabled ||
        !{'PGRST200', 'PGRST205', '42P01'}.contains(error.code) ||
        !'${error.message} ${error.details}'.contains('kibo_listing_photos')) {
      rethrow;
    }
    return (
      data: await read(basePublicListingColumns),
      photosUnavailable: true,
    );
  }
}

String listingReadError(Object error, {bool detail = false}) =>
    error is PostgrestException && error.code == '42501'
    ? 'La lecture des annonces est refusée par le serveur. Réessayez après vérification des accès.'
    : detail
    ? 'Impossible de charger cette annonce.'
    : 'Impossible de charger les annonces.';

class ListingPublicationDenied implements Exception {
  const ListingPublicationDenied();
}

abstract interface class IdempotentListingRepository {
  Future<String> createOnce(
    ListingDraft draft, {
    required String expectedUserId,
    required String operationId,
  });
}

class SupabaseListingRepository
    implements
        ListingRepository,
        IdempotentListingRepository,
        CatalogueDiscoveryRepository {
  SupabaseListingRepository(
    this.client, {
    DateTime Function()? clock,
    this.enhancedDiscovery = discoveryV2Enabled,
  }) : _clock = clock ?? DateTime.now;
  final SupabaseClient client;
  final bool enhancedDiscovery;
  final DateTime Function() _clock;
  @override
  Future<List<PublicListing>> published({
    int offset = 0,
    ListingQuery query = const ListingQuery(),
  }) async {
    if (query.validationError != null || offset < 0) {
      throw ArgumentError('Critères invalides.');
    }
    if (enhancedDiscovery && query.text.trim().isNotEmpty) {
      try {
        final rows = await client.rpc(
          'kibo_search_listings',
          params: {
            ..._discoveryParams(query),
            'p_sort': query.sort.name,
            'p_offset': offset,
          },
        );
        return (rows as List)
            .map(
              (r) =>
                  PublicListing.fromJson(Map<String, dynamic>.from(r as Map)),
            )
            .toList();
      } on PostgrestException catch (error) {
        if (error.code != 'PGRST202') rethrow;
      }
    }
    final result = await readPublicProjection((columns) async {
      try {
        return await _publishedRows(
          columns,
          offset,
          query,
          legacySearch: false,
        );
      } on PostgrestException catch (error) {
        if (query.text.trim().isEmpty ||
            error.code != '42703' ||
            !error.message.contains('kibo_search_vector')) {
          rethrow;
        }
        return _publishedRows(columns, offset, query, legacySearch: true);
      }
    });
    return result.data
        .map(
          (row) => PublicListing.fromJson(
            row,
            photosUnavailable: result.photosUnavailable,
          ),
        )
        .toList();
  }

  Map<String, dynamic> _discoveryParams(ListingQuery query) => {
    'p_text': query.text.trim(),
    'p_category': query.categoryId,
    'p_city': query.city.trim(),
    'p_min': listingPriceValue(query.minPrice),
    'p_max': listingPriceValue(query.maxPrice),
  };

  @override
  Future<List<SearchSuggestion>> suggestions(ListingQuery query) async {
    if (!enhancedDiscovery ||
        query.text.trim().runes.length < 3 ||
        query.validationError != null) {
      return [];
    }
    try {
      final rows = await client.rpc(
        'kibo_search_suggestions',
        params: _discoveryParams(query),
      );
      return (rows as List)
          .map(
            (r) => SearchSuggestion(
              r['text'] as String,
              correction: r['correction'] == true,
            ),
          )
          .toList();
    } on PostgrestException catch (error) {
      if (error.code == 'PGRST202') return [];
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _publishedRows(
    String columns,
    int offset,
    ListingQuery query, {
    required bool legacySearch,
  }) async {
    var request = client
        .from('listings')
        .select(columns)
        .eq('status', 'published');
    final prefix = listingPrefixQuery(query.text);
    if (prefix.isNotEmpty) {
      if (legacySearch) {
        // Chaîne JSON citée : virgules/parenthèses du texte ne peuvent pas
        // injecter de nouveaux filtres PostgREST. Recherche française serveur.
        final term = jsonEncode(prefix);
        request = request.or(
          'title.fts(french).$term,description.fts(french).$term',
        );
      } else {
        request = request.textSearch(
          'kibo_search_vector',
          prefix,
          config: 'french',
        );
      }
    }
    if (query.categoryId != null) {
      request = request.eq('category_id', query.categoryId!);
    }
    if (query.city.trim().isNotEmpty) {
      request = request.eq('city', query.city.trim());
    }
    if (query.minPrice.trim().isNotEmpty) {
      request = request.gte('price', normalizePrice(query.minPrice));
    }
    if (query.maxPrice.trim().isNotEmpty) {
      request = request.lte('price', normalizePrice(query.maxPrice));
    }
    var sorted =
        query.sort == ListingSort.newest || query.sort == ListingSort.relevance
        ? request.order('published_at', ascending: false, nullsFirst: false)
        : request
              .order(
                'price',
                ascending: query.sort == ListingSort.priceAscending,
              )
              .order('published_at', ascending: false, nullsFirst: false);
    final rows = await sorted
        .order('id', ascending: true)
        .range(offset, offset + 19);
    return rows;
  }

  @override
  Future<PublicListing?> detail(String id) async {
    final result = await readPublicProjection(
      (columns) => client
          .from('listings')
          .select(columns)
          .eq('status', 'published')
          .eq('id', id)
          .limit(1),
    );
    final row = result.data.isEmpty ? null : result.data.single;
    return row == null
        ? null
        : PublicListing.fromJson(
            row,
            photosUnavailable: result.photosUnavailable,
          );
  }

  @override
  String? get userId {
    final session = client.auth.currentSession;
    return session == null || session.isExpired ? null : session.user.id;
  }

  @override
  Future<List<ListingCategory>> categories() async {
    final rows = await client
        .from('categories')
        .select('id,name')
        .eq('is_active', true)
        .order('sort_order')
        .order('id');
    return rows
        .map(
          (row) => ListingCategory(
            id: row['id'] as String,
            name: row['name'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<String> create(ListingDraft draft, {required String expectedUserId}) =>
      _create(draft, expectedUserId: expectedUserId);
  @override
  Future<String> createOnce(
    ListingDraft draft, {
    required String expectedUserId,
    required String operationId,
  }) {
    if (!isOperationId(operationId)) {
      throw ArgumentError('Identifiant invalide');
    }
    return _create(
      draft,
      expectedUserId: expectedUserId,
      operationId: operationId,
    );
  }

  Future<String> _create(
    ListingDraft draft, {
    required String expectedUserId,
    String? operationId,
  }) async {
    if (userId == null || userId != expectedUserId) {
      throw StateError('Session modifiée.');
    }
    validateDraft(draft);
    List<Map<String, dynamic>> rows;
    try {
      rows = await client
          .from('listings')
          .insert({
            'id': ?operationId,
            'seller_id': expectedUserId,
            'category_id': draft.categoryId,
            'title': draft.title.trim(),
            'description': draft.description.trim(),
            'price': listingPriceValue(draft.price),
            'listing_type': draft.type,
            'status': 'published',
            // Le trigger proposé normalise cette date avec l’horloge serveur.
            'published_at': _clock().toUtc().toIso8601String(),
            'city': draft.city.trim(),
            'neighborhood': draft.neighborhood.trim().isEmpty
                ? null
                : draft.neighborhood.trim(),
          })
          .select('id,status,published_at');
    } on PostgrestException catch (error) {
      if (error.code == '42501') throw const ListingPublicationDenied();
      if (error.code != '23505' ||
          operationId == null ||
          userId != expectedUserId) {
        rethrow;
      }
      final existing = await client
          .from('listings')
          .select(
            'id,seller_id,title,description,price,city,neighborhood,category_id,listing_type,status,published_at',
          )
          .eq('id', operationId)
          .eq('seller_id', expectedUserId)
          .limit(1);
      if (existing.length != 1) rethrow;
      final row = existing.single;
      if (row['title'] != draft.title.trim() ||
          row['description'] != draft.description.trim() ||
          !sameListingPrice(row['price'], listingPriceValue(draft.price)) ||
          row['city'] != draft.city.trim() ||
          (row['neighborhood'] ?? '') != draft.neighborhood.trim() ||
          row['category_id'] != draft.categoryId ||
          row['listing_type'] != draft.type) {
        throw StateError('Conflit de publication');
      }
      rows = existing;
    }
    if (userId != expectedUserId) throw StateError('Session modifiée');
    if (rows.length != 1 ||
        (operationId != null && rows.single['id'] != operationId) ||
        rows.single['status'] != 'published' ||
        DateTime.tryParse(rows.single['published_at']?.toString() ?? '') ==
            null) {
      throw StateError('Résultat de création inattendu.');
    }
    return rows.single['id'] as String;
  }
}
