import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/main.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/listings/catalogue_search_form.dart';
import 'package:kibo/features/listings/listing_feed.dart';
import 'package:kibo/features/listings/listing_query.dart';
import '../support/listing_fake.dart';

void main() {
  testWidgets('critere actif peut etre retire individuellement', (
    tester,
  ) async {
    ListingQuery? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CatalogueSearchForm(
              repository: FakeListingRepository(),
              initialQuery: const ListingQuery(
                text: 'moto',
                city: 'Brazzaville',
              ),
              onApply: (q) => result = q,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final chip = find.widgetWithText(InputChip, 'Recherche : moto');
    await tester.ensureVisible(chip);
    final onDeleted = tester.widget<InputChip>(chip).onDeleted!;
    onDeleted();
    await tester.pumpAndSettle();
    expect(result!.text, isEmpty);
    expect(result!.city, 'Brazzaville');
  });
  testWidgets('recherche conservee apres changement onglet', (tester) async {
    final repo = FakeListingRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: KiboHomePage(repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recherche'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('catalogue-search')),
      'moto',
    );
    await tester.ensureVisible(find.text('Rechercher'));
    await tester.tap(find.text('Rechercher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recherche'));
    await tester.pumpAndSettle();
    expect(repo.lastQuery!.text, 'moto');
    expect(
      tester
          .widget<SearchBar>(find.byKey(const ValueKey('catalogue-search')))
          .controller!
          .text,
      'moto',
    );
  });
  testWidgets('etat vide propose remise a zero des filtres', (tester) async {
    final repo = FakeListingRepository()..listings = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: Scaffold(
          body: ListingFeed(
            repository: repo,
            initialQuery: const ListingQuery(city: 'Brazzaville'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réinitialiser les filtres'));
    await tester.pumpAndSettle();
    expect(repo.lastQuery!.isEmpty, true);
  });
}
