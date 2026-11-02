class ListingCategory {
  const ListingCategory({required this.id, required this.name});
  final String id;
  final String name;
}

class PublicListing {
  const PublicListing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.city,
    this.neighborhood,
    this.type = 'product',
    this.categoryName,
    this.photoPaths = const [],
    this.photosUnavailable = false,
    this.sellerId,
    this.publishedAt,
  });
  final String id, title, description, price, city, type;
  final String? sellerId;
  final String? neighborhood, categoryName;
  final List<String> photoPaths;
  final bool photosUnavailable;
  final DateTime? publishedAt;
  factory PublicListing.fromJson(
    Map<String, dynamic> row, {
    bool photosUnavailable = false,
  }) {
    if (row['status'] != 'published' || row['currency'] != 'XAF') {
      throw StateError('Annonce hors du catalogue public.');
    }
    return PublicListing(
      id: row['id'] as String,
      sellerId: row['seller_id'] as String?,
      title: row['title'] as String,
      description: row['description'] as String,
      price: row['price']?.toString() ?? '',
      city: row['city'] as String,
      neighborhood: row['neighborhood'] as String?,
      type: row['listing_type'] as String,
      categoryName:
          (row['category'] as Map<String, dynamic>?)?['name'] as String?,
      photoPaths: _photoPaths(row['photos']),
      photosUnavailable: photosUnavailable,
      publishedAt: row['published_at'] is String
          ? DateTime.tryParse(row['published_at'] as String)?.toUtc()
          : null,
    );
  }
  String get priceLabel => formatListingPrice(price);

  String get location => neighborhood == null || neighborhood!.isEmpty
      ? city
      : '$neighborhood, $city';
}

String formatListingPrice(String price) {
  if (price.trim().isEmpty) return 'Prix à négocier';
  final parts = price.split('.');
  final grouped = parts.first.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]} ',
  );
  return '$grouped${parts.length > 1 && int.tryParse(parts[1]) != 0 ? ',${parts[1]}' : ''} XAF';
}

List<String> _photoPaths(Object? value) {
  if (value == null) return const [];
  final photos = (value as List).cast<Map<String, dynamic>>().toList()
    ..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));
  return List.unmodifiable(photos.take(3).map((p) => p['path'] as String));
}

class ListingDraft {
  const ListingDraft({
    required this.title,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.city,
    this.type = 'product',
    this.neighborhood = '',
  });
  final String title, description, price, categoryId, city, type, neighborhood;
}

/// Prix décimal transmis comme chaîne à PostgreSQL, sans arrondi binaire.
String normalizePrice(String value) => value
    .trim()
    .replaceAll(RegExp(r'[ \u00a0\u202f]'), '')
    .replaceAll(',', '.');

String? listingPriceValue(String value) =>
    value.trim().isEmpty ? null : normalizePrice(value);

bool sameListingPrice(Object? actual, Object? expected) {
  final a = actual?.toString() ?? '', b = expected?.toString() ?? '';
  if (a.trim().isEmpty || b.trim().isEmpty) {
    return a.trim().isEmpty && b.trim().isEmpty;
  }
  if (validateListingPrice(a) != null || validateListingPrice(b) != null) {
    return false;
  }
  BigInt cents(String value) {
    final p = normalizePrice(value).split('.');
    return BigInt.parse(p.first) * BigInt.from(100) +
        BigInt.parse(p.length == 1 ? '0' : p.last.padRight(2, '0'));
  }

  return cents(a) == cents(b);
}

String? validateListingTitle(String? value) {
  final length = (value ?? '').trim().runes.length;
  return length < 5 || length > 120
      ? 'Le titre doit contenir entre 5 et 120 caractères.'
      : null;
}

String? validateListingDescription(String? value) {
  final length = (value ?? '').trim().runes.length;
  return length < 10 || length > 10000
      ? 'La description doit contenir entre 10 et 10 000 caractères.'
      : null;
}

String? validateListingPrice(String? value) =>
    (value ?? '').trim().isEmpty ||
        RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(normalizePrice(value ?? ''))
    ? null
    : 'Indiquez un prix XAF positif ou nul, avec au plus 12 chiffres et 2 décimales.';

String? validateListingCity(String? value) =>
    (value ?? '').trim().isEmpty || (value ?? '').trim().runes.length > 120
    ? 'Renseignez une ville de 1 à 120 caractères.'
    : null;

void validateDraft(ListingDraft draft) {
  if (validateListingTitle(draft.title) != null ||
      validateListingDescription(draft.description) != null ||
      validateListingPrice(draft.price) != null ||
      validateListingCity(draft.city) != null ||
      draft.categoryId.isEmpty ||
      !const ['product', 'service'].contains(draft.type)) {
    throw ArgumentError('Annonce invalide.');
  }
}
