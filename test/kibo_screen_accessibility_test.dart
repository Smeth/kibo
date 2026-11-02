import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/core/widgets/kibo_app_bar.dart';
import 'package:kibo/core/widgets/kibo_form_layout.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/profile/retained_history_page.dart';
import 'support/auth_fake.dart';
import 'support/manrope_fonts.dart';

class _History implements RetainedHistoryRepository {
  @override
  Future<List<Map<String, dynamic>>> retained(
    String owner,
    String kind, {
    String? thread,
    int offset = 0,
  }) async => [];
}

void main() {
  setUpAll(loadManropeFonts);

  Future<void> compact(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        builder: (context, body) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: body!,
        ),
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'titre long intégral et action accessible sur 320 / texte 200 %',
    (tester) async {
      const title = 'Mes coordonnées de contact';
      await compact(
        tester,
        Builder(
          builder: (context) => Scaffold(
            appBar: KiboAppBar(
              context,
              title: const Text(title),
              actions: [
                IconButton(
                  tooltip: 'Actualiser',
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
      );
      final text = tester.renderObject<RenderParagraph>(find.text(title));
      expect(text.didExceedMaxLines, isFalse);
      final bar = tester.getRect(find.byType(KiboAppBar));
      expect(
        bar.contains(tester.getRect(find.text(title)).bottomRight),
        isTrue,
      );
      expect(
        tester.getSize(find.byTooltip('Actualiser')).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'filtres archives à la ligne sans débordement et encore utilisables',
    (tester) async {
      final repository = FakeAuthRepository()
        ..identity = FakeAuthRepository.user;
      final auth = AuthController(repository);
      addTearDown(auth.dispose);
      addTearDown(repository.dispose);
      await compact(
        tester,
        RetainedHistoryPage(auth: auth, repository: _History()),
      );
      await tester.scrollUntilVisible(find.text('Commentaires'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Commentaires'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Commentaires'))
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('formulaire défilable avec clavier et marge système basse', (
    tester,
  ) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    tester.view.padding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.view.resetPadding);
    var saved = false;
    await compact(
      tester,
      Scaffold(
        body: KiboFormListView(
          children: [
            for (var i = 0; i < 5; i++)
              TextFormField(decoration: InputDecoration(labelText: 'Champ $i')),
            FilledButton(
              onPressed: () => saved = true,
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Enregistrer'),
      140,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    expect(saved, isTrue);
    expect(tester.getRect(find.text('Enregistrer')).bottom, lessThan(380));
    expect(tester.takeException(), isNull);
  });
}
