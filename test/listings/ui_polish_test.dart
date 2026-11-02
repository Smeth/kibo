import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/auth/password_pages.dart';
import 'package:kibo/features/listings/catalogue_search_form.dart';
import 'package:kibo/features/listings/listing_feed.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_query.dart';
import '../support/listing_fake.dart';
import '../support/manrope_fonts.dart';
import '../profile/account_mvp_test.dart' show RecoveryFake;

class CountingListings extends FakeListingRepository {
  int reads = 0;
  @override
  Future<List<PublicListing>> published({
    int offset = 0,
    ListingQuery query = const ListingQuery(),
  }) {
    reads++;
    return super.published(offset: offset, query: query);
  }
}

void main() {
  setUpAll(loadManropeFonts);
  testWidgets(
    'récupération email : 24 px avant action, même après validation',
    (tester) async {
      final repository = RecoveryFake();
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: PasswordResetPage(repository: repository),
        ),
      );
      final field = find.byType(TextFormField);
      final button = find.widgetWithText(FilledButton, 'Recevoir le lien');
      expect(
        tester.getTopLeft(button).dy - tester.getBottomLeft(field).dy,
        greaterThanOrEqualTo(24),
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(button).dy - tester.getBottomLeft(field).dy,
        greaterThanOrEqualTo(24),
      );
      expect(repository.resets, 0);
    },
  );

  for (final empty in [false, true]) {
    testWidgets('tirer pour actualiser, catalogue vide=$empty', (tester) async {
      final repository = CountingListings();
      if (empty) repository.listings = [];
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: Scaffold(
            body: ListingFeed(
              repository: repository,
              initialQuery: const ListingQuery(city: 'Brazzaville'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.reads, 1);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(repository.reads, 2);
      expect(repository.lastQuery!.city, 'Brazzaville');
      repository.readError = StateError('offline');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(repository.reads, 3);
      if (!empty) expect(find.text('Smartphone Android'), findsOneWidget);
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'saisie recherche centrée par rapport à la loupe, texte ×$scale',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: KiboTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CatalogueSearchForm(
                  repository: FakeListingRepository(),
                  onApply: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bar = find.byKey(const ValueKey('catalogue-search'));
        final editable = find.descendant(
          of: bar,
          matching: find.byType(EditableText),
        );
        await tester.enterText(editable, 'Téléphone');
        await tester.pump();
        final render = tester.state<EditableTextState>(editable).renderEditable;
        final caret = render.localToGlobal(
          render.getLocalRectForCaret(const TextPosition(offset: 3)).center,
        );
        final icon = tester.getCenter(
          find.descendant(of: bar, matching: find.byIcon(Icons.search)),
        );
        expect((caret.dy - icon.dy).abs(), lessThan(4));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
