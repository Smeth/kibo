import 'listing_query.dart';

enum OwnedListingStatus {
  all('Tous les statuts'),
  published('Publiée'),
  sold('Vendue'),
  archived('Archivée'),
  draft('Brouillon'),
  pending('En attente'),
  rejected('Refusée');

  const OwnedListingStatus(this.label);
  final String label;
}

class OwnedListingQuery {
  const OwnedListingQuery({
    this.status = OwnedListingStatus.all,
    this.text = '',
  });
  final OwnedListingStatus status;
  final String text;
  bool get isEmpty => status == OwnedListingStatus.all && text.trim().isEmpty;
  String? get validationError => text.trim().runes.length > 120
      ? 'La recherche est limitée à 120 caractères.'
      : text.trim().isNotEmpty && listingPrefixQuery(text).isEmpty
      ? 'Saisissez au moins une lettre ou un chiffre pour rechercher.'
      : null;
}
