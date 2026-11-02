import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as codec;
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/listings/listing_photo_cache.dart';
import 'package:kibo/features/listings/listing_photo_widgets.dart';
import 'package:kibo/features/listings/listing_photos.dart';
import '../support/auth_fake.dart';
import 'listing_photo_widgets_test.dart' show Reader, NoPicker;

class MemoryReader extends Reader implements CachedListingPhotoRepository {
  MemoryReader(this.owner);
  final Object? Function() owner;
  int downloads = 0;
  late final cache = ListingPhotoCache(
    scope: owner,
    download: (_) async {
      downloads++;
      return Uint8List.fromList(
        codec.encodePng(codec.Image(width: 2, height: 2)),
      );
    },
  );
  @override
  int get photoCacheRevision => cache.revision;
  @override
  Future<Uint8List> photoBytes(String path, {bool force = false}) =>
      cache.read(path, force: force);
}

void main() {
  testWidgets(
    'remonter une photo, autre taille : pas de téléchargement ni spinner',
    (tester) async {
      final repository = MemoryReader(() => null);
      Widget app(double width, int key) => MaterialApp(
        home: ListingPhotoScope(
          repository: repository,
          picker: NoPicker(),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: 150,
                child: ListingPhotoView(
                  key: ValueKey(key),
                  path: 'a',
                  label: 'Photo',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(150, 1));
      await tester.pumpAndSettle();
      expect(repository.downloads, 1);
      expect(find.byType(Image), findsOneWidget);
      await tester.pumpWidget(app(300, 2));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpAndSettle();
      expect(repository.downloads, 1);
      expect(find.byType(Image), findsOneWidget);
      expect(repository.requests, isEmpty); // Pas de création d'URL signée.
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'photo affichée : changement de session impose une nouvelle lecture',
    (tester) async {
      final authRepository = FakeAuthRepository();
      final auth = AuthController(authRepository);
      final repository = MemoryReader(() => auth.identity?.id);
      addTearDown(auth.dispose);
      addTearDown(authRepository.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: AuthScope(
            controller: auth,
            child: ListingPhotoScope(
              repository: repository,
              picker: NoPicker(),
              child: const Scaffold(
                body: SizedBox(
                  height: 150,
                  child: ListingPhotoView(path: 'a', label: 'Photo'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.downloads, 1);
      authRepository.emit(FakeAuthRepository.user);
      await tester.pumpAndSettle();
      expect(repository.downloads, 2);
      authRepository.emit(null);
      await tester.pumpAndSettle();
      expect(repository.downloads, 3);
      expect(tester.takeException(), isNull);
    },
  );
}
