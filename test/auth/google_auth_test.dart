import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/core/config/auth_callback.dart';
import 'package:kibo/core/supabase/secure_session_storage.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_page.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/auth_fake.dart';
import '../support/manrope_fonts.dart';
import '../support/supabase_fakes.dart';

class GoogleFake extends FakeAuthRepository implements GoogleAuthRepository {
  int googleCalls = 0;
  bool launched = true;
  @override
  Future<bool> signInWithGoogle() async {
    googleCalls++;
    await pending?.future;
    if (failure != null) throw failure!;
    return launched;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadManropeFonts);

  test(
    'Google SDK : fournisseur, callback, PKCE et navigateur externe',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      Map<dynamic, dynamic>? launch;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'launch');
            launch = call.arguments as Map<dynamic, dynamic>;
            return true;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        authOptions: AuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: false,
          pkceAsyncStorage: SecurePkceStorage(
            projectHost: 'google-test.invalid',
          ),
        ),
      );
      addTearDown(client.dispose);
      final repository = SupabaseAuthRepository(client);
      expect(await repository.signInWithGoogle(), isTrue);
      final url = Uri.parse(launch!['url'] as String);
      expect(url.path, '/auth/v1/authorize');
      expect(url.queryParameters['provider'], 'google');
      expect(url.queryParameters['redirect_to'], KiboAuthCallback.redirectUrl);
      expect(url.queryParameters['prompt'], 'select_account');
      expect(url.queryParameters['code_challenge'], isNotEmpty);
      expect(url.queryParameters['code_challenge_method'], 's256');
      expect(launch!['useWebView'], isFalse);
      expect(launch!['useSafariVC'], isFalse);
      expect(repository.identity, isNull);
    },
  );

  test(
    'ouverture Google : doublons bloqués, aucune session inventée, reprise',
    () async {
      final repository = GoogleFake()..pending = Completer<void>();
      final controller = AuthController(repository);
      addTearDown(controller.dispose);
      addTearDown(repository.dispose);
      final first = controller.signInWithGoogle();
      await controller.signInWithGoogle();
      expect(repository.googleCalls, 1);
      expect(controller.busy, isTrue);
      repository.pending!.complete();
      await first;
      expect(controller.identity, isNull);
      expect(controller.busy, isFalse);
      expect(repository.profileCalls, 0);
      await controller.signInWithGoogle();
      expect(repository.googleCalls, 2);
      repository.emit(FakeAuthRepository.user);
      await Future<void>.delayed(Duration.zero);
      expect(controller.identity?.id, FakeAuthRepository.user.id);
      expect(controller.message, isNull);
    },
  );

  test(
    'échecs Google : refus du navigateur et erreur sans détail sensible',
    () async {
      final repository = GoogleFake()..launched = false;
      final controller = AuthController(repository);
      addTearDown(controller.dispose);
      addTearDown(repository.dispose);
      await controller.signInWithGoogle();
      expect(controller.message, contains('Impossible d’ouvrir Google'));
      repository.failure = StateError('secret-fictif');
      await controller.signInWithGoogle();
      expect(controller.message, isNot(contains('secret-fictif')));
      expect(controller.busy, isFalse);
      expect(controller.identity, isNull);
    },
  );

  for (final registration in [false, true]) {
    testWidgets(
      'Google sans champs email, inscription=$registration, retour session',
      (tester) async {
        final repository = GoogleFake();
        final controller = AuthController(repository);
        addTearDown(controller.dispose);
        addTearDown(repository.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: KiboTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AuthPage(
                        controller: controller,
                        registration: registration,
                      ),
                    ),
                  ),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Ouvrir'));
        await tester.pumpAndSettle();
        final logo = tester.widget<Image>(
          find.descendant(
            of: find.byKey(const ValueKey('auth-google')),
            matching: find.byType(Image),
          ),
        );
        expect(
          (logo.image as AssetImage).assetName,
          'assets/branding/google-g.png',
        );
        expect(logo.width, 20);
        expect(logo.height, 20);
        await tester.tap(find.byKey(const ValueKey('auth-google')));
        await tester.pumpAndSettle();
        expect(repository.googleCalls, 1);
        expect(repository.signInCalls, 0);
        expect(find.byType(AuthPage), findsOneWidget);
        expect(find.text('Saisissez une adresse email valide.'), findsNothing);
        repository.emit(FakeAuthRepository.user);
        await tester.pumpAndSettle();
        expect(find.byType(AuthPage), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Google intégré : petit écran, thème sombre et texte agrandi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = GoogleFake()..pending = Completer<void>();
    final controller = AuthController(repository);
    addTearDown(controller.dispose);
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AuthPage(
              controller: controller,
              registration: true,
              embedded: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('auth-google'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    expect(repository.googleCalls, 1);
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
