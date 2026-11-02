# Notifications, signalements et modération — 2026-11-01

## Trois parcours

Le centre de notifications personnelles s'ouvre depuis la cloche et Profil. Liste de 20 lignes par page, filtre non lues, état vide, erreur/reprise. La cloche compte les non lues (requête limitée à 100 IDs, badge 99+), toutes les 30 secondes et immédiatement au retour du centre. Le clic marque uniquement cette notification comme lue via RPC, puis ouvre la conversation autorisée ou l'annonce/discussion indiquée. Aucune URL arbitraire n'est suivie ; une notification système reste lisible sans destination. Une cible disparue ne donne pas accès à du contenu masqué.

Le formulaire de signalement est disponible dans le détail d'annonce et sur chaque commentaire/réponse, catalogue et favoris compris. Connexion obligatoire ; une seule cible, motif explicite parmi cinq choix, précisions facultatives limitées à 2000 caractères. Aucun masquage automatique. Confirmation après réponse serveur ; erreur/doublon : saisie conservée, aucun retry automatique. Double envoi/retour bloqués pendant écriture.

L'entrée Modération de Profil n'apparaît qu'après autorisation du serveur. File paginée filtrée par état, lecture du contenu signalé via RPC administrateur et journal de la fiche. Motif de décision obligatoire (3–1000 caractères), confirmation, trois choix : rejeter le signalement ; clôturer sans masquer ; masquer le contenu puis clôturer. Une annonce publiée est retirée en passant à rejected avec motif ; un commentaire publié passe à hidden. Le traitement et le journal sont atomiques. Le motif d'un masquage est communiqué à l'auteur, explicitement annoncé dans la confirmation ; l'identité du signaleur ne lui est pas divulguée.

Ce parcours mobile minimal réutilise les droits existants. Aucun compte n'a reçu de rôle administrateur. L'interface web d'administration séparée envisagée, les sanctions de compte, la restauration d'un contenu et le traitement des signalements de profil ne sont pas implémentés. Les anciens signalements ayant plusieurs cibles ou ciblant un profil sont refusés par la fonction de décision.

## Contrat serveur et application autorisée

Audit réel préalable des schémas/politiques/guards : notifications SELECT propre, sans UPDATE ; reports INSERT propre pending, SELECT propre/admin et UPDATE admin ; aucune table de journal ni fonction de décision, aucun trigger de notifications. Réutilisation de ces tables, des guards annonces/commentaires et de private.is_admin (rôle issu de app_metadata signé, jamais de user_metadata).

Source exacte `supabase/proposals/safety_workflows.sql`, testée en SQL isolé puis autorisée (« Oui, appliquer ce contrat testé »). Migration **20261101051653 / kibo_safety_workflows**, apply_migration success=true. Aucune ligne existante modifiée par le déploiement ; aucun masquage ou signalement réel effectué pour tester.

- Table kibo_moderation_log : RLS, lecture administrateur, aucune écriture client. Identifiants de décision/cible/modérateur, action, motif et date ; pas de copie intégrale du contenu ni coordonnées.
- Fonctions publiques SECURITY INVOKER ; helpers SECURITY DEFINER dans kibo_safety_private, search_path vide, auth.uid et contrôle administrateur aux opérations concernées. Aucun EXECUTE PUBLIC/anon.
- Marquage lu limité à l'identité connectée, idempotent ; le client n'envoie aucune date ou identité arbitraire.
- INSERT reports limité aux colonnes reporter_id/cible/motif/précisions, statut/date serveur. Guard des nouvelles insertions authenticated : cible unique publiée, statut pending, auteur connecté et longueur, verrou de transaction par signaleur/cible pour refuser les doublons ouverts. Pas de nettoyage des signalements historiques ni de limite globale de fréquence.
- UPDATE reports direct retiré aux clients : la décision passe par la RPC, verrouille le signalement et refuse une clôture répétée. Les voies opérateur/service_role existantes restent privilégiées ; elles ne font pas partie du parcours client journalisé.
- Triggers des futurs messages/commentaires créant les notifications destinataires sans copier le texte des messages. Notifications de commentaire vers vendeur et auteur du parent, dédupliquées et sans auto-notification. Traitement d'un signalement : notification du signaleur ; masquage : notification de l'auteur.

Contrôle après application : RLS journal=true ; aucun UPDATE de colonne reports pour authenticated ; aucun INSERT journal client ; EXECUTE review anon=false/authenticated=true ; aucun definer public parmi les quatre RPC ; trois triggers installés ; journal encore vide au contrôle. Conseiller sécurité : seul avertissement préexistant [protection des mots de passe compromis](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection), réglages Auth inchangés. Cela ne constitue pas un audit exhaustif. [Référence des droits API/RLS consultée](https://supabase.com/docs/guides/api/securing-your-api).

## Vérifications et limites

25 nouveaux tests simulés (12 HTTP/repository, 13 widgets) : filtres/pagination/propriétaire, compteur limité aux IDs, marquage RPC, cible/champs/longueurs, refus de doublon sans retry, permission serveur avant file/journal/décision, A/B/A empêchant une décision tardive, affichage/erreur/reprise/vide, ouverture après lecture confirmée, formulaire et saisies conservées, double envoi, refus membre, confirmation/annulation administrateur, compteur actualisé au retour, visiteur et petit écran/texte agrandi.

SQL : `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Test-OwnerManagementSql.ps1 -Suite Safety -Port 55485`, code 0. Nouvelle fixture PostgreSQL 13 isolée, guards annonces réels et contrats reconstruits ; notification message/commentaire, isolation A/B/tiers/visiteur, lecture idempotente, métadonnées utilisateur sans privilège admin, signalements/doublons, masquage annonce/commentaire, journal protégé. Une défaillance volontaire du journal démontre le rollback du masquage et de la clôture. Cluster arrêté ; dossier `.dart_tool/owner-sql-75a5a103f7024bd6aa54d3e4eb5e933e` conservé. Ce test ne reproduit pas tout Supabase PG17/Auth/Storage.

Commandes Flutter (SDK existant via snapshot) : format lib/test ; analyze --no-pub --fatal-infos ; test --no-pub --reporter expanded ; même suite avec --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true ; git diff --check. Résultats globaux et lancement téléphone consignés dans PROGRESS.

Résultats finaux : 272 tests standard et 272 photos activées réussis, analyse stricte sans anomalie (57,5 s), format 89 fichiers sans changement, diff check code 0.

Lot compilé/installé/lancé sur le TECNO connecté via flutter run --no-resident, photos activées et configuration locale existante, code 0 ; activité MainActivity et processus observés. Aucune donnée effacée. Ce démarrage ne valide pas les interactions réelles entre deux comptes ni une opération de modération.

Session : champs privés et contenus effacés, écran définitivement invalidé et réponses tardives ignorées lors d'un changement de compte ; révision SDK pour A/B/A, listeners/timer libérés à la destruction. Le compteur est périodique pendant que son widget est monté ; pas de notifications push OS ni de réplication notifications activée. Pas de rattrapage automatique des événements antérieurs au déploiement, ni de notifications de publication dans ce lot. Pas de génération/réception réelle avec deux comptes testée, ni de décision réelle sur contenu utilisateur.

## Fichiers du lot

- Nouveaux : `lib/features/safety/safety_repository.dart`, `safety_page.dart`, `safety_entry.dart` ; `test/safety/safety_repository_test.dart`, `safety_widgets_test.dart` ; `supabase/proposals/safety_workflows.sql` ; `test/sql/safety_fixture.sql`, `safety_assertions.sql` ; ce document.
- Intégration : `lib/main.dart`, `lib/features/auth/profile_page.dart`, `lib/features/listings/listing_feed.dart`, `listing_detail_page.dart`, `lib/features/favorites/favorites_page.dart`, `lib/features/comments/comments_page.dart` ; suite Safety ajoutée à `scripts/Test-OwnerManagementSql.ps1`, autres suites conservées.
- Documentation : README, ARCHITECTURE, PROGRESS, NEXT_TASK et MVP_STATUS. Tous les changements antérieurs préservés ; aucun commit/push.
