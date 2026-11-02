import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/profile/engagement_pages.dart';
import 'package:kibo/features/profile/engagement_repository.dart';
import '../support/auth_fake.dart';

class EngagementFake implements AccountEngagementRepository {
  bool admin = false, messages = true, comments = true;
  int saves = 0, replies = 0, reviews = 0;
  Object? error;
  Map<String, dynamic>? request;
  Completer<Map<String, dynamic>>? pending;
  List<Map<String, dynamic>> rows = [];
  String? action, note;
  @override
  Future<Map<String, dynamic>> preferences(
    String owner, {
    bool? messages,
    bool? comments,
  }) async {
    if (error != null) throw error!;
    if (pending != null) return pending!.future;
    if (messages != null) {
      this.messages = messages;
      this.comments = comments!;
      saves++;
    }
    return {'messages': this.messages, 'comments': this.comments};
  }

  @override
  Future<Map<String, dynamic>> tracking(String owner) async {
    if (error != null) throw error!;
    return {'request': request, 'events': <dynamic>[]};
  }

  @override
  Future<bool> canReview(String owner) async => admin;
  @override
  Future<List<Map<String, dynamic>>> queue(
    String owner,
    String status, {
    int offset = 0,
  }) async =>
      rows.where((r) => r['status'] == status).skip(offset).take(20).toList();
  @override
  Future<void> reply(String owner, int version, String note) async {
    if (error != null) throw error!;
    replies++;
    this.note = note;
    request = {...request!, 'status': 'pending'};
  }

  @override
  Future<void> review(
    String owner,
    Map<String, dynamic> request,
    String action,
    String note,
  ) async {
    if (error != null) throw error!;
    reviews++;
    this.action = action;
    this.note = note;
    rows = [];
  }
}

Map<String, dynamic> sampleRequest({String status = 'pending'}) => {
  'owner_id': 'peer',
  'version': 7,
  'name': 'Membre fictif',
  'status': status,
  'requested_at': '2026-11-01T10:00:00Z',
  'operator_note': 'Une précision fictive',
};
void main() {
  late FakeAuthRepository auth;
  late AuthController controller;
  late EngagementFake repo;
  setUp(() {
    auth = FakeAuthRepository()..identity = FakeAuthRepository.user;
    controller = AuthController(auth);
    repo = EngagementFake();
  });
  tearDown(() async {
    controller.dispose();
    await auth.dispose();
  });
  Future<void> open(WidgetTester tester, {bool preferences = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EngagementPage(
          controller: controller,
          repository: repo,
          preferences: preferences,
        ),
      ),
    );
    if (repo.pending == null) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('examen opérateur à 320 px et texte double reste utilisable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    repo.admin = true;
    repo.rows = [sampleRequest()];
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: EngagementPage(controller: controller, repository: repo),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Examiner la demande'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Examiner la demande'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Examiner la demande'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Annuler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(repo.reviews, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'préférences chargées, modifiées et confirmation seulement après sauvegarde',
    (tester) async {
      await open(tester, preferences: true);
      await tester.tap(find.text('Nouveaux messages'));
      await tester.pump();
      expect(repo.saves, 0);
      await tester.tap(find.text('Enregistrer les préférences'));
      await tester.pumpAndSettle();
      expect(repo.saves, 1);
      expect(repo.messages, false);
      expect(repo.comments, true);
      expect(find.textContaining('Préférences enregistrées'), findsOneWidget);
    },
  );
  testWidgets(
    'erreur initiale interdit écriture, reprise et saisie conservée après refus',
    (tester) async {
      repo.error = StateError('fixture');
      await open(tester, preferences: true);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Enregistrer les préférences'),
            )
            .onPressed,
        isNull,
      );
      repo.error = null;
      await tester.tap(find.text('Actualiser'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Commentaires et réponses'));
      await tester.pump();
      repo.error = StateError('fixture');
      await tester.tap(find.text('Enregistrer les préférences'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Enregistrement non confirmé'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'Commentaires et réponses'),
            )
            .value,
        false,
      );
      expect(repo.saves, 0);
    },
  );
  testWidgets('réponse du demandeur validée et état rechargé', (tester) async {
    repo.request = sampleRequest(status: 'needs_info');
    await open(tester);
    expect(find.text('Précisions demandées'), findsOneWidget);
    await tester.ensureVisible(find.text('Envoyer mes précisions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envoyer mes précisions'));
    await tester.pumpAndSettle();
    expect(repo.replies, 0);
    await tester.enterText(find.byType(TextField), 'Précisions fictives');
    await tester.tap(find.text('Envoyer mes précisions'));
    await tester.pumpAndSettle();
    expect(repo.replies, 1);
    expect(find.text('En attente'), findsOneWidget);
    expect(find.text('Espace opérateur'), findsNothing);
  });
  testWidgets(
    'administrateur : confirmation, note obligatoire et absence de suppression effective',
    (tester) async {
      repo.admin = true;
      repo.rows = [sampleRequest()];
      await open(tester);
      await tester.scrollUntilVisible(
        find.text('Examiner la demande'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Examiner la demande'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Aucun compte ne sera supprimé'),
        findsOneWidget,
      );
      await tester.tap(find.text('Confirmer la décision'));
      await tester.pumpAndSettle();
      expect(repo.reviews, 0);
      await tester.enterText(
        find.byType(TextFormField),
        'Examen fictif en cours',
      );
      await tester.tap(find.text('Confirmer la décision'));
      await tester.pumpAndSettle();
      expect(repo.reviews, 1);
      expect(repo.action, 'processing');
      expect(repo.note, 'Examen fictif en cours');
    },
  );
  testWidgets(
    'session A/B/A invalide définitivement les préférences tardives',
    (tester) async {
      repo.pending = Completer<Map<String, dynamic>>();
      await open(tester, preferences: true);
      auth.emit(const AuthIdentity(id: 'B'));
      await tester.pump();
      auth.emit(FakeAuthRepository.user);
      await tester.pump();
      repo.pending!.complete({'messages': false, 'comments': false});
      await tester.pumpAndSettle();
      expect(find.textContaining('Session modifiée'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);
    },
  );
  testWidgets('petit écran et texte agrandi restent sans débordement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.8)),
          child: child!,
        ),
        home: EngagementPage(
          controller: controller,
          repository: repo,
          preferences: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
