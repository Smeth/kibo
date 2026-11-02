import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/password_pages.dart';
import 'package:kibo/features/profile/account_settings_page.dart';
import '../support/auth_fake.dart';

class RecoveryFake extends FakeAuthRepository
    implements PasswordRecoveryRepository {
  final recovery = StreamController<String>.broadcast();
  int resets = 0, changes = 0;
  @override
  Stream<String> get passwordRecoveryEvents => recovery.stream;
  @override
  Future<void> sendPasswordReset(String email) async {
    resets++;
  }

  @override
  Future<void> changePassword(String expectedOwner, String password) async {
    if (identity?.id != expectedOwner) throw StateError('Session');
    changes++;
  }

  @override
  Future<void> dispose() async {
    await recovery.close();
    await super.dispose();
  }
}

class AccountFake implements AccountRequestsRepository {
  String? value;
  Object? readError, afterWriteReadError;
  bool processingOnCancel = false;
  int requests = 0;
  @override
  Future<String?> status(String owner) async {
    if (readError != null) throw readError!;
    return value;
  }

  @override
  Future<void> request(String owner, {required bool cancel}) async {
    requests++;
    value = cancel
        ? processingOnCancel
              ? 'processing'
              : null
        : 'pending';
    readError = afterWriteReadError;
  }
}

void main() {
  Future<void> accountPage(WidgetTester tester, AccountFake account) async {
    final auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    final controller = AuthController(auth);
    addTearDown(controller.dispose);
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: AccountSettingsPage(controller: controller, repository: account),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'lecture rétablie efface l’ancienne erreur et autorise la demande',
    (tester) async {
      final account = AccountFake()..readError = StateError('fixture');
      await accountPage(tester, account);
      expect(
        find.textContaining('État du compte indisponible'),
        findsOneWidget,
      );
      expect(find.text('Enregistrer ma demande'), findsNothing);
      account.readError = null;
      await tester.ensureVisible(find.text('Actualiser l’état'));
      await tester.tap(find.text('Actualiser l’état'));
      await tester.pumpAndSettle();
      expect(find.textContaining('État du compte indisponible'), findsNothing);
      expect(find.text('Enregistrer ma demande'), findsOneWidget);
    },
  );
  testWidgets(
    'demande acceptée puis lecture échouée ne devient pas une fausse absence',
    (tester) async {
      final account = AccountFake()
        ..afterWriteReadError = StateError('fixture');
      await accountPage(tester, account);
      await tester.enterText(find.byType(TextField), 'SUPPRIMER');
      await tester.ensureVisible(find.text('Enregistrer ma demande'));
      await tester.tap(find.text('Enregistrer ma demande'));
      await tester.pumpAndSettle();
      expect(account.requests, 1);
      expect(find.textContaining('état actuel indisponible'), findsOneWidget);
      expect(find.text('Aucune demande en attente.'), findsNothing);
      expect(find.text('Enregistrer ma demande'), findsNothing);
    },
  );
  testWidgets(
    'annulation concurrente avec examen ne promet pas une annulation',
    (tester) async {
      final account = AccountFake()
        ..value = 'pending'
        ..processingOnCancel = true;
      await accountPage(tester, account);
      await tester.ensureVisible(find.text('Annuler ma demande'));
      await tester.tap(find.text('Annuler ma demande'));
      await tester.pumpAndSettle();
      expect(account.value, 'processing');
      expect(
        find.textContaining('L’annulation n’est pas confirmée'),
        findsOneWidget,
      );
      expect(find.text('Annuler ma demande'), findsNothing);
    },
  );
  test('evenement de recuperation ne cible pas un autre compte', () async {
    final repo = RecoveryFake()..identity = FakeAuthRepository.user;
    final controller = AuthController(repo);
    repo.recovery.add('test-user-a');
    repo.emit(const AuthIdentity(id: 'B'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.recoveringPassword, false);
    controller.dispose();
    await repo.dispose();
  });
  testWidgets('reset email valide et reponse sans enumeration de compte', (
    tester,
  ) async {
    final repo = RecoveryFake();
    addTearDown(repo.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: PasswordResetPage(repository: repo),
      ),
    );
    await tester.tap(find.text('Recevoir le lien'));
    await tester.pumpAndSettle();
    expect(repo.resets, 0);
    await tester.enterText(
      find.byType(TextFormField),
      'fictif@example.invalid',
    );
    await tester.tap(find.text('Recevoir le lien'));
    await tester.pumpAndSettle();
    expect(repo.resets, 1);
    expect(find.textContaining('Si un compte correspond'), findsOneWidget);
  });
  testWidgets('nouveau mot de passe exige confirmation et ferme recuperation', (
    tester,
  ) async {
    final repo = RecoveryFake()..identity = FakeAuthRepository.user;
    final controller = AuthController(repo);
    addTearDown(controller.dispose);
    addTearDown(repo.dispose);
    repo.recovery.add('test-user-a');
    await tester.pump();
    expect(controller.recoveringPassword, true);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: PasswordChangePage(controller: controller),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'FictifPass123!');
    await tester.enterText(find.byType(TextFormField).at(1), 'autre');
    await tester.tap(find.text('Mettre à jour le mot de passe'));
    await tester.pumpAndSettle();
    expect(repo.changes, 0);
    await tester.enterText(find.byType(TextFormField).at(1), 'FictifPass123!');
    await tester.tap(find.text('Mettre à jour le mot de passe'));
    await tester.pumpAndSettle();
    expect(repo.changes, 1);
    expect(controller.recoveringPassword, false);
  });
  testWidgets(
    'suppression demandee uniquement apres confirmation et annulable',
    (tester) async {
      final repo = FakeAuthRepository()..identity = FakeAuthRepository.user;
      final controller = AuthController(repo);
      final account = AccountFake();
      addTearDown(controller.dispose);
      addTearDown(repo.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: AccountSettingsPage(
            controller: controller,
            repository: account,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Enregistrer ma demande'));
      await tester.tap(find.text('Enregistrer ma demande'));
      await tester.pumpAndSettle();
      expect(account.requests, 0);
      await tester.enterText(find.byType(TextField), 'SUPPRIMER');
      await tester.ensureVisible(find.text('Enregistrer ma demande'));
      await tester.tap(find.text('Enregistrer ma demande'));
      await tester.pumpAndSettle();
      expect(account.value, 'pending');
      expect(find.textContaining('pas encore supprimés'), findsOneWidget);
      await tester.ensureVisible(find.text('Annuler ma demande'));
      await tester.tap(find.text('Annuler ma demande'));
      await tester.pumpAndSettle();
      expect(account.value, isNull);
    },
  );
  testWidgets('changement A B A invalide les reglages du compte', (
    tester,
  ) async {
    final repo = FakeAuthRepository()..identity = FakeAuthRepository.user;
    final controller = AuthController(repo);
    addTearDown(controller.dispose);
    addTearDown(repo.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: AccountSettingsPage(
          controller: controller,
          repository: AccountFake(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    repo.emit(const AuthIdentity(id: 'B'));
    repo.emit(FakeAuthRepository.user);
    await tester.pumpAndSettle();
    expect(find.textContaining('Session modifiée'), findsOneWidget);
  });
}
