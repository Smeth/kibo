import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kibo/features/listings/listing_repository.dart';
import 'package:kibo/features/listings/listing_query.dart';
import '../support/supabase_fakes.dart';

void main() {
  test(
    'enhanced search sends filters, relevance and page offset to RPC',
    () async {
      final calls = <String>[];
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        httpClient: MockClient((request) async {
          calls.add(request.url.path);
          final data = jsonDecode(request.body) as Map;
          expect(data['p_text'], 'télé');
          expect(data['p_city'], 'Brazzaville');
          expect(data['p_min'], '1000');
          if (request.url.path.endsWith('kibo_search_listings')) {
            expect(data['p_sort'], 'relevance');
            expect(data['p_offset'], 20);
            return http.Response(
              '[]',
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          expect(request.url.path.endsWith('kibo_search_suggestions'), isTrue);
          return http.Response(
            '[{"text":"Téléphone Samsung","correction":true}]',
            200,
            request: request,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(client.dispose);
      final repository = SupabaseListingRepository(
        client,
        enhancedDiscovery: true,
      );
      const query = ListingQuery(
        text: 'télé',
        city: 'Brazzaville',
        minPrice: '1000',
      );
      expect(await repository.published(query: query, offset: 20), isEmpty);
      final suggestions = await repository.suggestions(query);
      expect(suggestions.single.text, 'Téléphone Samsung');
      expect(suggestions.single.correction, isTrue);
      expect(calls.length, 2);
    },
  );
  test(
    'permission failures never silently fall back to legacy search',
    () async {
      var calls = 0;
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        httpClient: MockClient((request) async {
          calls++;
          return http.Response(
            '{"code":"42501","message":"refused"}',
            403,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );
      addTearDown(client.dispose);
      await expectLater(
        SupabaseListingRepository(
          client,
          enhancedDiscovery: true,
        ).published(query: const ListingQuery(text: 'samung')),
        throwsA(isA<PostgrestException>()),
      );
      expect(calls, 1);
    },
  );
}
