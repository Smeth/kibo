// Références générées depuis les vrais widgets ; uniquement des fixtures.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/main.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/core/theme/appearance_controller.dart';
import 'package:kibo/core/widgets/congo_city_field.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_page.dart';
import 'package:kibo/features/auth/password_pages.dart';
import 'package:kibo/features/chat/chat_page.dart';
import 'package:kibo/features/chat/chat_repository.dart';
import 'package:kibo/features/chat/blocked_users_page.dart';
import 'package:kibo/features/comments/comments_page.dart';
import 'package:kibo/features/comments/comments_repository.dart';
import 'package:kibo/features/favorites/favorites_controller.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_detail_page.dart';
import 'package:kibo/features/listings/listing_feed.dart';
import 'package:kibo/features/listings/listing_photos.dart';
import 'package:kibo/features/listings/listing_photo_widgets.dart';
import 'package:kibo/features/listings/publish_listing_page.dart';
import 'package:kibo/features/listings/listing_draft_store.dart';
import 'package:kibo/features/listings/my_listings_page.dart';
import 'package:kibo/features/listings/edit_listing_page.dart';
import 'package:kibo/features/listings/owned_listing_repository.dart';
import 'package:kibo/features/listings/owned_listing_query.dart';
import 'package:kibo/features/profile/edit_profile_page.dart';
import 'package:kibo/features/profile/account_settings_page.dart';
import 'package:kibo/features/profile/engagement_pages.dart';
import 'package:kibo/features/seller/seller_page.dart';
import 'package:kibo/features/seller/contact_preferences_page.dart';
import 'package:kibo/features/safety/safety_page.dart';
import '../test/support/listing_fake.dart';
import '../test/support/auth_fake.dart';
import '../test/support/draft_fake.dart';
import '../test/support/manrope_fonts.dart';
import '../test/chat/chat_widgets_test.dart' show EnhancedChatFake, thread;
import '../test/chat/message_actions_test.dart' show MessageActionsFake;
import '../test/safety/safety_widgets_test.dart' show SafetyFake;
import '../test/profile/account_mvp_test.dart' show RecoveryFake, AccountFake;
import '../test/profile/engagement_widgets_test.dart' show EngagementFake;
import 'maquette_fixtures.dart';

class _AppearanceMemory implements AppearanceStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String value) async {}
}

class _Owned implements OwnedListingRepository {
  static const row = OwnedListing(
    id: 'listing-a',
    sellerId: 'test-user-a',
    status: 'published',
    updatedAt: '2026-11-01T12:00:00Z',
    photoPaths: ['face', 'dos', 'accessoires'],
    draft: ListingDraft(
      title: 'Smartphone 128 Go',
      description: 'Très bon état, accessoires inclus.',
      price: '95000',
      city: 'Brazzaville',
      categoryId: 'category-a',
    ),
  );
  @override
  String? get userId => 'test-user-a';
  @override
  Future<List<OwnedListing>> mine(
    String ownerId, {
    int offset = 0,
    OwnedListingQuery query = const OwnedListingQuery(),
  }) async => offset == 0 ? [row] : [];
  @override
  Future<void> edit(OwnedListing listing, ListingDraft draft) async {}
  @override
  Future<void> transition(OwnedListing listing, String status) async {}
}

class _Photos implements ListingPhotoRepository, ListingPhotoPicker {
  _Photos(this.bytes);
  final Uint8List bytes;
  @override
  bool get enabled => true;
  @override
  Future<String> signedUrl(String path) async =>
      'https://fixture.invalid/$path';
  @override
  Future<void> attach(
    String listingId,
    List<ListingPhotoDraft> photos,
    String owner,
  ) async {}
  @override
  Future<List<ListingPhotoDraft>> pick(String owner) async => [
    ListingPhotoDraft(bytes),
  ];
  @override
  Future<List<ListingPhotoDraft>> recover(String owner) async => [];
}

class _ImageHttp extends HttpOverrides {
  _ImageHttp(this.bytes);
  final Uint8List bytes;
  @override
  HttpClient createHttpClient(SecurityContext? context) => _ImageClient(bytes);
}

class _ImageClient implements HttpClient {
  _ImageClient(this.bytes);
  final Uint8List bytes;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ImageRequest(bytes);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageRequest implements HttpClientRequest {
  _ImageRequest(this.bytes);
  final Uint8List bytes;
  @override
  HttpHeaders get headers => _Headers();
  @override
  Future<HttpClientResponse> close() async => _ImageResponse(bytes);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Headers implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageResponse extends Stream<List<int>> implements HttpClientResponse {
  _ImageResponse(this.bytes);
  final Uint8List bytes;
  @override
  int get statusCode => 200;
  @override
  int get contentLength => bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<Uint8List> illustration() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 800, 900),
    Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE5F2EC), Color(0xFF97B8A6)],
      ).createShader(const Rect.fromLTWH(0, 0, 800, 900)),
  );
  canvas.drawOval(
    const Rect.fromLTWH(170, 755, 460, 55),
    Paint()..color = const Color(0x3324382D),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(235, 85, 330, 680),
      const Radius.circular(48),
    ),
    Paint()..color = const Color(0xFF17211D),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(250, 100, 300, 650),
      const Radius.circular(36),
    ),
    Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF12A879), Color(0xFF075B45)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(250, 100, 300, 650)),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(340, 112, 120, 20),
      const Radius.circular(10),
    ),
    Paint()..color = const Color(0xFF17211D),
  );
  canvas.drawCircle(
    const Offset(400, 420),
    85,
    Paint()..color = const Color(0x228FFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(800, 900);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return data!.buffer.asUint8List();
}

const _boundary = ValueKey('maquette-export');
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadManropeFonts();
    await CongoPlaces.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets(
    'export de tous les écrans réels en clair et sombre',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bytes = await tester.runAsync(illustration);
      final previous = HttpOverrides.current;
      HttpOverrides.global = _ImageHttp(bytes!);
      addTearDown(() => HttpOverrides.global = previous);
      final photos = _Photos(bytes);
      final listings = FakeListingRepository()
        ..categoryRows = const [
          ListingCategory(id: 'category-a', name: 'Téléphones et informatique'),
        ]
        ..listings = [
          PublicListing(
            id: 'listing-a',
            publishedAt: DateTime.now().subtract(
              const Duration(hours: 1, minutes: 10),
            ),
            title: 'Smartphone 128 Go',
            description:
                'Un smartphone en très bon état, avec sa boîte et ses accessoires. À découvrir à Brazzaville. Remise en main propre à convenir avec le vendeur.',
            price: '95000',
            city: 'Brazzaville',
            neighborhood: 'Bacongo',
            categoryName: 'Téléphones et informatique',
            sellerId: 'seller',
            photoPaths: ['face', 'dos', 'accessoires'],
          ),
          PublicListing(
            id: 'listing-b',
            publishedAt: DateTime.now().subtract(
              const Duration(days: 2, hours: 3),
            ),
            title: 'Canapé trois places',
            description: 'Confortable et bien entretenu.',
            price: '180000',
            city: 'Brazzaville',
            categoryName: 'Maison et équipement',
          ),
        ];
      final authRepo = RecoveryFake()..identity = FakeAuthRepository.user;
      final auth = AuthController(authRepo);
      final guestRepo = RecoveryFake();
      final guest = AuthController(guestRepo);
      final appearance = AppearanceController(_AppearanceMemory());
      final favoriteRepo = FakeFavoritesRepository(listings: listings)
        ..saved = {'listing-a'};
      final favorites = FavoritesController(favoriteRepo);
      final seller = PreviewSeller();
      final launcher = PreviewLauncher();
      final comments = PreviewComments()
        ..rows = [
          ListingComment(
            id: 'c',
            userId: 'test-user-a',
            content: 'Bonjour, cet article est-il toujours disponible ?',
            createdAt: DateTime(2026, 11, 1),
          ),
        ];
      final chats = MessageActionsFake()
        ..items = [
          ChatMessage(
            id: 'own',
            senderId: 'test-user-a',
            content: 'Bonjour, votre annonce est-elle disponible ?',
            createdAt: DateTime(2026, 11, 1, 10, 25),
            readAt: '2026-11-01T10:26:00Z',
          ),
          ChatMessage(
            id: 'message',
            senderId: 'seller',
            content:
                'Bonjour ! Oui, il est disponible. Quand souhaitez-vous le voir ?',
            createdAt: DateTime(2026, 11, 1, 10, 30),
          ),
        ];
      final safety = SafetyFake()..admin = true;
      final engagement = EngagementFake()..admin = true;
      addTearDown(() => chats.updates.close());
      addTearDown(favorites.dispose);
      addTearDown(appearance.dispose);
      addTearDown(auth.dispose);
      addTearDown(guest.dispose);
      addTearDown(authRepo.dispose);
      addTearDown(guestRepo.dispose);
      favorites.bindUser('test-user-a');
      await favorites.refresh();
      Widget home() => KiboHomePage(
        repository: listings,
        chats: chats,
        safety: safety,
        sellers: seller,
        contactLauncher: launcher,
        comments: comments,
        ownedRepository: _Owned(),
        accountRequests: AccountFake(),
        draftStore: MemoryListingDraftStore(),
      );
      final entries = <Map<String, String>>[];
      Future<void> settle() async {
        for (var cycle = 0; cycle < 3; cycle++) {
          await tester.pump(const Duration(milliseconds: 100));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
        }
        await tester.pumpAndSettle();
      }

      Future<void> shot(
        String id,
        String title,
        Widget body,
        Brightness brightness, {
        bool signedIn = true,
        bool scaffold = false,
        Future<void> Function()? prepare,
      }) async {
        debugPrint('MAQUETTE $id ${brightness.name}');
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await settle();
        appearance.mode = brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light;
        final navigator = GlobalKey<NavigatorState>();
        final routed = !scaffold && body is! KiboHomePage;
        Widget screen = scaffold ? Scaffold(body: SafeArea(child: body)) : body;
        screen = AuthScope(
          controller: signedIn ? auth : guest,
          child: FavoritesScope(
            controller: favorites,
            child: ListingPhotoScope(
              repository: photos,
              picker: photos,
              child: screen,
            ),
          ),
        );
        await tester.pumpWidget(
          AppearanceScope(
            controller: appearance,
            child: RepaintBoundary(
              key: _boundary,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: KiboTheme.light,
                darkTheme: KiboTheme.dark,
                themeMode: appearance.mode,
                navigatorKey: navigator,
                home: routed ? const Scaffold() : screen,
              ),
            ),
          ),
        );
        if (routed) {
          navigator.currentState!
              .push(MaterialPageRoute<void>(builder: (_) => screen))
              .ignore();
        }
        for (var cycle = 0; cycle < 3; cycle++) {
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 150)),
          );
        }
        await settle();
        if (prepare != null) {
          await prepare();
          await settle();
        }
        expect(tester.takeException(), isNull, reason: id);
        final mode = brightness == Brightness.dark ? 'sombre' : 'clair';
        final path = 'maquette/$mode/$id.png';
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_boundary),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(path).parent.create(recursive: true);
          await File(path).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
        entries.add({
          'id': id,
          'title': title,
          'mode': mode,
          'path': '$mode/$id.png',
        });
      }

      for (final brightness in [Brightness.light, Brightness.dark]) {
        await shot('01-accueil', 'Accueil', home(), brightness);
        await shot(
          '02-recherche',
          'Recherche',
          home(),
          brightness,
          prepare: () async {
            await tester.tap(find.text('Recherche'));
            await settle();
          },
        );
        await shot(
          '03-filtres',
          'Filtres et tri',
          home(),
          brightness,
          prepare: () async {
            await tester.tap(find.text('Recherche'));
            await settle();
            await tester.tap(find.text('Filtres et tri'));
          },
        );
        await shot(
          '04-detail',
          'Détail de l’annonce',
          ListingDetailPage(
            id: 'listing-a',
            repository: listings,
            chats: chats,
            sellers: seller,
            contactLauncher: launcher,
            comments: comments,
            safety: safety,
          ),
          brightness,
        );
        await shot(
          '05-favoris',
          'Favoris',
          home(),
          brightness,
          prepare: () async {
            await tester.tap(find.text('Favoris'));
            await settle();
          },
        );
        await shot(
          '06-profil',
          'Profil connecté',
          home(),
          brightness,
          prepare: () async {
            await tester.tap(find.text('Profil'));
            await settle();
          },
        );
        await shot(
          '07-connexion-directe',
          'Profil : connexion directe',
          home(),
          brightness,
          prepare: () async {
            await tester.tap(find.text('Profil'));
            await settle();
          },
          signedIn: false,
        );
        await shot(
          '08-inscription',
          'Inscription',
          AuthPage(controller: guest, registration: true),
          brightness,
          signedIn: false,
        );
        await shot(
          '09-publication',
          'Publier une annonce',
          home(),
          brightness,
          prepare: () async {
            await tester.tap(find.text('Publier'));
            await settle();
          },
        );
        await shot(
          '10-photos',
          'Photos de l’annonce',
          home(),
          brightness,
          prepare: () async {
            await tester.tap(find.text('Publier'));
            await settle();
            await tester.ensureVisible(find.text('Ajouter des photos'));
            await tester.tap(find.text('Ajouter des photos'));
          },
        );
        await shot(
          '11-mes-annonces',
          'Mes annonces',
          MyListingsPage(repository: _Owned(), listings: listings),
          brightness,
        );
        await shot(
          '12-modifier-annonce',
          'Modifier une annonce',
          EditListingPage(
            listing: _Owned.row,
            repository: _Owned(),
            listings: listings,
          ),
          brightness,
        );
        await shot(
          '13-messages',
          'Conversations',
          ChatPage(repository: chats, ownerId: 'test-user-a'),
          brightness,
        );
        final empty = EnhancedChatFake()..rows = [];
        addTearDown(() => empty.updates.close());
        await shot(
          '14-messages-vides',
          'Messages : état vide',
          ChatPage(repository: empty, ownerId: 'test-user-a'),
          brightness,
        );
        await shot(
          '15-conversation',
          'Conversation',
          ChatPage(repository: chats, ownerId: 'test-user-a', thread: thread),
          brightness,
        );
        await shot(
          '16-notifications',
          'Notifications',
          SafetyPage(
            repository: safety,
            ownerId: 'test-user-a',
            screen: SafetyScreen.notifications,
          ),
          brightness,
        );
        await shot(
          '17-signalement',
          'Signaler un contenu',
          SafetyPage(
            repository: safety,
            ownerId: 'test-user-a',
            screen: SafetyScreen.report,
            listingId: 'listing-a',
          ),
          brightness,
        );
        await shot(
          '18-moderation',
          'Modération',
          SafetyPage(
            repository: safety,
            ownerId: 'test-user-a',
            screen: SafetyScreen.moderation,
          ),
          brightness,
        );
        await shot(
          '19-commentaires',
          'Commentaires',
          CommentsPage(repository: comments, listingId: 'listing-a'),
          brightness,
        );
        await shot(
          '20-reponses',
          'Réponses',
          CommentsPage(
            repository: comments,
            listingId: 'listing-a',
            parentId: 'c',
          ),
          brightness,
        );
        await shot(
          '21-vendeur',
          'Profil du vendeur',
          SellerPage(
            sellerId: 'seller',
            listingId: 'listing-a',
            repository: seller,
            launcher: launcher,
          ),
          brightness,
        );
        await shot(
          '22-coordonnees',
          'Coordonnées de contact',
          ContactPreferencesPage(ownerId: 'test-user-a', repository: seller),
          brightness,
        );
        await shot(
          '23-modifier-profil',
          'Modifier le profil',
          EditProfilePage(
            controller: auth,
            profile: (await authRepo.synchronizeProfile())!,
          ),
          brightness,
        );
        await shot(
          '24-mot-de-passe-oublie',
          'Mot de passe oublié',
          PasswordResetPage(repository: guestRepo),
          brightness,
          signedIn: false,
        );
        await shot(
          '25-changer-mot-de-passe',
          'Changer le mot de passe',
          PasswordChangePage(controller: auth),
          brightness,
        );
        await shot(
          '26-compte',
          'Compte et données',
          AccountSettingsPage(
            controller: auth,
            repository: AccountFake(),
            chats: chats,
          ),
          brightness,
        );
        await shot(
          '27-bloques',
          'Interlocuteurs bloqués',
          BlockedUsersPage(controller: auth, repository: chats),
          brightness,
        );
        await shot(
          '28-preferences',
          'Préférences de notifications',
          EngagementPage(
            controller: auth,
            repository: engagement,
            preferences: true,
          ),
          brightness,
        );
        await shot(
          '29-suivi-demande',
          'Suivi des demandes de compte',
          EngagementPage(controller: auth, repository: engagement),
          brightness,
        );
        await shot(
          '30-connexion-route',
          'Connexion depuis une action protégée',
          AuthPage(controller: guest),
          brightness,
          signedIn: false,
        );
        final previewStore = MemoryListingDraftStore()
          ..values['test-user-a'] = const ListingDraftSnapshot({
            'title': 'Smartphone 128 Go',
            'description': 'Très bon état, accessoires inclus.',
            'price': '95000',
            'category': 'category-a',
            'city': 'Brazzaville',
            'neighborhood': 'Bacongo',
            'type': 'product',
          });
        await shot(
          '31-apercu-publication',
          'Aperçu avant publication',
          PublishListingPage(repository: listings, draftStore: previewStore),
          brightness,
          scaffold: true,
          prepare: () async {
            await tester.ensureVisible(find.text('Aperçu de l’annonce'));
            await tester.tap(find.text('Aperçu de l’annonce'));
          },
        );
        await shot(
          '32-apparence',
          'Choix de l’apparence',
          home(),
          brightness,
          prepare: () async =>
              tester.tap(find.byTooltip('Changer l’apparence')),
        );
        final unavailable = FakeListingRepository()
          ..readError = StateError('Fixture hors ligne');
        await shot(
          '33-erreur-catalogue',
          'Catalogue indisponible',
          Scaffold(body: ListingFeed(repository: unavailable)),
          brightness,
        );
        await shot(
          '34-villes-congo',
          'Sélection des villes du Congo',
          home(),
          brightness,
          prepare: () async =>
              tester.tap(find.byKey(const ValueKey('home-city-filter'))),
        );
        await shot(
          '35-retirer-annonce',
          'Retirer une annonce du catalogue',
          MyListingsPage(repository: _Owned(), listings: listings),
          brightness,
          prepare: () async {
            await tester.scrollUntilVisible(
              find.text('Supprimer du catalogue').hitTestable(),
              180,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.tap(find.text('Supprimer du catalogue'));
          },
        );
        await shot(
          '36-modifier-message',
          'Modifier son message (contrat préparé)',
          ChatPage(repository: chats, ownerId: 'test-user-a', thread: thread),
          brightness,
          prepare: () async {
            await tester.tap(find.byKey(const ValueKey('message-actions-own')));
            await settle();
            await tester.tap(find.text('Modifier'));
          },
        );
        await shot(
          '37-supprimer-message',
          'Supprimer son message (contrat préparé)',
          ChatPage(repository: chats, ownerId: 'test-user-a', thread: thread),
          brightness,
          prepare: () async {
            await tester.tap(find.byKey(const ValueKey('message-actions-own')));
            await settle();
            await tester.tap(find.text('Supprimer'));
          },
        );
        await shot(
          '38-annonce-sans-photo',
          'Modifier une annonce sans photo',
          EditListingPage(
            listing: OwnedListing(
              id: _Owned.row.id,
              sellerId: _Owned.row.sellerId,
              status: _Owned.row.status,
              updatedAt: _Owned.row.updatedAt,
              draft: _Owned.row.draft,
            ),
            repository: _Owned(),
            listings: listings,
          ),
          brightness,
        );
        await shot(
          '39-appui-long-message',
          'Actions par appui long',
          ChatPage(repository: chats, ownerId: 'test-user-a', thread: thread),
          brightness,
          prepare: () async => tester.longPress(
            find.text('Bonjour, votre annonce est-elle disponible ?'),
          ),
        );
      }
      await tester.pumpWidget(const SizedBox());
      await settle();
      await tester.runAsync(() async {
        final html = StringBuffer(
          '<!doctype html><html lang="fr"><meta charset="utf-8"><title>KIBO · Maquettes</title><style>body{font:16px system-ui;background:#101a16;color:#e7f0eb;margin:32px}a{color:#6ddcb2}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px}img{width:100%;border-radius:24px}article{max-width:393px}header{margin-bottom:32px}</style><header><h1>KIBO · Références visuelles</h1><p>Vrais écrans Flutter · fixtures fictives · clair et sombre · 393 × 852</p></header><main>',
        );
        for (final entry in entries) {
          html.write(
            '<article><h2>${entry['title']} · ${entry['mode']}</h2><a href="${entry['path']}"><img loading="lazy" src="${entry['path']}" alt="${entry['title']} ${entry['mode']}"></a></article>',
          );
        }
        html.write('</main></html>');
        await File('maquette/index.html').writeAsString(html.toString());
        await File('maquette/manifest.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'viewport': {'width': 393, 'height': 852, 'pixelRatio': 2},
            'fixture': true,
            'screens': entries,
          }),
        );
        final catalogue = StringBuffer(
          '# Catalogue des écrans\n\nChaque lien correspond à un vrai écran Flutter alimenté uniquement par des fixtures.\n\n| Écran | Clair | Sombre |\n|---|---|---|\n',
        );
        for (final entry in entries.where(
          (entry) => entry['mode'] == 'clair',
        )) {
          catalogue.writeln(
            '| ${entry['title']} | [PNG](clair/${entry['id']}.png) | [PNG](sombre/${entry['id']}.png) |',
          );
        }
        await File('maquette/CATALOGUE.md').writeAsString(catalogue.toString());
      });
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
