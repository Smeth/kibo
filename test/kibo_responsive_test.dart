import 'package:kibo/core/widgets/kibo_bottom_navigation.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/config/supabase_config.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:kibo/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/manrope_fonts.dart';
import 'support/supabase_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadManropeFonts);

  testWidgets(
    'chargement et reconstructions conservent une seule initialisation',
    (tester) async {
      final startup = Completer<SupabaseClient>();
      final client = createTestClient();
      addTearDown(client.dispose);
      var calls = 0;
      final service = SupabaseService(
        config: testConfig,
        initializer: (_) {
          calls++;
          return startup.future;
        },
      );
      await tester.pumpWidget(KiboApp(supabase: service));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpWidget(KiboApp(supabase: service));
      expect(calls, 1);
      startup.complete(client);
      await tester.pumpAndSettle();
      expect(find.byType(KiboHomePage), findsOneWidget);
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scenario in [
    (width: 320.0, height: 640.0, scale: 1.0),
    (width: 320.0, height: 640.0, scale: 2.0),
    (width: 320.0, height: 640.0, scale: 3.0),
    (width: 360.0, height: 800.0, scale: 1.5),
    (width: 393.0, height: 800.0, scale: 2.0),
    (width: 800.0, height: 600.0, scale: 2.0),
  ]) {
    testWidgets(
      'accueil sans débordement ${scenario.width} / texte ${scenario.scale}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(scenario.width, scenario.height);
        tester.platformDispatcher.textScaleFactorTestValue = scenario.scale;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final client = createTestClient();
        addTearDown(client.dispose);
        final service = SupabaseService(
          config: testConfig,
          initializer: (_) async => client,
        );
        await tester.pumpWidget(KiboApp(supabase: service));
        await tester.pumpAndSettle();
        expect(find.text('KIBO'), findsOneWidget);
        final navigationBounds = tester.getRect(
          find.byType(KiboBottomNavigation),
        );
        final searchLabelBounds = tester.getRect(find.text('Recherche'));
        expect(
          searchLabelBounds.top,
          greaterThanOrEqualTo(navigationBounds.top),
        );
        expect(
          searchLabelBounds.bottom,
          lessThanOrEqualTo(navigationBounds.bottom),
        );
        expect(tester.takeException(), isNull);
        final scrollable = find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('Appartement à louer'),
          300,
          scrollable: scrollable,
          maxScrolls: 50,
        );
        await tester.pumpAndSettle();
        expect(find.text('Appartement à louer'), findsOneWidget);
        expect(find.text('120 000 FCFA / mois'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<KiboBottomNavigation>(find.byType(KiboBottomNavigation))
              .selectedIndex,
          4,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'erreur de configuration lisible sur petit écran avec texte agrandi',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var calls = 0;
      final service = SupabaseService(
        config: const SupabaseConfig(url: '', publicKey: ''),
        initializer: (_) async {
          calls++;
          throw StateError('Ne doit pas être appelé');
        },
      );
      await tester.pumpWidget(KiboApp(supabase: service));
      await tester.pumpAndSettle();
      expect(find.text('Configuration KIBO'), findsOneWidget);
      expect(find.textContaining('absente ou incomplète'), findsOneWidget);
      expect(calls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
