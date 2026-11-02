import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kibo/features/auth/auth_controller.dart';
import 'package:kibo/features/auth/auth_repository.dart';
import 'package:kibo/features/profile/profile_validation.dart';

import '../support/auth_fake.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthController controller;
  Future<void> flush() => Future<void>.delayed(Duration.zero);
  Future<void> connected() async {
    repository.identity = FakeAuthRepository.user;
    controller = AuthController(repository);
    await flush();
  }

  Future<bool> save({
    String name = ' Nouveau nom ',
    String city = ' Pointe-Noire ',
  }) => controller.updateProfile(
    expectedUserId: FakeAuthRepository.user.id,
    fullName: name,
    city: city,
  );
  setUp(() {
    repository = FakeAuthRepository();
  });
  tearDown(() async {
    controller.dispose();
    await repository.dispose();
  });

  test(
    'ville obligatoire ; pas de liste fermée ni de restriction sur les accents',
    () async {
      await connected();
      expect(validateProfileCity(null), isNotNull);
      expect(validateProfileCity('  '), isNotNull);
      expect(validateProfileCity(' Dolisie '), isNull);
      expect(await save(city: '  '), isFalse);
      expect(repository.profileSaveCalls, 0);
      expect(controller.profile?.city, 'Brazzaville');
    },
  );

  test('enregistrement et nom facultatif actualisent le profil', () async {
    await connected();
    expect(await save(), isTrue);
    expect(controller.profile?.city, 'Pointe-Noire');
    expect(controller.profile?.fullName, 'Nouveau nom');
    expect(controller.message, 'Profil mis à jour.');
    expect(await save(name: '  '), isTrue);
    expect(controller.profile?.fullName, isNull);
  });

  test('aucune écriture sans session ou profil chargé', () async {
    controller = AuthController(repository);
    expect(await save(), isFalse);
    repository.profileLoader = () async => null;
    repository.emit(FakeAuthRepository.user);
    await flush();
    expect(await save(), isFalse);
    expect(repository.profileSaveCalls, 0);
  });

  test('erreur masquée, ancien profil et formulaire récupérables', () async {
    await connected();
    repository.profileSaver = () async => throw StateError('détail privé');
    expect(await save(), isFalse);
    expect(controller.message, contains('Impossible d’enregistrer'));
    expect(controller.message, isNot(contains('privé')));
    expect(controller.profile?.city, 'Brazzaville');
    expect(controller.busy, isFalse);
    repository.profileSaver = null;
    expect(await save(), isTrue);
  });

  test('double soumission bloquée pendant l’enregistrement', () async {
    await connected();
    final pending = Completer<KiboProfile>();
    repository.profileSaver = () => pending.future;
    final operation = save();
    expect(controller.busy, isTrue);
    expect(await save(), isFalse);
    expect(repository.profileSaveCalls, 1);
    pending.complete(const KiboProfile(id: 'test-user-a', city: 'Dolisie'));
    expect(await operation, isTrue);
    expect(controller.busy, isFalse);
  });

  test('réponse de sauvegarde ignorée après fermeture de session', () async {
    await connected();
    final pending = Completer<KiboProfile>();
    repository.profileSaver = () => pending.future;
    final operation = save();
    repository.emit(null);
    await flush();
    pending.complete(
      const KiboProfile(id: 'test-user-a', city: 'Ancienne ville'),
    );
    expect(await operation, isFalse);
    expect(controller.profile, isNull);
    expect(controller.message, isNull);
  });

  test(
    'formulaire ancien et réponse tardive ne modifient pas le nouveau compte',
    () async {
      await connected();
      final pending = Completer<KiboProfile>();
      repository.profileSaver = () => pending.future;
      final operation = save();
      repository.profileLoader = () async =>
          const KiboProfile(id: 'test-user-b', city: 'Ville B');
      repository.emit(const AuthIdentity(id: 'test-user-b'));
      await flush();
      pending.complete(
        const KiboProfile(id: 'test-user-a', city: 'Ancienne ville'),
      );
      expect(await operation, isFalse);
      await flush();
      expect(controller.profile?.city, 'Ville B');
      expect(await save(), isFalse);
      expect(repository.profileSaveCalls, 1);
    },
  );
}
