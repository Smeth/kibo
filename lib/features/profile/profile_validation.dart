String? validateProfileCity(String? value) =>
    value == null || value.trim().isEmpty ? 'Renseignez votre ville.' : null;
