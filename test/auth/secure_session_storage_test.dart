import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/supabase/secure_session_storage.dart';
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/supabase_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'session restaurée par une nouvelle instance, isolée par projet puis effacée',
    () async {
      final first = SecureSessionStorage(projectHost: 'project-a.invalid');
      expect(await first.hasAccessToken(), isFalse);
      await first.persistSession('session-fictive');
      final restarted = SecureSessionStorage(projectHost: 'project-a.invalid');
      expect(await restarted.hasAccessToken(), isTrue);
      expect(await restarted.accessToken(), 'session-fictive');
      expect(
        await SecureSessionStorage(
          projectHost: 'project-b.invalid',
        ).accessToken(),
        isNull,
      );
      await restarted.removePersistedSession();
      expect(await first.accessToken(), isNull);
    },
  );

  test('la suppression attend une écriture en cours', () async {
    final storage = SecureSessionStorage(projectHost: 'project-a.invalid');
    final write = storage.persistSession('session-fictive');
    final remove = storage.removePersistedSession();
    await Future.wait([write, remove]);
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('le SDK restaure la session persistée après réinitialisation', () async {
    final expiry = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
    String encode(Map<String, dynamic> data) =>
        base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
    final session = jsonEncode({
      'access_token':
          '${encode({'alg': 'HS256'})}.${encode({'exp': expiry, 'sub': 'test-user'})}.signature-fictive',
      'refresh_token': 'refresh-fictif',
      'expires_in': 3600,
      'token_type': 'bearer',
      'user': {
        'id': 'test-user',
        'email': 'test@example.invalid',
        'aud': 'authenticated',
        'created_at': '2026-01-01T00:00:00Z',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
      },
    });
    final storage = SecureSessionStorage(projectHost: 'kibo-test.invalid');
    await storage.persistSession(session);
    for (var restart = 0; restart < 2; restart++) {
      final instance = await Supabase.initialize(
        url: testConfig.url,
        publishableKey: testConfig.publicKey,
        debug: false,
        httpClient: MockClient(
          (_) async => throw StateError('Aucun réseau attendu'),
        ),
        authOptions: FlutterAuthClientOptions(
          autoRefreshToken: false,
          detectSessionInUri: false,
          pkceAsyncStorage: SecurePkceStorage(projectHost: 'kibo-test.invalid'),
          localStorage: SecureSessionStorage(projectHost: 'kibo-test.invalid'),
        ),
      );
      try {
        expect(instance.client.auth.currentSession?.user.id, 'test-user');
      } finally {
        await instance.dispose();
      }
    }
    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
  });
}
