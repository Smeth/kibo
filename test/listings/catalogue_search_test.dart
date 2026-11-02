import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/listings/listing_feed.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_query.dart';
import 'package:kibo/features/listings/listing_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../support/listing_fake.dart';
import '../support/supabase_fakes.dart';

void main() {
  test(
    'critères combinés envoyés au serveur, pagination et tri stable',
    () async {
      var requests = 0;
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        httpClient: MockClient((request) async {
          requests++;
          final params = request.url.queryParameters;
          expect(params['status'], 'eq.published');
          expect(params['kibo_search_vector'], 'fts(french).moto:* & prix:*');
          expect(params['category_id'], 'eq.cat-a');
          expect(params['city'], 'eq.Brazzaville');
          expect(request.url.queryParametersAll['price'], [
            'gte.1000.50',
            'lte.9000',
          ]);
          expect(
            params['order'],
            'price.asc.nullslast,published_at.desc.nullslast,id.asc.nullslast',
          );
          expect(params['offset'], '20');
          expect(params['limit'], '20');
          expect(params.containsKey('or'), isFalse);
          return http.Response(
            '[]',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final repository = SupabaseListingRepository(client);
      await repository.published(
        offset: 20,
        query: const ListingQuery(
          text: 'moto, prix)',
          categoryId: 'cat-a',
          city: 'Brazzaville',
          minPrice: '1 000,50',
          maxPrice: '9000',
          sort: ListingSort.priceAscending,
        ),
      );
      expect(requests, 1);
      await expectLater(
        repository.published(
          query: const ListingQuery(minPrice: '2', maxPrice: '1'),
        ),
        throwsArgumentError,
      );
      expect(requests, 1);
    },
  );
  test('fourchette validée sans arrondi flottant et limites explicites', () {
    expect(
      const ListingQuery(
        minPrice: '999999999999,99',
        maxPrice: '999999999999,98',
      ).validationError,
      isNotNull,
    );
    expect(
      const ListingQuery(minPrice: '0', maxPrice: '0').validationError,
      isNull,
    );
    expect(const ListingQuery(minPrice: '-1').validationError, isNotNull);
    expect(ListingQuery(text: 'x' * 121).validationError, isNotNull);
  });
  testWidgets(
    'recherche, vide distinct, erreur, effacement et réponse obsolète',
    (tester) async {
      final repository = FakeListingRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: Scaffold(
            body: ListingFeed(repository: repository, searchEnabled: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final oldRows = repository.listings;
      final old = Completer<List<PublicListing>>();
      repository.pendingRead = old;
      await tester.enterText(
        find.byKey(const ValueKey('catalogue-search')),
        'ancien',
      );
      await tester.tap(find.byTooltip('Lancer la recherche'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repository.pendingRead = null;
      repository.listings = [];
      await tester.enterText(
        find.byKey(const ValueKey('catalogue-search')),
        'nouveau',
      );
      await tester.tap(find.byTooltip('Lancer la recherche'));
      await tester.pumpAndSettle();
      old.complete(oldRows);
      await tester.pumpAndSettle();
      expect(find.text('Aucun résultat pour ces critères.'), findsOneWidget);
      expect(find.text('Smartphone Android'), findsNothing);
      repository.readError = StateError('fixture privee');
      await tester.tap(find.byTooltip('Lancer la recherche'));
      await tester.pumpAndSettle();
      expect(find.text('Impossible de charger les annonces.'), findsOneWidget);
      expect(find.textContaining('fixture privee'), findsNothing);
      repository.readError = null;
      repository.listings = oldRows;
      await tester.tap(find.text('Effacer les critères'));
      await tester.pumpAndSettle();
      expect(repository.lastQuery!.isEmpty, isTrue);
      expect(repository.lastOffset, 0);
    },
  );
  testWidgets('filtres à 320 px, texte 150 %, clavier et prix incohérents', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeListingRepository()..listings = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: ListingFeed(repository: repository, searchEnabled: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Filtres et tri'));
    await tester.tap(find.text('Filtres et tri'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('catalogue-min')));
    await tester.enterText(find.byKey(const ValueKey('catalogue-min')), '2000');
    await tester.ensureVisible(find.byKey(const ValueKey('catalogue-max')));
    await tester.enterText(find.byKey(const ValueKey('catalogue-max')), '1000');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.text('Rechercher'));
    await tester.tap(find.text('Rechercher'));
    await tester.pumpAndSettle();
    expect(
      find.text('Le prix minimum doit être inférieur ou égal au maximum.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
