import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kibo/features/listings/listing_photo_cache.dart';
import 'package:kibo/features/listings/listing_photos.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../support/supabase_fakes.dart';

void main() {
  test(
    'même fichier partagé entre demandes concurrentes et accès synchrones',
    () async {
      var calls = 0;
      final pending = Completer<Uint8List>();
      final cache = ListingPhotoCache(
        scope: () => 'visitor',
        download: (_) {
          calls++;
          return pending.future;
        },
      );
      final first = cache.read('a');
      final second = cache.read('a');
      expect(calls, 1);
      pending.complete(Uint8List.fromList([1, 2, 3]));
      expect(identical(await first, await second), isTrue);
      final warm = cache.read('a');
      expect(warm, isA<SynchronousFuture<Uint8List>>());
      expect(identical(await warm, await first), isTrue);
      expect(calls, 1);
    },
  );

  test('expiration, reprise explicite, erreurs non conservées', () async {
    var now = DateTime(2026, 11, 2), calls = 0;
    var fail = false;
    final cache = ListingPhotoCache(
      scope: () => null,
      now: () => now,
      download: (_) async {
        calls++;
        if (fail) throw StateError('fixture');
        return Uint8List(3);
      },
    );
    await cache.read('a');
    now = now.add(const Duration(seconds: 46));
    await cache.read('a');
    await cache.read('a', force: true);
    expect(calls, 3);
    fail = true;
    await expectLater(cache.read('b'), throwsStateError);
    fail = false;
    await cache.read('b');
    expect(calls, 5);
  });

  test(
    'changement de session : purge et refus d’un résultat ancien en vol',
    () async {
      var scope = 'a';
      final pending = Completer<Uint8List>();
      final cache = ListingPhotoCache(
        scope: () => scope,
        download: (_) => pending.future,
      );
      final first = cache.read('private');
      scope = 'b';
      final failure = expectLater(first, throwsStateError);
      pending.complete(Uint8List(3));
      await failure;
      expect(cache.entryCount, 0);
      await cache.read('public');
      expect(cache.entryCount, 1);
      scope = 'a';
      final revision = cache.revision;
      expect(revision, greaterThan(0));
      expect(cache.entryCount, 0);
    },
  );

  test('limites mémoire LRU, nombre de fichiers et gros fichier', () async {
    final cache = ListingPhotoCache(
      scope: () => null,
      maxBytes: 6,
      maxEntries: 2,
      download: (path) async => Uint8List(path == 'huge' ? 7 : 3),
    );
    await cache.read('a');
    await cache.read('b');
    await cache.read('a');
    await cache.read('c');
    expect(cache.byteCount, 6);
    expect(cache.entryCount, 2);
    await cache.read('huge');
    expect(cache.byteCount, lessThanOrEqualTo(6));
    expect(cache.entryCount, lessThanOrEqualTo(2));
  });

  test(
    'SDK Storage : un téléchargement partagé pour cartes et détails',
    () async {
      var downloads = 0;
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, contains('/object/'));
          expect(request.url.path, contains('/$listingPhotoBucket/photo.png'));
          downloads++;
          return http.Response.bytes([1, 2, 3], 200);
        }),
      );
      addTearDown(client.dispose);
      final repository = SupabaseListingPhotoRepository(client);
      final first = await repository.photoBytes('photo.png');
      final second = await repository.photoBytes('photo.png');
      expect(identical(first, second), isTrue);
      expect(downloads, 1);
      await repository.photoBytes('photo.png', force: true);
      expect(downloads, 2);
    },
  );
}
