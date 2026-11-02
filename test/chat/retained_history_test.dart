import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/chat/chat_repository.dart';
import 'package:kibo/features/chat/chat_page.dart';
import 'package:kibo/features/comments/comments_repository.dart';
import '../support/auth_fake.dart';
import 'chat_widgets_test.dart' show EnhancedChatFake;

Map<String, dynamic> archivedThread() => {
  'id': 'thread',
  'listing_id': null,
  'buyer_id': 'test-user-a',
  'seller_id': null,
  'peer_deleted': true,
  'peer_name': 'Ancien nom privé',
  'last_content': 'Ancien aperçu privé',
  'title': 'Annonce retirée',
  'unread_count': 12,
};
Map<String, dynamic> archivedMessage() => {
  'id': 'message',
  'sender_id': null,
  'sender_deleted': true,
  'content': 'Ancien texte privé',
  'created_at': '2026-11-01T09:00:00Z',
};

class HistoryFake extends EnhancedChatFake {
  bool deleted = true;
  @override
  Future<Map<String, dynamic>> threadState(String owner, String id) async => {
    'peer_deleted': deleted,
    'blocked': false,
    'blocked_by_me': false,
  };
}

void main() {
  test(
    'projection supprimée accepte un survivant et retire nom, aperçu et faux non lus',
    () {
      final thread = ChatThread.fromJson(archivedThread());
      expect(thread.sellerId, isNull);
      expect(thread.listingId, isNull);
      expect(thread.peerName, 'Compte supprimé');
      expect(thread.lastContent, isNull);
      expect(thread.blocked, true);
      expect(thread.unreadCount, 0);
      expect(
        () => ChatThread.fromJson({...archivedThread(), 'buyer_id': null}),
        throwsFormatException,
      );
      expect(
        () => ChatThread.fromJson({...archivedThread(), 'peer_deleted': false}),
        throwsFormatException,
      );
    },
  );
  test('auteur supprimé ne réaffiche jamais un ancien contenu brut', () {
    final message = ChatMessage.fromJson(archivedMessage());
    expect(message.senderId, isNull);
    expect(message.content, 'Message anonymisé');
    expect(
      () =>
          ChatMessage.fromJson({...archivedMessage(), 'sender_deleted': false}),
      throwsFormatException,
    );
    expect(
      () => ChatMessage.fromJson({
        ...archivedMessage(),
        'sender_id': 'old-identity',
      }),
      throwsFormatException,
    );
  });
  test(
    'commentaire supprimé conserve le contexte sans auteur ni ancien texte',
    () {
      final row = {
        'id': 'comment',
        'user_id': null,
        'author_deleted': true,
        'content': 'Ancien texte privé',
        'status': 'published',
        'deleted_at': null,
        'parent_id': 'parent',
        'created_at': '2026-11-01T09:00:00Z',
      };
      final comment = ListingComment.fromJson(row);
      expect(comment.userId, isNull);
      expect(comment.content, 'Commentaire anonymisé');
      expect(comment.parentId, 'parent');
      expect(
        () => ListingComment.fromJson({...row, 'author_deleted': false}),
        throwsFormatException,
      );
    },
  );
  test('ancien contrat actif conserve son auteur et son texte', () {
    final message = ChatMessage.fromJson({
      ...archivedMessage(),
      'sender_id': 'active',
      'sender_deleted': false,
      'content': 'Texte actif',
    });
    expect(message.senderId, 'active');
    expect(message.content, 'Texte actif');
  });
  late FakeAuthRepository auth;
  late HistoryFake repo;
  setUp(() {
    auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    repo = HistoryFake();
  });
  tearDown(() async {
    await auth.dispose();
    await repo.updates.close();
  });
  testWidgets('historique lisible sans champ, envoi ou bouton de déblocage', (
    tester,
  ) async {
    repo.items = [
      ChatMessage.fromJson(archivedMessage()),
      ChatMessage(
        id: 'own',
        senderId: 'test-user-a',
        content: 'Ma contribution conservée',
        createdAt: DateTime(2026, 11, 1),
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: AuthSession(
          repository: auth,
          child: ChatPage(
            repository: repo,
            ownerId: 'test-user-a',
            thread: ChatThread.fromJson(archivedThread()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Historique en lecture seule'), findsOneWidget);
    expect(find.text('Message anonymisé'), findsOneWidget);
    expect(find.text('Ma contribution conservée'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Envoyer'), findsNothing);
    expect(find.byTooltip('Bloquer cet interlocuteur'), findsNothing);
    expect(repo.sends, 0);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'état supprimé reçu pendant une conversation active efface le brouillon et reste irréversible',
    (tester) async {
      repo.deleted = false;
      final active = ChatThread(
        id: 'thread',
        listingId: 'listing',
        buyerId: 'test-user-a',
        sellerId: 'peer',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: AuthSession(
            repository: auth,
            child: ChatPage(
              repository: repo,
              ownerId: 'test-user-a',
              thread: active,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Brouillon privé');
      repo.deleted = true;
      repo.items = [
        ChatMessage(
          id: 'stale',
          senderId: 'peer',
          content: 'Ancien cache privé',
          createdAt: DateTime(2026, 11, 1),
        ),
      ];
      await tester.tap(find.byTooltip('Actualiser les échanges'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Brouillon privé'), findsNothing);
      expect(find.text('Ancien cache privé'), findsNothing);
      expect(find.text('Message anonymisé'), findsOneWidget);
      repo.deleted = false;
      await tester.tap(find.byTooltip('Actualiser les échanges'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(repo.sends, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
