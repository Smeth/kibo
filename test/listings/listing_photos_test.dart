import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as image;
import 'package:kibo/features/listings/listing_photos.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../support/listing_session.dart';
import '../support/supabase_fakes.dart';

void main() {
  test('PNG réencodé JPEG, borné, sans EXIF et dédupliqué par contenu', () {
    final bytes = image.encodePng(image.Image(width: 1800, height: 30));
    final result = compressListingPhoto(bytes);
    expect(result.length, lessThanOrEqualTo(maxPhotoBytes));
    final decoded = image.decodeJpg(result)!;
    expect(decoded.width, 1600);
    expect(decoded.exif.isEmpty, isTrue);
    expect(ListingPhotoDraft(result).digest, ListingPhotoDraft(result).digest);
  });
  test('source trop grosse, type non admis et image tronquée refusés', () {
    for (final bytes in [
      Uint8List(0),
      Uint8List(maxSourcePhotoBytes + 1),
      Uint8List.fromList([1, 2, 3]),
    ]) {
      expect(
        () => compressListingPhoto(bytes),
        throwsA(isA<PhotoValidationException>()),
      );
    }
    final gif = image.encodeGif(image.Image(width: 2, height: 2));
    expect(
      () => compressListingPhoto(gif),
      throwsA(isA<PhotoValidationException>()),
    );
  });
  test(
    'reprise réservation/upload : chemin stable, pas de upsert ni de doublon',
    () async {
      final paths = <String>[];
      var reservationExists = false, failOnce = true;
      final photo = ListingPhotoDraft(
        compressListingPhoto(image.encodePng(image.Image(width: 2, height: 2))),
      );
      final expectedPath = 'user-a/listing-a/0-${photo.digest}.jpg';
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          http.Response response(String body, int status) => http.Response(
            body,
            status,
            request: request,
            headers: {'content-type': 'application/json'},
          );
          if (request.url.path == '/auth/v1/token') {
            return response(jsonEncode(listingTestSession()), 200);
          }
          if (request.url.path == '/rest/v1/kibo_listing_photos') {
            if (request.method == 'GET') {
              return response(jsonEncode({'path': expectedPath}), 200);
            }
            expect(jsonDecode(request.body)['path'], expectedPath);
            if (reservationExists) {
              return response('{"code":"23505","message":"fixture"}', 409);
            }
            reservationExists = true;
            return response('', 201);
          }
          expect(request.url.path, '/functions/v1/kibo-upload-listing-photo');
          paths.add(request.url.path);
          expect(jsonDecode(request.body)['digest'], photo.digest);
          if (failOnce) {
            failOnce = false;
            return response('{"error":"fixture network"}', 500);
          }
          return response(jsonEncode({'ok': true, 'path': expectedPath}), 200);
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'fixture@example.invalid',
        password: 'fixture',
      );
      final repository = SupabaseListingPhotoRepository(client, enabled: true);
      await expectLater(
        repository.attach('listing-a', [photo], 'user-a'),
        throwsA(isA<FunctionException>()),
      );
      await repository.attach('listing-a', [photo], 'user-a');
      await repository.attach('listing-a', [photo], 'user-a');
      expect(paths.toSet().length, 1);
      await expectLater(
        repository.attach('listing-a', [photo], 'user-b'),
        throwsStateError,
      );
      await expectLater(
        repository.attach('listing-a', [photo, photo], 'user-a'),
        throwsA(isA<PhotoValidationException>()),
      );
    },
  );
}
