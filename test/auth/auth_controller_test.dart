import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/auth/auth_validation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/auth_fake.dart';

void main() {
  Future<void> flush() => Future<void>.delayed(Duration.zero);
  late FakeAuthRepository repository;
  late AuthController controller;
  setUp(() {
    repository = FakeAuthRepository();
  });
  tearDown(() async {
    controller.dispose();
    await repository.dispose();
  });

  test(
    'validation email, mot de passe et compatibilité des anciens comptes',
    () {
      controller = AuthController(repository);
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('incorrect'), isNotNull);
      expect(validateEmail(' test@example.invalid '), isNull);
      expect(validatePassword('', registration: false), isNotNull);
      expect(validatePassword('short', registration: true), isNotNull);
      expect(validatePassword('short', registration: false), isNull);
      expect(validatePassword('password-test', registration: true), isNull);
    },
  );

  test('confirmation email sans session : aucun accès au profil', () async {
    controller = AuthController(repository);
    expect(
      await controller.submit(
        registration: true,
        email: 'test@example.invalid',
        password: 'password-test',
      ),
      isFalse,
    );
    expect(controller.identity, isNull);
    expect(controller.message, contains('confirmer'));
    expect(repository.profileCalls, 0);
  });

  test('connexion puis synchronisation du profil existant', () async {
    controller = AuthController(repository);
    expect(
      await controller.submit(
        registration: false,
        email: 'test@example.invalid',
        password: 'password-test',
      ),
      isTrue,
    );
    await flush();
    expect(controller.identity?.id, FakeAuthRepository.user.id);
    expect(controller.profileStatus, ProfileStatus.ready);
    expect(controller.profile?.city, 'Brazzaville');
  });

  test('inscription avec session immédiate récupère le profil', () async {
    repository.confirmation = false;
    controller = AuthController(repository);
    expect(
      await controller.submit(
        registration: true,
        email: 'test@example.invalid',
        password: 'password-test',
      ),
      isTrue,
    );
    await flush();
    expect(controller.profileStatus, ProfileStatus.ready);
  });

  test('session initiale restaurée et déconnexion réactives', () async {
    repository.identity = FakeAuthRepository.user;
    controller = AuthController(repository);
    await flush();
    expect(controller.profileStatus, ProfileStatus.ready);
    await controller.signOut();
    await flush();
    expect(controller.identity, isNull);
    expect(controller.profile, isNull);
    expect(controller.profileStatus, ProfileStatus.none);
  });

  test('profil absent ou refusé ne déconnecte pas le compte', () async {
    repository.identity = FakeAuthRepository.user;
    repository.profileLoader = () async => null;
    controller = AuthController(repository);
    await flush();
    expect(controller.profileStatus, ProfileStatus.missing);
    repository.profileLoader = () async => throw StateError('erreur privée');
    await controller.synchronizeProfile();
    expect(controller.profileStatus, ProfileStatus.failed);
    expect(controller.identity, isNotNull);
    expect(controller.message, isNull);
  });

  test('profil tardif ne réapparaît pas après déconnexion', () async {
    final pending = Completer<KiboProfile?>();
    repository.identity = FakeAuthRepository.user;
    repository.profileLoader = () => pending.future;
    controller = AuthController(repository);
    await controller.signOut();
    pending.complete(const KiboProfile(id: 'old', city: 'Test'));
    await flush();
    expect(controller.profile, isNull);
    expect(controller.profileStatus, ProfileStatus.none);
  });

  test('double soumission bloquée et erreurs brutes masquées', () async {
    repository.pending = Completer<void>();
    repository.failure = const AuthException(
      'détail privé',
      code: 'invalid_credentials',
    );
    controller = AuthController(repository);
    final operation = controller.submit(
      registration: false,
      email: 'test@example.invalid',
      password: 'password-test',
    );
    expect(controller.busy, isTrue);
    expect(
      await controller.submit(
        registration: false,
        email: 'test@example.invalid',
        password: 'password-test',
      ),
      isFalse,
    );
    repository.pending!.complete();
    await operation;
    expect(repository.signInCalls, 1);
    expect(controller.busy, isFalse);
    expect(controller.message, 'Email ou mot de passe incorrect.');
    expect(controller.message, isNot(contains('privé')));
  });

  test('erreur du flux auth traitée et expiration réactive', () async {
    controller = AuthController(repository);
    repository.events.addError(StateError('détail privé'));
    await flush();
    expect(controller.message, contains('actualiser'));
    expect(controller.message, isNot(contains('privé')));
    repository.emit(FakeAuthRepository.user);
    await flush();
    repository.emit(null);
    await flush();
    expect(controller.identity, isNull);
    expect(controller.profile, isNull);
  });
}
