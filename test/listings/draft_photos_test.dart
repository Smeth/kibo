import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kibo/features/listings/listing_draft_store.dart';
import 'package:kibo/features/listings/listing_photos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late SecureListingDraftStore store;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    root = await Directory('.dart_tool').createTemp('draft-photo-test-');
    store = SecureListingDraftStore(
      projectHost: 'fixture.invalid',
      directory: () async => root,
    );
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  final photo = ListingPhotoDraft(Uint8List.fromList([1, 2, 3]));
  test(
    'photos conservées après reconstruction, ordre et isolation des comptes',
    () async {
      final second = ListingPhotoDraft(Uint8List.fromList([4, 5]));
      await store.write(
        'A',
        ListingDraftSnapshot(
          {'title': 'A'},
          photos: [second, photo],
          createdId: 'confirmed',
        ),
      );
      await store.write(
        'B',
        ListingDraftSnapshot({'title': 'B'}, photos: [photo]),
      );
      final restarted = SecureListingDraftStore(
        projectHost: 'fixture.invalid',
        directory: () async => root,
      );
      final restored = (await restarted.read('A'))!;
      expect(restored.photos.map((p) => p.digest), [
        second.digest,
        photo.digest,
      ]);
      expect(restored.createdId, 'confirmed');
      await restarted.clear('A');
      expect(await restarted.read('A'), isNull);
      expect((await restarted.read('B'))!.photos.single.bytes, photo.bytes);
    },
  );
  test(
    'suppression dernière photo nettoie uniquement ses fichiers générés',
    () async {
      await store.write('A', ListingDraftSnapshot({}, photos: [photo]));
      final folder = (await root.list().toList()).single as Directory;
      final unrelated = File('${folder.path}/keep.txt');
      await unrelated.writeAsString('fixture');
      await store.write('A', const ListingDraftSnapshot({}));
      expect(
        (await folder.list().toList()).map((f) => f.uri.pathSegments.last),
        ['keep.txt'],
      );
      expect((await store.read('A'))!.photos, isEmpty);
    },
  );
  test(
    'photo manquante ou altérée refuse restauration sans écraser le manifeste',
    () async {
      await store.write('A', ListingDraftSnapshot({}, photos: [photo]));
      final folder = (await root.list().toList()).single as Directory;
      await File('${folder.path}/${photo.digest}.jpg').writeAsBytes([9]);
      await expectLater(store.read('A'), throwsFormatException);
      await File('${folder.path}/${photo.digest}.jpg').delete();
      await expectLater(store.read('A'), throwsA(isA<FileSystemException>()));
      await store.clear('A');
      expect(await store.read('A'), isNull);
    },
  );
  test(
    'manifestes dangereux et limites refusés, ancien texte lisible',
    () async {
      expect(
        ListingDraftSnapshot.decode('{"version":1,"fields":{}}').photos,
        isEmpty,
      );
      expect(
        () => ListingDraftSnapshot.decode(
          '{"version":1,"fields":{},"photos":["../other"]}',
        ),
        throwsFormatException,
      );
      await expectLater(
        store.write('A', ListingDraftSnapshot({}, photos: [photo, photo])),
        throwsFormatException,
      );
      expect(await store.read('A'), isNull);
    },
  );
  test(
    'écriture interrompue reprend le seul fichier temporaire du compte',
    () async {
      await store.write('A', ListingDraftSnapshot({}, photos: [photo]));
      final folder = (await root.list().toList()).single as Directory;
      final second = ListingPhotoDraft(Uint8List.fromList([8, 9]));
      await File('${folder.path}/${second.digest}.jpg.tmp').writeAsBytes([8]);
      await store.write('A', ListingDraftSnapshot({}, photos: [second]));
      expect((await store.read('A'))!.photos.single.bytes, second.bytes);
      expect(
        (await folder.list().toList()).map(
          (file) => file.uri.pathSegments.last,
        ),
        ['${second.digest}.jpg'],
      );
    },
  );
}
