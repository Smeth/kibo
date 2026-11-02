import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_page.dart';
import 'package:kibo/features/listings/catalogue_search_form.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_query.dart';
import 'package:kibo/features/seller/seller_page.dart';
import 'package:kibo/features/seller/seller_repository.dart';
import 'package:kibo/features/chat/chat_page.dart';
import 'support/auth_fake.dart';
import 'support/listing_fake.dart';
import 'support/manrope_fonts.dart';
import 'chat/chat_widgets_test.dart' show ChatFake;

class SellerFixture extends Fake implements SellerRepository {
  @override
  Future<PublicSeller?> profile(String id) async =>
      PublicSeller(id: id, name: 'Vendeur de recette', city: 'Brazzaville');
}

class LauncherFixture extends Fake implements ContactLauncher {}

void main() {
  setUpAll(() async {
    await loadManropeFonts();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  test('prix absent distinct de zéro, comparaison exacte et affichage', () {
    expect(listingPriceValue('  '), isNull);
    expect(listingPriceValue('0'), '0');
    expect(formatListingPrice(''), 'Prix à négocier');
    expect(formatListingPrice('0'), '0 XAF');
    expect(sameListingPrice(null, null), isTrue);
    expect(sameListingPrice(null, '0'), isFalse);
    expect(sameListingPrice('0.00', null), isFalse);
    expect(sameListingPrice('12345.50', '12 345,5'), isTrue);
    expect(sameListingPrice('garbage', 'garbage'), isFalse);
    final listing = PublicListing.fromJson({
      'id': 'fixture',
      'seller_id': 'seller',
      'title': 'Annonce sans prix',
      'description': 'Description de recette',
      'price': null,
      'status': 'published',
      'currency': 'XAF',
      'city': 'Brazzaville',
      'listing_type': 'product',
    });
    expect(listing.priceLabel, 'Prix à négocier');
  });

  test('préfixes Unicode sans opérateurs fournis par la saisie', () {
    expect(listingPrefixQuery('iph'), 'iph:*');
    expect(listingPrefixQuery('téléphone sam'), 'téléphone:* & sam:*');
    expect(
      listingPrefixQuery('moto,prix) " (status.eq.draft'),
      'moto:* & prix:* & status:* & eq:* & draft:*',
    );
    expect(listingPrefixQuery(' ! :* & '), isEmpty);
  });

  testWidgets(
    'recherche progressive dès trois caractères, temporisée et curseur conservé',
    (tester) async {
      final applied = <ListingQuery>[];
      var active = const ListingQuery();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => CatalogueSearchForm(
                  repository: FakeListingRepository(),
                  initialQuery: active,
                  onApply: (query) {
                    applied.add(query);
                    setState(() => active = query);
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('catalogue-search'));
      await tester.enterText(field, 'ip');
      await tester.pump(const Duration(milliseconds: 400));
      expect(applied, isEmpty);
      await tester.enterText(field, 'iph');
      await tester.pump(const Duration(milliseconds: 349));
      expect(applied, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(applied.single.text, 'iph');
      final input = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(input.focusNode.hasFocus, isTrue);
      expect(input.controller.selection.baseOffset, 3);
      await tester.enterText(field, 'iphone');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, 'iphone sam');
      await tester.pump(const Duration(milliseconds: 350));
      expect(applied.length, 2);
      expect(applied.last.text, 'iphone sam');
      await tester.enterText(field, '');
      await tester.pump(const Duration(milliseconds: 350));
      expect(applied.last.text, isEmpty);
      await tester.enterText(field, 'fermeture');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('vendeur : boutons espacés et logo officiel, texte ×$scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repo = FakeAuthRepository();
      final auth = AuthController(repo);
      final chats = ChatFake()..userId = null;
      addTearDown(auth.dispose);
      addTearDown(repo.dispose);
      addTearDown(chats.updates.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: AuthScope(
            controller: auth,
            child: RepaintBoundary(
              key: const ValueKey('seller-capture'),
              child: SellerPage(
                sellerId: 'seller',
                listingId: 'listing',
                repository: SellerFixture(),
                launcher: LauncherFixture(),
                chats: chats,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Appeler le vendeur'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final whatsapp = find
          .ancestor(
            of: find.text('Contacter sur WhatsApp'),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          )
          .first;
      final call = find
          .ancestor(
            of: find.text('Appeler le vendeur'),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          )
          .first;
      final message = find.byKey(const ValueKey('seller-direct-message'));
      expect(
        tester.getTopLeft(whatsapp).dy - tester.getBottomLeft(message).dy,
        greaterThanOrEqualTo(16),
      );
      expect(
        tester.getTopLeft(call).dy - tester.getBottomLeft(whatsapp).dy,
        greaterThanOrEqualTo(16),
      );
      final logo = tester.widget<Image>(find.byType(Image));
      expect(
        (logo.image as AssetImage).assetName,
        'assets/branding/whatsapp.png',
      );
      expect(tester.takeException(), isNull);
      if (scale == 1 && const bool.fromEnvironment('KIBO_EXPORT_REVIEW3')) {
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/branding/whatsapp.png'),
            tester.element(find.byType(SellerPage)),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('seller-capture')),
          );
          final picture = await boundary.toImage(pixelRatio: 2);
          final data = await picture.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '.dart_tool/review3-seller-preview.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          picture.dispose();
        });
      }
    });
  }

  for (final signIn in [false, true]) {
    testWidgets(
      'message vendeur : connexion requise, retour connecté=$signIn',
      (tester) async {
        final repo = FakeAuthRepository();
        final auth = AuthController(repo);
        final chats = ChatFake()..userId = null;
        addTearDown(auth.dispose);
        addTearDown(repo.dispose);
        addTearDown(chats.updates.close);
        await tester.pumpWidget(
          MaterialApp(
            home: AuthScope(
              controller: auth,
              child: SellerPage(
                sellerId: 'seller',
                listingId: 'listing',
                repository: SellerFixture(),
                launcher: LauncherFixture(),
                chats: chats,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Message direct'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Message direct'));
        await tester.pumpAndSettle();
        expect(find.byType(AuthPage), findsOneWidget);
        expect(chats.starts, 0);
        if (signIn) {
          chats.userId = FakeAuthRepository.user.id;
          repo.emit(FakeAuthRepository.user);
          await tester.pumpAndSettle();
          expect(find.byType(ChatPage), findsOneWidget);
          expect(chats.starts, 1);
        } else {
          Navigator.of(tester.element(find.byType(AuthPage))).pop();
          await tester.pumpAndSettle();
          expect(find.byType(ChatPage), findsNothing);
          expect(chats.starts, 0);
        }
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }
}
