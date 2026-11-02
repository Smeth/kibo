import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/core/widgets/congo_city_field.dart';
import 'package:kibo/main.dart';
import '../support/listing_fake.dart';
import '../support/manrope_fonts.dart';

void main() {
  setUpAll(() async {
    await loadManropeFonts();
    await CongoPlaces.load();
  });
  test(
    'catalogue local CG complet selon l’extrait, grandes villes et alias',
    () async {
      final metadata =
          jsonDecode(
                await rootBundle.loadString('assets/data/congo_places.json'),
              )
              as Map<String, dynamic>;
      expect(metadata['country'], 'CG');
      expect(metadata['recordCount'], 5778);
      final rows = await CongoPlaces.load();
      expect(rows.length, 4538);
      for (final name in [
        'Brazzaville',
        'Pointe-Noire',
        'Dolisie',
        'Nkayi',
        'Ouesso',
        'Owando',
        'Oyo',
        'Impfondo',
        'Sibiti',
        'Madingou',
        'Kinkala',
        'Ewo',
      ]) {
        expect(rows.any((p) => p.name == name), isTrue, reason: name);
      }
      expect(rows.any((p) => p.search.contains('betou')), isTrue);
    },
  );
  testWidgets('sélecteur : recherche sans accent et sélection dans le champ', (
    tester,
  ) async {
    final city = TextEditingController(text: 'Brazzaville');
    addTearDown(city.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.dark,
        home: Scaffold(body: CongoCityField(controller: city)),
      ),
    );
    await tester.tap(find.byTooltip('Choisir une ville du Congo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'dolisie');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Dolisie'));
    await tester.pumpAndSettle();
    expect(city.text, 'Dolisie');
    expect(find.byKey(const ValueKey('congo-city-options')), findsNothing);
  });
  testWidgets('filtre ville : uniquement choix dans le catalogue CG', (
    tester,
  ) async {
    final city = TextEditingController();
    addTearDown(city.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: Scaffold(
          body: CongoCityField(
            controller: city,
            allowAll: true,
            selectionOnly: true,
          ),
        ),
      ),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'Kinshasa');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Kinshasa'), findsNothing);
    expect(
      find.text('Aucune ville ou localité du Congo-Brazzaville trouvée.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(SearchBar), 'pointe');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Pointe-Noire'));
    await tester.pumpAndSettle();
    expect(city.text, 'Pointe-Noire');
  });
  testWidgets(
    'ville : saisie existante conservée et choix désactivé pendant attente',
    (tester) async {
      final city = TextEditingController(text: 'Localité historique');
      addTearDown(city.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: Scaffold(
            body: CongoCityField(controller: city, enabled: false),
          ),
        ),
      );
      await tester.tap(
        find.byTooltip('Choisir une ville du Congo'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(city.text, 'Localité historique');
      expect(find.byKey(const ValueKey('congo-city-options')), findsNothing);
    },
  );
  testWidgets(
    'accueil : choisir une ville filtre les annonces puis permet toutes les villes',
    (tester) async {
      final listings = FakeListingRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: KiboHomePage(repository: listings),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-city-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Pointe-Noire'));
      await tester.pumpAndSettle();
      expect(listings.lastQuery!.city, 'Pointe-Noire');
      await tester.tap(find.byKey(const ValueKey('home-city-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Toutes les villes'));
      await tester.pumpAndSettle();
      expect(listings.lastQuery!.city, isEmpty);
    },
  );
  testWidgets('sélecteur sur petit écran avec texte agrandi et clavier', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => pickCongoCity(context),
              child: const Text('Villes'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Villes'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(SearchBar), 'oyo');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(ListTile, 'Oyo'),
      150,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('congo-city-options')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.takeException(), isNull);
  });
}
