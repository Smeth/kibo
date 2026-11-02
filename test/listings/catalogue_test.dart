import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/listings/listing_feed.dart';
import 'package:kibo/features/listings/listing_detail_page.dart';
import 'package:kibo/features/listings/listing_models.dart';
import '../support/listing_fake.dart';

void main() {
  late FakeListingRepository repository;
  setUp(() {
    repository = FakeListingRepository()..userId = null;
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: Scaffold(body: ListingFeed(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('liste publique, détail puis retour sans session', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Smartphone Android'));
    await tester.pumpAndSettle();
    expect(find.byType(ListingDetailPage), findsOneWidget);
    expect(find.text('Description du smartphone'), findsOneWidget);
    expect(find.text('85 000 XAF'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ListingFeed), findsOneWidget);
  });
  testWidgets('chargement puis vide', (tester) async {
    repository.pendingRead = Completer<List<PublicListing>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ListingFeed(repository: repository)),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.pendingRead!.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Aucune annonce publiée pour le moment.'), findsOneWidget);
  });
  testWidgets('erreur masquée, retry et annonce devenue indisponible', (
    tester,
  ) async {
    repository.readError = StateError('détail privé');
    await open(tester);
    expect(find.text('Impossible de charger les annonces.'), findsOneWidget);
    expect(find.textContaining('privé'), findsNothing);
    repository.readError = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    repository.listings = [];
    await tester.tap(find.text('Smartphone Android'));
    await tester.pumpAndSettle();
    expect(find.text('Cette annonce n’est plus disponible.'), findsOneWidget);
  });
  testWidgets('détail en erreur, aucun contenu ancien affiché', (tester) async {
    await open(tester);
    repository.readError = StateError('détail privé');
    await tester.tap(find.text('Smartphone Android'));
    await tester.pumpAndSettle();
    expect(find.text('Impossible de charger cette annonce.'), findsOneWidget);
    expect(find.textContaining('privé'), findsNothing);
    repository.readError = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Description du smartphone'), findsOneWidget);
  });
  testWidgets('pagination et rangée impaire', (tester) async {
    final first = repository.listings.first;
    repository.listings = [
      for (var i = 0; i < 21; i++)
        PublicListing(
          id: 'id-$i',
          title: 'Titre numéro $i',
          description: first.description,
          price: first.price,
          city: first.city,
        ),
    ];
    await open(tester);
    await tester.scrollUntilVisible(find.text('Titre numéro 20'), 200);
    await tester.pumpAndSettle();
    expect(repository.lastOffset, 20);
    expect(find.text('Voir plus'), findsNothing);
    expect(find.text('Titre numéro 20'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
