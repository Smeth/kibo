import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../support/supabase_fakes.dart';
import '../support/listing_session.dart';

const testDraft = ListingDraft(
  title: ' Test produit ',
  description: ' Description du produit ',
  price: '12 345,50',
  categoryId: 'cat-a',
  city: ' Brazzaville ',
);

void main() {
  test('publication sans prix transmet NULL, jamais zéro', () async {
    final client = SupabaseClient(
      testConfig.url,
      testConfig.publicKey,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(jsonEncode(listingTestSession()), 200);
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('price'), isTrue);
        expect(body['price'], isNull);
        return http.Response(
          jsonEncode([
            {
              'id': 'listing-without-price',
              'status': 'published',
              'published_at': '2026-11-02T00:00:00Z',
            },
          ]),
          201,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    await client.auth.signInWithPassword(
      email: 'test@example.invalid',
      password: 'fictif',
    );
    expect(
      await SupabaseListingRepository(client).create(
        const ListingDraft(
          title: 'Annonce sans prix',
          description: 'Description suffisamment longue',
          price: '',
          categoryId: 'cat-a',
          city: 'Brazzaville',
        ),
        expectedUserId: 'user-a',
      ),
      'listing-without-price',
    );
  });
  test(
    'une réponse pending ou sans date valide ne confirme jamais une publication',
    () async {
      var row = <String, dynamic>{
        'id': 'listing-a',
        'status': 'pending',
        'published_at': null,
      };
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
          return http.Response(jsonEncode([row]), 201, request: request);
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'test@example.invalid',
        password: 'fictif',
      );
      final repository = SupabaseListingRepository(client);
      for (final invalid in [
        {'id': 'listing-a', 'status': 'pending', 'published_at': null},
        {'id': 'listing-a', 'status': 'published', 'published_at': null},
        {'id': 'listing-a', 'status': 'published', 'published_at': 'invalide'},
      ]) {
        row = invalid;
        await expectLater(
          repository.create(testDraft, expectedUserId: 'user-a'),
          throwsStateError,
        );
      }
    },
  );

  test('refus RLS sans retry ni repli pending', () async {
    var inserts = 0;
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
        inserts++;
        expect(jsonDecode(request.body)['status'], 'published');
        return http.Response(
          '{"code":"42501","message":"detail prive"}',
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
    await expectLater(
      SupabaseListingRepository(
        client,
      ).create(testDraft, expectedUserId: 'user-a'),
      throwsA(isA<ListingPublicationDenied>()),
    );
    expect(inserts, 1);
  });
  test(
    'lectures catalogue/détail : published explicite, pagination et colonnes publiques',
    () async {
      var detail = false;
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.queryParameters['status'], 'eq.published');
          final columns = request.url.queryParameters['select']!;
          expect(columns, isNot(contains('attributes')));
          expect(columns, isNot(contains('rejection_reason')));
          // L'identifiant du profil public relie l'annonce a son vendeur.
          expect(columns, contains('seller_id'));
          expect(columns, isNot(contains('phone_e164')));
          expect(columns, isNot(contains('whatsapp_e164')));
          if (detail) {
            expect(request.url.queryParameters['id'], 'eq.listing-a');
          } else {
            expect(request.url.queryParameters['offset'], '20');
            expect(request.url.queryParameters['limit'], '20');
          }
          return http.Response(
            jsonEncode([
              {
                'id': 'listing-a',
                'title': 'Titre public',
                'description': 'Description publique',
                'price': 1200,
                'currency': 'XAF',
                'city': 'Brazzaville',
                'listing_type': 'product',
                'status': 'published',
                'category': null,
              },
            ]),
            200,
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final repository = SupabaseListingRepository(client);
      expect(
        (await repository.published(offset: 20)).single.priceLabel,
        '1 200 XAF',
      );
      detail = true;
      expect((await repository.detail('listing-a'))?.title, 'Titre public');
      expect(
        () => PublicListing.fromJson({'status': 'archived', 'currency': 'XAF'}),
        throwsStateError,
      );
    },
  );
  test(
    'catégories actives et publication propriétaire avec date UTC confirmée par le serveur',
    () async {
      var inserts = 0;
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
          if (request.url.path == '/rest/v1/categories') {
            expect(request.url.queryParameters['is_active'], 'eq.true');
            return http.Response(
              '[{"id":"cat-a","name":"Catégorie"}]',
              200,
              request: request,
            );
          }
          inserts++;
          expect(request.method, 'POST');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['seller_id'], 'user-a');
          expect(body['price'], '12345.50');
          expect(body['status'], 'published');
          expect(body['published_at'], '2026-10-31T11:34:56.000Z');
          expect(body.keys.toSet(), {
            'seller_id',
            'category_id',
            'title',
            'description',
            'price',
            'listing_type',
            'city',
            'neighborhood',
            'status',
            'published_at',
          });
          return http.Response(
            '[{"id":"listing-a","status":"published","published_at":"2026-10-31T11:34:58Z"}]',
            201,
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      final repository = SupabaseListingRepository(
        client,
        clock: () => DateTime.parse('2026-10-31T12:34:56+01:00'),
      );
      expect(await repository.categories(), hasLength(1));
      await expectLater(
        repository.create(testDraft, expectedUserId: 'user-a'),
        throwsStateError,
      );
      await client.auth.signInWithPassword(
        email: 'test@example.invalid',
        password: 'test-only',
      );
      await expectLater(
        repository.create(testDraft, expectedUserId: 'other'),
        throwsStateError,
      );
      expect(
        await repository.create(testDraft, expectedUserId: 'user-a'),
        'listing-a',
      );
      expect(inserts, 1);
    },
  );
}
