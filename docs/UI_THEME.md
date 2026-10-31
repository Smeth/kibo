# Socle visuel KIBO — KIBO-003

## Manrope locale et provenance

Trois TTF statiques non modifiés sont embarqués, sans dépendance de chargement de police ni requête réseau : Regular 400, SemiBold 600 et ExtraBold 800. La famille Flutter déclarée dans `pubspec.yaml` est `Manrope`.

Source officielle : [googlefonts/manrope](https://github.com/googlefonts/manrope), révision figée [`468c0dbe38efa331b80bfe9448256abe27be44c3`](https://github.com/googlefonts/manrope/tree/468c0dbe38efa331b80bfe9448256abe27be44c3). Les fichiers proviennent de `fonts/ttf/` et leurs identifiants de blobs Git correspondent aux originaux.

| Fichier sous `assets/fonts/manrope/` | Poids vérifié dans OS/2 | SHA-256 du TTF |
|---|---|---|
| `manrope-regular.ttf` | 400 | `D23D6EEDF51DD495138AA1A83588027D4A63549CDFCC2FA5E0D8E84E09CF4CB1` |
| `manrope-semibold.ttf` | 600 | `F43EDB46A08E1538413EA2383EF01ED93CDAB191A2C57D2489D9590985858CF7` |
| `manrope-extrabold.ttf` | 800 | `C5C0FAA3C3A1B1A184F6BB2E405931BDBF51D21C72D8162309118E91304988E0` |

Licence : [SIL Open Font License 1.1 du même dépôt](https://github.com/googlefonts/manrope/blob/468c0dbe38efa331b80bfe9448256abe27be44c3/OFL.txt), copyright 2018 The Manrope Project Authors. Le texte complet est conservé dans `assets/fonts/manrope/OFL.txt`, avec seulement normalisation des fins de ligne et suppression des espaces en fin de ligne. Les TTF ne sont ni transformés ni renommés. La licence est aussi embarquée comme asset et enregistrée une seule fois dans `LicenseRegistry` via `KiboTheme.registerFontLicense()` ; aucune nouvelle page métier n’est ajoutée.

## Thème et composants

- `lib/core/theme/kibo_colors.dart` centralise les douze couleurs de la charte. `primaryContainer` conserve la teinte de sélection claire déjà présente dans l’accueil ; les quatre fonds illustratifs des annonces fictives sont conservés.
- `lib/core/theme/kibo_theme.dart` définit le thème clair Material 3, le `TextTheme` Manrope, les cartes, boutons, champs et la navigation. Titres/logo : 800 ; sections et libellés importants : 600 ; corps : 400. Les textes secondaires utilisent désormais au moins 12 px logiques.
- `MaterialApp` utilise `KiboTheme.light`. L’accueil reste dans `main.dart`, avec les mêmes catégories, quatre annonces fictives, cinq destinations et callbacks. Pas de nouvelle navigation ni fonctionnalité métier.
- Marges horizontales 16, espacements multiples de 4, cartes de rayon 16 et contrôles de rayon 12. Boutons de hauteur minimale 52, champ décoratif de hauteur minimale 56 et icônes standard 24. Les icônes d’illustration et de statut gardent une taille adaptée à leur rôle.
- Depuis KIBO-003.1, les annonces sont regroupées par rangées d’une ou deux colonnes selon la largeur et l’échelle du texte. Une illustration a une hauteur explicite calculée sur la largeur, bornée entre 140 et 180 px logiques ; le texte grandit naturellement, sans limite de lignes. `IntrinsicHeight` égalise les deux cartes d’une rangée ; son coût est limité aux quatre annonces fictives et devra être réévalué pour un futur flux réel. Le champ décoratif, l’en-tête, la bannière et les catégories peuvent aussi grandir.
- `lib/core/widgets/kibo_bottom_navigation.dart` utilise les styles de navigation du thème et mesure les cinq libellés avec le `TextScaler` système, sans plafonnement. Les cellules ont la même largeur et la même hauteur, avec une zone tactile d’au moins 64×72 px. Lorsque cinq colonnes ne tiennent plus, les destinations sont réparties sur plusieurs rangées centrées, sans masquer ni tronquer leurs libellés. Les états sélectionnés et les actions existantes sont conservés.
- Le démarrage Supabase, son service, sa configuration et ses paramètres de build ne sont pas modifiés. L’ajout au démarrage concerne uniquement l’enregistrement différé de la licence, sans réseau.

## Vérification et limites

### Vérification initiale KIBO-003

Les 13 tests précédents sont conservés sans modification. Onze tests s’ajoutent : assets et licence, thème réellement hérité, licence sans doublon, chargement/reconstruction sans seconde initialisation, six scénarios de rendu et erreur de configuration à texte agrandi.

Les tests responsive chargent les vrais TTF : 320×640 à facteurs 1, 2 et 3 ; 360×800 à 1,5 ; 393×800 à 2 ; 800×600 à 2. Ils vérifient le défilement jusqu’à la dernière annonce, les prix, les libellés de navigation dans leurs limites, la sélection de Profil et l’absence d’exception de rendu. Les tests ne contactent pas Supabase.

Des aperçus locaux à 393×852 avec Manrope et Material Icons ont été générés puis inspectés, en haut de page et sur les cartes après défilement. Le banc d’essai et les PNG restent sous `.dart_tool/`, ignorés par Git. Ce contrôle ne remplace pas une revue physique sur TECNO : aucun nouveau déploiement sur téléphone ni test réel Supabase n’est effectué pour cette intégration visuelle. La connexion réelle réussie de KIBO-002 reste documentée séparément.

Les commandes et résultats de validation sont consignés dans [PROGRESS.md](PROGRESS.md). Aucun thème sombre, contenu réel, schéma SQL, politique RLS, parcours d’authentification ou messagerie n’est ajouté.

### Complément KIBO-003.1

Les 24 tests de KIBO-003 sont conservés ; seules les assertions dépendant du composant Material remplacé sont adaptées. Six tests supplémentaires chargent les vrais TTF : quatre cas de navigation (320 et 360 px, texte 1 et 1,5) et deux cas pour les cartes (360 px, texte 1 et 1,5). Ils vérifient les libellés sur une ligne, l’échelle non plafonnée, la visibilité et l’alignement des destinations, les zones tactiles et leurs actions, les illustrations alignées et bornées, ainsi que l’accès aux quatre annonces. Résultat local : 30 tests réussis. Le contrôle physique reste distinct des tests automatisés ; ses résultats sont consignés dans `PROGRESS.md`.

Version corrigée installée et inspectée sur TECNO CK6n / Android 14 le 2026-10-31, en portrait, à 100 % puis 150 %. Les trois défauts ciblés sont corrigés dans ces conditions ; les cinq destinations et quatre annonces restent accessibles. La navigation prend deux rangées à 150 %, sans couper « Recherche ». Taille de texte initiale restaurée à 100 %. Captures uniquement hors Git ; aucune clé réelle publiée.
