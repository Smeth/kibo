import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kibo/features/comments/comments_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../support/listing_session.dart';
import '../support/supabase_fakes.dart';

Map<String, dynamic> commentJson() => {
  'id': 'comment-a',
  'listing_id': 'listing-a',
  'user_id': 'user-a',
  'parent_id': null,
  'content': 'Message de test',
  'status': 'published',
  'deleted_at': null,
  'created_at': '2026-11-01T10:00:00Z',
};
void main() {
  late SupabaseClient client;
  late SupabaseCommentsRepository repository;
  final requests = <http.Request>[];
  late Future<http.Response> Function(http.Request) respond;
  setUp(() async {
    requests.clear();
    respond = (r) async => http.Response(
      jsonEncode([
        {
          ...commentJson(),
          if (r.method == 'POST') ...jsonDecode(r.body) as Map<String, dynamic>,
        },
      ]),
      200,
    );
    client = SupabaseClient(
      testConfig.url,
      testConfig.publicKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) async {
        if (r.url.path == '/auth/v1/token') {
          return http.Response(jsonEncode(listingTestSession()), 200);
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
    repository = SupabaseCommentsRepository(client);
  });
  tearDown(() => client.dispose());
  test(
    'lecture publique filtre annonce/statut/suppression et pagination serveur',
    () async {
      final rows = await repository.read('listing-a', offset: 20);
      expect(rows.single.content, 'Message de test');
      final q = requests.single.url.queryParameters;
      expect(q['listing_id'], 'eq.listing-a');
      expect(q['listing.status'], 'eq.published');
      expect(q['status'], 'eq.published');
      expect(q['deleted_at'], 'is.null');
      expect(q['parent_id'], 'is.null');
      expect(q['offset'], '20');
      expect(q['limit'], '20');
      expect(q['order'], 'created_at.desc.nullslast,id.asc.nullslast');
    },
  );
  test('visiteur lit mais ne publie pas', () async {
    await client.auth.signOut(scope: SignOutScope.local);
    requests.clear();
    await repository.read('listing-a');
    await expectLater(
      repository.create('listing-a', 'Message', expectedUserId: 'user-a'),
      throwsStateError,
    );
    expect(requests.length, 1);
    expect(requests.single.method, 'GET');
  });
  test(
    'publication limitee aux champs publics et vendeur derive de session',
    () async {
      await repository.create(
        'listing-a',
        '  Message de test  ',
        expectedUserId: 'user-a',
      );
      expect(jsonDecode(requests.single.body), {
        'listing_id': 'listing-a',
        'user_id': 'user-a',
        'content': 'Message de test',
      });
    },
  );
  test(
    'reponse : parent public racine de la meme annonce relu avant INSERT',
    () async {
      await repository.create(
        'listing-a',
        'Reponse',
        expectedUserId: 'user-a',
        parentId: 'comment-a',
      );
      expect(requests.length, 2);
      expect(requests.first.url.queryParameters['parent_id'], 'is.null');
      expect(
        requests.first.url.queryParameters['listing.status'],
        'eq.published',
      );
      expect(jsonDecode(requests.last.body)['parent_id'], 'comment-a');
    },
  );
  test('parent absent refuse sans INSERT', () async {
    respond = (_) async => http.Response('[]', 200);
    await expectLater(
      repository.create(
        'listing-a',
        'Reponse',
        expectedUserId: 'user-a',
        parentId: 'hidden',
      ),
      throwsStateError,
    );
    expect(requests.length, 1);
    expect(requests.single.method, 'GET');
  });
  test('validation unicode/texte et compte B : aucune requete', () async {
    expect(validateComment('😀' * 2000), isNull);
    expect(validateComment('😀' * 2001), isNotNull);
    await expectLater(
      repository.create('listing-a', '   ', expectedUserId: 'user-a'),
      throwsArgumentError,
    );
    await expectLater(
      repository.create('listing-a', 'Test', expectedUserId: 'user-b'),
      throwsStateError,
    );
    expect(requests, isEmpty);
  });
  test(
    'retour pending/supprime ou mauvais dossier ne devient pas un succes',
    () async {
      respond = (_) async => http.Response(
        jsonEncode([
          {...commentJson(), 'status': 'pending'},
        ]),
        200,
      );
      await expectLater(
        repository.create(
          'listing-a',
          'Message de test',
          expectedUserId: 'user-a',
        ),
        throwsStateError,
      );
      respond = (_) async => http.Response(
        jsonEncode([
          {...commentJson(), 'listing_id': 'other'},
        ]),
        200,
      );
      await expectLater(repository.read('listing-a'), throwsStateError);
    },
  );
  test('erreur serveur propagee sans retry ni autre insertion', () async {
    respond = (_) async =>
        http.Response(jsonEncode({'code': '42501', 'message': 'private'}), 403);
    await expectLater(
      repository.create('listing-a', 'Message', expectedUserId: 'user-a'),
      throwsA(isA<PostgrestException>()),
    );
    expect(requests.length, 1);
  });
}
