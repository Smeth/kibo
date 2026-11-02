import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';
import 'phone_auth_validation.dart';

String phoneAuthError(Object error) {
  if (error is AuthException) {
    switch (error.code) {
      case 'otp_expired':
      case 'otp_disabled':
        return 'Code incorrect ou expiré. Vérifiez-le ou demandez un nouveau code.';
      case 'over_sms_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Trop de tentatives. Patientez avant de réessayer.';
      case 'phone_provider_disabled':
      case 'sms_send_failed':
        return 'Envoi du SMS indisponible. Réessayez plus tard ou utilisez Google ou votre email.';
    }
  }
  return 'Connexion téléphone impossible. Vérifiez votre connexion et réessayez.';
}

class PhoneAuthController extends ChangeNotifier {
  PhoneAuthController(this.repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final PhoneAuthRepository repository;
  final DateTime Function() _now;
  bool busy = false;
  bool _disposed = false;
  String? sentPhone;
  String? message;
  DateTime? _retryAt;
  int get retrySeconds {
    final milliseconds = _retryAt?.difference(_now()).inMilliseconds ?? 0;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> send(String input) async {
    if (_disposed || busy || !repository.phoneOtpEnabled) return false;
    final phone = normalizeAuthPhone(input);
    if (phone == null) {
      message = 'Saisissez un numéro congolais de 9 chiffres (indicatif +242).';
      _notify();
      return false;
    }
    if (retrySeconds > 0) return false;
    busy = true;
    message = null;
    // Délai également après échec : éviter les répétitions coûteuses.
    _retryAt = _now().add(const Duration(seconds: 60));
    _notify();
    try {
      await repository.sendPhoneOtp(phone);
      if (_disposed) return false;
      sentPhone = phone;
      message = 'Demande envoyée. Saisissez le code reçu par SMS.';
      return true;
    } catch (error) {
      if (!_disposed) message = phoneAuthError(error);
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> verify(String code) async {
    if (_disposed || busy || sentPhone == null || !repository.phoneOtpEnabled) {
      return false;
    }
    if (!validPhoneOtp(code)) {
      message = 'Saisissez le code à 6 chiffres reçu par SMS.';
      _notify();
      return false;
    }
    busy = true;
    message = null;
    _notify();
    try {
      await repository.verifyPhoneOtp(sentPhone!, code.trim());
      return !_disposed;
    } catch (error) {
      if (!_disposed) message = phoneAuthError(error);
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  void changeNumber() {
    if (_disposed || busy) return;
    sentPhone = null;
    message = null;
    // Le délai reste global au formulaire même après correction du numéro.
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
