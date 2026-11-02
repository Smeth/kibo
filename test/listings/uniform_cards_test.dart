import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/listings/listing_feed.dart';
import 'package:kibo/features/listings/listing_models.dart';
import '../support/listing_fake.dart';
import '../support/manrope_fonts.dart';

void main() {
  setUpAll(loadManropeFonts);
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'hauteurs égales entre lignes malgré titres, prix, villes et photos : texte $scale',
      (tester) async {
        tester.view.physicalSize = const Size(393, 852);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final rows = [
          const PublicListing(
            id: 'a',
            title: 'Moto',
            description: 'Fictif',
            price: '1000',
            city: 'Oyo',
          ),
          PublicListing(
            id: 'b',
            title:
                'Un titre volontairement très long pour vérifier une annonce sur plusieurs lignes',
            description: 'Fictif',
            price: '999999999999.50',
            city: 'Une localité au nom particulièrement long',
            photoPaths: const ['fixture'],
            publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          const PublicListing(
            id: 'c',
            title: 'Service',
            description: 'Fictif',
            price: '25000',
            city: 'Brazzaville',
            photosUnavailable: true,
          ),
          const PublicListing(
            id: 'd',
            title: 'Appartement à louer avec terrasse et plusieurs chambres',
            description: 'Fictif',
            price: '850000',
            city: 'Pointe-Noire',
          ),
        ];
        await tester.pumpWidget(
          MaterialApp(
            theme: scale == 1 ? KiboTheme.light : KiboTheme.dark,
            home: Scaffold(
              body: ListingFeed(
                repository: FakeListingRepository()..listings = rows,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final sizes = <Size>[];
        for (final row in rows) {
          final card = find.byKey(ValueKey('listing-card-${row.title}'));
          await tester.scrollUntilVisible(
            card,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          sizes.add(tester.getSize(card));
        }
        for (final size in sizes.skip(1)) {
          expect(size.height, closeTo(sizes.first.height, .01));
          expect(size.width, closeTo(sizes.first.width, .01));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
