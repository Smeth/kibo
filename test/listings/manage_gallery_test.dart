import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/listings/listing_photos.dart';
import 'package:kibo/features/listings/manage_listing_photos_page.dart';
import '../support/auth_fake.dart';

class GalleryFake implements ListingGalleryRepository {
  @override
  bool get galleryEnabled => true;
  bool fail = true;
  final operations = <String>[];
  final selections = <List<String?>>[];
  @override
  Future<GalleryState> gallery(String listing, String owner) async =>
      const GalleryState(['first', 'second'], 2, '2026-11-02', true);
  @override
  Future<GalleryState> saveGallery(
    String listing,
    String owner,
    int revision,
    String operation,
    List<GalleryPhoto> photos,
  ) async {
    operations.add(operation);
    selections.add(photos.map((p) => p.path).toList());
    if (fail) throw StateError('lost response');
    return GalleryState(
      photos.map((p) => p.path!).toList(),
      3,
      '2026-11-03',
      true,
    );
  }
}

class PickerFake implements ListingPhotoPicker {
  @override
  Future<List<ListingPhotoDraft>> pick(String owner) async => [];
  @override
  Future<List<ListingPhotoDraft>> recover(String owner) async => [];
}

void main() {
  testWidgets(
    'reordering, removal and uncertain retry preserve the exact operation',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final authRepo = FakeAuthRepository()..identity = FakeAuthRepository.user;
      final auth = AuthController(authRepo);
      addTearDown(auth.dispose);
      addTearDown(authRepo.dispose);
      final repository = GalleryFake();
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            controller: auth,
            child: ManageListingPhotosPage(
              listing: 'listing',
              owner: FakeAuthRepository.user.id,
              repository: repository,
              picker: PickerFake(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Déplacer après').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Retirer la photo').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Retirer la photo').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Enregistrer la galerie'), 200);
      await tester.tap(find.text('Enregistrer la galerie'));
      await tester.pumpAndSettle();
      expect(repository.selections.single, ['second']);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Retirer la photo',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Réessayer l’enregistrement'));
      await tester.tap(find.text('Réessayer l’enregistrement'));
      await tester.pumpAndSettle();
      expect(repository.operations.toSet().length, 1);
      expect(repository.selections[1], repository.selections[0]);
      authRepo.emit(null);
      await tester.pump();
      authRepo.emit(FakeAuthRepository.user);
      await tester.pumpAndSettle();
      expect(
        find.text('La session a changé. Revenez à vos annonces.'),
        findsOneWidget,
      );
      expect(find.text('Réessayer l’enregistrement'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
