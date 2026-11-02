# Accueil, villes et ancienneté — 2026-11-01

L’accueil reprend une composition plus proche de la référence initiale : en-tête vert compact, recherche large, choix de ville, catégories à icônes et cartes photo avec prix vert. Recherche et favoris utilisent des lignes compactes ; les menus de profil sont resserrés. Les composants respectent les thèmes clair/sombre et les parcours existants.

## Villes

Le catalogue embarqué contient 4 538 noms distincts issus de 5 778 enregistrements de lieux habités du Congo-Brazzaville (CG) dans l’export GeoNames récupéré le 1er novembre 2026. Source : https://download.geonames.org/export/dump/CG.zip ; licence et transformations dans `assets/data/GEONAMES-LICENSE.txt`. Il comprend des villes et localités rurales, sans garantie de recensement administratif exhaustif. Les noms homonymes sont regroupés, car le modèle actuel stocke une chaîne, sans identifiant géographique.

Le sélecteur est disponible depuis l’accueil, les filtres, la publication, la modification d’annonce et le profil. Recherche locale par nom et variantes, principales villes en tête, liste défilante chargée à la demande et cache en mémoire. Les formulaires conservent la saisie libre pour les anciennes valeurs et localités manquantes. Aucun GPS, accès réseau à l’utilisation ou modification des données existantes.

Le filtrage serveur reste celui du dépôt : égalité sur la ville enregistrée. La recherche de variantes dans le sélecteur ne normalise pas les anciennes annonces. L’import reproductible est dans `tool/import_congo_places.py` ; aucune dépendance ajoutée.

## Dates

`PublicListing` lit désormais le champ `published_at`, déjà présent dans la projection publique. Les cartes, listes et détails affichent minutes, heures, jours, mois et années. Aucune date inventée : champ absent omis sur les cartes et signalé sur le détail ; date future affichée en date absolue. L’ancienneté est recalculée à la reconstruction ou au rafraîchissement, sans minuteur permanent.

## Fichiers du lot

- Accueil : `lib/main.dart`, `lib/features/chat/chat_overview.dart`, `lib/features/listings/category_shortcuts.dart`.
- Villes : `lib/core/widgets/congo_city_field.dart`, `assets/data/`, `pubspec.yaml`, registre de licences dans `lib/core/theme/kibo_theme.dart` ; `lib/features/listings/catalogue_search_form.dart`, `publish_listing_page.dart`, `edit_listing_page.dart` et `lib/features/profile/edit_profile_page.dart`.
- Dates et cartes : `lib/core/widgets/publication_age.dart`, `lib/features/listings/listing_models.dart`, `listing_card.dart`, `listing_feed.dart`, `listing_detail_page.dart`, `lib/features/favorites/favorites_page.dart` ; espacement des menus dans `lib/core/widgets/kibo_section.dart`.
- Tests : `test/locations/congo_city_test.dart`, `test/listings/publication_age_test.dart`, assertions d’accueil dans les tests widget et Auth.
- Références : générateur `tool/export_maquettes_test.dart`, 68 PNG de 34 écrans/panneaux, galerie et manifeste dans `maquette/`.

Les annonces, profils, échanges et images des maquettes sont fictifs ; les noms géographiques proviennent du catalogue public attribué. Les PNG représentent un viewport, pas la totalité des pages défilantes. Ils ne constituent pas une copie pixel par pixel de l’image initiale.

## Vérifications et limites

Neuf nouveaux tests couvrent le catalogue, la recherche/sélection de ville, le filtre d’accueil et sa réinitialisation, le petit écran avec clavier et grand texte, la lecture des dates et leurs bornes, ainsi que les cartes normales/compactes. Résultats : **355 tests standard + 355 photos activées réussis**, analyse stricte sans anomalie, format 121 fichiers inchangés et diff conforme. Export supplémentaire réussi, 68 PNG et dimensions vérifiés. Une première passe avait révélé une infobulle doublonnée du bouton de chat ; elle a été corrigée avant les deux passes finales. Journaux `.dart_tool/reference3-{format,analyze,tests,photos-tests}.log`. La relance Android est consignée dans `PROGRESS.md`.

Aucun SQL, droit, paramètre Auth ou contenu distant modifié ; aucun compte ni annonce de recette réelle créé. Aucun commit/push. Le profilage et la recette à deux comptes restent différés. Les tests de widgets et l’export ne remplacent pas une recette complète sur appareil.
