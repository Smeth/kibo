import 'dart:async';
import 'package:kibo/features/auth/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  static const user = AuthIdentity(
    id: 'test-user-a',
    email: 'test@example.invalid',
  );
  final events = StreamController<AuthIdentity?>.broadcast();
  @override
  AuthIdentity? identity;
  @override
  Stream<AuthIdentity?> get identities => events.stream;
  bool confirmation = true;
  Object? failure;
  int signInCalls = 0;
  int profileCalls = 0;
  Completer<void>? pending;
  Future<KiboProfile?> Function()? profileLoader;
  Future<KiboProfile> Function()? profileSaver;
  int profileSaveCalls = 0;
  KiboProfile? savedProfile;

  void emit(AuthIdentity? user) {
    identity = user;
    events.add(user);
  }

  @override
  Future<bool> signUp(String email, String password) async {
    await pending?.future;
    if (failure != null) throw failure!;
    if (!confirmation) emit(user);
    return confirmation;
  }

  @override
  Future<void> signIn(String email, String password) async {
    signInCalls++;
    await pending?.future;
    if (failure != null) throw failure!;
    emit(user);
  }

  @override
  Future<void> signOut() async {
    if (failure != null) throw failure!;
    emit(null);
  }

  @override
  Future<KiboProfile?> synchronizeProfile() async {
    profileCalls++;
    if (profileLoader != null) return profileLoader!();
    if (savedProfile != null) return savedProfile;
    return const KiboProfile(
      id: 'test-user-a',
      city: 'Brazzaville',
      fullName: 'Profil test',
    );
  }

  @override
  Future<KiboProfile> updateProfile({
    required String expectedUserId,
    required String fullName,
    required String city,
  }) async {
    profileSaveCalls++;
    if (profileSaver != null) return profileSaver!();
    final name = fullName.trim();
    return savedProfile = KiboProfile(
      id: expectedUserId,
      city: city.trim(),
      fullName: name.isEmpty ? null : name,
    );
  }

  Future<void> dispose() => events.close();
}
