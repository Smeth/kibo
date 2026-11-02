import '../support/listing_fake.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/supabase/supabase_service.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_page.dart';
import 'package:kibo/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/auth_fake.dart';
import '../support/manrope_fonts.dart';
import '../support/supabase_fakes.dart';

void main() {
  setUpAll(loadManropeFonts);
  late FakeAuthRepository repository;
  setUp(() {
    repository = FakeAuthRepository();
  });
  tearDown(() async {
    await repository.dispose();
  });

  Future<void> home(WidgetTester tester) async {
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
  }

  Future<void> fill(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('auth-email')),
      'test@example.invalid',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-password')),
      'password-test',
    );
  }

  testWidgets('accueil public, connexion, profil et déconnexion', (
    tester,
  ) async {
    await home(tester);
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    await fill(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsNothing);
    expect(find.text('Profil test'), findsOneWidget);
    await tester.ensureVisible(find.text('Se déconnecter'));
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    expect(find.text('Profil test'), findsNothing);
    expect(find.text('Se connecter'), findsOneWidget);
    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();
    expect(find.text('Rechercher une annonce...'), findsOneWidget);
  });

  testWidgets('confirmation externe ferme le formulaire et affiche le profil', (
    tester,
  ) async {
    await home(tester);
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    // Simule l’événement de session émis par le SDK après échange PKCE.
    repository.emit(FakeAuthRepository.user);
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsNothing);
    expect(find.text('Profil test'), findsOneWidget);
    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('champs invalides, visibilité et confirmation de mot de passe', (
    tester,
  ) async {
    await home(tester);
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
    await tester.pumpAndSettle();
    expect(find.text('Renseignez votre adresse email.'), findsOneWidget);
    await fill(tester);
    await tester.enterText(
      find.byKey(const ValueKey('auth-confirmation')),
      'different',
    );
    await tester.tap(find.byTooltip('Afficher le mot de passe'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('auth-password')))
          .controller!
          .text,
      'password-test',
    );
    expect(find.byTooltip('Masquer le mot de passe'), findsOneWidget);
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Créer mon compte'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
    await tester.pumpAndSettle();
    expect(
      find.text('Les mots de passe doivent être identiques.'),
      findsOneWidget,
    );
    expect(repository.signInCalls, 0);
  });

  testWidgets(
    'confirmation email garde le formulaire ouvert et efface le mot de passe',
    (tester) async {
      await home(tester);
      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();
      await fill(tester);
      await tester.enterText(
        find.byKey(const ValueKey('auth-confirmation')),
        'password-test',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Créer mon compte'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Ouvrez son lien sur ce téléphone'),
        findsOneWidget,
      );
      expect(find.byType(AuthPage), findsOneWidget);
      expect(repository.profileCalls, 0);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('auth-password')))
            .controller!
            .text,
        isEmpty,
      );
    },
  );

  testWidgets('chargement désactive les soumissions et erreur en français', (
    tester,
  ) async {
    repository.pending = Completer<void>();
    repository.failure = const AuthException(
      'réponse brute',
      code: 'email_not_confirmed',
    );
    await home(tester);
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();
    await fill(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Confirmez votre adresse'), findsOneWidget);
    expect(find.textContaining('réponse brute'), findsNothing);
  });

  testWidgets('inscription sur 320 px à texte 150 % et clavier visible', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = AuthController(repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.light,
        home: AuthPage(controller: controller, registration: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('J’ai déjà un compte'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
