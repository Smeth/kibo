# Retrait ciblé MAINTAIN — appliqué le 2026-11-01

Accord explicite utilisateur : « Oui, applique le delta aux neuf tables et aux futures tables publiques créées par postgres ». Cet accord précise le périmètre refusé par la revue automatique pendant l'exécution autonome. Le fichier global `mvp_final_hardening.sql` reste non appliqué.

Source exacte : `supabase/proposals/client_maintain_pending_review.sql`, conservée sans changement, en-tête historique « NON APPLIQUE » compris. Migration réelle **20261101090123 / kibo_client_maintain_public**, apply_migration success=true, projet KIBO, PostgreSQL 17.11, acteur postgres.

Retrait de MAINTAIN pour anon et authenticated sur categories, reports, messages, conversations, notifications, listing_images, favorites, listing_comments et listings. Même retrait des droits par défaut de postgres sur les futures tables du schéma public. Aucun DML ni changement de politique, rôle, fonction ou donnée. Storage, service_role et defaults supabase_admin hors du delta.

## Contrôles réellement exécutés

Avant : neuf tables avec MAINTAIN effectif pour les deux clients, soit 18 droits, RLS active ; defaults MAINTAIN postgres/public présents pour ces deux rôles. Aucune entrée globale pouvant réintroduire ce droit relevée dans le résultat.

Après application :

- Tables ciblées conservant MAINTAIN pour anon/authenticated : **0**.
- Entrées MAINTAIN postgres/public pour ces clients : **0**.
- Empreinte des ACL hors MAINTAIN de toutes les tables publiques inchangée : `09b156921cb539e01d8caf5e2b91dd44`.
- Empreinte RLS/FORCE RLS de toutes les tables publiques inchangée : `1fa2fbfe18659b02856e6417c88f39d4`.
- Deux entrées postgres/storage MAINTAIN clients toujours présentes : Storage non touché.
- Conseiller sécurité : même avertissement préexistant [protection des mots de passe compromis désactivée](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection), aucun réglage Auth modifié.

Droits par défaut vérifiés dans pg_default_acl, aucune table distante de test créée. La fixture locale PG13 ne prend pas en charge MAINTAIN : aucun test local de ce privilège revendiqué. Code Flutter inchangé ; suites 293+293 antérieures conservées comme preuves historiques, pas relancées pour cette révocation serveur. Aucun build, commit ou push. Diff documentaire contrôlé avec git diff --check.

Ne pas rejouer le fichier global ni déduire une autorisation pour Storage, les defaults supabase_admin ou d'autres privilèges. Le blocage du périmètre public/postgres autorisé est levé. Recettes réelles à deux comptes, traitement opérateur des demandes de suppression et préparation du pilote restent les prochaines étapes MVP.
