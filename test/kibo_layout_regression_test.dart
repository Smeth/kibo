import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:kibo/core/widgets/kibo_bottom_navigation.dart';
import 'package:kibo/main.dart';

import 'support/manrope_fonts.dart';
import 'support/supabase_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadManropeFonts);

  for (final width in [320.0, 360.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('navigation complète et alignée : $width / $scale', (
        tester,
      ) async {
        await pumpHome(tester, width, scale);
        final navigation = find.byType(KiboBottomNavigation);
        final bounds = tester.getRect(navigation);
        final iconRows = <double, List<double>>{};
        for (final label in [
          'Accueil',
          'Recherche',
          'Publier',
          'Favoris',
          'Profil',
        ]) {
          final finder = find.descendant(
            of: navigation,
            matching: find.text(label),
          );
          final paragraph = tester.renderObject<RenderParagraph>(finder);
          final textBounds = tester.getRect(finder);
          final painter = TextPainter(
            text: paragraph.text,
            textDirection: TextDirection.ltr,
            textScaler: paragraph.textScaler,
          )..layout();
          expect(painter.computeLineMetrics(), hasLength(1));
          expect(painter.width, lessThanOrEqualTo(paragraph.size.width + 0.01));
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(paragraph.textScaler.scale(12), closeTo(12 * scale, 0.01));
          expect(bounds.contains(textBounds.topLeft), isTrue);
          expect(bounds.contains(textBounds.bottomRight), isTrue);
          painter.dispose();

          final tapArea = find.ancestor(
            of: finder,
            matching: find.byType(InkWell),
          );
          final icon = find.descendant(
            of: tapArea,
            matching: find.byType(Icon),
          );
          final iconBounds = tester.getRect(icon);
          expect(tester.getSize(tapArea).height, greaterThanOrEqualTo(52));
          expect(iconBounds.center.dx, closeTo(textBounds.center.dx, 0.01));
          iconRows.putIfAbsent(textBounds.top, () => []).add(iconBounds.top);
        }
        for (final row in iconRows.values) {
          for (final top in row) {
            expect(top, closeTo(row.first, 0.01));
          }
        }
        final labels = ['Accueil', 'Recherche', 'Publier', 'Favoris', 'Profil'];
        for (var index = 0; index < labels.length; index++) {
          await tester.tap(find.text(labels[index]));
          await tester.pumpAndSettle();
          expect(
            tester.widget<KiboBottomNavigation>(navigation).selectedIndex,
            index,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final scale in [1.0, 1.5]) {
    testWidgets('illustrations bornées et quatre annonces accessibles : $scale', (
      tester,
    ) async {
      await pumpHome(tester, 360, scale);
      final scrollable = find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first;
      final images = <Rect>[];
      for (final title in [
        'Smartphone Android',
        'Canapé moderne',
        'Moto en bon état',
        'Appartement à louer',
      ]) {
        final image = find.byKey(ValueKey('listing-image-$title'));
        await tester.scrollUntilVisible(image, 200, scrollable: scrollable);
        await tester.pumpAndSettle();
        final rect = tester.getRect(image);
        expect(rect.height, inInclusiveRange(140, 180));
        images.add(rect);
        final card = find.byKey(ValueKey('listing-card-$title'));
        expect(
          find.descendant(of: card, matching: find.text(title)),
          findsOneWidget,
        );
        final titleText = tester.widget<Text>(find.text(title));
        expect(titleText.maxLines, isNull);
        expect(tester.takeException(), isNull);
      }
      if (scale == 1) {
        // La première rangée est montée au même instant pour comparer ses limites.
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('listing-image-Smartphone Android')),
          -200,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        final first = tester.getRect(
          find.byKey(const ValueKey('listing-image-Smartphone Android')),
        );
        final second = tester.getRect(
          find.byKey(const ValueKey('listing-image-Canapé moderne')),
        );
        expect(first.top, closeTo(second.top, 0.01));
        expect(first.height, closeTo(second.height, 0.01));
        expect(first.bottom, closeTo(second.bottom, 0.01));
      }
      expect(images.map((image) => image.height).toSet(), hasLength(1));
      expect(find.text('120 000 FCFA / mois'), findsOneWidget);
    });
  }
}

Future<void> pumpHome(WidgetTester tester, double width, double scale) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final client = createTestClient();
  addTearDown(client.dispose);
  await tester.pumpWidget(
    KiboApp(
      supabase: SupabaseService(
        config: testConfig,
        initializer: (_) async => client,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
