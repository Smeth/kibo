import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/appearance_controller.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/main.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_page.dart';
import 'package:kibo/features/auth/profile_page.dart';
import 'package:kibo/features/chat/chat_page.dart';
import 'package:kibo/features/listings/listing_detail_page.dart';
import 'package:kibo/features/listings/listing_models.dart';
import '../support/auth_fake.dart';
import '../support/listing_fake.dart';
import '../support/manrope_fonts.dart';
import '../support/supabase_fakes.dart';
import '../support/guest_favorites_fake.dart';
import '../support/draft_fake.dart';
import '../chat/chat_widgets_test.dart' show ChatFake;

class _Store implements AppearanceStore {
  String? value;
  final writes = <String>[];
  Completer<String?>? pending;
  Completer<void>? firstWrite;
  @override
  Future<String?> read() async => pending == null ? value : pending!.future;
  @override
  Future<void> write(String value) async {
    writes.add(value);
    if (writes.length == 1 && firstWrite != null) await firstWrite!.future;
    this.value = value;
  }
}

void main() {
  setUpAll(loadManropeFonts);
  test(
    'apparence mémorisée et écriture ordonnée des changements rapides',
    () async {
      final store = _Store()
        ..value = 'dark'
        ..firstWrite = Completer<void>();
      final controller = AppearanceController(store);
      addTearDown(controller.dispose);
      await controller.initialize();
      expect(controller.mode, ThemeMode.dark);
      final first = controller.select(ThemeMode.light);
      final second = controller.select(ThemeMode.dark);
      await Future<void>.delayed(Duration.zero);
      expect(store.writes, ['light']);
      store.firstWrite!.complete();
      await Future.wait([first, second]);
      expect(store.value, 'dark');
      expect(controller.mode, ThemeMode.dark);
    },
  );
  test('lecture tardive ne remplace pas un choix utilisateur', () async {
    final store = _Store()..pending = Completer<String?>();
    final controller = AppearanceController(store);
    addTearDown(controller.dispose);
    final reading = controller.initialize();
    await controller.select(ThemeMode.dark);
    store.pending!.complete('light');
    await reading;
    expect(controller.mode, ThemeMode.dark);
  });
  test('contrastes du thème sombre pour les textes et actions', () {
    final theme = KiboTheme.dark;
    final s = theme.colorScheme;
    expect(theme.brightness, Brightness.dark);
    double ratio(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
    }

    for (final pair in [
      (s.onSurface, s.surface),
      (s.onSurfaceVariant, s.surface),
      (s.primary, s.surface),
      (s.onPrimary, s.primary),
      (s.onPrimaryContainer, s.primaryContainer),
    ]) {
      expect(ratio(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
    }
  });
  testWidgets(
    'choix clair/sombre dans KiboApp conserve les saisies et la session',
    (tester) async {
      final store = _Store()..value = 'system';
      final appearance = AppearanceController(store);
      final auth = FakeAuthRepository();
      final client = createTestClient();
      addTearDown(appearance.dispose);
      addTearDown(auth.dispose);
      addTearDown(client.dispose);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(
        KiboApp(
          appearance: appearance,
          supabase: SupabaseService(
            config: testConfig,
            initializer: (_) async => client,
          ),
          authRepository: auth,
          listingRepository: FakeListingRepository(),
          favoritesRepository: FakeFavoritesRepository(),
          guestFavoritesStore: MemoryGuestFavoritesStore(),
          draftStore: MemoryListingDraftStore(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(ProfilePage))).brightness,
        Brightness.dark,
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth-email')),
        'note@example.invalid',
      );
      tester.testTextInput.hide();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Clair'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(ProfilePage))).brightness,
        Brightness.light,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Sombre'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(ProfilePage))).brightness,
        Brightness.dark,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('auth-email')))
            .controller!
            .text,
        'note@example.invalid',
      );
      expect(store.value, 'dark');
      expect(auth.signInCalls, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'profil public : connexion directement dans la page sans dépiler l’accueil',
    (tester) async {
      final repo = FakeAuthRepository();
      addTearDown(repo.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.dark,
          home: Scaffold(
            body: AuthSession(repository: repo, child: const ProfilePage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('auth-email')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('auth-email')),
        'fixture@example.invalid',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth-password')),
        'mot-de-passe-test',
      );
      await tester.ensureVisible(find.text('Se connecter'));
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      expect(repo.signInCalls, 1);
      expect(find.text('Profil test'), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-password')), findsNothing);
      expect(find.byType(Scaffold), findsOneWidget);
    },
  );
  testWidgets('messages vides : texte triple sur 320 px sans débordement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    final chat = ChatFake()..rows = [];
    addTearDown(auth.dispose);
    addTearDown(chat.updates.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.dark,
        home: AuthSession(
          repository: auth,
          child: ChatPage(repository: chat, ownerId: 'test-user-a'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aucune conversation.'), findsOneWidget);
    await tester.ensureVisible(
      find.text('Écrivez à un vendeur depuis une annonce.'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(chat.sends, 0);
  });
  testWidgets(
    'détail : photo bord à bord et contact persistant avec garde invité',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = FakeListingRepository()
        ..listings = [
          PublicListing(
            id: 'fixture',
            title: 'Smartphone',
            description: 'Description fictive. ' * 150,
            price: '95000',
            city: 'Brazzaville',
            sellerId: 'seller',
            photoPaths: const ['fixture'],
          ),
        ];
      final auth = FakeAuthRepository();
      final chat = ChatFake()..userId = null;
      addTearDown(auth.dispose);
      addTearDown(chat.updates.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.dark,
          home: AuthSession(
            repository: auth,
            child: ListingDetailPage(
              id: 'fixture',
              repository: repo,
              chats: chat,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final hero = find.byKey(const ValueKey('listing-gallery-fixture'));
      expect(tester.getSize(hero).width, 320);
      final before = tester.getRect(find.byTooltip('Écrire au vendeur'));
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byTooltip('Écrire au vendeur')), before);
      await tester.tap(find.byTooltip('Écrire au vendeur'));
      await tester.pumpAndSettle();
      expect(chat.starts, 0);
      expect(find.byType(AuthPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
