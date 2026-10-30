import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:kibo/core/theme/kibo_colors.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/main.dart';

import '../support/supabase_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'les trois graisses déclarées et la licence sont embarquées localement',
    () async {
      final manifest =
          jsonDecode(await rootBundle.loadString('FontManifest.json'))
              as List<dynamic>;
      final family = manifest.cast<Map<String, dynamic>>().singleWhere(
        (entry) => entry['family'] == 'Manrope',
      );
      final fonts = family['fonts'] as List<dynamic>;
      expect(
        fonts.map((font) => font['weight']),
        unorderedEquals([400, 600, 800]),
      );
      for (final font in fonts) {
        final data = await rootBundle.load(font['asset'] as String);
        // Vérifie le poids réel dans OS/2, pas seulement le nom du fichier.
        final count = data.getUint16(4);
        var foundWeight = false;
        for (var index = 0; index < count; index++) {
          final record = 12 + 16 * index;
          if (data.getUint32(record) == 0x4F532F32) {
            final tableOffset = data.getUint32(record + 8);
            expect(data.getUint16(tableOffset + 4), font['weight']);
            foundWeight = true;
          }
        }
        expect(foundWeight, isTrue);
      }
      final license = await rootBundle.loadString(
        'assets/fonts/manrope/OFL.txt',
      );
      expect(license, contains('SIL OPEN FONT LICENSE Version 1.1'));
      expect(license, contains('Copyright 2018 The Manrope Project Authors'));
    },
  );

  testWidgets('le thème Manrope Emerald est hérité par l’accueil', (
    tester,
  ) async {
    final client = createTestClient();
    addTearDown(client.dispose);
    final service = SupabaseService(
      config: testConfig,
      initializer: (_) async => client,
    );
    await tester.pumpWidget(KiboApp(supabase: service));
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.byType(KiboHomePage)));
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, const Color(0xFF087F5B));
    expect(theme.scaffoldBackgroundColor, KiboColors.background);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Manrope');
    expect(
      tester.widget<Text>(find.text('KIBO')).style?.fontWeight,
      FontWeight.w800,
    );
    expect(
      tester
          .widget<Text>(find.text('Explorer les catégories'))
          .style
          ?.fontWeight,
      FontWeight.w600,
    );
    expect(theme.textTheme.bodySmall?.fontSize, greaterThanOrEqualTo(12));
    expect(theme.textTheme.bodyMedium?.fontWeight, FontWeight.w400);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  test(
    'la licence Manrope est accessible sans enregistrement dupliqué',
    () async {
      KiboTheme.registerFontLicense();
      KiboTheme.registerFontLicense();
      final entries = await LicenseRegistry.licenses
          .where((entry) => entry.packages.contains('Manrope'))
          .toList();
      expect(entries, hasLength(1));
    },
  );
}
