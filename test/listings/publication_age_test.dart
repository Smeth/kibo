import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/widgets/publication_age.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_card.dart';

void main() {
  final now = DateTime.utc(2026, 11, 1, 12);
  test('ancienneté : minutes, heures, jours et unités longues', () {
    for (final entry in <Duration, String>{
      const Duration(seconds: 30): 'à l’instant',
      const Duration(minutes: 59): 'il y a 59 min',
      const Duration(hours: 1): 'il y a 1 h',
      const Duration(hours: 23): 'il y a 23 h',
      const Duration(days: 2): 'il y a 2 j',
      const Duration(days: 60): 'il y a 2 mois',
      const Duration(days: 730): 'il y a 2 ans',
    }.entries) {
      expect(
        publicationAgeLabel(now.subtract(entry.key), now: now),
        entry.value,
      );
    }
  });
  test('aucune ancienneté inventée pour une date absente ou future', () {
    expect(publicationAgeLabel(null, now: now), isNull);
    expect(
      publicationAgeLabel(now.add(const Duration(days: 1)), now: now),
      startsWith('Publié le '),
    );
  });
  test('la projection publique conserve published_at et son fuseau', () {
    final row = <String, dynamic>{
      'id': 'fictif',
      'title': 'Smartphone',
      'description': 'Fictif',
      'price': 95000,
      'city': 'Brazzaville',
      'status': 'published',
      'listing_type': 'product',
      'currency': 'XAF',
      'published_at': '2026-11-01T14:00:00+02:00',
    };
    expect(PublicListing.fromJson(row).publishedAt, now);
    row['published_at'] = 'invalide';
    expect(PublicListing.fromJson(row).publishedAt, isNull);
    row.remove('published_at');
    expect(PublicListing.fromJson(row).publishedAt, isNull);
  });
  testWidgets('la carte affiche la vraie ancienneté en grille et en liste', (
    tester,
  ) async {
    final listing = PublicListing(
      id: 'fictif',
      title: 'Smartphone',
      description: 'Fictif',
      price: '95000',
      city: 'Brazzaville',
      publishedAt: DateTime.now().subtract(
        const Duration(hours: 2, minutes: 10),
      ),
    );
    for (final compact in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: Scaffold(
            body: ListingCard(
              listing: listing,
              imageHeight: 160,
              compact: compact,
              onOpen: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('il y a 2 h'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
