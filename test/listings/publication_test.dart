import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_repository.dart';
import 'package:kibo/features/listings/publish_listing_page.dart';
import '../support/auth_fake.dart';
import '../support/listing_fake.dart';

void main() {
  test('contraintes : longueurs Unicode, prix facultatif et précision', () {
    expect(validateListingTitle(' court '), isNull);
    expect(validateListingTitle('abcd'), isNotNull);
    expect(validateListingTitle(List.filled(120, '😀').join()), isNull);
    expect(validateListingTitle(List.filled(121, 'a').join()), isNotNull);
    expect(validateListingDescription('trop court'), isNull);
    expect(validateListingDescription('court'), isNotNull);
    for (final price in ['-1', '1.234', '1000000000000', 'NaN', '1e3']) {
      expect(validateListingPrice(price), isNotNull);
    }
    for (final price in ['', ' ', '0', '12 345,50', '999999999999.99']) {
      expect(validateListingPrice(price), isNull);
    }
    expect(normalizePrice(' 12 345,50 '), '12345.50');
    expect(validateListingCity(' '), isNotNull);
  });
  late FakeAuthRepository auth;
  late AuthController controller;
  late FakeListingRepository repository;
  setUp(() {
    auth = FakeAuthRepository();
    repository = FakeListingRepository();
    controller = AuthController(auth);
  });
  tearDown(() async {
    controller.dispose();
    await auth.dispose();
  });
  Future<void> open(WidgetTester tester, {bool connected = true}) async {
    if (connected) auth.emit(FakeAuthRepository.user);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: AuthScope(
          controller: controller,
          child: Scaffold(body: PublishListingPage(repository: repository)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester) async {
    for (final field in {
      'listing-title': 'Annonce de test',
      'listing-description': 'Description suffisamment longue',
      'listing-price': '1200',
    }.entries) {
      await tester.ensureVisible(find.byKey(ValueKey(field.key)));
      await tester.enterText(find.byKey(ValueKey(field.key)), field.value);
    }
    await tester.ensureVisible(find.byKey(const ValueKey('listing-category')));
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('listing-category')),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catégorie test').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publier l’annonce'));
  }

  testWidgets('visiteur : connexion requise, aucune création', (tester) async {
    await open(tester, connected: false);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.byType(Form), findsNothing);
    expect(repository.creates, 0);
  });

  testWidgets(
    'publication à 320 px, texte 150 % et clavier : validation accessible',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Publier l’annonce'));
      await tester.tap(find.text('Publier l’annonce'));
      await tester.pumpAndSettle();
      expect(repository.creates, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'validation, chargement sans doublon puis confirmation published',
    (tester) async {
      repository.pendingCreate = Completer<String>();
      await open(tester);
      await tester.ensureVisible(find.text('Publier l’annonce'));
      await tester.tap(find.text('Publier l’annonce'));
      await tester.pumpAndSettle();
      expect(repository.creates, 0);
      await fill(tester);
      await tester.tap(find.text('Publier l’annonce'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(repository.creates, 1);
      repository.pendingCreate!.complete('listing-a');
      await tester.pumpAndSettle();
      expect(find.textContaining('Annonce publiée.'), findsOneWidget);
      expect(repository.lastDraft?.city, 'Brazzaville');
    },
  );
  testWidgets('erreur de création masquée et saisies conservées', (
    tester,
  ) async {
    repository.createError = StateError('secret serveur');
    await open(tester);
    await fill(tester);
    await tester.tap(find.text('Publier l’annonce'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Publication non confirmée'), findsOneWidget);
    expect(find.textContaining('secret serveur'), findsNothing);
    expect(repository.lastDraft?.title, 'Annonce de test');
  });
  testWidgets(
    'refus de publication : message français, aucune annonce de succès',
    (tester) async {
      repository.createError = const ListingPublicationDenied();
      await open(tester);
      await fill(tester);
      await tester.tap(find.text('Publier l’annonce'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Publication refusée'), findsOneWidget);
      expect(find.textContaining('Annonce publiée.'), findsNothing);
      expect(repository.creates, 1);
    },
  );
  testWidgets('catégories absentes ou refusées : retry sans publication', (
    tester,
  ) async {
    repository.categoryError = StateError('privé');
    await open(tester);
    expect(find.text('Impossible de charger les catégories.'), findsOneWidget);
    repository.categoryError = null;
    repository.categoryRows = [];
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune catégorie disponible.'), findsOneWidget);
    expect(repository.creates, 0);
  });
  testWidgets('déconnexion efface le formulaire de publication', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('listing-title')),
      'Brouillon A',
    );
    auth.emit(null);
    await tester.pumpAndSettle();
    expect(find.text('Brouillon A'), findsNothing);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
