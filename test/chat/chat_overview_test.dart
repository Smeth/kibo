import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/chat/chat_overview.dart';
import 'package:kibo/features/chat/chat_repository.dart';
import 'package:kibo/features/chat/blocked_users_page.dart';
import '../support/auth_fake.dart';
import 'chat_widgets_test.dart' show EnhancedChatFake;

class OverviewFake extends EnhancedChatFake {
  int calls = 0, unblocks = 0;
  Completer<List<ChatThread>>? pendingRead;
  @override
  Future<List<ChatThread>> threads(String owner, {int offset = 0}) async {
    calls++;
    if (pendingRead != null) return pendingRead!.future;
    if (error != null) throw error!;
    return rows.skip(offset).take(20).toList();
  }

  @override
  Future<void> setBlocked(String owner, String id, bool value) async {
    if (sendError != null) throw sendError!;
    unblocks++;
    rows = [];
  }
}

ChatThread row(int i, {bool blocked = false}) => ChatThread(
  id: 't$i',
  listingId: 'l$i',
  buyerId: 'test-user-a',
  sellerId: 'peer',
  peerName: 'Vendeur fictif',
  unreadCount: 2,
  blocked: blocked,
  blockedByMe: blocked,
);

void main() {
  late FakeAuthRepository auth;
  late AuthController controller;
  late OverviewFake repo;
  setUp(() {
    auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    controller = AuthController(auth);
    repo = OverviewFake();
  });
  tearDown(() async {
    controller.dispose();
    await auth.dispose();
    await repo.updates.close();
  });
  Future<void> open(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: AuthScope(controller: controller, child: child),
    ),
  );
  testWidgets('lecteur d’écran distingue zéro et compteur indisponible', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      repo.rows = [];
      await open(tester, ChatEntry(repository: repo, onPressed: () {}));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('chat-unread-state')))
            .getSemanticsData()
            .value,
        '0 message(s) non lu(s)',
      );
      repo.error = StateError('fixture');
      await open(
        tester,
        ChatEntry(repository: repo, onPressed: () {}, revision: 1),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('chat-unread-state')))
            .getSemanticsData()
            .value,
        'Compteur indisponible',
      );
      await tester.pumpWidget(const SizedBox());
    } finally {
      semantics.dispose();
    }
  });
  test('lit toutes les pages et déduplique les conversations', () async {
    repo.rows = List.generate(21, row);
    final rows = await allChatThreads(repo, 'test-user-a');
    expect(rows, hasLength(21));
    expect(repo.calls, 2);
    repo.userId = 'B';
    await expectLater(allChatThreads(repo, 'test-user-a'), throwsStateError);
  });
  testWidgets('compteur au-delà des vingt premières et ouverture', (
    tester,
  ) async {
    repo.rows = List.generate(21, row);
    var opens = 0;
    await open(tester, ChatEntry(repository: repo, onPressed: () => opens++));
    await tester.pumpAndSettle();
    expect(find.text('42'), findsOneWidget);
    await tester.tap(find.text('Messages'));
    expect(opens, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('compteur tardif ignoré après changement de compte A/B/A', (
    tester,
  ) async {
    repo.pendingRead = Completer<List<ChatThread>>();
    final oldRead = repo.pendingRead!;
    await open(tester, ChatEntry(repository: repo, onPressed: () {}));
    await tester.pump();
    auth.emit(const AuthIdentity(id: 'B'));
    repo.userId = 'B';
    repo.pendingRead = null;
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    auth.emit(FakeAuthRepository.user);
    repo.userId = 'test-user-a';
    repo.rows = [row(1)];
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    oldRead.complete(List.generate(20, row));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(
      find.text('2'),
      findsOneWidget,
      reason:
          'calls=${repo.calls} auth=${controller.identity?.id} repo=${repo.userId}; ${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList()}',
    );
    expect(find.text('40'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('blocages dédupliqués, annulation puis déblocage confirmé', (
    tester,
  ) async {
    repo.rows = [row(0, blocked: true), row(1, blocked: true), row(2)];
    await open(
      tester,
      BlockedUsersPage(repository: repo, controller: controller),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vendeur fictif'), findsOneWidget);
    await tester.tap(find.text('Débloquer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(repo.unblocks, 0);
    await tester.tap(find.text('Débloquer'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Débloquer'));
    await tester.pumpAndSettle();
    expect(repo.unblocks, 1);
    expect(find.text('Aucun interlocuteur bloqué.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'erreur déblocage conserve la liste et changement de session masque les noms',
    (tester) async {
      repo.rows = [row(0, blocked: true)];
      repo.sendError = StateError('fixture');
      await open(
        tester,
        BlockedUsersPage(repository: repo, controller: controller),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Débloquer'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Débloquer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Déblocage non confirmé'), findsOneWidget);
      expect(repo.unblocks, 0);
      auth.emit(const AuthIdentity(id: 'B'));
      await tester.pumpAndSettle();
      expect(find.text('Vendeur fictif'), findsNothing);
      expect(find.textContaining('Session modifiée'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
