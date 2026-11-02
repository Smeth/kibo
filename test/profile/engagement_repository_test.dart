import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kibo/features/profile/account_settings_page.dart';
import '../support/supabase_fakes.dart';
import '../support/listing_session.dart';

void main() {
  late SupabaseClient client;
  late SupabaseAccountRequestsRepository repo;
  final requests = <http.Request>[];
  late Future<http.Response> Function(http.Request) respond;
  var owner = 'user-a';
  setUp(() async {
    requests.clear();
    owner = 'user-a';
    respond = (_) async => http.Response('{}', 200);
    client = SupabaseClient(
      testConfig.url,
      testConfig.publicKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(
            jsonEncode(listingTestSession()..['user']['id'] = owner),
            200,
            request: request,
          );
        }
        requests.add(request);
        final response = await respond(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    await client.auth.signInWithPassword(
      email: 'fixture@example.invalid',
      password: 'fixture',
    );
    repo = SupabaseAccountRequestsRepository(client);
  });
  tearDown(() async {
    await client.dispose();
  });
  test(
    'préférences propres sans identifiant arbitraire et lecture sans écriture',
    () async {
      respond = (_) async =>
          http.Response('{"messages":true,"comments":false}', 200);
      expect((await repo.preferences('user-a'))['comments'], false);
      expect(jsonDecode(requests.last.body), {
        'p_messages': null,
        'p_comments': null,
      });
      await repo.preferences('user-a', messages: false, comments: true);
      expect(jsonDecode(requests.last.body), {
        'p_messages': false,
        'p_comments': true,
      });
      expect(
        requests.last.url.path,
        endsWith('/rpc/kibo_notification_preferences'),
      );
      await expectLater(repo.preferences('other'), throwsStateError);
      await expectLater(
        repo.preferences('user-a', messages: true),
        throwsArgumentError,
      );
      expect(requests, hasLength(2));
    },
  );
  test(
    'suivi propre, permission serveur et pagination opérateur explicite',
    () async {
      respond = (request) async => http.Response(
        request.url.path.endsWith('kibo_can_moderate')
            ? 'true'
            : request.url.path.endsWith('kibo_account_queue')
            ? '[]'
            : '{"request":null,"events":[]}',
        200,
      );
      expect((await repo.tracking('user-a'))['request'], isNull);
      expect(await repo.canReview('user-a'), true);
      await repo.queue('user-a', 'needs_info', offset: 20);
      expect(jsonDecode(requests.last.body), {
        'p_status': 'needs_info',
        'p_offset': 20,
      });
    },
  );
  test(
    'décision compare version, aucun completed accepté, refus transmis sans retry',
    () async {
      final row = {'owner_id': 'target', 'version': 7};
      await expectLater(
        repo.review('user-a', row, 'completed', 'Fausse suppression'),
        throwsArgumentError,
      );
      expect(requests, isEmpty);
      respond = (_) async =>
          http.Response('{"code":"40001","message":"Conflit"}', 409);
      await expectLater(
        repo.review('user-a', row, 'needs_info', 'Précisions fictives'),
        throwsA(isA<PostgrestException>()),
      );
      expect(requests, hasLength(1));
      expect(jsonDecode(requests.single.body), {
        'p_owner': 'target',
        'p_version': 7,
        'p_action': 'needs_info',
        'p_note': 'Précisions fictives',
      });
    },
  );
  test('réponse propre validée avant envoi et version conservée', () async {
    respond = (_) async => http.Response('', 204);
    await expectLater(repo.reply('user-a', 9, 'a'), throwsArgumentError);
    await repo.reply('user-a', 9, ' Réponse fictive ');
    expect(jsonDecode(requests.single.body), {
      'p_version': 9,
      'p_note': 'Réponse fictive',
    });
  });
  test('réponse tardive A/B/A refusée même si le compte revient', () async {
    final pending = Completer<http.Response>();
    respond = (_) => pending.future;
    final result = repo.tracking('user-a');
    final checked = expectLater(result, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    owner = 'user-b';
    await client.auth.signInWithPassword(
      email: 'b@example.invalid',
      password: 'fixture',
    );
    owner = 'user-a';
    await client.auth.signInWithPassword(
      email: 'a@example.invalid',
      password: 'fixture',
    );
    pending.complete(http.Response('{"request":null,"events":[]}', 200));
    await checked;
  });
}
