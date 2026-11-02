import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/owned_listing_repository.dart';
import 'package:kibo/features/listings/owned_listing_query.dart';
import 'package:kibo/features/listings/listing_query.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/listing_session.dart';
import '../support/supabase_fakes.dart';

const ownedDraft = ListingDraft(
  title: 'Produit fictif',
  description: 'Description fictive de recette',
  price: '1000',
  categoryId: 'category-a',
  city: 'Brazzaville',
);
OwnedListing ownedRow({String owner = 'user-a', String status = 'published'}) =>
    OwnedListing(
      id: 'listing-a',
      sellerId: owner,
      status: status,
      updatedAt: '2026-11-01T01:00:00Z',
      draft: ownedDraft,
    );
Map<String, dynamic> ownedJson({String owner = 'user-a'}) => {
  'id': 'listing-a',
  'seller_id': owner,
  'status': 'published',
  'updated_at': '2026-11-01T01:00:00Z',
  'title': ownedDraft.title,
  'description': ownedDraft.description,
  'price': '1000',
  'category_id': 'category-a',
  'city': 'Brazzaville',
  'neighborhood': null,
  'listing_type': 'product',
};

void main() {
  late SupabaseClient client;
  late SupabaseOwnedListingRepository repository;
  final requests = <http.Request>[];
  late Future<http.Response> Function(http.Request) respond;
  setUp(() async {
    requests.clear();
    respond = (r) async => http.Response(
      jsonEncode([
        {...ownedJson(), ...jsonDecode(r.body) as Map<String, dynamic>},
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
      password: 'test-only',
    );
    repository = SupabaseOwnedListingRepository(client);
  });
  tearDown(() => client.dispose());

  test(
    'liste privée filtrée côté serveur et paginée sans statut public',
    () async {
      respond = (_) async => http.Response(jsonEncode([ownedJson()]), 200);
      final rows = await repository.mine('user-a', offset: 20);
      expect(rows.single.sellerId, 'user-a');
      final query = requests.single.url.queryParameters;
      expect(query['seller_id'], 'eq.user-a');
      expect(query.containsKey('status'), false);
      expect(query['offset'], '20');
      expect(query['limit'], '20');
      expect(query['order'], 'created_at.desc.nullslast,id.asc.nullslast');
    },
  );
  test('refuse une réponse contenant les annonces de B', () async {
    respond = (_) async =>
        http.Response(jsonEncode([ownedJson(owner: 'user-b')]), 200);
    await expectLater(repository.mine('user-a'), throwsStateError);
  });
  test(
    'recherche française combinée avec statut, propriétaire et pagination',
    () async {
      respond = (_) async => http.Response('[]', 200);
      const text = '  téléphone, (neuf) "OR" seller_id.eq.user-b  ';
      await repository.mine(
        'user-a',
        offset: 20,
        query: const OwnedListingQuery(
          status: OwnedListingStatus.archived,
          text: text,
        ),
      );
      final query = requests.single.url.queryParameters;
      expect(query['seller_id'], 'eq.user-a');
      expect(query['status'], 'eq.archived');
      expect(
        query['kibo_search_vector'],
        'fts(french).${listingPrefixQuery(text)}',
      );
      expect(query.containsKey('or'), false);
      expect(query['offset'], '20');
      expect(query['limit'], '20');
    },
  );
  test('texte blanc ne transmet aucun filtre de recherche', () async {
    respond = (_) async => http.Response('[]', 200);
    await repository.mine('user-a', query: const OwnedListingQuery(text: '  '));
    expect(
      requests.single.url.queryParameters.containsKey('kibo_search_vector'),
      false,
    );
  });
  test('recherche trop longue ou pagination négative : zéro requête', () async {
    await expectLater(
      repository.mine('user-a', query: OwnedListingQuery(text: 'a' * 121)),
      throwsArgumentError,
    );
    await expectLater(
      repository.mine('user-a', offset: -1),
      throwsArgumentError,
    );
    expect(requests, isEmpty);
  });
  test(
    'erreur de recherche propagée sans élargir au catalogue public',
    () async {
      respond = (_) async => http.Response(
        jsonEncode({'code': '42501', 'message': 'Denied'}),
        403,
      );
      await expectLater(
        repository.mine(
          'user-a',
          query: const OwnedListingQuery(text: 'produit'),
        ),
        throwsA(isA<PostgrestException>()),
      );
      expect(requests.length, 1);
    },
  );
  for (final status in OwnedListingStatus.values.where(
    (s) => s != OwnedListingStatus.all,
  )) {
    test(
      'filtre serveur $status conserve le propriétaire et la pagination',
      () async {
        respond = (_) async => http.Response('[]', 200);
        await repository.mine(
          'user-a',
          offset: 20,
          query: OwnedListingQuery(status: status),
        );
        final query = requests.single.url.queryParameters;
        expect(query['seller_id'], 'eq.user-a');
        expect(query['status'], 'eq.${status.name}');
        expect(query['offset'], '20');
        expect(query['limit'], '20');
      },
    );
  }
  test('aucune requête pour consulter ou modifier le compte B', () async {
    await expectLater(repository.mine('user-b'), throwsStateError);
    await expectLater(
      repository.edit(ownedRow(owner: 'user-b'), ownedDraft),
      throwsStateError,
    );
    await expectLater(
      repository.transition(ownedRow(owner: 'user-b'), 'archived'),
      throwsStateError,
    );
    expect(requests, isEmpty);
  });
  test(
    'modification ciblée et optimiste, sans champs protégés/photos/favoris',
    () async {
      await repository.edit(ownedRow(), ownedDraft);
      final request = requests.single;
      expect(request.method, 'PATCH');
      expect(jsonDecode(request.body).keys.toSet(), {
        'title',
        'description',
        'price',
        'category_id',
        'city',
        'neighborhood',
        'listing_type',
      });
      expect(request.url.queryParameters['id'], 'eq.listing-a');
      expect(request.url.queryParameters['seller_id'], 'eq.user-a');
      expect(request.url.queryParameters['status'], 'eq.published');
      expect(
        request.url.queryParameters['updated_at'],
        'eq.2026-11-01T01:00:00Z',
      );
    },
  );
  for (final target in ['sold', 'archived']) {
    test(
      'transition $target modifie uniquement le statut sur le même ID',
      () async {
        await repository.transition(ownedRow(), target);
        expect(jsonDecode(requests.single.body), {'status': target});
        expect(requests.single.method, 'PATCH');
      },
    );
  }
  test('une vente peut être archivée, jamais republiée', () async {
    await repository.transition(ownedRow(status: 'sold'), 'archived');
    await expectLater(
      repository.transition(ownedRow(status: 'sold'), 'published'),
      throwsA(isA<ListingManagementConflict>()),
    );
    await expectLater(
      repository.edit(ownedRow(status: 'archived'), ownedDraft),
      throwsA(isA<ListingManagementConflict>()),
    );
    expect(requests.length, 1);
  });
  test('absence de ligne modifiée = conflit, pas un succès', () async {
    respond = (_) async => http.Response('[]', 200);
    await expectLater(
      repository.transition(ownedRow(), 'sold'),
      throwsA(isA<ListingManagementConflict>()),
    );
  });
  for (final invalid in <Map<String, dynamic>>[
    {'seller_id': 'user-b'},
    {'status': 'published'},
    {'updated_at': null},
    {'updated_at': 'invalide'},
  ]) {
    test('transition non confirmée pour retour $invalid', () async {
      respond = (_) async => http.Response(
        jsonEncode([
          {...ownedJson(), 'status': 'sold', ...invalid},
        ]),
        200,
      );
      await expectLater(
        repository.transition(ownedRow(), 'sold'),
        throwsA(isA<ListingManagementUnconfirmed>()),
      );
      expect(requests.length, 1);
    });
  }
  test('contenu serveur différent : pas de faux succès', () async {
    respond = (_) async => http.Response(
      jsonEncode([
        {...ownedJson(), 'title': 'Ancien titre'},
      ]),
      200,
    );
    await expectLater(
      repository.edit(ownedRow(), ownedDraft),
      throwsA(isA<ListingManagementUnconfirmed>()),
    );
  });
  test('prix décimal équivalent accepté sans arrondi flottant', () async {
    respond = (_) async => http.Response(
      jsonEncode([
        {...ownedJson(), 'price': '1000.00'},
      ]),
      200,
    );
    await repository.edit(ownedRow(), ownedDraft);
    expect(requests.length, 1);
  });
  test(
    'effacer le prix envoie NULL et confirme le retour serveur absent',
    () async {
      final draft = ListingDraft(
        title: ownedDraft.title,
        description: ownedDraft.description,
        price: '',
        categoryId: ownedDraft.categoryId,
        city: ownedDraft.city,
      );
      await repository.edit(ownedRow(), draft);
      expect((jsonDecode(requests.single.body) as Map)['price'], isNull);
    },
  );
  test('42501 reste un refus serveur sans contournement', () async {
    respond = (_) async => http.Response(
      jsonEncode({'code': '42501', 'message': 'Protected fields'}),
      403,
    );
    await expectLater(
      repository.transition(ownedRow(), 'archived'),
      throwsA(isA<PostgrestException>()),
    );
    expect(requests.length, 1);
    expect(
      listingManagementError(
        const PostgrestException(message: 'private data', code: '42501'),
      ),
      isNot(contains('private data')),
    );
  });
  test(
    'erreur réseau conservée, aucune recréation ni relance automatique',
    () async {
      respond = (_) async => throw http.ClientException('offline');
      await expectLater(
        repository.edit(ownedRow(), ownedDraft),
        throwsA(isA<http.ClientException>()),
      );
      expect(requests.length, 1);
    },
  );
  test(
    'photos propriétaire triées et projection activable sans écrire',
    () async {
      respond = (_) async => http.Response(
        jsonEncode([
          {
            ...ownedJson(),
            'photos': [
              {'position': 2, 'path': 'photo-c'},
              {'position': 0, 'path': 'photo-a'},
            ],
          },
        ]),
        200,
      );
      final photosRepository = SupabaseOwnedListingRepository(
        client,
        withPhotos: true,
      );
      final rows = await photosRepository.mine('user-a');
      expect(rows.single.photoPaths, ['photo-a', 'photo-c']);
      expect(
        requests.single.url.queryParameters['select'],
        contains('photos:kibo_listing_photos(path,position)'),
      );
      expect(requests.single.method, 'GET');
    },
  );
  test('session absente : aucune lecture ni écriture', () async {
    await client.auth.signOut(scope: SignOutScope.local);
    requests.clear();
    await expectLater(repository.mine('user-a'), throwsStateError);
    await expectLater(
      repository.edit(ownedRow(), ownedDraft),
      throwsStateError,
    );
    expect(requests, isEmpty);
  });
}
