import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_page.dart';
import 'package:kibo/features/listings/catalogue_search_form.dart';
import 'package:kibo/features/listings/listing_card.dart';
import 'package:kibo/features/listings/listing_detail_page.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_photo_widgets.dart';
import 'package:kibo/features/listings/publish_listing_page.dart';
import 'package:kibo/main.dart';
import '../support/auth_fake.dart';
import '../support/draft_fake.dart';
import '../support/guest_favorites_fake.dart';
import '../support/listing_fake.dart';
import '../support/manrope_fonts.dart';
import '../support/supabase_fakes.dart';
import '../chat/chat_widgets_test.dart' show ChatFake;
import 'listing_photo_widgets_test.dart' show Reader, NoPicker;

const previewKey = ValueKey('uiux-preview');
Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('KIBO_CAPTURE_UI_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(previewKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = await Directory(
      '.dart_tool/uiux-previews',
    ).create(recursive: true);
    await File(
      '${folder.path}/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void viewport(WidgetTester tester, {double width = 393, double scale = 1}) {
  tester.view.physicalSize = Size(width, 852);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Widget page(Widget body) => RepaintBoundary(
  key: previewKey,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: KiboTheme.light,
    home: body,
  ),
);

void main() {
  setUpAll(() async {
    await loadManropeFonts();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('accueil : recherche directe publique et cartes accessibles', (
    tester,
  ) async {
    viewport(tester);
    final client = createTestClient();
    final auth = FakeAuthRepository();
    addTearDown(client.dispose);
    addTearDown(auth.dispose);
    final listings = FakeListingRepository()..userId = null;
    await tester.pumpWidget(
      RepaintBoundary(
        key: previewKey,
        child: KiboApp(
          supabase: SupabaseService(
            config: testConfig,
            initializer: (_) async => client,
          ),
          authRepository: auth,
          listingRepository: listings,
          favoritesRepository: FakeFavoritesRepository(listings: listings),
          guestFavoritesStore: MemoryGuestFavoritesStore(),
          draftStore: MemoryListingDraftStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, 'home');
    await tester.ensureVisible(
      find.byKey(const ValueKey('home-search-action')),
    );
    await tester.tap(find.byKey(const ValueKey('home-search-action')));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogueSearchForm), findsOneWidget);
    expect(auth.signInCalls, 0);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'carte : longue catégorie et prix restent lisibles à texte doublé',
    (tester) async {
      viewport(tester, width: 320, scale: 2);
      var opens = 0;
      const listing = PublicListing(
        id: 'fixture',
        title: 'Canapé avec un titre détaillé',
        description: 'Fictif',
        price: '12500000',
        city: 'Brazzaville',
        categoryName: 'Maison et équipement pour toute la famille',
      );
      await tester.pumpWidget(
        page(
          Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListingCard(
                  listing: listing,
                  imageHeight: 180,
                  onOpen: () => opens++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final category = find.text(listing.categoryName!);
      expect(
        tester.getTopLeft(category).dy,
        greaterThan(
          tester
              .getBottomRight(
                find.byKey(ValueKey('listing-image-${listing.title}')),
              )
              .dy,
        ),
      );
      await tester.ensureVisible(find.text(listing.title));
      await tester.tap(find.text(listing.title));
      expect(opens, 1);
      expect(tester.takeException(), isNull);
      await capture(tester, 'card-large-text');
    },
  );
  Future<void> gallery(WidgetTester tester, List<String> paths) async {
    await tester.pumpWidget(
      page(
        Scaffold(
          body: SingleChildScrollView(
            child: ListingPhotoScope(
              repository: Reader(),
              picker: NoPicker(),
              child: ListingPhotoGallery(
                key: const ValueKey('gallery'),
                paths: paths,
                title: 'Photos fictives',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'galerie : boutons et balayage sur petit écran avec texte agrandi',
    (tester) async {
      viewport(tester, width: 320, scale: 2);
      await gallery(tester, ['one', 'two', 'three']);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Photo précédente',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Photo suivante'));
      await tester.pumpAndSettle();
      expect(find.text('Photo 2 sur 3'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-290, 0));
      await tester.pumpAndSettle();
      expect(find.text('Photo 3 sur 3'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Photo suivante',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'galerie : remplacement des photos remet la première sans index invalide',
    (tester) async {
      viewport(tester);
      await gallery(tester, ['one', 'two']);
      await tester.tap(find.byTooltip('Photo suivante'));
      await tester.pumpAndSettle();
      await gallery(tester, ['replacement']);
      expect(find.text('Photo 1 sur 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'détail : contacter avant une longue description et garder le contrôle de connexion',
    (tester) async {
      viewport(tester);
      final repo = FakeListingRepository()..userId = null;
      repo.listings = [
        PublicListing(
          id: 'detail',
          title: 'Canapé 3 places',
          description: List.filled(
            80,
            'Description fictive détaillée.',
          ).join(' '),
          price: '125000',
          city: 'Brazzaville',
          neighborhood: 'Bacongo',
          categoryName: 'Maison et équipement',
          sellerId: 'seller',
        ),
      ];
      final auth = FakeAuthRepository();
      final chat = ChatFake()..userId = null;
      addTearDown(auth.dispose);
      addTearDown(chat.updates.close);
      await tester.pumpWidget(
        page(
          AuthSession(
            repository: auth,
            child: ListingDetailPage(
              id: 'detail',
              repository: repo,
              chats: chat,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byTooltip('Écrire au vendeur')).dy,
        greaterThan(tester.getTopLeft(find.text('Description')).dy),
      );
      final contactTop = tester
          .getTopLeft(find.byTooltip('Écrire au vendeur'))
          .dy;
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byTooltip('Écrire au vendeur')).dy,
        contactTop,
      );
      await capture(tester, 'detail');
      await tester.tap(find.byTooltip('Écrire au vendeur'));
      await tester.pumpAndSettle();
      expect(chat.starts, 0);
      expect(find.byType(AuthPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('détail : erreur récupérable à texte triple sans débordement', (
    tester,
  ) async {
    viewport(tester, width: 320, scale: 3);
    final repo = FakeListingRepository()
      ..readError = StateError('fixture privée');
    await tester.pumpWidget(
      page(ListingDetailPage(id: 'listing-a', repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('fixture privée'), findsNothing);
    await tester.ensureVisible(find.text('Réessayer'));
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'publication : sections claires et sauvegarde après les champs, clavier adapté',
    (tester) async {
      viewport(tester);
      final auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        page(
          Scaffold(
            body: ListingPhotoScope(
              repository: Reader(),
              picker: NoPicker(),
              child: AuthSession(
                repository: auth,
                child: PublishListingPage(
                  repository: FakeListingRepository(),
                  draftStore: MemoryListingDraftStore(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture(tester, 'publish');
      final title = find.byKey(const ValueKey('listing-title'));
      expect(
        tester
            .widget<EditableText>(
              find.descendant(of: title, matching: find.byType(EditableText)),
            )
            .textInputAction,
        TextInputAction.next,
      );
      expect(
        tester.getTopLeft(title).dy,
        lessThan(tester.getTopLeft(find.text('Brouillon sur cet appareil')).dy),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('listing-neighborhood')),
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(const ValueKey('listing-neighborhood')),
                matching: find.byType(EditableText),
              ),
            )
            .textInputAction,
        TextInputAction.done,
      );
      expect(find.textContaining('photos restent temporaires'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
