import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kibo/features/favorites/favorites_repository.dart';
import 'package:kibo/features/listings/listing_card.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_photos.dart';
import 'package:kibo/features/listings/listing_query.dart';
import 'package:kibo/features/listings/listing_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../support/listing_session.dart';
import '../support/supabase_fakes.dart';

const row = {
  'id': 'existing-listing',
  'title': 'Annonce existante',
  'description': 'Description fictive',
  'price': '1000',
  'currency': 'XAF',
  'city': 'Brazzaville',
  'listing_type': 'product',
  'status': 'published',
  'published_at': '2026-11-01T01:00:00Z',
  'category': {'name': 'Catégorie'},
};

http.Response reply(http.Request request, Object data, int status) =>
    http.Response(
      jsonEncode(data),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );

void main() {
  for (final operation in ['catalogue', 'detail', 'favoris']) {
    test('$operation lisible malgré la seule relation photos absente', () async {
      final reads = <http.Request>[];
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (request.url.path == '/auth/v1/token') {
            return reply(request, listingTestSession(), 200);
          }
          reads.add(request);
          expect(request.method, 'GET');
          if (operation == 'favoris') {
            expect(request.url.queryParameters['user_id'], 'eq.user-a');
            expect(
              request.url.queryParameters['listing.status'],
              'eq.published',
            );
          } else {
            expect(request.url.queryParameters['status'], 'eq.published');
          }
          if (request.url.queryParameters['select']!.contains(
            'kibo_listing_photos',
          )) {
            return reply(request, {
              'code': 'PGRST200',
              'message':
                  "Could not find a relationship between 'listings' and 'kibo_listing_photos' in the schema cache",
            }, 400);
          }
          return reply(
            request,
            operation == 'favoris'
                ? [
                    {'listing': row},
                  ]
                : [row],
            200,
          );
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'fixture@example.invalid',
        password: 'fixture',
      );
      final repository = SupabaseListingRepository(client);
      final result = switch (operation) {
        'detail' => (await repository.detail('existing-listing'))!,
        'favoris' => (await SupabaseFavoritesRepository(
          client,
        ).visible('user-a')).single,
        _ => (await repository.published()).single,
      };
      expect(result.id, 'existing-listing');
      expect(result.photosUnavailable, listingPhotosEnabled);
      expect(result.photoPaths, isEmpty);
      expect(reads.length, listingPhotosEnabled ? 2 : 1);
    });
  }

  for (final error in [
    const PostgrestException(
      message: 'permission denied for function is_admin',
      code: '42501',
    ),
    const PostgrestException(
      message: 'categories relationship missing',
      code: 'PGRST200',
    ),
  ]) {
    test(
      'pas de contournement du refus ou d’une autre relation : ${error.code}',
      () async {
        var calls = 0;
        await expectLater(
          readPublicProjection((_) async {
            calls++;
            throw error;
          }),
          throwsA(same(error)),
        );
        expect(calls, 1);
      },
    );
  }

  test(
    'vecteur absent : recherche serveur sur titre/description, critères conservés et texte cité',
    () async {
      var reads = 0;
      const term = 'moto,prix) " (status.eq.draft';
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        httpClient: MockClient((request) async {
          reads++;
          final params = request.url.queryParameters;
          expect(request.method, 'GET');
          expect(params['status'], 'eq.published');
          expect(params['category_id'], 'eq.cat-a');
          expect(params['city'], 'eq.Brazzaville');
          expect(params['offset'], '20');
          expect(params['limit'], '20');
          expect(
            params['order'],
            'price.asc.nullslast,published_at.desc.nullslast,id.asc.nullslast',
          );
          expect(request.url.queryParametersAll['price'], [
            'gte.1000',
            'lte.2000',
          ]);
          if (params.containsKey('kibo_search_vector')) {
            return reply(request, {
              'code': '42703',
              'message': 'column listings.kibo_search_vector does not exist',
            }, 400);
          }
          expect(
            params['or'],
            '(title.fts(french).${jsonEncode(listingPrefixQuery(term))},description.fts(french).${jsonEncode(listingPrefixQuery(term))})',
          );
          return reply(request, [row], 200);
        }),
      );
      addTearDown(client.dispose);
      final result = await SupabaseListingRepository(client).published(
        offset: 20,
        query: const ListingQuery(
          text: term,
          categoryId: 'cat-a',
          city: 'Brazzaville',
          minPrice: '1000',
          maxPrice: '2000',
          sort: ListingSort.priceAscending,
        ),
      );
      expect(reads, 2);
      expect(result.single.id, 'existing-listing');
    },
  );

  test('erreur sur une autre colonne : aucune recherche élargie', () async {
    var reads = 0;
    final client = SupabaseClient(
      testConfig.url,
      testConfig.publicKey,
      httpClient: MockClient((request) async {
        reads++;
        return reply(request, {
          'code': '42703',
          'message': 'column listings.price does not exist',
        }, 400);
      }),
    );
    addTearDown(client.dispose);
    await expectLater(
      SupabaseListingRepository(
        client,
      ).published(query: const ListingQuery(text: 'moto')),
      throwsA(isA<PostgrestException>()),
    );
    expect(reads, 1);
  });

  for (final stage in ['table_absente', 'fonction_absente', 'pret']) {
    test(
      'préflight $stage : GET limit 0 et OPTIONS seulement, aucune écriture',
      () async {
        final methods = <String>[];
        final client = SupabaseClient(
          testConfig.url,
          testConfig.publicKey,
          httpClient: MockClient((request) async {
            methods.add(request.method);
            if (request.url.path == '/rest/v1/kibo_listing_photos') {
              expect(request.method, 'GET');
              expect(request.url.queryParameters['limit'], '0');
              return stage == 'table_absente'
                  ? reply(request, {
                      'code': 'PGRST205',
                      'message': 'missing table',
                    }, 404)
                  : reply(request, [], 200);
            }
            expect(request.method, 'OPTIONS');
            expect(request.url.path, '/functions/v1/kibo-upload-listing-photo');
            return reply(request, {}, stage == 'fonction_absente' ? 404 : 200);
          }),
        );
        addTearDown(client.dispose);
        final repository = SupabaseListingPhotoRepository(
          client,
          enabled: true,
        );
        if (stage == 'pret') {
          await repository.checkPublicationAvailability();
        } else {
          await expectLater(
            repository.checkPublicationAvailability(),
            throwsA(isA<PhotoBackendUnavailable>()),
          );
        }
        expect(
          methods,
          stage == 'table_absente' ? ['GET'] : ['GET', 'OPTIONS'],
        );
      },
    );
  }

  testWidgets(
    'photo indisponible signalée, pas présentée comme annonce sans photo',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListingCard(
              listing: const PublicListing(
                id: 'test',
                title: 'Annonce test',
                description: 'Fictive',
                price: '1000',
                city: 'Brazzaville',
                photosUnavailable: true,
              ),
              imageHeight: 140,
              onOpen: () {},
            ),
          ),
        ),
      );
      expect(find.text('Photos momentanément indisponibles.'), findsOneWidget);
      expect(find.text('Annonce test'), findsOneWidget);
    },
  );
}
