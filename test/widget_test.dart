import 'package:kibo/core/widgets/kibo_bottom_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kibo/main.dart';
import 'package:kibo/core/config/supabase_config.dart';
import 'package:kibo/core/supabase/supabase_service.dart';

import 'support/supabase_fakes.dart';

void main() {
  testWidgets('L’accueil KIBO affiche son identité et sa navigation', (
    WidgetTester tester,
  ) async {
    final client = createTestClient();
    addTearDown(client.dispose);
    final service = SupabaseService(
      config: testConfig,
      initializer: (_) async => client,
    );
    await tester.pumpWidget(KiboApp(supabase: service));
    await tester.pumpAndSettle();

    expect(find.text('KIBO'), findsOneWidget);
    expect(find.text('Le commerce, simplement.'), findsOneWidget);
    expect(find.text('Bienvenue sur KIBO !'), findsOneWidget);
    expect(
      tester
          .widget<KiboBottomNavigation>(find.byType(KiboBottomNavigation))
          .destinations,
      hasLength(5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('affiche une erreur sans configuration et sans accès SDK', (
    tester,
  ) async {
    final service = SupabaseService(
      config: const SupabaseConfig.fromEnvironment(),
      initializer: (_) async {
        throw StateError('Le SDK ne doit pas être appelé');
      },
    );
    await tester.pumpWidget(KiboApp(supabase: service));
    await tester.pumpAndSettle();
    expect(find.text('Configuration KIBO'), findsOneWidget);
    expect(find.textContaining('absente ou incomplète'), findsOneWidget);
    expect(find.byType(KiboHomePage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('affiche une erreur pour une configuration invalide', (
    tester,
  ) async {
    final service = SupabaseService(
      config: SupabaseConfig(url: 'invalid', publicKey: testConfig.publicKey),
    );
    await tester.pumpWidget(KiboApp(supabase: service));
    await tester.pumpAndSettle();
    expect(find.textContaining('URL de projet HTTPS'), findsOneWidget);
    expect(find.byType(KiboHomePage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('affiche une erreur générique après échec SDK', (tester) async {
    final service = SupabaseService(
      config: testConfig,
      initializer: (_) async => throw Exception('valeur sensible'),
    );
    await tester.pumpWidget(KiboApp(supabase: service));
    await tester.pumpAndSettle();
    expect(find.textContaining('Impossible d’initialiser'), findsOneWidget);
    expect(find.textContaining('valeur sensible'), findsNothing);
    expect(find.byType(KiboHomePage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
