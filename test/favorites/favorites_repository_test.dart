import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kibo/features/favorites/favorites_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../support/supabase_fakes.dart';
import '../support/listing_session.dart';

void main() {
  test(
    'refus RLS : lectures et écritures propagent le refus sans contournement',
    () async {
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (request.url.path == '/auth/v1/token') {
            return http.Response(
              jsonEncode(listingTestSession()),
              200,
              request: request,
            );
          }
          return http.Response(
            '{"code":"42501","message":"refus simulé"}',
            403,
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'test@example.invalid',
        password: 'fictif',
      );
      final repository = SupabaseFavoritesRepository(client);
      for (final operation in <Future<Object?> Function()>[
        () => repository.ids('user-a'),
        () => repository.visible('user-a'),
        () async {
          await repository.add('listing-a', 'user-a');
          return null;
        },
        () async {
          await repository.remove('listing-a', 'user-a');
          return null;
        },
      ]) {
        await expectLater(operation(), throwsA(isA<PostgrestException>()));
      }
    },
  );
  test(
    'favoris : ownership partout, jointure published, INSERT/DELETE sans UPDATE',
    () async {
      final methods = <String>[];
      var duplicate = false;
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (request.url.path == '/auth/v1/token') {
            return http.Response(
              jsonEncode(listingTestSession()),
              200,
              request: request,
            );
          }
          methods.add(request.method);
          expect(request.url.path, '/rest/v1/favorites');
          if (request.method == 'POST') {
            expect(jsonDecode(request.body), {
              'user_id': 'user-a',
              'listing_id': 'listing-a',
            });
            return http.Response(
              duplicate ? '{"code":"23505","message":"duplicate fictif"}' : '',
              duplicate ? 409 : 201,
              request: request,
            );
          }
          expect(request.url.queryParameters['user_id'], 'eq.user-a');
          if (request.method == 'DELETE') {
            expect(request.url.queryParameters['listing_id'], 'eq.listing-a');
            return http.Response('', 204, request: request);
          }
          final visible = request.url.queryParameters['select']!.startsWith(
            'listing:',
          );
          if (visible) {
            expect(
              request.url.queryParameters['listing.status'],
              'eq.published',
            );
            expect(request.url.queryParameters['select'], contains('!inner'));
            return http.Response(
              '[{"listing":{"id":"listing-a","title":"Titre public","description":"Description publique","price":100,"currency":"XAF","city":"Brazzaville","listing_type":"product","status":"published"}}]',
              200,
              request: request,
            );
          }
          return http.Response(
            '[{"listing_id":"listing-a"}]',
            200,
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final repository = SupabaseFavoritesRepository(client);
      await expectLater(
        repository.add('listing-a', 'user-a'),
        throwsStateError,
      );
      await client.auth.signInWithPassword(
        email: 'test@example.invalid',
        password: 'fictif',
      );
      await expectLater(repository.ids('other'), throwsStateError);
      expect(await repository.ids('user-a'), {'listing-a'});
      expect((await repository.visible('user-a')).single.id, 'listing-a');
      await repository.add('listing-a', 'user-a');
      duplicate = true;
      await repository.add('listing-a', 'user-a');
      await repository.remove('listing-a', 'user-a');
      expect(methods, ['GET', 'GET', 'POST', 'POST', 'DELETE']);
    },
  );
}
