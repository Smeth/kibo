import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/chat/chat_page.dart';
import 'package:kibo/features/chat/chat_repository.dart';
import '../support/auth_fake.dart';
import 'chat_widgets_test.dart' show EnhancedChatFake, thread;

class MessageActionsFake extends EnhancedChatFake
    implements ChatMessageActions {
  bool available = true, failChange = false;
  int changesCount = 0;
  @override
  Future<bool> messageActionsAvailable(String owner, String threadId) async =>
      available;
  @override
  Future<ChatMessage> changeMessage(
    String owner,
    String threadId,
    ChatMessage message, {
    String? content,
    bool delete = false,
  }) async {
    changesCount++;
    if (failChange) throw StateError('Fixture');
    final row = ChatMessage(
      id: message.id,
      senderId: owner,
      content: delete ? 'Message supprimé' : content!.trim(),
      createdAt: message.createdAt,
      editedAt: delete ? message.editedAt : '2026-11-01T12:00:00Z',
      deletedAt: delete ? '2026-11-01T12:00:00Z' : null,
    );
    items[items.indexWhere((m) => m.id == row.id)] = row;
    return row;
  }
}

void main() {
  late MessageActionsFake repo;
  late FakeAuthRepository auth;
  setUp(() {
    auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    repo = MessageActionsFake()
      ..items = [
        ChatMessage(
          id: 'own',
          senderId: 'test-user-a',
          content: 'Message initial',
          createdAt: DateTime.utc(2026, 11, 1),
        ),
        ChatMessage(
          id: 'other',
          senderId: 'seller',
          content: 'Réponse reçue',
          createdAt: DateTime.utc(2026, 11, 1),
        ),
      ];
  });
  tearDown(() async {
    await auth.dispose();
    await repo.updates.close();
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.dark,
        home: AuthSession(
          repository: auth,
          child: ChatPage(
            repository: repo,
            ownerId: 'test-user-a',
            thread: thread,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> action(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const ValueKey('message-actions-own')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'appui long sur le texte puis suppression confirmée sans utiliser les points',
    (tester) async {
      await open(tester);
      await tester.longPress(find.text('Message initial'));
      await tester.pumpAndSettle();
      expect(find.text('Actions du message'), findsOneWidget);
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer ce message ?'), findsOneWidget);
      expect(repo.changesCount, 0);
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      expect(find.text('Message supprimé'), findsOneWidget);
      expect(repo.changesCount, 1);
    },
  );
  testWidgets(
    'appui long : modifier et copier accessibles, fermeture sans mutation',
    (tester) async {
      await open(tester);
      await tester.longPress(find.text('Message initial'));
      await tester.pumpAndSettle();
      expect(find.text('Copier'), findsOneWidget);
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('edit-message-content')),
        findsOneWidget,
      );
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(repo.changesCount, 0);
    },
  );

  testWidgets(
    'modifier son message conserve la conversation et affiche Modifié',
    (tester) async {
      await open(tester);
      expect(find.byKey(const ValueKey('message-actions-other')), findsNothing);
      await action(tester, 'Modifier');
      await tester.enterText(
        find.byKey(const ValueKey('edit-message-content')),
        'Message corrigé',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.text('Message corrigé'), findsOneWidget);
      expect(find.text('Modifié'), findsOneWidget);
      expect(repo.changesCount, 1);
    },
  );
  testWidgets(
    'suppression annulée puis confirmée laisse une trace sans ancien contenu',
    (tester) async {
      await open(tester);
      await action(tester, 'Supprimer');
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(repo.changesCount, 0);
      await action(tester, 'Supprimer');
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      expect(find.text('Message supprimé'), findsOneWidget);
      expect(find.text('Message initial'), findsNothing);
      expect(find.byKey(const ValueKey('message-actions-own')), findsNothing);
    },
  );
  testWidgets('contrat absent ou échange bloqué : aucune action de mutation', (
    tester,
  ) async {
    repo.available = false;
    await open(tester);
    expect(find.byTooltip('Actions du message'), findsNothing);
    repo.available = true;
    repo.blocked = true;
    await tester.tap(find.byTooltip('Actualiser les échanges'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Actions du message'), findsNothing);
  });
  testWidgets(
    'échec de modification conserve le message et explique la reprise',
    (tester) async {
      repo.failChange = true;
      await open(tester);
      await action(tester, 'Modifier');
      await tester.enterText(
        find.byKey(const ValueKey('edit-message-content')),
        'Correction',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.text('Message initial'), findsOneWidget);
      expect(find.textContaining('Modification non confirmée'), findsOneWidget);
      await action(tester, 'Modifier');
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('edit-message-content')),
            )
            .controller!
            .text,
        'Correction',
      );
    },
  );
  testWidgets(
    'déconnexion pendant l’édition masque le texte et désactive la sauvegarde',
    (tester) async {
      await open(tester);
      await action(tester, 'Modifier');
      auth.emit(null);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit-message-content')), findsNothing);
      expect(
        find.text('Session modifiée. Fermez ce formulaire.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Enregistrer'),
            )
            .onPressed,
        isNull,
      );
      expect(repo.changesCount, 0);
    },
  );
  testWidgets('session changée pendant la confirmation : aucune écriture', (
    tester,
  ) async {
    await open(tester);
    await action(tester, 'Supprimer');
    auth.emit(null);
    await tester.pump();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(repo.changesCount, 0);
    expect(find.text('Message initial'), findsNothing);
  });
  testWidgets(
    'conversation et édition sur petit écran sombre avec texte agrandi',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await open(tester);
      await action(tester, 'Modifier');
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('edit-message-content')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
