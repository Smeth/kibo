import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kibo/core/theme/kibo_theme.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_page.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/auth/phone_auth_controller.dart';
import 'package:kibo/features/auth/phone_auth_page.dart';
import 'package:kibo/features/auth/phone_auth_validation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/auth_fake.dart';
import '../support/manrope_fonts.dart';
import '../support/supabase_fakes.dart';

class PhoneFake extends FakeAuthRepository implements PhoneAuthRepository {
  @override
  bool phoneOtpEnabled = true;
  int sends = 0;
  int verifies = 0;
  String? target;
  bool emitOnVerify = true;
  @override
  Future<void> sendPhoneOtp(String phone) async {
    sends++;
    target = phone;
    await pending?.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> verifyPhoneOtp(String phone, String code) async {
    verifies++;
    target = phone;
    await pending?.future;
    if (failure != null) throw failure!;
    if (emitOnVerify) {
      emit(const AuthIdentity(id: 'phone-user', phone: '+242061234567'));
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadManropeFonts);

  test('numéro CG normalisé et codes stricts', () {
    for (final number in [
      '06 123 45 67',
      '+242 06 123 45 67',
      '00242061234567',
    ]) {
      expect(normalizeAuthPhone(number), '+242061234567');
    }
    for (final number in [
      '',
      '06123',
      '+243061234567',
      'tel:061234567',
      '06abc1234567',
      '+2420612345678',
    ]) {
      expect(normalizeAuthPhone(number), isNull);
    }
    expect(validPhoneOtp(' 123456 '), isTrue);
    for (final code in ['12345', '1234567', '12a456', '12 456']) {
      expect(validPhoneOtp(code), isFalse);
    }
  });

  test(
    'SDK OTP : SMS, création autorisée, vérification et session sans email',
    () async {
      var calls = 0;
      final transport = MockClient((request) async {
        calls++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['phone'], '+242061234567');
        if (request.url.path.endsWith('/otp')) {
          expect(body['channel'], 'sms');
          expect(body['create_user'], isTrue);
          expect(body['data'], isEmpty);
          return http.Response('{}', 200);
        }
        expect(request.url.path, '/auth/v1/verify');
        expect(body['type'], 'sms');
        expect(body['token'], '123456');
        final expiry = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
        String encode(Map<String, dynamic> data) =>
            base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
        return http.Response(
          jsonEncode({
            'access_token':
                '${encode({'alg': 'HS256'})}.${encode({'exp': expiry, 'sub': 'phone-user'})}.fake',
            'refresh_token': 'fake-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': 'phone-user',
              'phone': '+242061234567',
              'email': '',
              'aud': 'authenticated',
              'created_at': '2026-01-01T00:00:00Z',
              'app_metadata': <String, dynamic>{},
              'user_metadata': <String, dynamic>{},
            },
          }),
          200,
        );
      });
      final client = SupabaseClient(
        testConfig.url,
        testConfig.publicKey,
        httpClient: transport,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      addTearDown(client.dispose);
      final repository = SupabaseAuthRepository(client, phoneOtpEnabled: true);
      await repository.sendPhoneOtp('06 123 45 67');
      expect(repository.identity, isNull);
      await repository.verifyPhoneOtp('+242061234567', '123456');
      expect(repository.identity?.phone, '+242061234567');
      expect(calls, 2);
    },
  );

  test('SDK désactivé ou saisie invalide : aucune requête', () async {
    var calls = 0;
    final client = SupabaseClient(
      testConfig.url,
      testConfig.publicKey,
      httpClient: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);
    final disabled = SupabaseAuthRepository(client);
    expect(disabled.phoneOtpEnabled, isFalse);
    await expectLater(disabled.sendPhoneOtp('061234567'), throwsStateError);
    await expectLater(
      disabled.verifyPhoneOtp('061234567', '123456'),
      throwsStateError,
    );
    final enabled = SupabaseAuthRepository(client, phoneOtpEnabled: true);
    await expectLater(enabled.sendPhoneOtp('invalid'), throwsArgumentError);
    await expectLater(
      enabled.verifyPhoneOtp('061234567', 'x'),
      throwsArgumentError,
    );
    expect(calls, 0);
  });

  test('envoi : doublons, délai, numéro corrigé et renvoi', () async {
    var now = DateTime(2026, 11, 2);
    final repository = PhoneFake()..pending = Completer<void>();
    final controller = PhoneAuthController(repository, now: () => now);
    addTearDown(repository.dispose);
    addTearDown(controller.dispose);
    final first = controller.send('061234567');
    expect(await controller.send('061234567'), isFalse);
    expect(await controller.verify('123456'), isFalse);
    repository.pending!.complete();
    expect(await first, isTrue);
    expect(controller.sentPhone, '+242061234567');
    expect(repository.sends, 1);
    expect(await controller.send('061234567'), isFalse);
    controller.changeNumber();
    expect(controller.sentPhone, isNull);
    expect(controller.retrySeconds, 60);
    now = now.add(const Duration(seconds: 61));
    expect(await controller.send('051234567'), isTrue);
    expect(repository.target, '+242051234567');
    expect(repository.sends, 2);
  });

  test('code expiré, nouveau code et aucun faux succès', () async {
    final repository = PhoneFake()..emitOnVerify = false;
    final controller = PhoneAuthController(repository);
    addTearDown(repository.dispose);
    addTearDown(controller.dispose);
    expect(await controller.verify('123456'), isFalse);
    await controller.send('061234567');
    expect(await controller.verify('123'), isFalse);
    repository.failure = const AuthException('raw-secret', code: 'otp_expired');
    expect(await controller.verify('123456'), isFalse);
    expect(controller.message, contains('incorrect ou expiré'));
    expect(controller.message, isNot(contains('raw-secret')));
    expect(controller.sentPhone, '+242061234567');
    repository.failure = null;
    expect(await controller.verify('123456'), isTrue);
    expect(repository.identity, isNull);
  });

  test('disposition pendant envoi et mode désactivé sans effets', () async {
    final repository = PhoneFake()..pending = Completer<void>();
    addTearDown(repository.dispose);
    final controller = PhoneAuthController(repository);
    final pending = controller.send('061234567');
    controller.dispose();
    repository.pending!.complete();
    expect(await pending, isFalse);
    final disabled = PhoneAuthController(repository..phoneOtpEnabled = false);
    addTearDown(disabled.dispose);
    expect(await disabled.send('061234567'), isFalse);
    expect(repository.sends, 1);
  });

  test(
    'SMS refusé : erreur française, délai conservé et aucun code attendu',
    () async {
      final repository = PhoneFake()
        ..failure = const AuthException(
          'private-provider-detail',
          code: 'sms_send_failed',
        );
      final controller = PhoneAuthController(repository);
      addTearDown(repository.dispose);
      addTearDown(controller.dispose);
      expect(await controller.send('061234567'), isFalse);
      expect(controller.sentPhone, isNull);
      expect(controller.retrySeconds, 60);
      expect(controller.message, contains('Envoi du SMS indisponible'));
      expect(controller.message, isNot(contains('private-provider-detail')));
      expect(await controller.send('061234567'), isFalse);
      expect(repository.sends, 1);
    },
  );

  testWidgets('OTP petit écran, clavier, texte agrandi, correction du numéro', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = PhoneFake();
    final auth = AuthController(repository);
    addTearDown(auth.dispose);
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: KiboTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(2),
            viewInsets: const EdgeInsets.only(bottom: 200),
          ),
          child: child!,
        ),
        home: PhoneAuthPage(auth: auth, repository: repository),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('phone-number')),
      '061234567',
    );
    await tester.ensureVisible(find.text('Recevoir un code SMS'));
    await tester.tap(find.text('Recevoir un code SMS'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Modifier le numéro'));
    await tester.tap(find.text('Modifier le numéro'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('phone-number')), findsOneWidget);
    expect(find.byKey(const ValueKey('phone-code')), findsNothing);
    expect(repository.verifies, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('téléphone préparé désactivé : bouton visible sans envoi', (
    tester,
  ) async {
    final repository = PhoneFake()..phoneOtpEnabled = false;
    final auth = AuthController(repository);
    addTearDown(auth.dispose);
    addTearDown(repository.dispose);
    await tester.pumpWidget(MaterialApp(home: AuthPage(controller: auth)));
    final button = find.byKey(const ValueKey('auth-phone'));
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    expect(find.text('Téléphone · bientôt disponible'), findsOneWidget);
    expect(repository.sends, 0);
  });

  testWidgets(
    'numéro/code et fermeture des deux routes seulement sur session',
    (tester) async {
      final repository = PhoneFake()..emitOnVerify = false;
      final auth = AuthController(repository);
      addTearDown(auth.dispose);
      addTearDown(repository.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: KiboTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AuthPage(controller: auth),
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
      await tester.tap(find.byKey(const ValueKey('auth-phone')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('phone-number')),
        '061234567',
      );
      await tester.tap(find.text('Recevoir un code SMS'));
      await tester.pumpAndSettle();
      expect(repository.target, '+242061234567');
      expect(find.text('Renvoyer dans 60s'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('phone-code')),
        '123456',
      );
      await tester.tap(find.text('Vérifier le code'));
      await tester.pumpAndSettle();
      expect(find.byType(PhoneAuthPage), findsOneWidget);
      repository.emit(
        const AuthIdentity(id: 'phone-user', phone: '+242061234567'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PhoneAuthPage), findsNothing);
      expect(find.byType(AuthPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
