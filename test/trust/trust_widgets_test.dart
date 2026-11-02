import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/trust/help_page.dart';
import 'package:kibo/features/trust/official_badge.dart';

void main() {
  testWidgets(
    'badge uniquement après confirmation serveur, jamais sur erreur',
    (tester) async {
      var trusted = true;
      Widget badge(String id) => MaterialApp(
        home: Scaffold(
          body: OfficialBadge(
            userId: id,
            verify: (_) async {
              if (!trusted) throw StateError('Server unavailable');
              return true;
            },
          ),
        ),
      );
      await tester.pumpWidget(badge('fixture-a'));
      await tester.pumpAndSettle();
      expect(find.text('Équipe KIBO'), findsOneWidget);
      trusted = false;
      await tester.pumpWidget(badge('fixture-b'));
      await tester.pumpAndSettle();
      expect(find.text('Équipe KIBO'), findsNothing);
    },
  );
  testWidgets(
    'aide lisible à texte double avec contact et conservation explicites',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: const HelpPage(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(kiboSupportEmail), 250);
      expect(find.text(kiboSupportEmail), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -1700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
