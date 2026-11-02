// Génération explicite d'aperçus fictifs, hors de la suite fonctionnelle.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/main.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import '../test/support/auth_fake.dart';
import '../test/support/listing_fake.dart';
import '../test/support/guest_favorites_fake.dart';
import '../test/support/draft_fake.dart';
import '../test/support/manrope_fonts.dart';
import '../test/support/supabase_fakes.dart';
import '../test/listings/uiux_marketplace_test.dart'
    show capture, viewport, previewKey;

void main() {
  setUpAll(() async {
    await loadManropeFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets('aperçus Material 3 : profil, favoris et recherche fictifs', (
    tester,
  ) async {
    viewport(tester);
    final client = createTestClient();
    final auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    final listings = FakeListingRepository();
    final favorites = FakeFavoritesRepository(listings: listings)
      ..saved = {'listing-a', 'listing-b'};
    addTearDown(client.dispose);
    addTearDown(auth.dispose);
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
          favoritesRepository: favorites,
          guestFavoritesStore: MemoryGuestFavoritesStore(),
          draftStore: MemoryListingDraftStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final entry in {
      'Profil': 'm3-profile',
      'Favoris': 'm3-favorites',
      'Recherche': 'm3-search',
    }.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      await capture(tester, entry.value);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
