/// Congo-Brazzaville : neuf chiffres nationaux, indicatif +242.
/// N'accepte pas de lettres, extensions ou indicatifs d'autres pays.
String? normalizeAuthPhone(String value) {
  var phone = value.trim().replaceAll(RegExp(r'[\s().-]'), '');
  if (phone.startsWith('00242')) phone = '+242${phone.substring(5)}';
  if (RegExp(r'^\d{9}$').hasMatch(phone)) phone = '+242$phone';
  return RegExp(r'^\+242\d{9}$').hasMatch(phone) ? phone : null;
}

bool validPhoneOtp(String value) => RegExp(r'^\d{6}$').hasMatch(value.trim());
