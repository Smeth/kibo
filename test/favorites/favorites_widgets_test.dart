import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/main.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:kibo/features/favorites/favorite_button.dart';
import '../support/auth_fake.dart';
import '../support/listing_fake.dart';
import '../support/supabase_fakes.dart';
import '../support/guest_favorites_fake.dart';

void main() {
  testWidgets(
    'proposition après connexion : report sans écriture, confirmation puis transfert',
    (tester) async {
      final local = MemoryGuestFavoritesStore()..saved = {'listing-a'};
      final auth = FakeAuthRepository();
      final remote = FakeFavoritesRepository()..userId = null;
      final client = createTestClient();
      addTearDown(client.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        KiboApp(
          supabase: SupabaseService(
            config: testConfig,
            initializer: (_) async => client,
          ),
          authRepository: auth,
          listingRepository: FakeListingRepository(),
          favoritesRepository: remote,
          guestFavoritesStore: local,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Favoris sur ce téléphone'), findsOneWidget);
      remote.userId = FakeAuthRepository.user.id;
      auth.emit(FakeAuthRepository.user);
      await tester.pumpAndSettle();
      expect(find.text('Ajouter à mon compte'), findsOneWidget);
      expect(remote.adds, 0);
      await tester.tap(find.text('Plus tard'));
      await tester.pumpAndSettle();
      expect(find.text('Ajouter à mon compte'), findsNothing);
      expect(local.saved, {'listing-a'});
      remote.userId = null;
      auth.emit(null);
      await tester.pumpAndSettle();
      remote.userId = FakeAuthRepository.user.id;
      auth.emit(FakeAuthRepository.user);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajouter à mon compte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(remote.adds, 0);
      await tester.tap(find.text('Ajouter à mon compte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer le transfert'));
      await tester.pumpAndSettle();
      expect(remote.saved, {'listing-a'});
      expect(local.saved, isEmpty);
      expect(find.text('Smartphone Android'), findsOneWidget);
      expect(find.text('Ajouter à mon compte'), findsNothing);
    },
  );

  testWidgets(
    'compte changé pendant la confirmation : aucun transfert vers B',
    (tester) async {
      final local = MemoryGuestFavoritesStore()..saved = {'listing-a'};
      final auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
      final remote = FakeFavoritesRepository();
      final client = createTestClient();
      addTearDown(client.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        KiboApp(
          supabase: SupabaseService(
            config: testConfig,
            initializer: (_) async => client,
          ),
          authRepository: auth,
          listingRepository: FakeListingRepository(),
          favoritesRepository: remote,
          guestFavoritesStore: local,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajouter à mon compte'));
      await tester.pumpAndSettle();
      remote.userId = 'user-b';
      auth.emit(const AuthIdentity(id: 'user-b'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer le transfert'));
      await tester.pumpAndSettle();
      expect(remote.adds, 0);
      expect(remote.saved, isEmpty);
      expect(local.saved, {'listing-a'});
    },
  );

  testWidgets('favoris locaux sur 320 px et texte 150 % sans débordement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = createTestClient();
    addTearDown(client.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: KiboApp(
          supabase: SupabaseService(
            config: testConfig,
            initializer: (_) async => client,
          ),
          listingRepository: FakeListingRepository(),
          favoritesRepository: FakeFavoritesRepository()..userId = null,
          guestFavoritesStore: MemoryGuestFavoritesStore()
            ..saved = {'listing-a'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoris'));
    await tester.pumpAndSettle();
    expect(find.text('Favoris sur ce téléphone'), findsOneWidget);
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.text('Favoris sur ce téléphone')),
      ).scale(10),
      15,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('état commun carte/détail/favoris et retrait', (tester) async {
    final auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    final favorites = FakeFavoritesRepository();
    final client = createTestClient();
    addTearDown(client.dispose);
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      KiboApp(
        supabase: SupabaseService(
          config: testConfig,
          initializer: (_) async => client,
        ),
        authRepository: auth,
        listingRepository: FakeListingRepository(),
        favoritesRepository: favorites,
        guestFavoritesStore: MemoryGuestFavoritesStore(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(FavoriteButton).first,
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byTooltip('Ajouter aux favoris').first);
    await tester.pumpAndSettle();
    expect(favorites.saved, {'listing-a'});
    await tester.tap(find.text('Smartphone Android'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoris'));
    await tester.pumpAndSettle();
    expect(find.text('Smartphone Android'), findsOneWidget);
    await tester.tap(find.byTooltip('Retirer des favoris'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucun favori disponible'), findsOneWidget);
    expect(favorites.saved, isEmpty);
    auth.emit(null);
    await tester.pumpAndSettle();
    expect(find.text('Favoris sur ce téléphone'), findsOneWidget);
  });
  testWidgets('visiteur : favori enregistré localement sans écriture serveur', (
    tester,
  ) async {
    final client = createTestClient();
    addTearDown(client.dispose);
    final favorites = FakeFavoritesRepository()..userId = null;
    final local = MemoryGuestFavoritesStore();
    await tester.pumpWidget(
      KiboApp(
        supabase: SupabaseService(
          config: testConfig,
          initializer: (_) async => client,
        ),
        listingRepository: FakeListingRepository(),
        favoritesRepository: favorites,
        guestFavoritesStore: local,
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(FavoriteButton).first,
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byTooltip('Ajouter aux favoris').first);
    await tester.pumpAndSettle();
    expect(local.saved, {'listing-a'});
    expect(find.byTooltip('Retirer des favoris').first, findsOneWidget);
    expect(favorites.adds, 0);
    await tester.tap(find.text('Favoris'));
    await tester.pumpAndSettle();
    expect(find.text('Smartphone Android'), findsOneWidget);
    await tester.tap(find.text('Smartphone Android'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
    await tester.tap(find.byTooltip('Retirer des favoris'));
    await tester.pumpAndSettle();
    expect(local.saved, isEmpty);
  });
}
