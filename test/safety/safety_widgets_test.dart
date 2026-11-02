import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/chat/chat_repository.dart';
import 'package:kibo/features/safety/safety_repository.dart';
import 'package:kibo/features/safety/safety_page.dart';
import 'package:kibo/features/safety/safety_entry.dart';
import 'package:kibo/features/listings/listing_detail_page.dart';
import '../support/auth_fake.dart';
import '../support/listing_fake.dart';
import 'package:kibo/main.dart';

class SafetyFake implements SafetyRepository {
  @override
  String? userId = 'test-user-a';
  bool admin = false, unread = false;
  Object? error;
  int reads = 0, marks = 0, sends = 0, reviews = 0, counts = 0;
  int unreadValue = 100;
  String? decision;
  Completer<void>? pending;
  List<AppNotice> notices = const [
    AppNotice(
      id: 'n',
      title: 'Nouveau message',
      body: 'Notification fictive',
      data: {'conversation_id': 't'},
    ),
  ];
  List<ContentReport> reportRows = const [
    ContentReport(
      id: 'r',
      reason: 'Motif fictif',
      status: 'pending',
      listingId: 'listing-a',
      details: 'Détails fictifs',
    ),
  ];
  @override
  Future<List<AppNotice>> notifications(
    String owner, {
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    reads++;
    unread = unreadOnly;
    if (error != null) throw error!;
    return offset == 0 ? notices : [];
  }

  @override
  Future<int> unreadCount(String owner) async {
    counts++;
    return unreadValue;
  }

  @override
  Future<void> markRead(String owner, String id) async {
    marks++;
    if (error != null) throw error!;
    unreadValue = 0;
  }

  @override
  Future<void> report(
    String owner, {
    String? listingId,
    String? commentId,
    required String reason,
    required String details,
  }) async {
    sends++;
    await pending?.future;
    if (error != null) throw error!;
  }

  @override
  Future<bool> canModerate(String owner) async => admin;
  @override
  Future<List<ContentReport>> reports(
    String owner, {
    required String status,
    int offset = 0,
  }) async {
    reads++;
    return offset == 0 ? reportRows : [];
  }

  @override
  Future<List<ModerationRecord>> history(String owner, String id) async => [];
  @override
  Future<Map<String, dynamic>?> content(String owner, String id) async => {
    'title': 'Contenu fictif',
    'content': 'Description à examiner',
    'status': 'published',
  };
  @override
  Future<void> review(
    String owner,
    String id,
    String action,
    String reason,
  ) async {
    reviews++;
    decision = action;
    if (error != null) throw error!;
    reportRows = [];
  }

  @override
  Future<ChatThread?> conversation(String owner, String id) async => null;
}

void main() {
  late SafetyFake repo;
  late FakeAuthRepository auth;
  setUp(() {
    repo = SafetyFake();
    auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
  });
  tearDown(() => auth.dispose());
  Future<void> open(
    WidgetTester tester,
    SafetyScreen screen, {
    Future<void> Function(AppNotice)? onOpen,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: AuthSession(
          repository: auth,
          child: SafetyPage(
            repository: repo,
            ownerId: 'test-user-a',
            screen: screen,
            listingId: screen == SafetyScreen.report ? 'listing-a' : null,
            onOpenNotice: onOpen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseReason(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(reportReasons.first).last);
    await tester.pumpAndSettle();
  }

  testWidgets('affichage filtre et ouverture apres marquage lu', (
    tester,
  ) async {
    var opens = 0;
    await open(
      tester,
      SafetyScreen.notifications,
      onOpen: (_) async {
        opens++;
      },
    );
    expect(find.text('Nouveau message'), findsOneWidget);
    await tester.tap(find.text('Non lues uniquement'));
    await tester.pumpAndSettle();
    expect(repo.unread, true);
    await tester.tap(find.text('Nouveau message'));
    await tester.pumpAndSettle();
    expect(repo.marks, 1);
    expect(opens, 1);
  });
  testWidgets('notifications erreur reprise puis vide', (tester) async {
    repo.error = Exception('offline');
    await open(tester, SafetyScreen.notifications);
    expect(find.textContaining('Chargement impossible'), findsOneWidget);
    repo.error = null;
    repo.notices = [];
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aucune notification'), findsOneWidget);
  });
  testWidgets('signalement motif obligatoire et succes explicite', (
    tester,
  ) async {
    await open(tester, SafetyScreen.report);
    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pumpAndSettle();
    expect(repo.sends, 0);
    await chooseReason(tester);
    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pumpAndSettle();
    expect(repo.sends, 1);
    expect(find.textContaining('Signalement envoyé.'), findsOneWidget);
  });
  testWidgets('echec signalement conserve precisions sans retry', (
    tester,
  ) async {
    repo.error = Exception('offline');
    await open(tester, SafetyScreen.report);
    await chooseReason(tester);
    await tester.enterText(find.byType(TextFormField), 'Texte fictif');
    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Signalement non confirmé'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'Texte fictif',
    );
    expect(repo.sends, 1);
  });
  testWidgets('envoi bloque double clic et A B A invalide le formulaire', (
    tester,
  ) async {
    repo.pending = Completer<void>();
    await open(tester, SafetyScreen.report);
    await chooseReason(tester);
    await tester.enterText(find.byType(TextFormField), 'Privé');
    await tester.tap(find.text('Envoyer le signalement'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byWidgetPredicate((w) => w is FilledButton),
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
  testWidgets(
    'passer d’une annonce à un message réinitialise la décision et exclut le masquage',
    (tester) async {
      repo.admin = true;
      repo.reportRows = [
        repo.reportRows.first,
        const ContentReport(
          id: 'message-report',
          reason: 'Message abusif fictif',
          status: 'pending',
          messageId: 'message-fixture',
        ),
      ];
      await open(tester, SafetyScreen.moderation);
      await tester.tap(find.text('Motif fictif'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<String>).last,
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Masquer le contenu').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Retour aux signalements'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Retour aux signalements'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Message abusif fictif'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<String>).last,
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      expect(find.text('Masquer le contenu'), findsNothing);
      expect(find.text('Rejeter le signalement'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('moderation refuse le membre ordinaire sans lire la file', (
    tester,
  ) async {
    await open(tester, SafetyScreen.moderation);
    expect(find.textContaining('Accès réservé'), findsOneWidget);
    expect(repo.reads, 0);
  });
  testWidgets('decision admin exige motif confirmation puis cloture', (
    tester,
  ) async {
    repo.admin = true;
    await open(tester, SafetyScreen.moderation);
    await tester.tap(find.text('Motif fictif'));
    await tester.pumpAndSettle();
    expect(find.text('Description à examiner'), findsOneWidget);
    await tester.ensureVisible(find.text('Appliquer la décision'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appliquer la décision'));
    await tester.pumpAndSettle();
    expect(repo.reviews, 0);
    await tester.enterText(
      find.byType(TextFormField),
      'Motif de décision fictif',
    );
    await tester.ensureVisible(find.text('Appliquer la décision'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appliquer la décision'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmer la décision'), findsOneWidget);
    expect(repo.reviews, 0);
    await tester.tap(find.text('Confirmer'));
    await tester.pumpAndSettle();
    expect(repo.reviews, 1);
    expect(find.text('Aucun signalement dans cet état.'), findsOneWidget);
  });
  testWidgets('compteur borne et moderation visibles selon permission', (
    tester,
  ) async {
    repo.admin = true;
    await tester.pumpWidget(
      MaterialApp(
        home: AuthSession(
          repository: auth,
          child: Scaffold(
            body: Column(
              children: [
                SafetyEntry(repository: repo, onPressed: () {}),
                SafetyEntry(
                  repository: repo,
                  moderation: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('99+'), findsOneWidget);
    expect(find.text('Modération'), findsOneWidget);
    auth.emit(null);
    await tester.pumpAndSettle();
    expect(find.text('99+'), findsNothing);
    expect(find.text('Modération'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('visiteur peut lire annonce mais signalement invite connexion', (
    tester,
  ) async {
    auth.identity = null;
    repo.userId = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: AuthSession(
          repository: auth,
          child: ListingDetailPage(
            id: 'listing-a',
            repository: FakeListingRepository(),
            safety: repo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Signaler cette annonce'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Signaler cette annonce'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Connectez-vous depuis Profil'), findsOneWidget);
    expect(repo.sends, 0);
  });
  testWidgets('formulaire 320px et texte agrandi reste accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: AuthSession(
          repository: auth,
          child: SafetyPage(
            repository: repo,
            ownerId: 'test-user-a',
            screen: SafetyScreen.report,
            listingId: 'l',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('lecture echouee ne declenche pas la navigation', (tester) async {
    var opened = 0;
    await open(
      tester,
      SafetyScreen.notifications,
      onOpen: (_) async {
        opened++;
      },
    );
    repo.error = Exception('offline');
    await tester.tap(find.text('Nouveau message'));
    await tester.pumpAndSettle();
    expect(opened, 0);
    expect(
      find.textContaining('Ouverture ou lecture non confirmée'),
      findsOneWidget,
    );
  });
  testWidgets('compteur accueil actualise immediatement au retour', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: AuthSession(
          repository: auth,
          child: KiboHomePage(
            repository: FakeListingRepository(),
            safety: repo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('99+'), findsOneWidget);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouveau message'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('99+'), findsNothing);
    expect(repo.counts, greaterThan(1));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('annulation de decision necrit rien', (tester) async {
    repo.admin = true;
    await open(tester, SafetyScreen.moderation);
    await tester.tap(find.text('Motif fictif'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Motif fictif');
    await tester.ensureVisible(find.text('Appliquer la décision'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appliquer la décision'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(repo.reviews, 0);
    expect(find.text('Description à examiner'), findsOneWidget);
  });
}
