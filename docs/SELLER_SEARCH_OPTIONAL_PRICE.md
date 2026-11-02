# Profil vendeur, recherche progressive et prix facultatif — 2026-11-02

## Profil vendeur et message direct

`SellerPage` utilise l’espacement commun de 16 px minimum entre ses éléments, notamment WhatsApp/appel. Bouton Message direct ajouté quand un service de chat est disponible et que le vendeur n’est pas le membre connecté. Le détail d’annonce utilise le même parcours : visiteur → AuthPage → discussion après connexion réussie. Annulation : aucune conversation créée. Pas de message automatique, de conversation avec soi-même ni de coordonnées privées lues pour ouvrir le chat. Les contrôles de session et de participant du repository restent applicables.

Le pictogramme WhatsApp vient du site officiel : SVG source conservé, rendu PNG transparent 128 px, tracés et couleur officiels préservés, sur pastille blanche pour les deux thèmes. Aucune nouvelle dépendance Flutter. Provenance dans `assets/branding/README.md`.

## Recherche

Le vecteur distant combine le **titre et la description**. Le client utilisait `websearch_to_tsquery`, qui recherche des mots/lexèmes complets : contrôle distant sur les annonces publiées, « iph » = 0 résultat, alors que `iph:*` = 44. La saisie seule ne déclenchait pas de lecture.

Correction : recherche automatique après 350 ms sans nouvelle saisie dès trois caractères, effacement automatique lors d’une saisie vidée, bouton Rechercher et validation clavier conservés. Le clavier et le curseur restent actifs. Timer annulé au démontage, à l’application explicite et à l’effacement. Les réponses tardives restent ignorées par le feed existant.

Contrôle réel supplémentaire via l’API publique, avec la seule clé publique et les droits visiteur : `iph:*`, HTTP **206**, 20 lignes retournées, Content-Range **0-19/44**. Aucun jeton de session extrait ni donnée écrite pour ce contrôle.

Recherche par préfixes sur les mots du titre/description, via le vecteur GIN existant. Seules les lettres/chiffres Unicode construisent la tsquery ; pas d’opérateur fourni par le visiteur. Plusieurs termes sont combinés par ET ; ils peuvent être répartis entre titre et description dans le vecteur courant. Repli pour ancien backend conservé, désormais avec les mêmes préfixes, sur titre ou description. Même comportement de préfixe dans Mes annonces. Une saisie uniquement composée de signes reçoit une erreur de validation.

Cela n’est pas une correction orthographique ni une recherche au milieu de tous les mots ; la normalisation française existante demeure. Les filtres de ville/catégorie/prix et la pagination de vingt restent en place.

## Prix facultatif réellement activé

Prix vide dans Flutter → `NULL` PostgreSQL → **Prix à négocier** dans cartes, détail, favoris, gestion et aperçu. Prix explicite zéro → **0 XAF**. Validation/précision des prix renseignés inchangées ; publication et modification envoient bien NULL et comparent les confirmations sans confondre zéro/absence. Prix facultatif indiqué dans les deux formulaires, quatre champs requis au lieu de cinq dans la préparation. Les bornes de recherche excluent naturellement les annonces sans prix ; les tris par prix placent les NULL à la fin avec le SDK courant.

Fichier exact : `supabase/proposals/optional_listing_price.sql`. Tests réels PostgreSQL local jetable : publication sans prix, ajout de zéro, retrait du prix, refus d’un prix négatif et de la modification par un autre vendeur. Réapplication idempotente testée ; transaction des données fictives annulée, cluster arrêté. Commande : `scripts/Test-OwnerManagementSql.ps1 -Suite OptionalPrice -Port 55492`.

Après accord explicite « Oui, appliquer le prix facultatif dans Supabase », migration **20261102021424 / kibo_optional_listing_price** appliquée avec succès. Seul `ALTER COLUMN price DROP NOT NULL` ; aucun DML ni changement de RLS/grant/trigger/index. Contrôle distant avant/après : **1 200 annonces**, empreinte identique des IDs/prix, des politiques et des triggers ; RLS toujours active ; nullable NO → YES. Aucun prix existant changé. Ce contrôle de contrat ne constitue pas une publication réelle sans prix sous une session mobile.

Les conseillers distants avant/après conservent les avertissements existants : [protection des mots de passe compromis](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection), [journal d’actions à RLS sans politique directe](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy) (accès volontairement fermé), et recommandations de [performance/index](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys)/[RLS](https://supabase.com/docs/guides/database/database-linter?lint=0003_auth_rls_initplan). Aucun réglage Auth ni optimisation de politiques hors périmètre appliqué.

## Vérifications et fichiers

**435 tests standard + 435 avec photos activées réussis.** Tests dédiés : prix NULL distinct de zéro, sérialisation de publication/modification, préfixes Unicode/injection, temporisation/curseur/annulation de timer, espacements à 320 px et texte ×1/×2, connexion/annulation avant discussion. Analyse stricte sans anomalie. Journaux ignorés sous `.dart_tool/review3-*` ; résultats finaux et installation consignés dans PROGRESS.

Fichiers principaux : `seller_page.dart`, nouveau `chat/open_seller_chat.dart`, `listing_detail_page.dart`, `catalogue_search_form.dart`, `listing_query.dart`, modèles et repositories publics/propriétaire, formulaires publication/modification, assets de marque et `pubspec.yaml`. Tests de régression adaptés au nouveau parcours de connexion. Documentation produit mise à jour. Aucun commit/push.

Commandes exécutées avec le SDK local : `dart format lib test tool`, `flutter analyze --no-pub --fatal-infos`, `flutter test --no-pub`, `flutter test --no-pub --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true`, sept tests dédiés avec export des vrais widgets, `git diff --check`, test PostgreSQL local ci-dessus et `scripts/Launch-KiboAndroid.ps1 -ProfileMode`. La capture de widgets utilise des fixtures ; elle ne prouve pas l’envoi d’un message ou une publication réelle sans prix sur téléphone.

Installation réellement terminée : build profile 49,9 s, installation 8,0 s, processus **16509**, KIBO au premier plan confirmé. Aucune désinstallation/effacement, aucun message ou annonce métier ajouté à distance pour la recette. Capture du profil vendeur avec le logo chargé et les vrais widgets inspectée : `.dart_tool/review3-seller-preview.png` (fixtures, ignorée par Git).
