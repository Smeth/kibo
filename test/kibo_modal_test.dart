import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/core/widgets/kibo_modal.dart';
import 'support/manrope_fonts.dart';

void main() {
  setUpAll(loadManropeFonts);
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'feuille accessible, action explicite et fermeture : sombre=$dark texte=$scale',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          String? result;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? KiboTheme.dark : KiboTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () async {
                        result = await showKiboModalSheet<String>(
                          context: context,
                          builder: (context) => KiboSheet(
                            title: 'Gérer la sélection',
                            subtitle: 'Deux annonces sélectionnées',
                            child: KiboSheetAction(
                              label: 'Marquer les annonces vendues',
                              icon: Icons.check_circle_outline,
                              onTap: () => Navigator.pop(context, 'sold'),
                            ),
                          ),
                        );
                      },
                      child: const Text('Ouvrir'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Ouvrir'));
          await tester.pumpAndSettle();
          expect(result, isNull);
          await tester.ensureVisible(find.text('Marquer les annonces vendues'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Marquer les annonces vendues'));
          await tester.pumpAndSettle();
          expect(result, 'sold');
          result = null;
          await tester.tap(find.text('Ouvrir'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Fermer'));
          await tester.pumpAndSettle();
          expect(result, isNull);
          expect(find.byType(KiboSheet), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'confirmation en grande police avec clavier : bouton atteignable sans débordement',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      var confirmed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  confirmed =
                      await showDialog<bool>(
                        context: context,
                        builder: (context) => KiboDialog(
                          title: const Text('Confirmer la modification'),
                          content: TextFormField(
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Votre message',
                            ),
                            minLines: 2,
                            maxLines: 4,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Enregistrer'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(confirmed, isFalse);
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
