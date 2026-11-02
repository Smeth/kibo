import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/main.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:kibo/core/widgets/kibo_bottom_navigation.dart';
import 'package:kibo/features/listings/listing_photos.dart';
import '../support/auth_fake.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import '../support/listing_fake.dart';
import '../support/supabase_fakes.dart';
import '../support/draft_fake.dart';

// Le scénario publie sans photo, mais doit aussi fonctionner avec la fonction
// photos activée : la récupération Android doit rester un service simulé.
class _EmptyPhotos implements ListingPhotoPicker, ListingPhotoRepository {
  final recoveredOwners = <String>[];

  @override
  bool get enabled => true;

  @override
  Future<List<ListingPhotoDraft>> recover(String owner) async {
    recoveredOwners.add(owner);
    return [];
  }

  @override
  Future<List<ListingPhotoDraft>> pick(String owner) async => throw StateError(
    'Aucune sélection attendue dans ce scénario sans photo.',
  );

  @override
  Future<void> attach(
    String listingId,
    List<ListingPhotoDraft> photos,
    String owner,
  ) async =>
      throw StateError('Aucun upload attendu pour une annonce sans photo.');

  @override
  Future<String> signedUrl(String path) async =>
      throw StateError('Aucune lecture photo attendue dans ce scénario.');
}

void main() {
  testWidgets(
    'vendeur -> publication -> acheteur -> favori persistant -> isolation A/B',
    (tester) async {
      final auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
      final listings = FakeListingRepository()
        ..publishCreates = true
        ..listings = [];
      final favorites = FakeFavoritesRepository(listings: listings);
      final photos = _EmptyPhotos();
      final client = createTestClient();
      addTearDown(client.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        KiboApp(
          draftStore: MemoryListingDraftStore(),
          supabase: SupabaseService(
            config: testConfig,
            initializer: (_) async => client,
          ),
          authRepository: auth,
          listingRepository: listings,
          favoritesRepository: favorites,
          photoRepository: photos,
          photoPicker: photos,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publier'));
      await tester.pumpAndSettle();
      expect(photos.recoveredOwners, [FakeAuthRepository.user.id]);
      expect(find.text('Ajouter des photos'), findsOneWidget);
      for (final field in {
        'listing-title': 'Annonce immédiate',
        'listing-description': 'Description de test publication directe',
        'listing-price': '1000',
      }.entries) {
        await tester.ensureVisible(find.byKey(ValueKey(field.key)));
        await tester.enterText(find.byKey(ValueKey(field.key)), field.value);
      }
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('listing-category')),
      );
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
      await tester.tap(find.text('Publier l’annonce'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<KiboBottomNavigation>(find.byType(KiboBottomNavigation))
            .selectedIndex,
        0,
      );
      // Laisser disparaître le message de confirmation qui recouvre le bas du catalogue.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Annonce immédiate').hitTestable(),
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Annonce immédiate'));
      await tester.pumpAndSettle();
      expect(
        find.text('Description de test publication directe'),
        findsOneWidget,
      );
      // Le même catalogue public est ouvert par un autre compte.
      listings.userId = 'test-user-b';
      favorites.userId = 'test-user-b';
      auth.emit(
        const AuthIdentity(id: 'test-user-b', email: 'buyer@example.invalid'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ajouter aux favoris'));
      await tester.pumpAndSettle();
      expect(favorites.saved, {'created-listing'});
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Annonce immédiate'), findsOneWidget);
      expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
      await tester.tap(find.byTooltip('Actualiser les favoris'));
      await tester.pumpAndSettle();
      expect(favorites.saved, {'created-listing'});
      // Recréation de l'application et des contrôleurs ; serveur fictif conservé.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        KiboApp(
          key: const ValueKey('restart'),
          draftStore: MemoryListingDraftStore(),
          supabase: SupabaseService(
            config: testConfig,
            initializer: (_) async => client,
          ),
          authRepository: auth,
          listingRepository: listings,
          favoritesRepository: favorites,
          photoRepository: photos,
          photoPicker: photos,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publier'));
      await tester.pumpAndSettle();
      expect(photos.recoveredOwners, contains('test-user-b'));
      await tester.tap(find.text('Favoris'));
      await tester.pumpAndSettle();
      expect(find.text('Annonce immédiate'), findsOneWidget);
      expect(find.byTooltip('Retirer des favoris'), findsOneWidget);
      favorites.userId = 'test-user-a';
      listings.userId = 'test-user-a';
      auth.emit(FakeAuthRepository.user);
      await tester.pumpAndSettle();
      expect(find.text('Annonce immédiate'), findsNothing);
      favorites.userId = 'test-user-b';
      listings.userId = 'test-user-b';
      auth.emit(
        const AuthIdentity(id: 'test-user-b', email: 'buyer@example.invalid'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Retirer des favoris'));
      await tester.pumpAndSettle();
      expect(favorites.saved, isEmpty);
    },
  );
}
