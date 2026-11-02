import 'dart:async';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_repository.dart';
import 'package:kibo/features/listings/listing_query.dart';
import 'package:kibo/features/favorites/favorites_repository.dart';

class FakeListingRepository implements ListingRepository {
  @override
  String? userId = 'test-user-a';
  List<ListingCategory> categoryRows = const [
    ListingCategory(id: 'category-a', name: 'Catégorie test'),
  ];
  Object? categoryError, createError;
  Completer<String>? pendingCreate;
  int creates = 0;
  ListingDraft? lastDraft;
  bool publishCreates = false;
  List<PublicListing> listings = const [
    PublicListing(
      id: 'listing-a',
      title: 'Smartphone Android',
      description: 'Description du smartphone',
      price: '85000',
      city: 'Brazzaville',
    ),
    PublicListing(
      id: 'listing-b',
      title: 'Canapé moderne',
      description: 'Description du canapé',
      price: '150000',
      city: 'Brazzaville',
    ),
    PublicListing(
      id: 'listing-c',
      title: 'Moto en bon état',
      description: 'Description de la moto',
      price: '450000',
      city: 'Brazzaville',
    ),
    PublicListing(
      id: 'listing-d',
      title: 'Appartement à louer',
      description: 'Description de l’appartement',
      price: '120000',
      city: 'Brazzaville',
    ),
  ];
  Object? readError;
  Completer<List<PublicListing>>? pendingRead;
  int? lastOffset;
  ListingQuery? lastQuery;
  @override
  Future<List<PublicListing>> published({
    int offset = 0,
    ListingQuery query = const ListingQuery(),
  }) async {
    lastQuery = query;
    lastOffset = offset;
    if (readError != null) throw readError!;
    if (pendingRead != null) return pendingRead!.future;
    return listings.skip(offset).take(20).toList();
  }

  @override
  Future<PublicListing?> detail(String id) async {
    if (readError != null) throw readError!;
    for (final row in listings) {
      if (row.id == id) return row;
    }
    return null;
  }

  @override
  Future<List<ListingCategory>> categories() async {
    if (categoryError != null) throw categoryError!;
    return categoryRows;
  }

  @override
  Future<String> create(
    ListingDraft draft, {
    required String expectedUserId,
  }) async {
    creates++;
    lastDraft = draft;
    if (createError != null) throw createError!;
    final id = pendingCreate == null
        ? 'created-listing'
        : await pendingCreate!.future;
    if (publishCreates) {
      listings = [
        PublicListing(
          id: id,
          title: draft.title.trim(),
          description: draft.description.trim(),
          price: normalizePrice(draft.price),
          city: draft.city.trim(),
          type: draft.type,
        ),
        ...listings,
      ];
    }
    return id;
  }
}

class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository({FakeListingRepository? listings})
    : listings = listings ?? FakeListingRepository();
  @override
  String? userId = 'test-user-a';
  final Map<String, Set<String>> _savedByUser = {};
  Set<String> get saved =>
      _savedByUser.putIfAbsent(userId ?? '', () => <String>{});
  set saved(Set<String> value) => _savedByUser[userId ?? ''] = value;
  final FakeListingRepository listings;
  Object? failure;
  Completer<void>? pending;
  Completer<Set<String>>? pendingIds;
  int adds = 0, removes = 0;
  @override
  Future<Set<String>> ids(String expectedUserId) async {
    if (failure != null) throw failure!;
    return pendingIds == null ? {...saved} : pendingIds!.future;
  }

  @override
  Future<List<PublicListing>> visible(
    String expectedUserId, {
    int offset = 0,
  }) async {
    if (failure != null) throw failure!;
    return listings.listings
        .where((row) => saved.contains(row.id))
        .skip(offset)
        .take(20)
        .toList();
  }

  @override
  Future<void> add(String id, String expectedUserId) async {
    adds++;
    await pending?.future;
    if (failure != null) throw failure!;
    saved.add(id);
  }

  @override
  Future<void> remove(String id, String expectedUserId) async {
    removes++;
    await pending?.future;
    if (failure != null) throw failure!;
    saved.remove(id);
  }
}
