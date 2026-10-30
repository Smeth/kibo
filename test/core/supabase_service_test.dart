import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/config/supabase_config.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/supabase_fakes.dart';

void main() {
  test('aucune initialisation sans configuration valide', () async {
    for (final config in [
      const SupabaseConfig(url: '', publicKey: ''),
      SupabaseConfig(url: 'invalid', publicKey: testConfig.publicKey),
    ]) {
      var calls = 0;
      final service = SupabaseService(
        config: config,
        initializer: (_) async {
          calls++;
          throw StateError('Ne doit pas être appelé');
        },
      );
      expect((await service.initialize()).isReady, isFalse);
      expect(calls, 0);
      expect(() => service.client, throwsStateError);
    }
  });

  test('initialise une seule fois et expose le client injecté', () async {
    var calls = 0;
    final completer = Completer<SupabaseClient>();
    final client = createTestClient();
    addTearDown(client.dispose);
    final service = SupabaseService(
      config: testConfig,
      initializer: (config) {
        expect(config, same(testConfig));
        calls++;
        return completer.future;
      },
    );
    final first = service.initialize();
    final second = service.initialize();
    expect(second, same(first));
    expect(() => service.client, throwsStateError);
    completer.complete(client);
    expect((await first).isReady, isTrue);
    expect(service.client, same(client));
    expect(service.initialize(), same(first));
    expect(calls, 1);
  });

  test('masque une erreur SDK et ne réinitialise pas après échec', () async {
    var calls = 0;
    final service = SupabaseService(
      config: testConfig,
      initializer: (_) async {
        calls++;
        throw StateError('Une valeur sensible fictive à ne pas afficher');
      },
    );
    final result = await service.initialize();
    expect(result.isReady, isFalse);
    expect(result.errorMessage, isNot(contains('valeur sensible')));
    expect(await service.initialize(), same(result));
    expect(calls, 1);
    expect(() => service.client, throwsStateError);
  });
}
