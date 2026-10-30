import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kibo/main.dart';

void main() {
  testWidgets('L’accueil KIBO affiche son identité et sa navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KiboApp());

    expect(find.text('KIBO'), findsOneWidget);
    expect(find.text('Le commerce, simplement.'), findsOneWidget);
    expect(find.text('Bienvenue sur KIBO !'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });
}
