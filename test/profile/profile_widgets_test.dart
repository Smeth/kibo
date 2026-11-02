import '../support/listing_fake.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/profile/edit_profile_page.dart';
import 'package:kibo/main.dart';

import '../support/auth_fake.dart';
import '../support/manrope_fonts.dart';
import '../support/supabase_fakes.dart';

void main() {
  setUpAll(loadManropeFonts);
  late FakeAuthRepository repository;
  setUp(() {
    repository = FakeAuthRepository()..identity = FakeAuthRepository.user;
  });
  tearDown(() async {
    await repository.dispose();
  });
  Future<void> openEditor(
    WidgetTester tester, {
    VoidCallback? beforeEditorBuild,
  }) async {
    final client = createTestClient();
    addTearDown(client.dispose);
    await tester.pumpWidget(
      KiboApp(
        listingRepository: FakeListingRepository(),
        favoritesRepository: FakeFavoritesRepository(),
        supabase: SupabaseService(
          config: testConfig,
          initializer: (_) async => client,
        ),
        authRepository: repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier mon profil'));
    beforeEditorBuild?.call();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'session fermée pendant l’ouverture du formulaire : aucun crash',
    (tester) async {
      await openEditor(tester, beforeEditorBuild: () => repository.emit(null));
      expect(find.textContaining('Votre session a changé'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(repository.profileSaveCalls, 0);
    },
  );

  testWidgets('champs préremplis, validation, sauvegarde et retour au profil', (
    tester,
  ) async {
    await openEditor(tester);
    expect(find.text('Profil test'), findsOneWidget);
    expect(find.text('Brazzaville'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('profile-city')), '  ');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Renseignez votre ville.'), findsOneWidget);
    expect(repository.profileSaveCalls, 0);
    await tester.enterText(
      find.byKey(const ValueKey('profile-full-name')),
      'Nom modifié',
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-city')),
      'Dolisie',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfilePage), findsNothing);
    expect(find.text('Nom modifié'), findsOneWidget);
    expect(find.text('Dolisie'), findsOneWidget);
    expect(find.text('Profil mis à jour.'), findsOneWidget);
    await tester.tap(find.text('Modifier mon profil'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-city')),
      'Abandon',
    );
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Dolisie'), findsOneWidget);
    expect(repository.profileSaveCalls, 1);
  });
  testWidgets(
    'chargement, refus puis nouvelle tentative sans perdre la saisie',
    (tester) async {
      final pending = Completer<KiboProfile>();
      repository.profileSaver = () => pending.future;
      await openEditor(tester);
      await tester.enterText(
        find.byKey(const ValueKey('profile-city')),
        'Ville saisie',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('profile-city')))
            .enabled,
        isFalse,
      );
      pending.completeError(StateError('réponse privée'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Impossible d’enregistrer'), findsOneWidget);
      expect(find.textContaining('privée'), findsNothing);
      expect(find.text('Ville saisie'), findsOneWidget);
      repository.profileSaver = null;
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfilePage), findsNothing);
      expect(find.text('Ville saisie'), findsOneWidget);
    },
  );
  testWidgets('changement de compte masque la saisie du précédent', (
    tester,
  ) async {
    await openEditor(tester);
    await tester.enterText(
      find.byKey(const ValueKey('profile-full-name')),
      'Brouillon privé',
    );
    repository.emit(null);
    await tester.pumpAndSettle();
    expect(find.text('Brouillon privé'), findsNothing);
    expect(find.text('Enregistrer'), findsNothing);
    expect(find.textContaining('Votre session a changé'), findsOneWidget);
    expect(repository.profileSaveCalls, 0);
  });
  testWidgets(
    'édition à 320 px, texte 150 % et clavier : actions accessibles',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openEditor(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 240);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Annuler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfilePage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
