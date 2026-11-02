import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/auth_callback.dart';
import '../profile/profile_validation.dart';
import 'phone_auth_validation.dart';

class AuthIdentity {
  const AuthIdentity({required this.id, this.email, this.phone});
  final String id;
  final String? email;
  final String? phone;
}

class KiboProfile {
  const KiboProfile({required this.id, required this.city, this.fullName});
  final String id;
  final String city;
  final String? fullName;
}

abstract interface class AuthRepository {
  AuthIdentity? get identity;
  Stream<AuthIdentity?> get identities;

  /// Vrai si l’inscription ne fournit pas encore de session.
  Future<bool> signUp(String email, String password);
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<KiboProfile?> synchronizeProfile();
  Future<KiboProfile> updateProfile({
    required String expectedUserId,
    required String fullName,
    required String city,
  });
}

abstract interface class PasswordRecoveryRepository {
  Stream<String> get passwordRecoveryEvents;
  Future<void> sendPasswordReset(String email);
  Future<void> changePassword(String expectedOwner, String password);
}

abstract interface class GoogleAuthRepository {
  /// Indique seulement si le navigateur a pu être ouvert, pas si la session existe.
  Future<bool> signInWithGoogle();
}

abstract interface class PhoneAuthRepository {
  bool get phoneOtpEnabled;
  Future<void> sendPhoneOtp(String phone);
  Future<void> verifyPhoneOtp(String phone, String code);
}

class SupabaseAuthRepository
    implements
        AuthRepository,
        PasswordRecoveryRepository,
        GoogleAuthRepository,
        PhoneAuthRepository {
  SupabaseAuthRepository(
    this.client, {
    this.clearPersistedSession,
    this.phoneOtpEnabled = const bool.fromEnvironment(
      'KIBO_PHONE_AUTH_ENABLED',
    ),
  });
  final SupabaseClient client;
  @override
  final bool phoneOtpEnabled;

  void _checkPhoneEnabled() {
    if (!phoneOtpEnabled) throw StateError('Connexion téléphone indisponible');
    if (identity != null) throw StateError('Compte déjà connecté');
  }

  @override
  Future<void> sendPhoneOtp(String phone) async {
    _checkPhoneEnabled();
    final normalized = normalizeAuthPhone(phone);
    if (normalized == null) throw ArgumentError('Numéro invalide');
    await client.auth.signInWithOtp(
      phone: normalized,
      channel: OtpChannel.sms,
      shouldCreateUser: true,
    );
  }

  @override
  Future<void> verifyPhoneOtp(String phone, String code) async {
    _checkPhoneEnabled();
    final normalized = normalizeAuthPhone(phone);
    if (normalized == null || !validPhoneOtp(code)) {
      throw ArgumentError('Numéro ou code invalide');
    }
    final response = await client.auth.verifyOTP(
      phone: normalized,
      token: code.trim(),
      type: OtpType.sms,
    );
    if (response.session == null) {
      throw const AuthException('Vérification sans session');
    }
  }

  final Future<void> Function()? clearPersistedSession;
  @override
  Future<bool> signInWithGoogle() => client.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: KiboAuthCallback.redirectUrl,
    authScreenLaunchMode: LaunchMode.externalApplication,
    queryParams: const {'prompt': 'select_account'},
  );

  @override
  Stream<String> get passwordRecoveryEvents => client.auth.onAuthStateChange
      .where(
        (state) =>
            state.event == AuthChangeEvent.passwordRecovery &&
            state.session != null,
      )
      .map((state) => state.session!.user.id);
  @override
  Future<void> sendPasswordReset(String email) => client.auth
      .resetPasswordForEmail(email, redirectTo: KiboAuthCallback.redirectUrl);
  @override
  Future<void> changePassword(String expectedOwner, String password) async {
    if (identity?.id != expectedOwner) throw StateError('Session modifiée');
    await client.auth.updateUser(UserAttributes(password: password));
    if (identity?.id != expectedOwner) throw StateError('Session modifiée');
  }

  AuthIdentity? _identity(Session? session) {
    if (session == null || session.isExpired) return null;
    return AuthIdentity(
      id: session.user.id,
      email: session.user.email,
      phone: session.user.phone,
    );
  }

  @override
  AuthIdentity? get identity => _identity(client.auth.currentSession);

  @override
  Stream<AuthIdentity?> get identities =>
      client.auth.onAuthStateChange.map((state) => _identity(state.session));

  @override
  Future<bool> signUp(String email, String password) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: KiboAuthCallback.redirectUrl,
    );
    return response.session == null;
  }

  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut(scope: SignOutScope.local);
    } finally {
      // Le SDK retire déjà sa session locale même si la révocation réseau échoue.
      await clearPersistedSession?.call();
    }
  }

  @override
  Future<KiboProfile?> synchronizeProfile() async {
    final user = identity;
    if (user == null) return null;
    // Le trigger on_auth_user_created crée la ligne. Aucun INSERT/UPSERT client.
    final profile = await client
        .from('profiles')
        .select('id, full_name, city')
        .eq('id', user.id)
        .maybeSingle();
    if (profile == null) return null;
    return KiboProfile(
      id: profile['id'] as String,
      city: profile['city'] as String,
      fullName: profile['full_name'] as String?,
    );
  }

  @override
  Future<KiboProfile> updateProfile({
    required String expectedUserId,
    required String fullName,
    required String city,
  }) async {
    final user = identity;
    if (user == null || user.id != expectedUserId) {
      throw StateError('La session du formulaire a changé.');
    }
    if (validateProfileCity(city) != null) {
      throw ArgumentError('La ville est obligatoire.');
    }
    final name = fullName.trim();
    // Liste fermée de champs ; id, rôle et type de compte ne sont jamais écrits.
    // La RLS distante reste l’autorité, même si la session change en vol.
    final profiles = await client
        .from('profiles')
        .update({'full_name': name.isEmpty ? null : name, 'city': city.trim()})
        .eq('id', user.id)
        .select('id, full_name, city');
    if (profiles.length != 1 || profiles.single['id'] != user.id) {
      throw StateError('Le profil n’a pas été mis à jour.');
    }
    final profile = profiles.single;
    return KiboProfile(
      id: profile['id'] as String,
      city: profile['city'] as String,
      fullName: profile['full_name'] as String?,
    );
  }
}

String authErrorMessage(Object error) {
  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'Email ou mot de passe incorrect.';
      case 'email_not_confirmed':
        return 'Confirmez votre adresse email avant de vous connecter.';
      case 'weak_password':
        return 'Ce mot de passe ne respecte pas les règles de sécurité du serveur.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Trop de tentatives. Patientez avant de réessayer.';
      case 'signup_disabled':
        return 'Les inscriptions sont temporairement indisponibles.';
      case 'provider_disabled':
      case 'unsupported_provider':
        return 'La connexion Google est temporairement indisponible. Vous pouvez utiliser votre email.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Inscription impossible. Essayez de vous connecter ou vérifiez vos emails.';
    }
  }
  return 'Opération impossible. Vérifiez votre connexion et réessayez.';
}
