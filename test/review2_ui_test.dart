import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/listings/catalogue_search_form.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_query.dart';
import 'package:kibo/features/listings/my_listings_page.dart';
import 'package:kibo/features/listings/owned_listing_repository.dart';
import 'package:kibo/features/listings/owned_listing_query.dart';
import 'package:kibo/features/profile/account_settings_page.dart';
import 'package:kibo/features/safety/admin_page.dart';
import 'package:kibo/features/safety/safety_page.dart';
import 'package:kibo/features/favorites/favorites_page.dart';
import 'package:kibo/features/favorites/favorites_controller.dart';
import 'package:kibo/main.dart';
import 'package:kibo/features/listings/listing_photo_widgets.dart';
import 'package:kibo/features/listings/edit_listing_page.dart';
import 'listings/listing_photo_widgets_test.dart' show Reader, NoPicker;
import 'support/auth_fake.dart';
import 'support/listing_fake.dart';
import 'support/manrope_fonts.dart';
import 'safety/safety_widgets_test.dart' show SafetyFake;
import 'profile/engagement_widgets_test.dart' show EngagementFake;
import 'profile/account_mvp_test.dart' show AccountFake;

OwnedListing ownedRow(String id) => OwnedListing(
  id: id,
  sellerId: FakeAuthRepository.user.id,
  status: 'published',
  updatedAt: 'old',
  draft: ListingDraft(
    title: 'Annonce $id',
    description: 'Description de recette',
    price: '10000',
    categoryId: 'category-a',
    city: 'Brazzaville',
  ),
);

class OwnedBatchFake implements OwnedListingRepository {
  @override
  String? userId = FakeAuthRepository.user.id;
  List<OwnedListing> rows = [ownedRow('a'), ownedRow('b')];
  final transitions = <String>[];
  String? fail;
  int reads = 0;
  @override
  Future<List<OwnedListing>> mine(
    String ownerId, {
    int offset = 0,
    OwnedListingQuery query = const OwnedListingQuery(),
  }) async {
    reads++;
    return rows
        .where(
          (r) =>
              r.sellerId == ownerId &&
              (query.status == OwnedListingStatus.all ||
                  r.status == query.status.name),
        )
        .skip(offset)
        .take(20)
        .toList();
  }

  @override
  Future<void> transition(OwnedListing listing, String status) async {
    transitions.add(listing.id);
    if (listing.id == fail) throw StateError('fixture conflict');
    rows = rows
        .map(
          (r) => r.id == listing.id
              ? OwnedListing(
                  id: r.id,
                  sellerId: r.sellerId,
                  status: status,
                  updatedAt: 'new',
                  draft: r.draft,
                  photoPaths: r.photoPaths,
                )
              : r,
        )
        .toList();
  }

  @override
  Future<void> edit(OwnedListing listing, ListingDraft draft) async {}
}

class RefreshFavorites extends FakeFavoritesRepository {
  int reads = 0;
  @override
  Future<Set<String>> ids(String expectedUserId) {
    reads++;
    return super.ids(expectedUserId);
  }
}

class PendingAdmin extends SafetyFake {
  final permission = Completer<bool>();
  @override
  Future<bool> canModerate(String owner) => permission.future;
}

void main() {
  setUpAll(() async {
    await loadManropeFonts();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  Future<AuthController> controller() async {
    final repository = FakeAuthRepository()..identity = FakeAuthRepository.user;
    final auth = AuthController(repository);
    addTearDown(auth.dispose);
    addTearDown(repository.dispose);
    return auth;
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final scale in [1.0, 2.0]) {
    for (final expanded in [false, true]) {
      testWidgets('écart filtres/action, texte ×$scale, ouvert=$expanded', (
        tester,
      ) async {
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
        if (expanded) await tap(tester, 'Filtres et tri');
        final previous = expanded
            ? find.byWidgetPredicate(
                (w) => w is DropdownButtonFormField<ListingSort>,
              )
            : find.widgetWithText(FilterChip, 'Filtres et tri');
        final action = find.widgetWithText(FilledButton, 'Rechercher');
        expect(
          tester.getTopLeft(action).dy - tester.getBottomLeft(previous).dy,
          greaterThanOrEqualTo(16),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'Mes annonces : statut séparé des actions et refresh avec critères',
    (tester) async {
      final auth = await controller();
      final repository = OwnedBatchFake();
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: AuthScope(
            controller: auth,
            child: MyListingsPage(
              repository: repository,
              listings: FakeListingRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final status = find.ancestor(
        of: find.byKey(const ValueKey('owned-status')),
        matching: find.byType(InputDecorator),
      );
      expect(
        tester.getTopLeft(find.widgetWithText(FilledButton, 'Rechercher')).dy -
            tester.getBottomLeft(status.first).dy,
        greaterThanOrEqualTo(16),
      );
      final before = repository.reads;
      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();
      expect(repository.reads, before + 1);
    },
  );

  for (final fail in [false, true]) {
    testWidgets('archivage groupé confirmé, échec partiel=$fail', (
      tester,
    ) async {
      final auth = await controller();
      final repository = OwnedBatchFake();
      if (fail) repository.fail = 'b';
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: AuthScope(
            controller: auth,
            child: MyListingsPage(
              repository: repository,
              listings: FakeListingRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Sélectionner les annonces chargées');
      await tap(tester, 'Supprimer la sélection');
      expect(repository.transitions, isEmpty);
      await tap(tester, 'Confirmer la sélection');
      expect(repository.transitions, ['a', 'b']);
      expect(repository.rows.first.status, 'archived');
      expect(repository.rows.last.status, fail ? 'published' : 'archived');
      expect(
        find.textContaining(fail ? '1 échec(s)' : '0 échec(s)'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('annulation groupée ne modifie aucune annonce', (tester) async {
    final auth = await controller();
    final repository = OwnedBatchFake();
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: auth,
          child: MyListingsPage(
            repository: repository,
            listings: FakeListingRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tap(tester, 'Sélectionner les annonces chargées');
    await tap(tester, 'Supprimer la sélection');
    await tap(tester, 'Annuler');
    expect(repository.transitions, isEmpty);
  });

  testWidgets('favoris : geste refresh sur liste vide', (tester) async {
    final auth = await controller();
    final repository = RefreshFavorites();
    final listings = FakeListingRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: auth,
          child: FavoritesSession(
            repository: repository,
            child: Scaffold(body: FavoritesPage(listings: listings)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = repository.reads;
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(repository.reads, before + 1);
  });

  testWidgets('notifications : tirer actualise sans perdre non-lues', (
    tester,
  ) async {
    final auth = await controller();
    final repository = SafetyFake()..notices = [];
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScope(
          controller: auth,
          child: SafetyPage(
            repository: repository,
            ownerId: FakeAuthRepository.user.id,
            screen: SafetyScreen.notifications,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    final before = repository.reads;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(repository.reads, before + 1);
    expect(repository.unread, isTrue);
  });

  testWidgets('compte et données : titre, paragraphe et champ séparés', (
    tester,
  ) async {
    final auth = await controller();
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: AccountSettingsPage(controller: auth, repository: AccountFake()),
      ),
    );
    await tester.pumpAndSettle();
    final title = find.text('Demander la suppression de mon compte');
    final paragraph = find.textContaining(
      'Cette demande doit être traitée par l’opérateur KIBO.',
    );
    expect(
      tester.getTopLeft(paragraph).dy - tester.getBottomLeft(title).dy,
      greaterThanOrEqualTo(16),
    );
    expect(
      tester.getTopLeft(find.byType(TextField)).dy -
          tester.getBottomLeft(paragraph).dy,
      greaterThanOrEqualTo(16),
    );
  });

  testWidgets('administration : membre refusé sans lecture de la file', (
    tester,
  ) async {
    final auth = await controller();
    final safety = SafetyFake();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminPage(
          auth: auth,
          safety: safety,
          onReports: () async {},
          onAccounts: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(safety.reads, 0);
    expect(find.textContaining('Accès administrateur requis'), findsOneWidget);
    expect(find.text('Ouvrir la modération'), findsNothing);
  });

  testWidgets('administration : modules, révocation et petit écran sombre', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = await controller();
    final safety = SafetyFake()..admin = true;
    final accounts = EngagementFake()..admin = true;
    var opens = 0;
    const capture = ValueKey('review2-admin-capture');
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.dark,
        home: RepaintBoundary(
          key: capture,
          child: AdminPage(
            auth: auth,
            safety: safety,
            accounts: accounts,
            onReports: () async {
              opens++;
            },
            onAccounts: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ouvrir la modération'), findsOneWidget);
    await tap(tester, 'Ouvrir la modération');
    expect(opens, 1);
    if (const bool.fromEnvironment('KIBO_EXPORT_REVIEW2')) {
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        final picture = await boundary.toImage(pixelRatio: 2);
        final data = await picture.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '.dart_tool/review2-admin-preview.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        picture.dispose();
      });
    }
    safety.admin = false;
    await tester.tap(find.byTooltip('Actualiser l’administration'));
    await tester.pumpAndSettle();
    expect(find.text('Ouvrir la modération'), findsNothing);
    expect(find.textContaining('Accès administrateur requis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('administration : A/B/A invalide les réponses tardives', (
    tester,
  ) async {
    final repository = FakeAuthRepository()..identity = FakeAuthRepository.user;
    final auth = AuthController(repository);
    final safety = PendingAdmin();
    addTearDown(auth.dispose);
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: AdminPage(
          auth: auth,
          safety: safety,
          onReports: () async {},
          onAccounts: () async {},
        ),
      ),
    );
    await tester.pump();
    repository.emit(const AuthIdentity(id: 'other'));
    await tester.pump();
    repository.emit(FakeAuthRepository.user);
    await tester.pump();
    safety.permission.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Ouvrir la modération'), findsNothing);
    expect(safety.reads, 0);
  });

  testWidgets(
    'profil vers Mes annonces puis modification conserve le service photo',
    (tester) async {
      final auth = await controller();
      final listings = FakeListingRepository();
      final owned = OwnedBatchFake();
      final row = owned.rows.first;
      owned.rows = [
        OwnedListing(
          id: row.id,
          sellerId: row.sellerId,
          status: row.status,
          updatedAt: row.updatedAt,
          draft: row.draft,
          photoPaths: const ['fixture.jpg'],
        ),
      ];
      final reader = Reader();
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: AuthScope(
            controller: auth,
            child: FavoritesSession(
              repository: FakeFavoritesRepository(),
              child: ListingPhotoScope(
                repository: reader,
                picker: NoPicker(),
                child: KiboHomePage(
                  repository: listings,
                  ownedRepository: owned,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'Profil');
      await tap(tester, 'Mes annonces');
      await tester.scrollUntilVisible(
        find.text('Modifier'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(MyListingsPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(find.text('Modifier'));
      await tester.pumpAndSettle();
      expect(reader.requests, contains('fixture.jpg'));
      await tap(tester, 'Modifier');
      expect(
        ListingPhotoScope.maybeOf(
          tester.element(find.byType(EditListingPage)),
        )?.repository,
        same(reader),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
