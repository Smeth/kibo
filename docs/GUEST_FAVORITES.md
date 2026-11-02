# Favoris sans connexion — 2026-11-01

Les trois tâches approuvées sont implémentées localement : ajout/retrait visiteur, persistance sur le téléphone, transfert proposé au compte. Aucun déploiement ni écriture Supabase réelle pendant le développement.

## Expérience

Un visiteur utilise les mêmes cœurs du catalogue et du détail. L'onglet Favoris affiche « Favoris sur ce téléphone ». La sélection est conservée après fermeture et déconnexion. Le contenu des annonces est relu publiquement, y compris après connexion ; une annonce retirée/archivée n'est pas affichée. Son ID reste dans la sélection, sans conférer un droit d'accès.

Après connexion, l'onglet Favoris affiche les favoris du compte et propose « Ajouter à mon compte » pour la sélection locale restante. « Plus tard » masque l'offre jusqu'au prochain changement de session ; aucune écriture serveur. Le bouton de transfert ouvre une confirmation ; une annulation ne transfère rien. Aucun favori du compte n'est copié vers la sélection visiteur à la déconnexion.

## Persistance et erreurs

La clé `kibo.guestFavorites.v1.<hôte-projet>` utilise flutter_secure_storage déjà installé, indépendamment des clés session/PKCE. Format JSON versionné : version 1 et liste dédupliquée d'identifiants. Aucun titre, prix, photo, URL signée, identité ou jeton n'est enregistré dans cette clé. Aucun deleteAll, migration serveur ou nouvelle dépendance.

Lecture/corruption en échec : pas de réinitialisation silencieuse ni d'écrasement de l'ancienne sélection. Écriture en échec : sélection précédente conservée en mémoire, pas de faux succès. Les doubles écritures sont bloquées par le contrôleur. Un échec après écriture effective peut nécessiter une relance pour relire le stockage ; aucune garantie d'atomicité système inventée.

Le contenu nécessite une connexion réseau : ce lot ne constitue pas un catalogue hors ligne. L'ajout/retrait sur une fiche déjà ouverte n'effectue aucune requête réseau ; les IDs restent disponibles malgré une panne réseau. Les lectures sont bornées à vingt IDs par page, en utilisant les fiches publiques existantes (au plus vingt requêtes concurrentes). La pagination avance sur les IDs examinés, pas seulement sur les fiches visibles ; son offset tient compte des retraits dans les pages déjà examinées. Un traitement serveur groupé pourra réduire les requêtes ultérieurement.

## Transfert et isolation

L'accord capture le compte et la révision de session. Changement A/B ou A/B/A : accord périmé, aucun transfert vers la nouvelle session. Le traitement vérifie ces valeurs avant chaque ajout et après les lectures. Une requête déjà envoyée peut être effective sur A ; un changement de session ne peut pas annuler cette écriture. La sélection locale est conservée si la confirmation serveur n'a pas été obtenue.

Les IDs déjà présents dans le compte sont ignorés à l'ajout. Le repository authentifié existant reste l'autorité pour INSERT et ses contrôles RLS. Une relecture des IDs du compte confirme le résultat ; seuls les IDs confirmés quittent le stockage local. Un élément refusé reste local tandis que les autres peuvent réussir. Échec de suppression locale après succès serveur : sélection conservée, reprise dédupliquée. Favoris préexistants du compte intacts ; aucun DELETE distant.

La sélection visiteur appartient à l'appareil, pas à une identité. Sur téléphone partagé, chacun peut voir cette sélection publique et choisir explicitement de la transférer à son propre compte. Elle n'inclut jamais les favoris privés d'un compte déconnecté. La désinstallation, l'effacement des données ou les comportements natifs de sauvegarde/restauration ne sont pas une persistance garantie par ce lot.

## Tests et limites

Tests ciblés favoris/navigation : **34 réussis** (28 favoris + 6 navigation), dont 18 nouveaux tests favoris (15 contrôleur/stockage/transfert et 3 widgets). Couverture : restauration par nouvelle instance, séparation par projet et logout, corruption, erreurs lecture/écriture, doubles pressions, ajout hors réseau, réseau/reprise, annonces masquées, pagination après retrait, déduplication, refus/annulation, transfert partiel, reprise après erreur disque et changements de compte. Widget sur 320 px avec échelle 150 % effectivement vérifiée, navigation détail et état commun des cœurs.

Stockage natif simulé via le mock officiel de flutter_secure_storage ; services de compte/catalogue fictifs. Aucune recette TECNO, aucune preuve de stockage sécurisé sur appareil, de persistance après arrêt Android réel ou de transfert Supabase réel revendiquée. Suite complète initiale : 186 réussis et quatre timeouts navigation ; analyse initiale : trois infos de style. Corrections suspendues conformément à WORKFLOW, puis autorisation utilisateur « Oui, corriger et terminer le lot ». Timeouts corrigés par injection du store fictif dans les tests de navigation ; aucun timeout augmenté, aucun test retiré. Résultats finaux à consigner dans PROGRESS.

Contrôles exécutés : `flutter test --no-pub test/favorites test/kibo_layout_regression_test.dart --reporter expanded` (34 réussis), `flutter test --no-pub --reporter expanded` (191 réussis), même suite avec `--dart-define=KIBO_LISTING_PHOTOS_ENABLED=true` (191 réussis), `flutter analyze --no-pub --fatal-infos` (aucune anomalie), `dart format --output=none --set-exit-if-changed lib test` (71 fichiers, zéro changement), `git diff --check` (code 0, avertissements LF/CRLF préexistants). Commandes Flutter exécutées via le SDK installé (`dart .../flutter_tools.snapshot`) avec accès aux caches ; aucun pub get ni changement de dépendances.

Fichiers du lot : `AGENTS.md`, `README.md`, `docs/CAHIER_DES_CHARGES.md`, `docs/DECISIONS_TECHNIQUES.md`, `docs/ARCHITECTURE.md`, `docs/LISTINGS.md`, `docs/GUEST_FAVORITES.md`, `docs/PROGRESS.md`, `docs/NEXT_TASK.md`, `lib/main.dart`, `lib/features/favorites/guest_favorites.dart`, `favorites_controller.dart`, `favorites_page.dart`, `favorite_button.dart`, `test/support/guest_favorites_fake.dart`, `test/favorites/guest_favorites_test.dart`, `test/favorites/favorites_widgets_test.dart`, `test/kibo_layout_regression_test.dart`. Nouveaux fichiers : contrôleur/store guest, fake store, tests guest et présent document. Changements antérieurs conservés.
