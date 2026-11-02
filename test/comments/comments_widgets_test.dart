import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/comments/comments_repository.dart';
import 'package:kibo/features/comments/comments_page.dart';
import 'package:kibo/features/listings/listing_detail_page.dart';
import '../support/auth_fake.dart';
import '../support/listing_fake.dart';
import '../support/supabase_fakes.dart';
import '../support/guest_favorites_fake.dart';
import 'package:kibo/main.dart';
import 'package:kibo/core/supabase/supabase_service.dart';

class _Comments extends Fake implements CommentsRepository {
  @override
  String? userId = FakeAuthRepository.user.id;
  Object? failure;
  Completer<void>? pending;
  int creates = 0;
  String? sentParent;
  List<ListingComment> rows = [];
  @override
  Future<List<ListingComment>> read(
    String listingId, {
    String? parentId,
    int offset = 0,
  }) async {
    if (failure != null) throw failure!;
    return rows
        .where((r) => r.parentId == parentId)
        .skip(offset)
        .take(20)
        .toList();
  }

  @override
  Future<void> create(
    String listingId,
    String content, {
    required String expectedUserId,
    String? parentId,
  }) async {
    creates++;
    sentParent = parentId;
    await pending?.future;
    if (failure != null) throw failure!;
    rows.add(
      ListingComment(
        id: 'comment-$creates',
        userId: expectedUserId,
        content: content.trim(),
        parentId: parentId,
        createdAt: DateTime(2026, 11, 1),
      ),
    );
  }
}

void main() {
  late FakeAuthRepository auth;
  late _Comments repository;
  setUp(() {
    auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    repository = _Comments();
  });
  tearDown(() => auth.dispose());
  Future<void> open(WidgetTester tester, {bool detail = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthSession(
          repository: auth,
          child: detail
              ? ListingDetailPage(
                  id: 'listing-a',
                  repository: FakeListingRepository(),
                  comments: repository,
                )
              : CommentsPage(listingId: 'listing-a', repository: repository),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final fromFavorites in [false, true]) {
    testWidgets(
      'navigation ${fromFavorites ? 'favoris' : 'catalogue'} vers discussion garde la session',
      (tester) async {
        final client = createTestClient();
        addTearDown(client.dispose);
        final favorites = FakeFavoritesRepository()..saved = {'listing-a'};
        await tester.pumpWidget(
          KiboApp(
            supabase: SupabaseService(
              config: testConfig,
              initializer: (_) async => client,
            ),
            authRepository: auth,
            listingRepository: FakeListingRepository(),
            favoritesRepository: favorites,
            guestFavoritesStore: MemoryGuestFavoritesStore(),
            commentsRepository: repository,
          ),
        );
        await tester.pumpAndSettle();
        if (fromFavorites) {
          await tester.tap(find.text('Favoris'));
          await tester.pumpAndSettle();
        }
        await tester.scrollUntilVisible(
          find.text('Smartphone Android'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Smartphone Android'));
        if (!fromFavorites) {
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -180),
          );
        }
        await tester.pumpAndSettle();
        await tester.tap(find.text('Smartphone Android'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Commentaires et réponses'));
        await tester.tap(find.text('Commentaires et réponses'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('comment-content')), findsOneWidget);
        expect(find.textContaining('Connectez-vous'), findsNothing);
      },
    );
  }

  testWidgets('discussion sur 320 px et texte 150 % avec clavier', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester);
    await tester.enterText(
      find.byKey(const ValueKey('comment-content')),
      'Texte accessible',
    );
    await tester.ensureVisible(find.text('Publier le commentaire'));
    await tester.tap(find.text('Publier le commentaire'));
    await tester.pumpAndSettle();
    expect(find.text('Commentaire publié.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('visiteur consulte et ne voit pas le formulaire', (tester) async {
    auth.identity = null;
    repository.rows = [
      ListingComment(
        id: 'root',
        userId: 'member',
        content: 'Bonjour public',
        createdAt: DateTime(2026),
      ),
    ];
    await open(tester);
    expect(find.text('Bonjour public'), findsOneWidget);
    expect(find.text('Membre · 01/01/2026'), findsOneWidget);
    expect(find.byKey(const ValueKey('comment-content')), findsNothing);
    expect(find.textContaining('Connectez-vous'), findsOneWidget);
    expect(repository.creates, 0);
  });
  testWidgets(
    'detail ouvre commentaires avec la session existante puis publication',
    (tester) async {
      await open(tester, detail: true);
      await tester.ensureVisible(find.text('Commentaires et réponses'));
      await tester.tap(find.text('Commentaires et réponses'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('comment-content')),
        'Commentaire de recette',
      );
      await tester.tap(find.text('Publier le commentaire'));
      await tester.pumpAndSettle();
      expect(find.text('Commentaire publié.'), findsOneWidget);
      expect(find.text('Commentaire de recette'), findsOneWidget);
    },
  );
  testWidgets('reponse ouverte sur parent racine, sans niveau supplementaire', (
    tester,
  ) async {
    repository.rows = [
      ListingComment(
        id: 'root',
        userId: 'member',
        content: 'Question publique',
        createdAt: DateTime(2026),
      ),
    ];
    await open(tester);
    await tester.tap(find.text('Voir les réponses'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('comment-content')),
      'Une réponse',
    );
    await tester.tap(find.text('Publier la réponse'));
    await tester.pumpAndSettle();
    expect(repository.sentParent, 'root');
    expect(find.text('Une réponse'), findsOneWidget);
    expect(find.text('Voir les réponses'), findsNothing);
  });
  testWidgets('validation et erreur gardent le texte sans faux succes', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Publier le commentaire'));
    await tester.pumpAndSettle();
    expect(repository.creates, 0);
    await tester.enterText(
      find.byKey(const ValueKey('comment-content')),
      'Texte conservé',
    );
    repository.failure = Exception('private');
    await tester.tap(find.text('Publier le commentaire'));
    await tester.pumpAndSettle();
    expect(find.text('Texte conservé'), findsOneWidget);
    expect(find.textContaining('Publication non confirmée'), findsOneWidget);
    expect(find.textContaining('private'), findsNothing);
  });
  testWidgets(
    'double envoi/retour bloques, changement de compte efface le brouillon et ignore le retour',
    (tester) async {
      await open(tester);
      repository.pending = Completer<void>();
      await tester.enterText(
        find.byKey(const ValueKey('comment-content')),
        'Texte A',
      );
      await tester.tap(find.text('Publier le commentaire'));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Publication…'),
            )
            .onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Commentaires'), findsOneWidget);
      repository.userId = 'user-b';
      auth.emit(const AuthIdentity(id: 'user-b'));
      await tester.pump();
      repository.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Texte A'), findsNothing);
      expect(find.text('Commentaire publié.'), findsNothing);
      expect(repository.creates, 1);
    },
  );
  testWidgets('pagination et lecture en erreur puis reprise', (tester) async {
    repository.failure = Exception('offline');
    await open(tester);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    repository.failure = null;
    repository.rows = List.generate(
      21,
      (i) => ListingComment(
        id: 'c$i',
        userId: 'm',
        content: 'Message $i',
        createdAt: DateTime(2026),
      ),
    );
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Voir plus'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Voir plus'));
    await tester.pumpAndSettle();
    expect(find.text('Voir plus'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
