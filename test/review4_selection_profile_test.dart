import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/core/widgets/kibo_section.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/profile_page.dart';
import 'package:kibo/features/listings/my_listings_page.dart';
import 'package:kibo/features/safety/safety_entry.dart';
import 'package:kibo/features/seller/seller_page.dart';
import 'support/auth_fake.dart';
import 'support/listing_fake.dart';
import 'support/manrope_fonts.dart';
import 'review2_ui_test.dart' show OwnedBatchFake;
import 'review3_seller_search_price_test.dart'
    show SellerFixture, LauncherFixture;
import 'chat/chat_widgets_test.dart' show ChatFake;
import 'safety/safety_widgets_test.dart' show SafetyFake;

void main() {
  setUpAll(() async {
    await loadManropeFonts();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  Future<AuthController> authController() async {
    final repo = FakeAuthRepository()..identity = FakeAuthRepository.user;
    final auth = AuthController(repo);
    addTearDown(auth.dispose);
    addTearDown(repo.dispose);
    return auth;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'appui sur carte sélectionne, barre persistante et suppression confirmée ×$scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final auth = await authController();
        final repo = OwnedBatchFake();
        await tester.pumpWidget(
          MaterialApp(
            theme: KiboTheme.light,
            home: RepaintBoundary(
              key: const ValueKey('selection-capture'),
              child: AuthScope(
                controller: auth,
                child: MyListingsPage(
                  repository: repo,
                  listings: FakeListingRepository(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final id in ['a', 'b']) {
          final title = find.text('Annonce $id');
          await tester.scrollUntilVisible(
            title,
            250,
            scrollable: find.byType(Scrollable).first,
          );
          await tapVisible(tester, title);
        }
        expect(find.text('2 annonces'), findsOneWidget);
        expect(repo.transitions, isEmpty);
        expect(
          tester
              .getSize(find.byKey(const ValueKey('owned-selection-bar')))
              .height,
          lessThan(scale == 1 ? 100 : 180),
        );
        if (const bool.fromEnvironment('KIBO_EXPORT_REVIEW4')) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('selection-capture')),
            );
            final picture = await boundary.toImage(pixelRatio: 2);
            final data = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '.dart_tool/review4-selection-$scale.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            picture.dispose();
          });
        }
        final delete = find.text('Supprimer la sélection');
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byTooltip('Actions de la sélection'));
        await tapVisible(tester, delete);
        expect(find.text('Retirer 2 annonces du catalogue ?'), findsOneWidget);
        expect(repo.transitions, isEmpty);
        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();
        expect(repo.transitions, isEmpty);
        await tapVisible(tester, find.byTooltip('Actions de la sélection'));
        await tapVisible(tester, delete);
        await tapVisible(tester, find.text('Confirmer la sélection'));
        expect(repo.transitions, ['a', 'b']);
        expect(repo.rows.every((r) => r.status == 'archived'), isTrue);
        expect(find.byTooltip('Actions de la sélection'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('appui sur contenu décoche et cases ne basculent pas deux fois', (
    tester,
  ) async {
    final auth = await authController();
    final repo = OwnedBatchFake();
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: auth,
          child: MyListingsPage(
            repository: repo,
            listings: FakeListingRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final title = find.text('Annonce a');
    await tester.scrollUntilVisible(
      title,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tapVisible(tester, title);
    expect(find.text('1 annonce'), findsOneWidget);
    await tapVisible(tester, title);
    expect(find.byTooltip('Actions de la sélection'), findsNothing);
    await tapVisible(tester, find.byKey(const ValueKey('select-owned-a')));
    expect(find.text('1 annonce'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Tout désélectionner'));
    expect(find.byTooltip('Actions de la sélection'), findsNothing);
    expect(repo.transitions, isEmpty);
  });

  testWidgets(
    'bouton individuel ouvre sa confirmation sans sélectionner la carte',
    (tester) async {
      final auth = await authController();
      final repo = OwnedBatchFake()..rows.removeLast();
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            controller: auth,
            child: MyListingsPage(
              repository: repo,
              listings: FakeListingRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.text('Supprimer du catalogue');
      await tester.scrollUntilVisible(
        action,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tapVisible(tester, action);
      expect(find.text('Supprimer du catalogue ?'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Actions de la sélection'), findsNothing);
      expect(repo.transitions, isEmpty);
    },
  );

  testWidgets('barre de sélection bornée même avec le clavier ouvert', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final auth = await authController();
    final repo = OwnedBatchFake();
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: auth,
          child: MyListingsPage(
            repository: repo,
            listings: FakeListingRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final title = find.text('Annonce a');
    await tester.scrollUntilVisible(
      title,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tapVisible(tester, title);
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Actions de la sélection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'session perdue pendant le menu : aucune confirmation ni transition',
    (tester) async {
      final auth = await authController();
      final repo = OwnedBatchFake();
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            controller: auth,
            child: MyListingsPage(
              repository: repo,
              listings: FakeListingRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Sélectionner les annonces chargées'));
      await tapVisible(tester, find.byTooltip('Actions de la sélection'));
      repo.userId = null;
      await auth.signOut();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Supprimer la sélection'));
      expect(repo.transitions, isEmpty);
      expect(find.text('Retirer 2 annonces du catalogue ?'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final theme in [KiboTheme.light, KiboTheme.dark]) {
    testWidgets(
      'entrée Administration réutilise les lignes du profil, thème ${theme.brightness}',
      (tester) async {
        final auth = await authController();
        final safety = SafetyFake()..admin = true;
        var opens = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: AuthScope(
              controller: auth,
              child: ProfilePage(
                onMyListings: () {},
                moderationEntry: SafetyEntry(
                  repository: safety,
                  moderation: true,
                  moderationLabel: 'Administration',
                  onPressed: () {
                    opens++;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final admin = find.byWidgetPredicate(
          (w) => w is KiboMenuAction && w.label == 'Administration',
        );
        final mine = find.byWidgetPredicate(
          (w) => w is KiboMenuAction && w.label == 'Mes annonces',
        );
        expect(admin, findsOneWidget);
        expect(tester.getSize(admin).width, tester.getSize(mine).width);
        expect(
          find.descendant(of: admin, matching: find.byType(ListTile)),
          findsOneWidget,
        );
        await tapVisible(tester, find.text('Administration'));
        expect(opens, 1);
      },
    );
  }

  testWidgets(
    'son propre profil vendeur garde Message direct visible et explique le refus',
    (tester) async {
      final auth = await authController();
      final chats = ChatFake();
      addTearDown(chats.updates.close);
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            controller: auth,
            child: SellerPage(
              sellerId: FakeAuthRepository.user.id,
              listingId: 'listing',
              repository: SellerFixture(),
              launcher: LauncherFixture(),
              chats: chats,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('seller-direct-message'));
      expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
      expect(
        find.textContaining('Cette annonce vous appartient'),
        findsOneWidget,
      );
      expect(chats.starts, 0);
    },
  );
}
