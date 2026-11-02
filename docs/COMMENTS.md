# Commentaires et réponses — MVP local, 2026-11-01

Depuis le détail d'une annonce disponible, « Commentaires et réponses » ouvre la discussion. Lecture publique, pagination serveur par vingt, actualisation manuelle et consultation séparée des réponses à un commentaire racine. Un seul niveau de réponse. La navigation fonctionne depuis le catalogue et les favoris en conservant la session.

Un visiteur consulte et reçoit l'indication de connexion pour participer. Un compte connecté publie un texte trim de 1 à 2000 caractères Unicode. Chargement, validation, erreurs/reprise, blocage du double envoi et du retour pendant publication. Changement de compte : texte effacé, réponse tardive ignorée ; le repository vérifie la session avant et après l'INSERT. Une requête déjà envoyée peut avoir été effective : aucune relance automatique ni garantie d'idempotence. En cas d'échec, texte conservé et invitation à relire la discussion avant réessai.

## Contrat réutilisé

Table distante existante listing_comments, RLS active et triggers audités : validate_comment vérifie l'annonce published et l'appartenance du parent à cette annonce, parent racine uniquement ; guard_comment_update protège auteur/annonce/parent/statut/suppression logique hors admin. Ce lot ne modifie ni ces fonctions ni leurs politiques.

SELECT client : ID annonce, status published, deleted_at NULL et jointure annonce published, même pour l'auteur/admin autorisé à voir davantage par RLS. Réponses : parent relu publiquement avec les mêmes filtres et parent_id NULL. INSERT : listing_id, user_id issu de la session, content et parent_id éventuel seulement ; valeurs de statut/dates laissées au serveur. Le retour doit confirmer annonce/auteur/parent/texte et published sans suppression, avec une date valide.

Projection publique sans email/téléphone/profil privé. L'auteur est présenté comme « Vous » ou « Membre » ; l'affichage d'un nom public est à compléter avec le futur profil vendeur. Aucun chargement des profils privés. Le modèle déduit la visibilité des champs explicitement sélectionnés, sans fallback sur une erreur RLS.

## Limites et tests

Pas d'édition/suppression des messages dans ce lot : un DELETE physique pourrait effacer des réponses d'autres membres par cascade, il n'est pas ajouté par défaut. Pas de Realtime ni de notifications ; relire explicitement la discussion. Les réponses sont triées chronologiquement et paginées : une nouvelle réponse après vingt messages peut nécessiter « Voir plus ».

Le parent doit être visible dans le client. Le trigger serveur ne vérifie pas son statut de modération ; un durcissement du parent masqué via API directe reste à examiner séparément. RLS et triggers restent l'autorité, les contrôles client ne les remplacent pas. Aucune certification de production ou recette d'écriture distante revendiquée.

Tests SDK HTTP fictifs et widgets : lecture publique filtrée/paginée, refus de session/parent absent, bornes Unicode, projection/INSERT restreints, réponses serveur non confirmées, refus RLS, navigation catalogue/favoris/détail, publication/réponse, erreur avec texte conservé, doubles envois/retour et changement de compte, 320 px/texte 150 % et pagination. Résultats finaux dans PROGRESS.

Version finale : **208 tests standard + 208 photos activées réussis**, dont 17 nouveaux tests commentaires (8 SDK, 9 widgets). Analyse stricte sans anomalie et format 75 fichiers conforme, diff check code 0. Date française JJ/MM/AAAA vérifiée. Aucun contenu utilisateur réel publié par les tests.

Commandes exécutées via le SDK existant (`dart .../flutter_tools.snapshot`) : `flutter test --no-pub --reporter expanded`, même suite avec `--dart-define=KIBO_LISTING_PHOTOS_ENABLED=true`, `flutter analyze --no-pub --fatal-infos`, `dart format --output=none --set-exit-if-changed lib test`, `git diff --check`. Journaux sous `.dart_tool/`, ignorés. Pas de dépendance ajoutée, APK généré ou installation Android.

Incidents courants corrigés dans le lot sans demande d'avis, conformément à la nouvelle consigne : réponse HTTP fictive sans request attendue par le SDK, ordre ID descendant par défaut rendu explicitement ascendant, carte sous la navigation dans un test (défilement réel/attente de rendu), infos de style. Aucun test désactivé.

Fichiers du lot : `lib/features/comments/comments_repository.dart`, `comments_page.dart`, `lib/main.dart`, `lib/features/listings/listing_feed.dart`, `listing_detail_page.dart`, `lib/features/favorites/favorites_page.dart`, `test/comments/comments_repository_test.dart`, `comments_widgets_test.dart`, `AGENTS.md`, `README.md`, `docs/WORKFLOW.md`, `docs/ARCHITECTURE.md`, `docs/PROGRESS.md`, `docs/NEXT_TASK.md`, `docs/COMMENTS.md`, `docs/MVP_STATUS.md`, `docs/OWNER_MANAGEMENT_DEPLOYED_20261101.md`, `docs/OWNER_MANAGEMENT_DEPLOYMENT_REVIEW.md`, `docs/OWNER_LISTING_MANAGEMENT.md`. Les fichiers SQL appliqués du lot précédent ne sont pas modifiés.
