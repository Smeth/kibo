import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kibo/features/safety/safety_repository.dart';
import '../support/listing_session.dart';
import '../support/supabase_fakes.dart';

void main() {
  late SupabaseClient client;
  late SupabaseSafetyRepository repo;
  final requests = <http.Request>[];
  late Future<http.Response> Function(http.Request) respond;
  String sessionOwner = 'user-a';
  setUp(() async {
    requests.clear();
    sessionOwner = 'user-a';
    respond = (_) async => http.Response('[]', 200);
    client = SupabaseClient(
      testConfig.url,
      testConfig.publicKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) async {
        if (r.url.path == '/auth/v1/token') {
          return http.Response(
            jsonEncode(listingTestSession()..['user']['id'] = sessionOwner),
            200,
            request: r,
          );
        }
        requests.add(r);
        final response = await respond(r);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: r,
        );
      }),
    );
    await client.auth.signInWithPassword(
      email: 'a@example.invalid',
      password: 'fictif',
    );
    repo = SupabaseSafetyRepository(client);
  });
  tearDown(() async {
    await repo.dispose();
    await client.dispose();
  });
  test('notifications filtrees par proprietaire non lues et page', () async {
    respond = (_) async => http.Response(
      jsonEncode([
        {
          'id': 'n',
          'title': 'Titre',
          'body': 'Fictif',
          'data': {'listing_id': 'listing'},
          'read_at': null,
        },
      ]),
      200,
    );
    expect(
      (await repo.notifications(
        'user-a',
        offset: 20,
        unreadOnly: true,
      )).single.id,
      'n',
    );
    expect(requests.single.url.queryParameters['user_id'], 'eq.user-a');
    expect(requests.single.url.queryParameters['read_at'], 'is.null');
    expect(requests.single.url.queryParameters['limit'], '20');
    expect(requests.single.url.queryParameters['offset'], '20');
  });
  test('compteur borne ne lit que les identifiants', () async {
    respond = (_) async => http.Response('[{"id":"n"}]', 200);
    expect(await repo.unreadCount('user-a'), 1);
    expect(requests.single.url.queryParameters['select'], 'id');
    expect(requests.single.url.queryParameters['limit'], '100');
  });
  test('autre compte refuse toutes les operations', () async {
    await expectLater(repo.notifications('B'), throwsStateError);
    await expectLater(repo.markRead('B', 'n'), throwsStateError);
    await expectLater(repo.canModerate('B'), throwsStateError);
    expect(requests, isEmpty);
  });
  test('marquage lu seulement RPC bornee ID', () async {
    respond = (_) async => http.Response('', 204);
    await repo.markRead('user-a', 'n');
    expect(
      requests.single.url.path,
      endsWith('/rpc/kibo_mark_notification_read'),
    );
    expect(jsonDecode(requests.single.body), {'p_id': 'n'});
  });
  test('signalement uniquement cible auteur motif precisions', () async {
    respond = (_) async =>
        http.Response('[{"id":"r","reporter_id":"user-a"}]', 201);
    await repo.report(
      'user-a',
      commentId: 'c',
      reason: reportReasons.first,
      details: '  Test fictif  ',
    );
    expect(jsonDecode(requests.single.body), {
      'reporter_id': 'user-a',
      'comment_id': 'c',
      'reason': reportReasons.first,
      'details': 'Test fictif',
    });
  });
  test('cible unique et longueurs verifiees sans reseau', () async {
    await expectLater(
      repo.report(
        'user-a',
        listingId: 'l',
        commentId: 'c',
        reason: reportReasons.first,
        details: '',
      ),
      throwsArgumentError,
    );
    await expectLater(
      repo.report('user-a', listingId: 'l', reason: 'inconnu', details: ''),
      throwsArgumentError,
    );
    await expectLater(
      repo.report(
        'user-a',
        listingId: 'l',
        reason: reportReasons.first,
        details: 'x' * 2001,
      ),
      throwsArgumentError,
    );
    expect(requests, isEmpty);
  });
  test('refus doublon ne retente pas', () async {
    respond = (_) async =>
        http.Response('{"code":"23505","message":"déjà en cours"}', 409);
    await expectLater(
      repo.report(
        'user-a',
        listingId: 'l',
        reason: reportReasons.first,
        details: '',
      ),
      throwsA(isA<PostgrestException>()),
    );
    expect(requests.length, 1);
  });
  test('non administrateur ne lit pas la file globale', () async {
    respond = (_) async => http.Response('false', 200);
    await expectLater(
      repo.reports('user-a', status: 'pending'),
      throwsStateError,
    );
    expect(requests.single.url.path, endsWith('/rpc/kibo_can_moderate'));
  });
  test('file et journal controles par autorisation serveur', () async {
    respond = (r) async => http.Response(
      r.url.path.endsWith('kibo_can_moderate') ? 'true' : '[]',
      200,
    );
    await repo.reports('user-a', status: 'resolved', offset: 20);
    expect(requests.last.url.queryParameters['status'], 'eq.resolved');
    await repo.history('user-a', 'r');
    expect(requests.last.url.queryParameters['report_id'], 'eq.r');
  });
  test('decision par RPC et motif sans UPDATE direct', () async {
    respond = (r) async => http.Response(
      r.url.path.endsWith('kibo_can_moderate') ? 'true' : '',
      r.url.path.endsWith('kibo_can_moderate') ? 200 : 204,
    );
    await repo.review('user-a', 'r', 'hide', ' Motif test ');
    expect(jsonDecode(requests.last.body), {
      'p_id': 'r',
      'p_action': 'hide',
      'p_reason': 'Motif test',
    });
    expect(requests.every((r) => r.method == 'POST'), true);
  });
  test('motif vide et action invalide refuses', () async {
    await expectLater(
      repo.review('user-a', 'r', 'hide', ''),
      throwsArgumentError,
    );
    await expectLater(
      repo.review('user-a', 'r', 'delete', 'Motif'),
      throwsArgumentError,
    );
    expect(requests, isEmpty);
  });
  test('A B A pendant verification bloque la decision tardive', () async {
    final pending = Completer<http.Response>();
    respond = (_) => pending.future;
    final assertion = expectLater(
      repo.review('user-a', 'r', 'hide', 'Motif test'),
      throwsStateError,
    );
    await Future<void>.delayed(Duration.zero);
    sessionOwner = 'user-b';
    await client.auth.signInWithPassword(
      email: 'b@example.invalid',
      password: 'fictif',
    );
    await Future<void>.delayed(Duration.zero);
    sessionOwner = 'user-a';
    await client.auth.signInWithPassword(
      email: 'a@example.invalid',
      password: 'fictif',
    );
    await Future<void>.delayed(Duration.zero);
    pending.complete(http.Response('true', 200));
    await assertion;
    expect(requests.length, 1);
  });
}
