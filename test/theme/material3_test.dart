import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_colors.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/listings/listing_card.dart';
import 'package:kibo/features/listings/listing_feed.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_query.dart';
import 'package:kibo/features/listings/catalogue_search_form.dart';
import 'package:kibo/features/listings/listing_photo_widgets.dart';
import 'package:kibo/features/listings/listing_photos.dart';
import 'package:kibo/main.dart';
import '../support/listing_fake.dart';
import '../support/manrope_fonts.dart';

class _LargeFixture extends FakeListingRepository {
  _LargeFixture() {
    listings = List.generate(
      200,
      (i) => PublicListing(
        id: 'local-$i',
        title: 'Fictif $i',
        description: 'Fictif',
        price: '95000',
        city: 'Brazzaville',
      ),
    );
  }
  @override
  Future<List<PublicListing>> published({
    int offset = 0,
    ListingQuery query = const ListingQuery(),
  }) async => listings;
}

class _PhotoFixture implements ListingPhotoRepository, ListingPhotoPicker {
  @override
  bool get enabled => true;
  @override
  Future<String> signedUrl(String path) async => 'https://image.invalid/$path';
  @override
  Future<void> attach(
    String listingId,
    List<ListingPhotoDraft> photos,
    String owner,
  ) async => throw UnimplementedError();
  @override
  Future<List<ListingPhotoDraft>> pick(String owner) async => [];
  @override
  Future<List<ListingPhotoDraft>> recover(String owner) async => [];
}

void main() {
  setUpAll(loadManropeFonts);
  test('M3 et contrastes des textes et des champs de la charte', () {
    final theme = KiboTheme.light;
    expect(theme.useMaterial3, isTrue);
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
    }

    for (final color in [
      KiboColors.primary,
      KiboColors.primaryDark,
      KiboColors.textPrimary,
      KiboColors.textSecondary,
    ]) {
      expect(contrast(color, KiboColors.surface), greaterThanOrEqualTo(4.5));
    }
    expect(
      contrast(theme.colorScheme.outline, theme.colorScheme.surface),
      greaterThanOrEqualTo(3),
    );
    expect(theme.colorScheme.tertiary, KiboColors.primaryDark);
    expect(theme.colorScheme.surfaceContainer, KiboColors.background);
  });
  testWidgets(
    '200 annonces : seuls les éléments proches du viewport sont montés',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: Scaffold(
            body: PrimaryScrollController(
              controller: controller,
              child: ListingFeed(repository: _LargeFixture()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ListingCard).evaluate().length, lessThan(20));
      expect(find.text('Fictif 0'), findsOneWidget);
      expect(find.text('Fictif 199'), findsNothing);
      final feedScroll = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView).first)
          .controller!;
      feedScroll.jumpTo(5000);
      await tester.pumpAndSettle();
      expect(
        find.byType(ListingCard).evaluate().length,
        inInclusiveRange(1, 20),
      );
      expect(find.text('Fictif 0'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'catégorie accueil ouvre la recherche avec son identifiant réel',
    (tester) async {
      final repo = FakeListingRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: KiboHomePage(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Catégorie test'));
      await tester.tap(find.text('Catégorie test'));
      await tester.pumpAndSettle();
      expect(find.byType(CatalogueSearchForm), findsOneWidget);
      expect(repo.lastQuery!.categoryId, 'category-a');
    },
  );
  testWidgets('recherche Material : limite, soumission et chip de filtres', (
    tester,
  ) async {
    ListingQuery? applied;
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CatalogueSearchForm(
              repository: FakeListingRepository(),
              onApply: (value) => applied = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey('catalogue-search'));
    await tester.enterText(search, 'a' * 160);
    expect(tester.widget<SearchBar>(search).controller!.text.length, 120);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(applied!.text.length, 120);
    await tester.tap(find.widgetWithText(FilterChip, 'Filtres et tri'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Filtres et tri'))
          .selected,
      isTrue,
    );
    expect(find.byKey(const ValueKey('catalogue-city')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'la résolution photo suit les contraintes de la carte, pas tout l’écran',
    (tester) async {
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      final photos = _PhotoFixture();
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: Scaffold(
            body: ListingPhotoScope(
              repository: photos,
              picker: photos,
              child: const Center(
                child: SizedBox(
                  width: 150,
                  height: 180,
                  child: ListingPhotoView(
                    path: 'fixture',
                    label: 'Photo fictive',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as ResizeImage).width, 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
