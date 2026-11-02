import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/chat/chat_repository.dart';
import 'package:kibo/features/chat/chat_page.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_page.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/listings/listing_detail_page.dart';
import 'package:kibo/features/listings/listing_models.dart';
import '../support/auth_fake.dart';
import '../support/listing_fake.dart';
import 'package:kibo/main.dart';
import 'package:kibo/core/theme/kibo_theme.dart';

const thread = ChatThread(
  id: 'thread',
  listingId: 'listing',
  buyerId: 'test-user-a',
  sellerId: 'seller',
  title: 'Annonce fictive',
);

class ChatFake implements ChatRepository {
  @override
  String? userId = 'test-user-a';
  final updates = StreamController<void>.broadcast();
  List<ChatThread> rows = [thread];
  List<ChatMessage> items = [];
  Object? error, sendError;
  int sends = 0, starts = 0, reads = 0;
  Completer<void>? pending;
  @override
  Future<List<ChatThread>> threads(String owner, {int offset = 0}) async {
    if (error != null) throw error!;
    return offset == 0 ? rows : [];
  }

  @override
  Future<ChatThread> start(
    String owner,
    String listingId,
    String sellerId,
  ) async {
    starts++;
    if (error != null) throw error!;
    return thread;
  }

  @override
  Future<List<ChatMessage>> messages(
    String owner,
    String id, {
    int offset = 0,
  }) async {
    reads++;
    if (error != null) throw error!;
    return offset == 0 ? List.of(items) : [];
  }

  @override
  Future<void> send(String owner, String id, String content) async {
    sends++;
    await pending?.future;
    if (sendError != null) throw sendError!;
    items.insert(
      0,
      ChatMessage(
        id: 'm$sends',
        senderId: owner,
        content: content.trim(),
        createdAt: DateTime(2026, 11, 1),
      ),
    );
  }

  @override
  Stream<void> changes(String owner, {String? threadId}) => updates.stream;
}

class EnhancedChatFake extends ChatFake implements ChatEnhancements {
  int marks = 0;
  bool blocked = false;
  final operationIds = <String>[];
  @override
  Future<Map<String, dynamic>> threadState(String owner, String id) async => {
    'blocked': blocked,
    'blocked_by_me': blocked,
  };
  @override
  Future<void> markRead(String owner, String id, DateTime through) async {
    marks++;
  }

  @override
  Future<void> setBlocked(String owner, String id, bool value) async {
    blocked = value;
  }

  @override
  Future<void> sendOnce(
    String owner,
    String id,
    String content,
    String operationId,
  ) async {
    operationIds.add(operationId);
    await send(owner, id, content);
  }
}

void main() {
  late FakeAuthRepository auth;
  late ChatFake repo;
  setUp(() {
    auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    repo = ChatFake();
  });
  tearDown(() async {
    await auth.dispose();
    await repo.updates.close();
  });
  Future<void> open(
    WidgetTester tester, {
    ChatThread? conversation,
    Widget? child,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: AuthSession(
          repository: auth,
          child:
              child ??
              ChatPage(
                repository: repo,
                ownerId: 'test-user-a',
                thread: conversation,
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('liste et ouverture de conversation puis vide', (tester) async {
    await open(tester);
    expect(find.text('Annonce fictive'), findsOneWidget);
    await tester.tap(find.text('Annonce fictive'));
    await tester.pumpAndSettle();
    expect(find.text('Dites bonjour !'), findsOneWidget);
    expect(find.text('Votre message'), findsOneWidget);
  });
  testWidgets('liste vide et erreur recuperable', (tester) async {
    repo.error = Exception('offline');
    await open(tester);
    expect(find.textContaining('Impossible de charger'), findsOneWidget);
    repo.error = null;
    repo.rows = [];
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucune conversation.'), findsOneWidget);
  });
  testWidgets('validation et envoi confirme affiche le message', (
    tester,
  ) async {
    await open(tester, conversation: thread);
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(repo.sends, 0);
    await tester.enterText(find.byType(TextFormField), 'Bonjour fictif');
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(repo.sends, 1);
    expect(find.text('Bonjour fictif'), findsOneWidget);
    expect(find.text('Vous'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      isEmpty,
    );
  });
  testWidgets('echec conserve le brouillon et ne retente pas', (tester) async {
    repo.sendError = Exception('offline');
    await open(tester, conversation: thread);
    await tester.enterText(find.byType(TextFormField), 'Brouillon');
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Envoi non confirmé'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Brouillon',
    );
    expect(repo.sends, 1);
  });
  testWidgets('double envoi bloque et session A B A efface les donnees', (
    tester,
  ) async {
    repo.pending = Completer<void>();
    await open(tester, conversation: thread);
    await tester.enterText(find.byType(TextFormField), 'Privé');
    await tester.tap(find.text('Envoyer'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byWidgetPredicate((widget) => widget is FilledButton),
          )
          .onPressed,
      isNull,
    );
    auth.emit(const AuthIdentity(id: 'B'));
    auth.emit(FakeAuthRepository.user);
    await tester.pump();
    repo.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Session modifiée'), findsOneWidget);
    expect(find.text('Privé'), findsNothing);
    expect(repo.sends, 1);
  });
  testWidgets('actualisation fusionne sans doubler et detruit abonnement', (
    tester,
  ) async {
    await open(tester, conversation: thread);
    repo.items = [
      ChatMessage(
        id: 'one',
        senderId: 'seller',
        content: 'Réponse fictive',
        createdAt: DateTime(2026),
      ),
    ];
    repo.updates.add(null);
    await tester.pumpAndSettle();
    repo.updates.add(null);
    await tester.pumpAndSettle();
    expect(find.text('Réponse fictive'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(repo.updates.hasListener, false);
  });
  testWidgets('visiteur ne lit ni ne cree de conversation', (tester) async {
    auth.identity = null;
    repo.userId = null;
    await open(
      tester,
      child: ListingDetailPage(
        id: 'listing',
        repository: FakeListingRepository()
          ..listings = const [
            PublicListing(
              id: 'listing',
              title: 'Annonce test',
              description: 'Description fictive',
              price: '1000',
              city: 'Brazzaville',
              sellerId: 'seller',
            ),
          ],
        chats: repo,
      ),
    );
    await tester.ensureVisible(find.byTooltip('Écrire au vendeur'));
    await tester.tap(find.byTooltip('Écrire au vendeur'));
    await tester.pumpAndSettle();
    expect(repo.starts, 0);
    expect(find.byType(AuthPage), findsOneWidget);
  });
  testWidgets('petit ecran texte agrandi sans debordement', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
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
    expect(tester.takeException(), isNull);
  });
  testWidgets('accueil relie Mes messages sur petit ecran', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(
      tester,
      child: KiboHomePage(repository: FakeListingRepository(), chats: repo),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Mes messages'));
    await tester.pumpAndSettle();
    expect(find.text('Annonce fictive'), findsOneWidget);
  });
  testWidgets('messages precedents pagines puis fin', (tester) async {
    repo.items = List.generate(
      30,
      (i) => ChatMessage(
        id: 'm$i',
        senderId: 'seller',
        content: 'Message $i',
        createdAt: DateTime(2026, 1, 1, 0, i),
      ),
    );
    await open(tester, conversation: thread);
    await tester.dragUntilVisible(
      find.text('Messages précédents'),
      find.byType(ListView),
      const Offset(0, 600),
    );
    await tester.tap(find.text('Messages précédents'));
    await tester.pumpAndSettle();
    expect(find.text('Messages précédents'), findsNothing);
    expect(repo.reads, 2);
  });
  testWidgets('lecture visible marque les messages et blocage empeche envoi', (
    tester,
  ) async {
    final enhanced = EnhancedChatFake()
      ..items = [
        ChatMessage(
          id: 'incoming',
          senderId: 'seller',
          content: 'Message reçu',
          createdAt: DateTime(2026),
        ),
      ];
    repo = enhanced;
    await open(tester, conversation: thread);
    expect(enhanced.marks, 1);
    await tester.tap(find.byTooltip('Bloquer cet interlocuteur'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(enhanced.blocked, true);
    expect(find.textContaining('sont bloqués'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('retry apres echec reutilise le meme identifiant', (
    tester,
  ) async {
    final enhanced = EnhancedChatFake()..sendError = Exception('offline');
    repo = enhanced;
    await open(tester, conversation: thread);
    await tester.enterText(find.byType(TextFormField), 'Message stable');
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    enhanced.sendError = null;
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(enhanced.operationIds.length, 2);
    expect(enhanced.operationIds.toSet().length, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('arriere plan libere abonnement et reprise reconnecte', (
    tester,
  ) async {
    await open(tester, conversation: thread);
    expect(repo.updates.hasListener, true);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    expect(repo.updates.hasListener, false);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(repo.updates.hasListener, true);
  });
}
