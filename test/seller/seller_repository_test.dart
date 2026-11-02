import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kibo/features/seller/seller_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../support/listing_session.dart';
import '../support/supabase_fakes.dart';

Map<String, dynamic> contactJson() => {
  'owner_id': 'user-a',
  'phone_e164': '+9991234567',
  'whatsapp_e164': null,
  'calls_enabled': true,
  'whatsapp_enabled': false,
  'updated_at': '2026-11-01T10:00:00Z',
};
void main() {
  late SupabaseClient client;
  late SupabaseSellerRepository repository;
  late Future<http.Response> Function(http.Request) respond;
  final requests = <http.Request>[];
  setUp(() async {
    requests.clear();
    respond = (_) async => http.Response('[]', 200);
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
    repository = SupabaseSellerRepository(client);
  });
  tearDown(() => client.dispose());
  test(
    'profil public selectionne uniquement nom ville et ID autorises',
    () async {
      respond = (_) async => http.Response(
        jsonEncode([
          {
            'id': 'seller',
            'full_name': 'Vendeur test',
            'city': 'Brazzaville',
            'bio': 'Présentation',
          },
        ]),
        200,
      );
      expect((await repository.profile('seller'))!.name, 'Vendeur test');
      expect(
        requests.single.url.queryParameters['select'],
        'id,full_name,city',
      );
      expect(requests.single.url.queryParameters['id'], 'eq.seller');
    },
  );
  test(
    'preferences propres filtrees, nouveau formulaire desactive par defaut',
    () async {
      final value = await repository.preferences('user-a');
      expect(value.callsEnabled, false);
      expect(value.whatsappEnabled, false);
      expect(requests.single.url.queryParameters['owner_id'], 'eq.user-a');
    },
  );
  test('aucun acces prive/contact sans session ou pour B', () async {
    await expectLater(repository.preferences('user-b'), throwsStateError);
    await expectLater(
      repository.save(const ContactPreferences(), expectedUserId: 'user-b'),
      throwsStateError,
    );
    await client.auth.signOut(scope: SignOutScope.local);
    requests.clear();
    await expectLater(
      repository.contact('listing-a', expectedUserId: 'user-a'),
      throwsStateError,
    );
    expect(requests, isEmpty);
  });
  test('creation ciblee sans champs dates ou roles', () async {
    respond = (r) async => http.Response(
      jsonEncode([
        {...contactJson(), ...jsonDecode(r.body) as Map<String, dynamic>},
      ]),
      200,
    );
    await repository.save(
      const ContactPreferences(phone: '+999 123 4567', callsEnabled: true),
      expectedUserId: 'user-a',
    );
    expect(jsonDecode(requests.single.body), {
      'owner_id': 'user-a',
      'phone_e164': '+9991234567',
      'whatsapp_e164': null,
      'calls_enabled': true,
      'whatsapp_enabled': false,
    });
    expect(requests.single.method, 'POST');
  });
  test('edition optimiste sans modifier ownership ou date', () async {
    respond = (r) async => http.Response(
      jsonEncode([
        {...contactJson(), ...jsonDecode(r.body) as Map<String, dynamic>},
      ]),
      200,
    );
    await repository.save(
      const ContactPreferences(
        phone: '+9991234567',
        callsEnabled: true,
        updatedAt: '2026-11-01T10:00:00Z',
      ),
      expectedUserId: 'user-a',
    );
    expect(requests.single.method, 'PATCH');
    expect(
      requests.single.url.queryParameters['updated_at'],
      'eq.2026-11-01T10:00:00Z',
    );
    expect(jsonDecode(requests.single.body).containsKey('owner_id'), false);
  });
  test(
    'conflit et refus conservent un echec, pas de retry automatique',
    () async {
      await expectLater(
        repository.save(
          const ContactPreferences(updatedAt: 'old'),
          expectedUserId: 'user-a',
        ),
        throwsStateError,
      );
      expect(requests.length, 1);
      requests.clear();
      respond = (_) async => http.Response(
        jsonEncode({'code': '42501', 'message': 'private'}),
        403,
      );
      await expectLater(
        repository.preferences('user-a'),
        throwsA(isA<PostgrestException>()),
      );
      expect(requests.length, 1);
    },
  );
  test('contact recupere seulement par RPC annonce et session', () async {
    respond = (_) async => http.Response(
      jsonEncode([
        {'phone_e164': '+9991234567', 'whatsapp_e164': null},
      ]),
      200,
    );
    final contact = await repository.contact(
      'listing-a',
      expectedUserId: 'user-a',
    );
    expect(contact.phone, '+9991234567');
    expect(contact.whatsapp, isNull);
    expect(
      requests.single.url.path,
      '/rest/v1/rpc/kibo_listing_seller_contact',
    );
    expect(jsonDecode(requests.single.body), {'p_listing_id': 'listing-a'});
  });
  test('numeros malformes jamais convertis en URL executable', () async {
    expect(normalizeContactNumber('+999 (123) 45-67'), '+9991234567');
    expect(callUri('+9991234567').toString(), 'tel:+9991234567');
    expect(whatsappUri('+9991234567').toString(), 'https://wa.me/9991234567');
    expect(() => callUri('javascript:alert(1)'), throwsArgumentError);
    expect(
      () => whatsappUri('+123;https://example.invalid'),
      throwsArgumentError,
    );
    respond = (_) async => http.Response(
      jsonEncode([
        {'phone_e164': 'https://bad.invalid', 'whatsapp_e164': null},
      ]),
      200,
    );
    await expectLater(
      repository.contact('listing-a', expectedUserId: 'user-a'),
      throwsStateError,
    );
  });
}
