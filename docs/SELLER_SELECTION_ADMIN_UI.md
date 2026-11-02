# Vendeur, sélection des cartes et entrée Administration — 2026-11-02

## Trois ajustements demandés

- Profil vendeur : Message direct reste au-dessus de WhatsApp, avec au moins 16 px d’écart. Pour un visiteur, l’écran de connexion s’ouvre avant la discussion ; annuler ne crée aucune conversation. Sur sa propre annonce, le bouton reste désormais visible mais désactivé, avec une explication, au lieu d’être masqué. Les moyens WhatsApp/appel et leur logo sont conservés.
- Mes annonces : l’appui sur le contenu de toute carte éligible sélectionne/désélectionne l’annonce. Les cases restent utilisables, les boutons Modifier/Vendue/Supprimer gardent leur propre action sans sélectionner la carte en plus. Bordure et fond distinguent les cartes sélectionnées. Une barre reste en bas de l’écran pendant le défilement : compteur, Supprimer la sélection, Marquer la sélection vendue et Tout désélectionner. Sa hauteur est bornée à 40 % de la hauteur disponible et son contenu peut défiler avec un texte très agrandi. Un appui de sélection ferme le clavier ; même si un clavier reste affiché, la barre ne déborde pas.
- Profil admin : `SafetyEntry` affiche maintenant le même `KiboMenuAction` (Card/ListTile, icône, chevron, espacements et largeur) que les autres entrées. Le contrôle serveur existant reste nécessaire pour afficher l’entrée ; aucun droit n’est accordé par le style.

## Suppression groupée

Le bouton reprend le retrait existant du catalogue : **archivage**, conservation des photos/conversations/favoris, confirmation obligatoire et bilan des échecs partiels. Pas d’effacement définitif ajouté. Seules les annonces publiées/vendues et déjà chargées sont éligibles ; aucune sélection implicite de toutes les pages du compte. Les gardes de session, les contrôles de propriétaire/version et les mutations serveur existantes sont conservés. Aucun traitement réel de données distantes effectué pour les tests de ce lot.

## Fichiers et validation

Code : `lib/features/seller/seller_page.dart`, `lib/features/listings/my_listings_page.dart`, `lib/features/safety/safety_entry.dart`. Tests nouveaux : `test/review4_selection_profile_test.dart` (huit scénarios) ; tests existants de suppression et d’espacement vendeur adaptés dans `review2_ui_test.dart` et `review3_seller_search_price_test.dart`.

Huit nouveaux tests et quinze tests de revue précédente réussis, ainsi que les sept tests vendeur/recherche/prix. Ils couvrent l’appui sur le contenu des cartes, la suppression groupée confirmée/annulée, les échecs partiels existants, l’absence de double sélection sur cases/boutons, le bouton propre vendeur désactivé, l’écart Message/WhatsApp, le style admin clair/sombre et le clavier ouvert sur une fenêtre réduite. Scénarios sur petit écran 320 px et texte ×1/×2. Ce sont des fixtures, pas une suppression réelle ni une recette sous le compte admin du téléphone.

Commandes SDK local : `dart format lib test`, `flutter analyze --no-pub --fatal-infos`, tests ciblés, suites complètes standard/photos, `git diff --check` et lanceur Android profile après validation. **442 tests standard + 442 photos activées réussis**, analyse et diff conformes. Sept tests de revue rejoués avec polices réelles et export PNG ; captures `.dart_tool/review4-selection-1.0.png` et `review4-selection-2.0.png` inspectées. Résultat d’installation dans PROGRESS. Aucun changement SQL/RLS/Auth requis ; aucun commit/push autorisé.

Dernier cas ajouté : clavier ouvert avec 400 px d’inset sur une fenêtre de 640 px ; barre limitée à la hauteur réellement disponible, sélection qui défocalise le clavier. **443 tests standard + 443 photos activées réussis**, 23 tests ciblés rejoués après ce correctif, analyse finale conforme. Installation finale : build profile 83,6 s, installation 5,1 s, processus **20344**, KIBO au premier plan confirmé, sans effacement. Aucun clic de suppression réelle réalisé sur le téléphone.
