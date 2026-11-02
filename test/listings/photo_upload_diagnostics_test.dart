import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kibo/core/diagnostics/photo_upload_diagnostics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> event(String line) =>
    jsonDecode(line.substring(PhotoUploadDiagnostics.marker.length))
        as Map<String, dynamic>;

void main() {
  test(
    'transport exact, corrélation locale et serveur, aucune donnée privée',
    () async {
      final lines = <String>[];
      const requestId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
      final client = PhotoDiagnosticHttpClient(
        MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer PRIVATE_TOKEN');
          expect(request.headers.containsKey('x-kibo-attempt'), isFalse);
          expect(request.body, 'PRIVATE_IMAGE');
          return http.Response(
            'PRIVATE_BODY',
            403,
            headers: {
              'sb-request-id': requestId,
              'set-cookie': 'PRIVATE_COOKIE',
            },
          );
        }),
      );
      addTearDown(client.close);
      final diagnostics = PhotoUploadDiagnostics(sink: lines.add);
      await expectLater(
        diagnostics.trace((attempt) async {
          attempt.stage('reservation_insert');
          final response = await client.post(
            Uri.parse(
              'https://fixture.invalid/rest/v1/kibo_listing_photos?private=PRIVATE_QUERY',
            ),
            headers: {'authorization': 'Bearer PRIVATE_TOKEN'},
            body: 'PRIVATE_IMAGE',
          );
          expect(response.body, 'PRIVATE_BODY');
          throw const PostgrestException(
            message: 'PRIVATE_MESSAGE',
            code: '42501',
            details: 'PRIVATE_DETAILS',
            hint: 'PRIVATE_HINT',
          );
        }),
        throwsA(isA<PostgrestException>()),
      );
      final failed = event(lines.last);
      expect(failed['http_status'], 403);
      expect(failed['code'], '42501');
      expect(failed['server_request_id'], requestId);
      expect(failed['attempt'], matches(RegExp(r'^[a-f0-9]{32}$')));
      expect(
        lines.every((line) => event(line)['attempt'] == failed['attempt']),
        isTrue,
      );
      expect(lines.join(), isNot(contains('PRIVATE')));
      expect(lines.join(), isNot(contains('fixture.invalid')));
      // Aucun log hors contexte photo, même en cas d'appel à la même route.
      final count = lines.length;
      await client.post(
        Uri.parse('https://fixture.invalid/rest/v1/kibo_listing_photos'),
        headers: {'authorization': 'Bearer PRIVATE_TOKEN'},
        body: 'PRIVATE_IMAGE',
      );
      expect(lines.length, count);
    },
  );

  test(
    'sans transport instrumenté : statut inconnu, jamais déduit du SQLSTATE',
    () async {
      final lines = <String>[];
      await expectLater(
        PhotoUploadDiagnostics(sink: lines.add).trace((attempt) async {
          attempt.stage('reservation_lookup');
          throw const PostgrestException(message: 'PRIVATE', code: '42501');
        }),
        throwsA(isA<PostgrestException>()),
      );
      expect(event(lines.last)['http_status'], isNull);
      expect(event(lines.last)['code'], '42501');
    },
  );

  test(
    'erreurs brutes et codes arbitraires exclus, exception originale préservée',
    () async {
      for (final error in [
        const FunctionException(
          status: 502,
          details: {'error': 'PRIVATE_SECRET', 'message': 'PRIVATE_IMAGE'},
        ),
        const PostgrestException(message: 'PRIVATE', code: 'PRIVATE_SECRET'),
        StateError('PRIVATE_PATH'),
        const FunctionsFetchException(details: 'PRIVATE_URL'),
      ]) {
        final lines = <String>[];
        await expectLater(
          PhotoUploadDiagnostics(sink: lines.add).trace((attempt) async {
            attempt.stage('edge_invoke');
            throw error;
          }),
          throwsA(same(error)),
        );
        expect(lines.join(), isNot(contains('PRIVATE')));
        expect(event(lines.last)['code'], isNull);
        if (error is FunctionsFetchException) {
          expect(event(lines.last)['http_status'], isNull);
        }
      }
    },
  );

  test('statut de confirmation conservé, request-id malformé exclu', () async {
    final lines = <String>[];
    final client = PhotoDiagnosticHttpClient(
      MockClient(
        (_) async => http.Response(
          '{}',
          200,
          headers: {'sb-request-id': 'PRIVATE_SECRET'},
        ),
      ),
    );
    addTearDown(client.close);
    await expectLater(
      PhotoUploadDiagnostics(sink: lines.add).trace((attempt) async {
        attempt.stage('edge_invoke');
        await client.post(
          Uri.parse(
            'https://fixture.invalid/functions/v1/kibo-upload-listing-photo',
          ),
        );
        attempt.stage('response_confirmation', keepResponse: true);
        throw StateError('PRIVATE');
      }),
      throwsStateError,
    );
    expect(event(lines.last)['http_status'], 200);
    expect(event(lines.last)['server_request_id'], isNull);
    expect(lines.join(), isNot(contains('PRIVATE')));
  });

  test(
    'diagnostic désactivé ou sink cassé : la reprise reste inchangée',
    () async {
      final lines = <String>[];
      expect(
        await PhotoUploadDiagnostics(
          enabled: false,
          sink: lines.add,
        ).trace((_) async => 42),
        42,
      );
      expect(lines, isEmpty);
      expect(
        await PhotoUploadDiagnostics(
          sink: (_) => throw StateError('fixture'),
        ).trace((_) async => 42),
        42,
      );
    },
  );
}
