# Revue des écrans, administration et second lot — 2026-11-02

## Écrans et gestes

Espacement vertical commun de 16 px minimum via `KiboFormColumn` / `KiboFormListView`, sans cumuler les anciens séparateurs. Appliqué aux formulaires d’authentification, recherche, profil/contact, compte et données, demandes de compte, commentaires et signalements. Les formulaires de publication/modification conservent leurs séparateurs de champs existants. Les barres d’actions repliables ont aussi un espacement entre lignes.

Favoris, Mes annonces et Notifications : tirer **verticalement vers le bas depuis le haut** actualise aussi les listes courtes/vides. Les critères restent actifs ; les annonces affichées sont conservées si une actualisation échoue. Le geste demandé comme « horizontal » pour Notifications est interprété comme le rafraîchissement usuel vers le bas, pas comme une navigation latérale.

Les routes Profil → Mes annonces → Modifier transmettent désormais `ListingPhotoScope` : l’absence de cette dépendance empêchait le chargement des images sur ces écrans. Le cache existant est réutilisé.

Mes annonces propose la sélection des annonces chargées et éligibles, l’archivage groupé et le marquage vendu. Confirmation, contrôle de session, mutations serveur existantes et bilan des échecs partiels. Le retrait du catalogue est un **archivage**, sans destruction des photos/conversations. Une sélection ne couvre pas les pages qui n’ont pas été chargées. Aucun effacement définitif ajouté.

## Administration

Nouvelle entrée Profil → Administration avec deux modules : signalements/modération et demandes de compte. Le tableau d’accueil affiche des compteurs sur la première page (20+ si pleine), le chargement/erreur/refus et l’actualisation. Les files et décisions existantes conservent leurs vérifications serveur, motifs, confirmations et journaux.

Instruction utilisateur explicite appliquée : `kanasmeth@gmail.com`, compte confirmé, a reçu `app_metadata.role=admin`. Mise à jour distante bornée à son UUID et son email, métadonnées restantes préservées. Contrôle de `private.is_admin()` : rôle lu dans le JWT signé, jamais dans `user_metadata`. Les deux comptes de données restent membres. Une déconnexion/reconnexion est nécessaire pour disposer d’un nouveau jeton et voir l’entrée. Aucun mot de passe demandé ou changé.

Pas de console web dédiée, d’attribution des rôles depuis Flutter, de suspension globale ni de suppression définitive de compte dans ce MVP. Le traitement d’une demande ne constitue pas l’effacement du compte. Aucune nouvelle migration ni politique RLS requise pour cet écran.

## Second jeu de données autorisé

Choix explicite : vendeur `frposx@gmail.com`, 1 080 annonces supplémentaires et 4 320 commentaires/réponses. Questions sous l’autre compte de test désigné ; réponses sous le vendeur. Manifeste `assets/test_catalogue/stress_catalogue.json`, lot `kibo-stress-20261102-v1`, 120 annonces dans chacune des neuf catégories. IDs stables distincts du premier lot. Titres TEST PERF et descriptions fictives explicites.

108 sources d’images réutilisées (95 visuels distincts), chacune téléversée vers l’objet propre à son annonce. Ce jeu augmente le nombre de lignes, pages et objets ; ses petites images compressées ne simulent pas des milliers de grandes photos uniques ni une charge simultanée de nombreux utilisateurs.

Le lanceur accepte les deux manifestes autorisés, vérifie le volume/lot et l’identité, compresse chaque source une fois, puis traite au plus trois annonces en parallèle. Reprise par IDs stables, pas de nettoyage ou réessai automatique après échec. Les commentaires opérateur sont bornés au manifeste, aux deux auteurs et aux annonces avec JPEG confirmé ; parents avant réponses, conflits différents refusés, aucune suppression/mise à jour des commentaires existants.

Incident réel : erreur réseau `ClientException` après 612 confirmations. Les 612 IDs du préfixe ont été confrontés au manifeste (vendeur, titre, publication, marqueur, photo position 0 et objet JPEG non vide) : 612/612 confirmés. Reprise ciblée avec `KIBO_SEED_VERIFIED_PREFIX=612` dans la configuration ignorée, uniquement après ce contrôle distant ; les éléments suivants conservent leurs IDs idempotents. Ce paramètre n’est pas une vérification autonome et doit être remis à zéro pour un autre lot. Cinq transactions opérateur de 108 annonces ont importé les 2 160 premiers commentaires, sans toucher au premier lot.

## Vérifications locales acquises

Suites complètes : **426 tests standard et 426 avec photos activées réussis** ; analyse stricte : aucune anomalie. Après les derniers détails de disposition, les 42 tests ciblés concernés ont été rejoués avec succès. Les 15 tests de revue couvrent notamment les écarts à texte ×1/×2, les trois rafraîchissements, l’archivage confirmé/annulé/partiel, les droits administrateur/révocation/A-B-A et la transmission du service photo jusqu’à la modification. Neuf tests d’import couvrent aussi le nouveau manifeste et le cache des sources avec parallélisme borné. Captures des vrais widgets avec données simulées : contrôle visuel distinct d’une session admin réelle sur téléphone.

L’import distant et la réinstallation normale sont consignés séparément après vérification effective ; une compilation ou un compteur en cours ne prouve pas la fin du chargement. `scripts/Launch-KiboAndroid.ps1 -ProfileMode` prépare un lancement en mode profile, avec les mêmes paramètres et sans effacement. Aucun résultat FPS ou mesure de fluidité en mode profile n’est revendiqué. Aucun commit/push autorisé.

## Bilan distant réellement vérifié

Le compteur natif a terminé à 1 080. Les dix transactions opérateur de commentaires sont achevées. Audit final : **1 080 annonces publiées, 1 080 objets JPEG non vides, 4 320 commentaires publiés (2 160 racines et 2 160 réponses)** ; 120 annonces dans chacune des neuf catégories. 4 320 notifications automatiques de commentaire ; aucun auteur/destinataire hors des deux comptes désignés. Vendeur frposx, questions smethturc, réponses frposx.

Premier lot conservé : 108 annonces publiées, 108 JPEG, 432 commentaires et 432 notifications. Total des deux lots : **1 188 annonces, 1 188 objets image et 4 752 commentaires**. RLS active sur les six tables contrôlées (annonces, photos, commentaires, notifications, signalements et journal). Rôles vérifiés : deux comptes de test membres, kanasmeth admin. Aucun schéma, politique, bucket ou préférence de notification modifié.

Les dix SQL de commentaires et l’audit sont conservés sous `.dart_tool/stress-preparation/`, ignoré par Git. Ce chargement opérateur ne constitue pas une recette du formulaire de commentaire sous le compte acheteur. L’attribution du rôle ne constitue pas une connexion native réelle sous le compte administrateur.

Installation normale terminée : `scripts/Launch-KiboAndroid.ps1 -ProfileMode`, build profile 56,6 s, installation 6,4 s, processus **13433**, premier plan confirmé, sans désinstallation/effacement. Capture Android réelle inspectée : accueil KIBO sombre avec les nouvelles annonces TEST PERF et leurs images chargées. Les gestes et décisions admin n’ont pas été exercés physiquement ; aucun FPS mesuré. Capture locale ignorée `.dart_tool/review2-phone-profile.png`.

## Fichiers et commandes

Code : nouveau composant `lib/core/widgets/kibo_form_layout.dart` et écran `lib/features/safety/admin_page.dart` ; intégration dans `main.dart`, formulaires auth/profil/contact/commentaires/signalements, recherche, favoris, gestion des annonces et demandes de compte. Import : `test_catalogue_importer.dart`, `tool/import_test_catalogue.dart`, `scripts/prepare_stress_catalogue.py`, manifeste stress, `pubspec.yaml` et option profile du lanceur Android. Tests : `test/review2_ui_test.dart`, importeur et adaptation du défilement des tests de gestion/modération existants. Aucun travail préexistant supprimé/réinitialisé.

Commandes réellement exécutées via le SDK local : `dart format lib test tool`, `flutter analyze --fatal-infos`, `flutter test`, `flutter test --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true`, tests UI ciblés, export PNG des vrais widgets, `git diff --check`, compilation APK profile et lanceurs PowerShell d’import/reprise. Vérification de syntaxe PowerShell réussie. Les journaux bruts contenant potentiellement des paramètres de compilation restent ignorés et ne doivent pas être partagés sans expurgation.
