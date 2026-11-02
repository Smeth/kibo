import 'listing_models.dart';

// Pas d'opérateurs tsquery fournis par le client : uniquement lettres/chiffres.
String listingPrefixQuery(String text) => RegExp(
  r'[\p{L}\p{N}]+',
  unicode: true,
).allMatches(text).map((m) => '${m.group(0)!}:*').join(' & ');

enum ListingSort { relevance, newest, priceAscending, priceDescending }

class ListingQuery {
  const ListingQuery({
    this.text = '',
    this.categoryId,
    this.city = '',
    this.minPrice = '',
    this.maxPrice = '',
    this.sort = ListingSort.relevance,
  });
  final String text, city, minPrice, maxPrice;
  final String? categoryId;
  final ListingSort sort;
  bool get isEmpty =>
      text.trim().isEmpty &&
      categoryId == null &&
      city.trim().isEmpty &&
      minPrice.isEmpty &&
      maxPrice.isEmpty &&
      sort == ListingSort.relevance;
  String? get validationError {
    if (text.trim().runes.length > 120 || city.trim().runes.length > 120) {
      return 'Recherche et ville limitées à 120 caractères.';
    }
    if (text.trim().isNotEmpty && listingPrefixQuery(text).isEmpty) {
      return 'Saisissez au moins une lettre ou un chiffre pour rechercher.';
    }
    for (final price in [minPrice, maxPrice]) {
      if (price.trim().isNotEmpty && validateListingPrice(price) != null) {
        return 'Indiquez des prix XAF positifs ou nuls.';
      }
    }
    if (minPrice.trim().isNotEmpty &&
        maxPrice.trim().isNotEmpty &&
        _cents(minPrice) > _cents(maxPrice)) {
      return 'Le prix minimum doit être inférieur ou égal au maximum.';
    }
    return null;
  }

  int _cents(String value) {
    final parts = normalizePrice(value).split('.');
    return int.parse(parts.first) * 100 +
        (parts.length == 1 ? 0 : int.parse(parts.last.padRight(2, '0')));
  }
}
