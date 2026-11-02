import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as image;
import 'package:kibo/features/listings/listing_photos.dart';
import 'package:kibo/core/diagnostics/photo_upload_diagnostics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/listing_session.dart';
import '../support/supabase_fakes.dart';

void main() {
  for (final failure in [
    (reservation: true, status: 403, code: '42501'),
    (reservation: true, status: 404, code: 'PGRST205'),
    (reservation: false, status: 401, code: 'authentication'),
    (reservation: false, status: 404, code: 'NOT_FOUND'),
    (reservation: false, status: 502, code: 'storage'),
    (reservation: false, status: 503, code: 'configuration'),
  ]) {
    test(
      'échec $failure puis reprise du même chemin sans écriture annonce',
      () async {
        final fixture = _PhotoServer(
          reservationStatus: failure.reservation ? failure.status : null,
          functionStatus: failure.reservation ? null : failure.status,
          errorCode: failure.code,
        );
        addTearDown(fixture.client.dispose);
        await fixture.signIn();
        final photo = _photo(2);
        final pending = [photo];
        final diagnosticLines = <String>[];
        final repository = SupabaseListingPhotoRepository(
          fixture.client,
          enabled: true,
          diagnostics: PhotoUploadDiagnostics(sink: diagnosticLines.add),
        );
        await expectLater(
          repository.attach(_PhotoServer.listing, pending, _PhotoServer.owner),
          failure.reservation
              ? throwsA(
                  isA<PostgrestException>().having(
                    (e) => e.code,
                    'code',
                    failure.code,
                  ),
                )
              : throwsA(
                  isA<FunctionException>().having(
                    (e) => e.status,
                    'status',
                    failure.status,
                  ),
                ),
        );
        expect(pending.single.digest, photo.digest);
        expect(fixture.uploadPositions, failure.reservation ? isEmpty : [0]);
        expect(fixture.reservations.length, failure.reservation ? 0 : 1);
        final events = diagnosticLines
            .map(
              (line) =>
                  jsonDecode(
                        line.substring(PhotoUploadDiagnostics.marker.length),
                      )
                      as Map<String, dynamic>,
            )
            .toList();
        final failed = events.last;
        expect(failed['event'], 'failure');
        expect(
          failed['stage'],
          failure.reservation ? 'reservation_insert' : 'edge_invoke',
        );
        expect(failed['http_status'], failure.status);
        expect(failed['code'], failure.code);
        final firstAttempt = failed['attempt'];
        await repository.attach(
          _PhotoServer.listing,
          pending,
          _PhotoServer.owner,
        );
        expect(fixture.reservations, {0: fixture.path(0, photo.digest)});
        expect(fixture.uploadPositions, failure.reservation ? [0] : [0, 0]);
        expect(fixture.uploaded, {0});
        final completed =
            jsonDecode(
                  diagnosticLines.last.substring(
                    PhotoUploadDiagnostics.marker.length,
                  ),
                )
                as Map<String, dynamic>;
        expect(completed['event'], 'success');
        expect(completed['attempt'], isNot(firstAttempt));
      },
    );
  }

  test(
    'seconde photo en échec : reprise des deux mêmes réservations immuables',
    () async {
      final fixture = _PhotoServer(functionStatus: 502, failPosition: 1);
      addTearDown(fixture.client.dispose);
      await fixture.signIn();
      final photos = [_photo(2), _photo(3)];
      final repository = SupabaseListingPhotoRepository(
        fixture.client,
        enabled: true,
      );
      await expectLater(
        repository.attach(_PhotoServer.listing, photos, _PhotoServer.owner),
        throwsA(
          isA<FunctionException>().having((e) => e.status, 'status', 502),
        ),
      );
      final reservedBefore = Map<int, String>.of(fixture.reservations);
      expect(fixture.uploaded, {0});
      expect(reservedBefore.length, 2);
      await repository.attach(_PhotoServer.listing, photos, _PhotoServer.owner);
      expect(fixture.reservations, reservedBefore);
      expect(fixture.uploadPositions, [0, 1, 0, 1]);
      expect(fixture.uploaded, {0, 1});
    },
  );
}

ListingPhotoDraft _photo(int width) => ListingPhotoDraft(
  compressListingPhoto(image.encodePng(image.Image(width: width, height: 2))),
);

class _PhotoServer {
  _PhotoServer({
    this.reservationStatus,
    this.functionStatus,
    this.errorCode = 'storage',
    this.failPosition = 0,
  }) {
    client = SupabaseClient(
      testConfig.url,
      testConfig.publicKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: PhotoDiagnosticHttpClient(MockClient(_handle)),
    );
  }
  static const owner = '11111111-1111-4111-8111-111111111111';
  static const listing = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  late final SupabaseClient client;
  final int? reservationStatus, functionStatus;
  final int failPosition;
  final String errorCode;
  bool failed = false;
  final reservations = <int, String>{};
  final uploadPositions = <int>[];
  final uploaded = <int>{};
  String path(int position, String digest) =>
      '$owner/$listing/$position-$digest.jpg';
  Future<void> signIn() async {
    await client.auth.signInWithPassword(
      email: 'fixture@example.invalid',
      password: 'fixture',
    );
  }

  Future<http.Response> _handle(http.Request request) async {
    http.Response reply(Object body, int status) => http.Response(
      jsonEncode(body),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );
    if (request.url.path == '/auth/v1/token') {
      final session = listingTestSession();
      (session['user'] as Map<String, dynamic>)['id'] = owner;
      return reply(session, 200);
    }
    expect(request.method, isNot(anyOf('DELETE', 'PATCH')));
    if (request.url.path == '/rest/v1/kibo_listing_photos') {
      if (request.method == 'GET') {
        expect(request.url.queryParameters['listing_id'], 'eq.$listing');
        final position = int.parse(
          request.url.queryParameters['position']!.substring(3),
        );
        return reply({'path': reservations[position]}, 200);
      }
      expect(request.method, 'POST');
      if (reservationStatus != null && !failed) {
        failed = true;
        return reply({
          'code': errorCode,
          'message': 'fixture',
        }, reservationStatus!);
      }
      final row = jsonDecode(request.body) as Map<String, dynamic>;
      expect(row['listing_id'], listing);
      final position = row['position'] as int;
      if (reservations.containsKey(position)) {
        return reply({'code': '23505', 'message': 'fixture duplicate'}, 409);
      }
      reservations[position] = row['path'] as String;
      return reply({}, 201);
    }
    // Tout autre endpoint, notamment INSERT listings ou upload Storage direct,
    // fait échouer le test : la reprise ne fait que réserver/invoquer l'Edge.
    expect(request.url.path, '/functions/v1/kibo-upload-listing-photo');
    expect(request.method, 'POST');
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(body['listingId'], listing);
    final position = body['position'] as int;
    expect(reservations[position], path(position, body['digest'] as String));
    uploadPositions.add(position);
    if (functionStatus != null && position == failPosition && !failed) {
      failed = true;
      return reply({'error': errorCode}, functionStatus!);
    }
    uploaded.add(position);
    return reply({'ok': true, 'path': reservations[position]}, 200);
  }
}
