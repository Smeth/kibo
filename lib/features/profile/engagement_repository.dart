abstract interface class AccountEngagementRepository {
  Future<Map<String, dynamic>> preferences(
    String owner, {
    bool? messages,
    bool? comments,
  });
  Future<Map<String, dynamic>> tracking(String owner);
  Future<bool> canReview(String owner);
  Future<List<Map<String, dynamic>>> queue(
    String owner,
    String status, {
    int offset = 0,
  });
  Future<void> review(
    String owner,
    Map<String, dynamic> request,
    String action,
    String note,
  );
  Future<void> reply(String owner, int version, String note);
}

const accountDeletionEnabled = bool.fromEnvironment(
  'KIBO_ACCOUNT_DELETION_ENABLED',
);

abstract interface class AccountDeletionExecutor {
  bool get deletionEnabled;
  Future<bool> executeDeletion(String actor, Map<String, dynamic> request);
}

String accountRequestLabel(String status) => switch (status) {
  'pending' => 'En attente',
  'processing' => 'En cours d’examen',
  'needs_info' => 'Précisions demandées',
  'rejected' => 'Demande refusée',
  'completed' => 'Traitement clôturé',
  _ => 'État indisponible',
};
