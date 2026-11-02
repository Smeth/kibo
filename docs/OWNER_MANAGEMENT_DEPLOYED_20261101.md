# Vente/archivage — application autorisée du 2026-11-01

Après la proposition concrète du lot précédent, l'utilisateur répond « vas y » et demande de poursuivre les fonctionnalités du MVP sans bloquer sur les incidents non bloquants. Les quatre fichiers accessibles ont été appliqués via apply_migration sur KIBO, après relecture de la baseline et des droits de l'acteur. Aucun retour arrière appliqué à distance, aucun UPDATE/INSERT/DELETE de donnée métier.

Acteur SQL : postgres non-superuser, PostgreSQL 17.11. Il n'est pas membre de supabase_admin : **client_privileges_03_defaults_supabase_admin.sql non appliqué**, sans tentative de contournement ni nouvelle demande bloquant les fonctionnalités.

Migrations réellement enregistrées :

| Version distante | Nom | Source locale appliquée |
|---|---|---|
| 20261101042109 | kibo_owner_management_enum | supabase/proposals/owner_management_01_enum.sql |
| 20261101042116 | kibo_owner_management_guards | supabase/proposals/owner_management_02_guards.sql |
| 20261101042123 | kibo_client_table_privileges | supabase/proposals/client_privileges_01_tables.sql |
| 20261101042132 | kibo_client_postgres_defaults | supabase/proposals/client_privileges_02_defaults_postgres.sql |

Sources appliquées sans modification, réponses success=true. Les en-têtes « proposition » sont conservés pour ne pas altérer les fichiers appliqués ; ce compte rendu et l'historique serveur font foi. La CLI locale n'est pas installée et aucun fichier migration à timestamp fabriqué : conserver ces correspondances avant réconciliation de l'historique. Aucun db push/reset global.

## Contrôles distants après application

Enum : draft,pending,published,rejected,archived,sold. Les deux guards ont la même empreinte prosrc `90f8a195363171aca55afe8223f1c35e`. Le guard privé conserve son ACL implicite ; le public conserve postgres/service_role seulement. Le protocole propriétaire testé localement est désormais déployé, mais aucune vente/édition/archivage réel sur compte A/B n'a été exécuté.

Les grants TRUNCATE/REFERENCES/TRIGGER sur les tables publiques pour anon/authenticated sont **0** après application (54 relevés dans le précédent audit). Les default ACL public de postgres ne contiennent plus ces trois droits pour les rôles clients ; ceux de service_role sont conservés. Les default ACL supabase_admin restent inchangées et nécessitent l'opérateur approprié. MAINTAIN et les autres surfaces restent hors du durcissement ciblé. Ne pas annoncer un audit de sécurité complet.

Les contrôles sont des lectures de métadonnées, pas une recette RLS d'écriture distante. Aucune annonce, photo, favori ou identité de test créé/modifié/supprimé. Aucun APK compilé/installé, commit ou push.

Conseiller de sécurité Supabase consulté après application : un avertissement, protection contre les mots de passe compromis désactivée. Aucun réglage Auth modifié ; suivi à traiter séparément, ce résultat n'est pas un audit exhaustif. Les permissions supabase_admin différées et MAINTAIN restent des limites explicites.

## Suite produit exécutée dans le même lot

Le contrat listing_comments est audité en lecture seule : RLS active, contenu trim 1–2000, annonce publiée exigée, parent même annonce et un seul niveau de réponse, droits d'auteur et champs système protégés en UPDATE. La lecture SQL sous rôle anon, jointe aux annonces publiées et LIMIT 0, réussit ; aucune ligne de commentaire réelle retournée. L'interface Flutter de consultation/publication/réponses est développée sans migration commentaires supplémentaire. [Fonctionnalité et limites](COMMENTS.md).
