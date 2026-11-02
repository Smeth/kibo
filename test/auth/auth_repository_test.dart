import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/core/config/auth_callback.dart';
import 'package:kibo/core/supabase/secure_session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/supabase_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  const userId = '11111111-1111-4111-8111-111111111111';
  final user = {
    'id': userId,
    'email': 'test@example.invalid',
    'aud': 'authenticated',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2026-01-01T00:00:00Z',
  };
  Map<String, dynamic> session() {
    final expiry = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
    String encode(Map<String, dynamic> value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    return {
      'access_token':
          '${encode({'alg': 'HS256'})}.${encode({'exp': expiry, 'sub': userId})}.signature-fictive',
      'refresh_token': 'refresh-fictif',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': user,
    };
  }

  test(
    'signup sans session : aucune métadonnée inventée ni écriture profiles',
    () async {
      final requests = <http.Request>[];
      final transport = MockClient((request) async {
        requests.add(request);
        expect(request.url.path, '/auth/v1/signup');
        return http.Response(jsonEncode(user), 200, request: request);
      });
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        httpClient: transport,
        authOptions: AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.pkce,
          pkceAsyncStorage: SecurePkceStorage(projectHost: 'kibo-test.invalid'),
        ),
      );
      addTearDown(client.dispose);
      final repository = SupabaseAuthRepository(client);
      expect(
        await repository.signUp('test@example.invalid', 'password-test'),
        isTrue,
      );
      expect(await repository.synchronizeProfile(), isNull);
      expect(requests, hasLength(1));
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['data'] ?? <String, dynamic>{}, isEmpty);
      expect(
        requests.single.url.queryParameters['redirect_to'],
        KiboAuthCallback.redirectUrl,
      );
      expect(body['code_challenge_method'], 's256');
      expect(body['code_challenge'], isNotEmpty);
    },
  );

  test('callback PKCE après recréation du client : session réactive', () async {
    var exchanges = 0;
    final transport = MockClient((request) async {
      if (request.url.path == '/auth/v1/signup') {
        return http.Response(jsonEncode(user), 200, request: request);
      }
      expect(request.url.path, '/auth/v1/token');
      expect(request.url.queryParameters['grant_type'], 'pkce');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['auth_code'], 'code-fictif');
      expect(body['code_verifier'], isNotEmpty);
      exchanges++;
      return http.Response(jsonEncode(session()), 200, request: request);
    });
    SupabaseClient createClient() => SupabaseClient(
      testConfig.url,
      testConfig.publicKey,
      httpClient: transport,
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.pkce,
        pkceAsyncStorage: SecurePkceStorage(
          projectHost: 'callback-test.invalid',
        ),
      ),
    );
    final first = createClient();
    await SupabaseAuthRepository(
      first,
    ).signUp('test@example.invalid', 'password-test');
    await first.dispose();
    final restarted = createClient();
    addTearDown(restarted.dispose);
    final repository = SupabaseAuthRepository(restarted);
    final signedIn = repository.identities.firstWhere((user) => user != null);
    final callback = Uri.parse(
      '${KiboAuthCallback.redirectUrl}?code=code-fictif',
    );
    expect(KiboAuthCallback.accepts(callback), isTrue);
    await restarted.auth.getSessionFromUrl(callback);
    expect((await signedIn)?.id, userId);
    expect(repository.identity?.id, userId);
    expect(exchanges, 1);
    // Le SDK consomme le vérificateur : un rejeu ne doit pas ouvrir une session.
    await expectLater(
      restarted.auth.getSessionFromUrl(callback),
      throwsA(isA<AuthException>()),
    );
    expect(exchanges, 1);
  });

  test(
    'callback sans vérificateur local : aucune session ni requête réseau',
    () async {
      var requests = 0;
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        httpClient: MockClient((request) async {
          requests++;
          throw StateError('Aucun réseau attendu');
        }),
        authOptions: AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.pkce,
          pkceAsyncStorage: SecurePkceStorage(
            projectHost: 'other-device.invalid',
          ),
        ),
      );
      addTearDown(client.dispose);
      await expectLater(
        client.auth.getSessionFromUrl(
          Uri.parse('${KiboAuthCallback.redirectUrl}?code=code-fictif'),
        ),
        throwsA(isA<AuthException>()),
      );
      expect(client.auth.currentSession, isNull);
      expect(requests, 0);
    },
  );

  test(
    'connexion, lecture filtrée du profil et déconnexion sans INSERT ni UPSERT',
    () async {
      final methods = <String>[];
      var denied = false;
      var cleared = false;
      final transport = MockClient((request) async {
        methods.add('${request.method} ${request.url.path}');
        if (request.url.path == '/auth/v1/token') {
          return http.Response(jsonEncode(session()), 200, request: request);
        }
        if (request.url.path == '/auth/v1/logout') {
          return http.Response('', 204, request: request);
        }
        expect(request.url.path, '/rest/v1/profiles');
        expect(request.method, 'GET');
        expect(request.url.queryParameters['id'], 'eq.$userId');
        expect(request.url.queryParameters['select'], 'id,full_name,city');
        if (denied) {
          return http.Response(
            jsonEncode({'message': 'refus privé', 'code': '42501'}),
            403,
            request: request,
          );
        }
        return http.Response(
          jsonEncode([
            {'id': userId, 'full_name': 'Profil test', 'city': 'Brazzaville'},
          ]),
          200,
          request: request,
        );
      });
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        httpClient: transport,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);
      final repository = SupabaseAuthRepository(
        client,
        clearPersistedSession: () async {
          cleared = true;
        },
      );
      await repository.signIn('test@example.invalid', 'password-test');
      expect(repository.identity?.id, userId);
      expect((await repository.synchronizeProfile())?.city, 'Brazzaville');
      denied = true;
      await expectLater(
        repository.synchronizeProfile(),
        throwsA(isA<PostgrestException>()),
      );
      await repository.signOut();
      expect(cleared, isTrue);
      expect(repository.identity, isNull);
      expect(
        methods
            .where((method) => method.endsWith('/profiles'))
            .every((method) => method.startsWith('GET ')),
        isTrue,
      );
    },
  );

  test(
    'profil : PATCH filtré, deux champs seulement et nom vide nullable',
    () async {
      final patches = <Map<String, dynamic>>[];
      final transport = MockClient((request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(jsonEncode(session()), 200, request: request);
        }
        expect(request.method, 'PATCH');
        expect(request.url.path, '/rest/v1/profiles');
        expect(request.url.queryParameters['id'], 'eq.$userId');
        expect(request.url.queryParameters['select'], 'id,full_name,city');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.keys.toSet(), {'full_name', 'city'});
        patches.add(body);
        return http.Response(
          jsonEncode([
            {'id': userId, ...body},
          ]),
          200,
          request: request,
        );
      });
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        httpClient: transport,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);
      final repository = SupabaseAuthRepository(client);
      await repository.signIn('test@example.invalid', 'password-test');
      final updated = await repository.updateProfile(
        expectedUserId: userId,
        fullName: ' Nom affiché ',
        city: ' Dolisie ',
      );
      expect(updated.city, 'Dolisie');
      expect(updated.fullName, 'Nom affiché');
      final cleared = await repository.updateProfile(
        expectedUserId: userId,
        fullName: '  ',
        city: 'Brazzaville',
      );
      expect(cleared.fullName, isNull);
      expect(patches, [
        {'full_name': 'Nom affiché', 'city': 'Dolisie'},
        {'full_name': null, 'city': 'Brazzaville'},
      ]);
    },
  );

  test(
    'profil : sans session, identité périmée, RLS et zéro ligne ne réussissent pas',
    () async {
      var patches = 0;
      var denied = true;
      final transport = MockClient((request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(jsonEncode(session()), 200, request: request);
        }
        expect(request.method, 'PATCH');
        patches++;
        return http.Response(
          denied
              ? jsonEncode({'message': 'refus privé', 'code': '42501'})
              : '[]',
          denied ? 403 : 200,
          request: request,
        );
      });
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        httpClient: transport,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);
      final repository = SupabaseAuthRepository(client);
      Future<KiboProfile> save({String id = userId, String city = 'Dolisie'}) =>
          repository.updateProfile(
            expectedUserId: id,
            fullName: 'Nom',
            city: city,
          );
      await expectLater(save(), throwsStateError);
      await repository.signIn('test@example.invalid', 'password-test');
      await expectLater(save(id: 'other-user'), throwsStateError);
      await expectLater(save(city: '  '), throwsArgumentError);
      expect(patches, 0);
      await expectLater(save(), throwsA(isA<PostgrestException>()));
      denied = false;
      await expectLater(save(), throwsStateError);
      expect(patches, 2);
    },
  );
}
