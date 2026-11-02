import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:kibo/features/listings/listing_photos.dart';
import 'package:kibo/features/listings/listing_draft_store.dart';
import 'package:kibo/main.dart';
import '../support/auth_fake.dart';
import '../support/listing_fake.dart';
import '../support/supabase_fakes.dart';
import '../support/draft_fake.dart';

class Picker implements ListingPhotoPicker {
  List<ListingPhotoDraft> rows = [];
  @override
  Future<List<ListingPhotoDraft>> pick(String owner) async => rows;
  @override
  Future<List<ListingPhotoDraft>> recover(String owner) async => [];
}

class Photos implements ListingPhotoRepository, PhotoPublicationPreflight {
  bool available = true;
  int preflights = 0;
  @override
  Future<void> checkPublicationAvailability() async {
    preflights++;
    if (!available) throw const PhotoBackendUnavailable();
  }

  @override
  bool get enabled => true;
  int calls = 0;
  bool fail = true;
  List<ListingPhotoDraft> sent = [];
  @override
  Future<void> attach(
    String id,
    List<ListingPhotoDraft> photos,
    String owner,
  ) async {
    calls++;
    sent = photos;
    if (fail) throw StateError('fixture réseau');
  }

  @override
  Future<String> signedUrl(String path) async =>
      'https://fixture.invalid/photo';
}

void main() {
  testWidgets(
    'brouillon restauré avec photos termine sans recréer une annonce confirmée',
    (tester) async {
      final auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
      final listings = FakeListingRepository();
      final photos = Photos()..fail = false;
      final photo = ListingPhotoDraft(
        image.encodeJpg(image.Image(width: 2, height: 2)),
      );
      final drafts = MemoryListingDraftStore();
      drafts.values['test-user-a'] = ListingDraftSnapshot(
        {
          'title': 'Annonce restaurée',
          'description': 'Description fictive restaurée',
          'price': '1000',
          'city': 'Brazzaville',
          'category': 'category-a',
          'type': 'product',
        },
        createdId: 'already-confirmed',
        photos: [photo],
      );
      final client = createTestClient();
      addTearDown(auth.dispose);
      addTearDown(client.dispose);
      await tester.pumpWidget(
        KiboApp(
          draftStore: drafts,
          supabase: SupabaseService(
            config: testConfig,
            initializer: (_) async => client,
          ),
          authRepository: auth,
          listingRepository: listings,
          favoritesRepository: FakeFavoritesRepository(listings: listings),
          photoRepository: photos,
          photoPicker: Picker(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publier'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      await tester.ensureVisible(find.text('Réessayer les photos'));
      await tester.tap(find.text('Réessayer les photos'));
      await tester.pumpAndSettle();
      expect(listings.creates, 0);
      expect(photos.calls, 1);
      expect(photos.sent.single.digest, photo.digest);
      expect(drafts.values['test-user-a'], isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'aperçu, suppression, ordre et reprise photos sans recréer une annonce',
    (tester) async {
      final auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
      final listings = FakeListingRepository()..publishCreates = true;
      final favorites = FakeFavoritesRepository(listings: listings);
      final picker = Picker();
      final photos = Photos();
      final first = ListingPhotoDraft(
        image.encodeJpg(image.Image(width: 2, height: 2)),
      );
      final second = ListingPhotoDraft(
        image.encodeJpg(image.Image(width: 3, height: 2)),
      );
      picker.rows = [first, second];
      final client = createTestClient();
      addTearDown(auth.dispose);
      addTearDown(client.dispose);
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
          photoPicker: picker,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publier'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ajouter des photos'));
      await tester.tap(find.text('Ajouter des photos'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNWidgets(2));
      await tester.ensureVisible(find.byTooltip('Avancer la photo 2'));
      await tester.tap(find.byTooltip('Avancer la photo 2'));
      await tester.pumpAndSettle();
      // Retirer et sélectionner à nouveau vérifie l'absence de doublons.
      await tester.tap(find.byTooltip('Supprimer la photo 2'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ajouter des photos'));
      await tester.tap(find.text('Ajouter des photos'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNWidgets(2));
      for (final field in {
        'listing-title': 'Annonce avec photos',
        'listing-description': 'Description fictive avec photos',
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
      photos.available = false;
      await tester.tap(find.text('Publier l’annonce'));
      await tester.pumpAndSettle();
      expect(listings.creates, 0);
      expect(photos.calls, 0);
      expect(find.textContaining('Aucune annonce créée'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
      photos.available = true;
      await tester.ensureVisible(find.text('Publier l’annonce'));
      await tester.tap(find.text('Publier l’annonce'));
      await tester.pumpAndSettle();
      expect(listings.creates, 1);
      expect(photos.sent.map((p) => p.digest), [second.digest, first.digest]);
      expect(find.textContaining('photos incomplètes'), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(2));
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton &&
                    widget.tooltip == 'Supprimer la photo 1',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Réessayer les photos'));
      await tester.tap(find.text('Réessayer les photos'));
      await tester.pumpAndSettle();
      expect(listings.creates, 1);
      expect(photos.calls, 2);
      expect(photos.sent.map((p) => p.digest), [second.digest, first.digest]);
      expect(find.textContaining('photos incomplètes'), findsOneWidget);
      photos.fail = false;
      await tester.ensureVisible(find.text('Réessayer les photos'));
      await tester.tap(find.text('Réessayer les photos'));
      await tester.pumpAndSettle();
      expect(listings.creates, 1);
      expect(photos.calls, 3);
      // Les reprises après création ne réexécutent pas le préflight et ne
      // recréent jamais l'annonce même si le backend redevient indisponible.
      expect(photos.preflights, 2);
      expect(find.text('Annonce publiée.'), findsOneWidget);
    },
  );
}
