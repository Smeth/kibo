import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/profile/engagement_pages.dart';
import 'package:kibo/features/profile/engagement_repository.dart';
import '../support/auth_fake.dart';
import 'engagement_widgets_test.dart' show EngagementFake, sampleRequest;

class DeletionFake extends EngagementFake implements AccountDeletionExecutor {
  @override
  bool get deletionEnabled => true;
  int executions = 0;
  @override
  Future<bool> executeDeletion(
    String actor,
    Map<String, dynamic> request,
  ) async {
    executions++;
    throw StateError('fixture');
  }
}

void main() {
  testWidgets(
    'admin deletion requires typed confirmation, preserves resumable error and has no overflow at large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final source = FakeAuthRepository()..identity = FakeAuthRepository.user;
      final auth = AuthController(source);
      addTearDown(auth.dispose);
      addTearDown(source.dispose);
      final repo = DeletionFake()
        ..admin = true
        ..rows = [sampleRequest(status: 'processing')];
      await tester.pumpWidget(
        MaterialApp(
          home: EngagementPage(
            controller: auth,
            repository: repo,
            operatorOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('En cours d’examen').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Supprimer définitivement'),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer définitivement'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Confirmer la suppression'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer la suppression'));
      await tester.pumpAndSettle();
      expect(repo.executions, 0);
      await tester.tap(find.text('Supprimer définitivement'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'SUPPRIMER');
      await tester.ensureVisible(find.text('Confirmer la suppression'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmer la suppression'));
      await tester.pumpAndSettle();
      expect(repo.executions, 1);
      expect(
        find.text(
          'Suppression non confirmée. Consultez le message en haut de l’écran.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
