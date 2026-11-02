import 'dart:async';

import 'package:flutter/widgets.dart';

import 'auth_repository.dart';
import '../profile/profile_validation.dart';

enum ProfileStatus { none, loading, ready, missing, failed }

class AuthController extends ChangeNotifier {
  AuthController(this.repository) {
    final recovery = repository;
    if (recovery is PasswordRecoveryRepository) {
      _recoverySubscription = (recovery as PasswordRecoveryRepository)
          .passwordRecoveryEvents
          .listen((recoveryOwner) {
            scheduleMicrotask(() {
              if (!_disposed && _identity?.id == recoveryOwner) {
                recoveringPassword = true;
                _notify();
              }
            });
          });
    }
    _identity = repository.identity;
    _subscription = repository.identities.listen(
      _onIdentity,
      onError: (Object error) {
        message =
            'Impossible d’actualiser la session. Vérifiez votre connexion.';
        _notify();
      },
    );
    if (_identity != null) unawaited(synchronizeProfile());
  }

  final AuthRepository repository;
  StreamSubscription<String>? _recoverySubscription;
  bool recoveringPassword = false;
  void finishPasswordRecovery() {
    recoveringPassword = false;
    _notify();
  }

  late final StreamSubscription<AuthIdentity?> _subscription;
  AuthIdentity? _identity;
  AuthIdentity? get identity => _identity;
  bool busy = false;
  String? message;
  ProfileStatus profileStatus = ProfileStatus.none;
  KiboProfile? profile;
  bool _disposed = false;
  int _profileRequest = 0;
  bool _savingProfile = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _onIdentity(AuthIdentity? user) {
    final changed = user?.id != _identity?.id;
    _identity = user;
    if (changed) {
      recoveringPassword = false;
      _profileRequest++;
      profileStatus = ProfileStatus.none;
      profile = null;
      message = null;
    }
    _notify();
    if (user != null && (changed || profileStatus == ProfileStatus.none)) {
      unawaited(synchronizeProfile());
    }
  }

  Future<bool> submit({
    required bool registration,
    required String email,
    required String password,
  }) async {
    if (busy) return false;
    busy = true;
    message = null;
    _notify();
    try {
      final confirmation = registration
          ? await repository.signUp(email.trim(), password)
          : await repository.signIn(email.trim(), password).then((_) => false);
      if (_disposed) return false;
      _onIdentity(repository.identity);
      if (confirmation) {
        message =
            'Si l’inscription est acceptée, un email vous permettra de confirmer votre adresse. Ouvrez son lien sur ce téléphone pour revenir dans KIBO. Si nécessaire, connectez-vous ensuite.';
      }
      return !confirmation && _identity != null;
    } catch (error) {
      message = authErrorMessage(error);
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  bool get supportsGoogle => repository is GoogleAuthRepository;

  Future<void> signInWithGoogle() async {
    if (_disposed || busy || _identity != null || !supportsGoogle) return;
    busy = true;
    message = null;
    _notify();
    try {
      final launched = await (repository as GoogleAuthRepository)
          .signInWithGoogle();
      if (_disposed || _identity != null) return;
      message = launched
          ? 'Terminez la connexion dans Google. Si vous avez annulé, vous pouvez réessayer ou utiliser votre email.'
          : 'Impossible d’ouvrir Google. Réessayez ou utilisez votre email.';
    } catch (error) {
      if (!_disposed && _identity == null) message = authErrorMessage(error);
    } finally {
      // L’ouverture du navigateur n’est pas une authentification. Seul le flux
      // de session du SDK ferme le formulaire ; annuler laisse le choix réutilisable.
      busy = false;
      _notify();
    }
  }

  Future<void> synchronizeProfile() async {
    if (_identity == null || _savingProfile) return;
    final request = ++_profileRequest;
    profileStatus = ProfileStatus.loading;
    _notify();
    try {
      final result = await repository.synchronizeProfile();
      if (!_disposed && request == _profileRequest) {
        profile = result;
        profileStatus = result != null
            ? ProfileStatus.ready
            : ProfileStatus.missing;
      }
    } catch (_) {
      if (!_disposed && request == _profileRequest) {
        profileStatus = ProfileStatus.failed;
      }
    }
    _notify();
  }

  Future<bool> updateProfile({
    required String expectedUserId,
    required String fullName,
    required String city,
  }) async {
    if (_disposed || busy) return false;
    if (_identity?.id != expectedUserId ||
        repository.identity?.id != expectedUserId ||
        profile?.id != expectedUserId ||
        profileStatus != ProfileStatus.ready) {
      message = 'Votre profil doit être rechargé avant modification.';
      _notify();
      return false;
    }
    final error = validateProfileCity(city);
    if (error != null) {
      message = error;
      _notify();
      return false;
    }
    final request = ++_profileRequest;
    busy = true;
    _savingProfile = true;
    message = null;
    _notify();
    bool isCurrent() =>
        !_disposed &&
        request == _profileRequest &&
        _identity?.id == expectedUserId &&
        repository.identity?.id == expectedUserId;
    try {
      final updated = await repository.updateProfile(
        expectedUserId: expectedUserId,
        fullName: fullName,
        city: city,
      );
      if (!isCurrent()) return false;
      if (updated.id != expectedUserId) {
        throw StateError('Réponse de profil incohérente.');
      }
      profile = updated;
      profileStatus = ProfileStatus.ready;
      message = 'Profil mis à jour.';
      return true;
    } catch (_) {
      if (isCurrent()) {
        message =
            'Impossible d’enregistrer votre profil. Vérifiez votre connexion et réessayez.';
      }
      return false;
    } finally {
      busy = false;
      _savingProfile = false;
      _notify();
      // Un nouveau compte peut être arrivé pendant la sauvegarde de l’ancien.
      if (!_disposed &&
          _identity != null &&
          profileStatus == ProfileStatus.none) {
        unawaited(synchronizeProfile());
      }
    }
  }

  Future<void> signOut() async {
    if (busy) return;
    busy = true;
    message = null;
    _notify();
    try {
      await repository.signOut();
      if (!_disposed) _onIdentity(repository.identity);
    } catch (error) {
      message = authErrorMessage(error);
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _profileRequest++;
    unawaited(_subscription.cancel());
    unawaited(_recoverySubscription?.cancel());
    super.dispose();
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);
  static AuthController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
}

class AuthSession extends StatefulWidget {
  const AuthSession({super.key, required this.repository, required this.child});
  final AuthRepository repository;
  final Widget child;
  @override
  State<AuthSession> createState() => _AuthSessionState();
}

class _AuthSessionState extends State<AuthSession> {
  late final controller = AuthController(widget.repository);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AuthScope(controller: controller, child: widget.child);
}
