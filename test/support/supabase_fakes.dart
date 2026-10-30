import 'package:kibo/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Valeurs fictives, sans projet ni accès à un backend.
const testConfig = SupabaseConfig(
  url: 'https://kibo-test.invalid',
  publicKey: 'sb_publishable_kibo_test_only',
);

SupabaseClient createTestClient() => _FakeSupabaseClient();

// Ne pas construire le vrai SDK dans les tests de widgets : son isolate JSON
// n’appartient pas à l’horloge simulée du WidgetTester.
class _FakeSupabaseClient implements SupabaseClient {
  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Aucune opération SDK attendue dans ces tests.');
}
