import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/config/supabase_config.dart';

import '../support/supabase_fakes.dart';

String fakeJwt(String role) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode({'role': role})}.fake_signature';
}

void main() {
  test('accepte une configuration HTTPS et publishable fictive', () {
    expect(testConfig.validationError, isNull);
  });

  test('accepte uniquement le rôle anon du format JWT historique', () {
    for (final role in ['anon', 'service_role', 'authenticated']) {
      final config = SupabaseConfig(
        url: testConfig.url,
        publicKey: fakeJwt(role),
      );
      expect(config.validationError == null, role == 'anon');
    }
  });

  test('rejette la configuration absente ou incomplète', () {
    for (final config in [
      const SupabaseConfig(url: '', publicKey: ''),
      SupabaseConfig(url: testConfig.url, publicKey: ''),
      SupabaseConfig(url: '', publicKey: testConfig.publicKey),
    ]) {
      expect(config.validationError, isNotNull);
    }
  });

  test('rejette les URL non HTTPS ou non racine et les identifiants', () {
    for (final url in [
      'not-a-url',
      'http://kibo-test.invalid',
      'https://',
      'https://user:password@kibo-test.invalid',
      'https://kibo-test.invalid/rest/v1',
      'https://kibo-test.invalid?key=hidden',
      'https://kibo-test.invalid#fragment',
      ' https://kibo-test.invalid',
    ]) {
      expect(
        SupabaseConfig(
          url: url,
          publicKey: testConfig.publicKey,
        ).validationError,
        isNotNull,
      );
    }
  });

  test(
    'rejette les clés malformées et privilégiées sans révéler leur valeur',
    () {
      for (final key in [
        'sb_secret_fictitious',
        'service_role',
        'arbitrary',
        'sb_publishable_',
        'sb_publishable_bad key',
        'bad.bad.bad',
        'a.e30.signature',
        ' sb_publishable_test',
      ]) {
        final error = SupabaseConfig(
          url: testConfig.url,
          publicKey: key,
        ).validationError;
        expect(error, isNotNull);
        expect(error, isNot(contains(key)));
      }
    },
  );

  test('lit les paramètres de compilation, vides dans les tests CI', () {
    const config = SupabaseConfig.fromEnvironment();
    expect(config.url, const String.fromEnvironment('SUPABASE_URL'));
    expect(config.publicKey, const String.fromEnvironment('SUPABASE_ANON_KEY'));
  });
}
