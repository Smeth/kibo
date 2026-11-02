import 'dart:convert';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kibo/features/chat/chat_repository.dart';
import '../support/supabase_fakes.dart';
import '../support/listing_session.dart';

void main() {
  late SupabaseClient client;
  late SupabaseChatRepository repo;
  final requests = <http.Request>[];
  final thread = {
    'id': 'thread',
    'listing_id': 'listing',
    'buyer_id': 'user-a',
    'seller_id': 'seller',
    'listing': {'title': 'Annonce test'},
  };
  final message = {
    'id': 'message',
    'conversation_id': 'thread',
    'sender_id': 'user-a',
    'content': 'Bonjour',
    'message_type': 'text',
    'created_at': '2026-11-01T10:00:00Z',
  };
  late Future<http.Response> Function(http.Request) respond;
  var sessionOwner = 'user-a';
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
      email: 'test@example.invalid',
      password: 'fictif',
    );
    repo = SupabaseChatRepository(client);
  });
  tearDown(() async {
    await repo.dispose();
    await client.dispose();
  });
  test('actions absentes : compatibilité avec le serveur existant', () async {
    respond = (_) async => http.Response(
      jsonEncode({'code': 'PGRST202', 'message': 'function absent'}),
      404,
    );
    expect(await repo.messageActionsAvailable('user-a', 'thread'), isFalse);
    await expectLater(
      repo.changeMessage(
        'user-a',
        'thread',
        ChatMessage.fromJson(message),
        content: 'Correction',
      ),
      throwsStateError,
    );
    expect(requests, hasLength(1));
  });
  test('modifier : RPC contrôlé et confirmation du résultat', () async {
    respond = (r) async => http.Response(
      r.url.path.endsWith('kibo_chat_message_actions')
          ? 'true'
          : jsonEncode({
              ...message,
              'content': 'Correction',
              'edited_at': '2026-11-01T12:00:00Z',
            }),
      200,
    );
    expect(await repo.messageActionsAvailable('user-a', 'thread'), isTrue);
    final changed = await repo.changeMessage(
      'user-a',
      'thread',
      ChatMessage.fromJson(message),
      content: ' Correction ',
    );
    expect(changed.content, 'Correction');
    expect(changed.editedAt, isNotNull);
    final sent = jsonDecode(requests.last.body) as Map;
    expect(sent['p_expected_content'], 'Bonjour');
    expect(sent['p_expected_edited_at'], isNull);
    expect(sent['p_content'], 'Correction');
    expect(sent['p_delete'], false);
    respond = (_) async => http.Response(
      jsonEncode({
        ...message,
        'content': 'Correction',
        'sender_id': 'other',
        'edited_at': '2026-11-01T12:00:00Z',
      }),
      200,
    );
    await expectLater(
      repo.changeMessage(
        'user-a',
        'thread',
        ChatMessage.fromJson(message),
        content: 'Correction',
      ),
      throwsStateError,
    );
  });
  test('suppression : trace confirmée, auteur et session contrôlés', () async {
    respond = (r) async => http.Response(
      r.url.path.endsWith('kibo_chat_message_actions')
          ? 'true'
          : jsonEncode({
              ...message,
              'content': 'Message supprimé',
              'deleted_at': '2026-11-01T12:00:00Z',
            }),
      200,
    );
    await repo.messageActionsAvailable('user-a', 'thread');
    final removed = await repo.changeMessage(
      'user-a',
      'thread',
      ChatMessage.fromJson(message),
      delete: true,
    );
    expect(removed.deletedAt, isNotNull);
    expect(removed.content, 'Message supprimé');
    final count = requests.length;
    await expectLater(
      repo.changeMessage('user-a', 'thread', removed, content: 'Restaurer'),
      throwsStateError,
    );
    await expectLater(
      repo.changeMessage(
        'user-b',
        'thread',
        ChatMessage.fromJson(message),
        delete: true,
      ),
      throwsStateError,
    );
    expect(requests, hasLength(count));
  });
  test('liste limitee aux participants et pagination stable', () async {
    respond = (_) async => http.Response(jsonEncode([thread]), 200);
    expect(
      (await repo.threads('user-a', offset: 20)).single.title,
      'Annonce test',
    );
    expect(requests.single.url.path, endsWith('/rpc/kibo_chat_summaries'));
    expect(jsonDecode(requests.single.body), {'p_offset': 20});
  });
  test(
    'compteur global RPC sans limite de conversations ni contenu téléchargé',
    () async {
      respond = (_) async => http.Response('47', 200);
      expect(await repo.unreadCount('user-a'), 47);
      expect(requests.single.url.path, endsWith('/rpc/kibo_chat_unread_count'));
      await expectLater(repo.unreadCount('user-b'), throwsStateError);
      expect(requests, hasLength(1));
    },
  );
  test('session differente refuse toute requete privee', () async {
    await expectLater(repo.threads('user-b'), throwsStateError);
    await expectLater(
      repo.send('user-b', 'thread', 'Bonjour'),
      throwsStateError,
    );
    expect(requests, isEmpty);
  });
  test('conversation existante reutilisee sans insertion', () async {
    respond = (_) async => http.Response(jsonEncode([thread]), 200);
    expect((await repo.start('user-a', 'listing', 'seller')).id, 'thread');
    expect(requests.single.method, 'GET');
  });
  test('creation bornee au compte et annonce, sans upsert', () async {
    respond = (r) async =>
        http.Response(r.method == 'GET' ? '[]' : jsonEncode([thread]), 200);
    await repo.start('user-a', 'listing', 'seller');
    expect(jsonDecode(requests.last.body), {
      'listing_id': 'listing',
      'buyer_id': 'user-a',
      'seller_id': 'seller',
    });
    expect(
      requests.last.headers['prefer'],
      isNot(contains('merge-duplicates')),
    );
  });
  test('conflit unique relit sans deuxieme creation', () async {
    var reads = 0;
    respond = (r) async => r.method == 'POST'
        ? http.Response('{"code":"23505","message":"collision"}', 409)
        : http.Response(reads++ == 0 ? '[]' : jsonEncode([thread]), 200);
    expect((await repo.start('user-a', 'listing', 'seller')).id, 'thread');
    expect(requests.where((r) => r.method == 'POST').length, 1);
  });
  test('soi-meme et contenu invalide refuses sans reseau', () async {
    await expectLater(
      repo.start('user-a', 'listing', 'user-a'),
      throwsStateError,
    );
    await expectLater(
      repo.send('user-a', 'thread', '   '),
      throwsArgumentError,
    );
    await expectLater(
      repo.send('user-a', 'thread', 'a' * 5001),
      throwsArgumentError,
    );
    expect(requests, isEmpty);
    expect(validateMessage('😀' * 5000), isNull);
  });
  test('lecture refuse un non participant avant messages', () async {
    await expectLater(repo.messages('user-a', 'thread'), throwsStateError);
    expect(requests.length, 1);
    expect(requests.single.url.path, endsWith('/conversations'));
  });
  test('lecture messages texte seulement et envoi champs limites', () async {
    respond = (r) async => http.Response(
      jsonEncode([r.url.path.endsWith('/conversations') ? thread : message]),
      200,
    );
    expect((await repo.messages('user-a', 'thread')).single.content, 'Bonjour');
    expect(requests.last.url.queryParameters['conversation_id'], 'eq.thread');
    expect(requests.last.url.queryParameters['message_type'], 'eq.text');
    expect(requests.last.url.queryParameters['limit'], '30');
    requests.clear();
    await repo.send('user-a', 'thread', ' Bonjour ');
    expect(jsonDecode(requests.last.body), {
      'conversation_id': 'thread',
      'sender_id': 'user-a',
      'content': 'Bonjour',
      'message_type': 'text',
    });
  });
  test('envoi incertain ne retente pas automatiquement', () async {
    respond = (r) async => r.method == 'POST'
        ? http.Response('{"message":"indisponible","code":"XX000"}', 500)
        : http.Response(jsonEncode([thread]), 200);
    await expectLater(
      repo.send('user-a', 'thread', 'Bonjour'),
      throwsA(isA<PostgrestException>()),
    );
    expect(requests.where((r) => r.method == 'POST').length, 1);
  });
  test('changement A B A pendant lecture interdit creation tardive', () async {
    final pending = Completer<http.Response>();
    respond = (_) => pending.future;
    final request = repo.start('user-a', 'listing', 'seller');
    final assertion = expectLater(request, throwsStateError);
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
    pending.complete(http.Response('[]', 200));
    await assertion;
    expect(requests.where((r) => r.method == 'POST'), isEmpty);
  });
  test('lecture et blocage utilisent seulement les RPC autorisees', () async {
    respond = (r) async => http.Response(
      r.url.path.endsWith('thread_state')
          ? '{"blocked":true,"blocked_by_me":true}'
          : '',
      r.url.path.endsWith('thread_state') ? 200 : 204,
    );
    expect((await repo.threadState('user-a', 'thread'))['blocked'], true);
    await repo.markRead('user-a', 'thread', DateTime.utc(2026, 11, 1));
    expect(jsonDecode(requests.last.body), {
      'p_thread': 'thread',
      'p_through': '2026-11-01T00:00:00.000Z',
    });
    await repo.setBlocked('user-a', 'thread', true);
    expect(jsonDecode(requests.last.body), {
      'p_thread': 'thread',
      'p_blocked': true,
    });
  });
  test(
    'retry du meme message confirme ID et contenu sans double insertion',
    () async {
      const id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
      respond = (r) async {
        if (r.url.path.endsWith('/conversations')) {
          return http.Response(jsonEncode([thread]), 200);
        }
        if (r.method == 'POST') {
          return http.Response('{"code":"23505","message":"duplicate"}', 409);
        }
        return http.Response(
          jsonEncode([
            {...message, 'id': id},
          ]),
          200,
        );
      };
      await repo.sendOnce('user-a', 'thread', 'Bonjour', id);
      expect(requests.where((r) => r.method == 'POST').length, 1);
      expect(requests.last.url.queryParameters['id'], 'eq.$id');
      await expectLater(
        repo.sendOnce('user-a', 'thread', 'Texte différent', id),
        throwsStateError,
      );
    },
  );
}
