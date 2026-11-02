String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Renseignez votre adresse email.';
  if (email.length > 254 ||
      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Renseignez une adresse email valide.';
  }
  return null;
}

String? validatePassword(String? value, {required bool registration}) {
  if (value == null || value.isEmpty) return 'Renseignez votre mot de passe.';
  if (registration && value.length < 8) {
    return 'Utilisez au moins 8 caractères.';
  }
  return null;
}
