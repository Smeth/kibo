import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kibo/core/diagnostics/operation_id.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/listings/listing_repository.dart';
import 'package:kibo/features/listings/listing_models.dart';
import 'package:kibo/features/listings/listing_feed.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/profile/account_settings_page.dart';
import '../support/supabase_fakes.dart';
import '../support/listing_session.dart';
import '../support/listing_fake.dart';

class _MemoryPkce extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

void main() {
  test('identifiants de reprise uniques et UUID valides', () {
    final ids = List.generate(100, (_) => newOperationId());
    expect(ids.toSet().length, 100);
    expect(ids.every(isOperationId), true);
  });
  test(
    'publication incertaine relit meme ID sans doublon ni contenu different',
    () async {
      const id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
      var posts = 0;
      var title = 'Titre fictif';
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        authOptions: AuthClientOptions(
          autoRefreshToken: false,
          pkceAsyncStorage: _MemoryPkce(),
        ),
        httpClient: MockClient((request) async {
          if (request.url.path == '/auth/v1/token') {
            return http.Response(
              jsonEncode(listingTestSession()),
              200,
              request: request,
            );
          }
          if (request.method == 'POST') {
            posts++;
            expect(jsonDecode(request.body)['id'], id);
            return http.Response(
              '{"code":"23505","message":"duplicate"}',
              409,
              request: request,
            );
          }
          expect(request.url.queryParameters['seller_id'], 'eq.user-a');
          return http.Response(
            jsonEncode([
              {
                'id': id,
                'seller_id': 'user-a',
                'title': title,
                'description': 'Description fictive',
                'price': '1000.00',
                'city': 'Brazzaville',
                'neighborhood': null,
                'category_id': 'cat',
                'listing_type': 'product',
                'status': 'published',
                'published_at': '2026-11-01T10:00:00Z',
              },
            ]),
            200,
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'fictif@example.invalid',
        password: 'fictif',
      );
      final repo = SupabaseListingRepository(client);
      const draft = ListingDraft(
        title: 'Titre fictif',
        description: 'Description fictive',
        price: '1000',
        city: 'Brazzaville',
        categoryId: 'cat',
      );
      expect(
        await repo.createOnce(draft, expectedUserId: 'user-a', operationId: id),
        id,
      );
      expect(posts, 1);
      title = 'Autre contenu';
      await expectLater(
        repo.createOnce(draft, expectedUserId: 'user-a', operationId: id),
        throwsStateError,
      );
    },
  );
  test(
    'recuperation et demande de compte utilisent les contrats attendus',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        authOptions: AuthClientOptions(
          autoRefreshToken: false,
          pkceAsyncStorage: _MemoryPkce(),
        ),
        httpClient: MockClient((r) async {
          if (r.url.path == '/auth/v1/token') {
            return http.Response(
              jsonEncode(listingTestSession()),
              200,
              request: r,
            );
          }
          requests.add(r);
          return http.Response('{}', 200, request: r);
        }),
      );
      addTearDown(client.dispose);
      await client.auth.signInWithPassword(
        email: 'fictif@example.invalid',
        password: 'fictif',
      );
      await SupabaseAuthRepository(
        client,
      ).sendPasswordReset('fictif@example.invalid');
      expect(requests.single.url.path, endsWith('/recover'));
      expect(
        jsonDecode(requests.single.body)['email'],
        'fictif@example.invalid',
      );
      requests.clear();
      await SupabaseAccountRequestsRepository(
        client,
      ).request('user-a', cancel: false);
      expect(jsonDecode(requests.single.body), {'p_cancel': false});
    },
  );
  testWidgets('lecture lente expire sans perdre les annonces deja affichees', (
    tester,
  ) async {
    final repo = FakeListingRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: Scaffold(body: ListingFeed(repository: repo)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Smartphone Android'), findsOneWidget);
    repo.pendingRead = Completer<List<PublicListing>>();
    await tester.tap(find.byTooltip('Actualiser les annonces'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();
    expect(find.text('Smartphone Android'), findsOneWidget);
    repo.pendingRead!.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Smartphone Android'), findsOneWidget);
  });
}
