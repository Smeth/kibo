# Annonces et favoris — KIBO-008/009/010

**État courant du 2026-11-02 : prix facultatif réellement activé**, annonce sans prix affichée « Prix à négocier », recherche progressive titre/description par préfixes et message vendeur avec connexion intégrés. [État serveur, tests et limites](SELLER_SEARCH_OPTIONAL_PRICE.md). Les anciennes mentions de prix obligatoire ci-dessous appartiennent à l’historique du socle.

Décision du 2026-11-01 : favoris locaux autorisés sans connexion, favoris synchronisés après authentification. Transfert local → compte uniquement sur confirmation explicite, sans suppression des favoris du compte. [Contrat et tests du lot visiteurs](GUEST_FAVORITES.md). Les sections KIBO-010 ci-dessous restent l'historique du socle authentifié.

État courant : [extension locale photos et recherche](LISTING_PHOTOS_SEARCH.md). Les mentions « sans photos/recherche avancée » plus bas décrivent le lot initial. Les contrats serveur photos/recherche sont préparés localement, non appliqués au serveur ; les limitations distantes restent explicites.

## Contrat déployé et adaptation validée

**Décision courante : publication immédiate au lancement.** Le nouveau client demande published et une date UTC ; un delta SQL préparé impose l’heure serveur et adapte la RLS, sans application distante. Le prix reste obligatoire. Voir [DIRECT_PUBLICATION.md](DIRECT_PUBLICATION.md) pour les effets, tests locaux et prérequis de déploiement. La politique distante précédemment communiquée refuse encore ce nouveau flux tant que le delta n’est pas appliqué.

Historique : le propriétaire avait fourni les métadonnées PostgreSQL et validé le prix obligatoire en XAF, pending et la publication administrative. La dernière décision retire cette modération préalable. Aucun champ `is_negotiable` n’existe ; aucun réglage de négociabilité ou upload d’image n’est ajouté. Une annonce sans photo est acceptée.

- `listings` : UUID, vendeur `seller_id` lié à profiles, catégorie UUID, titre trim 5–120 caractères, description trim 10–10 000, prix numeric(14,2) >= 0, devise XAF, ville requise. Types product/service ; statuts draft/pending/published/rejected/archived. Quartier facultatif. Valeurs par défaut laissées au serveur : pending, XAF, attributes objet vide, vues 0 et dates. Les autres colonnes de modération ne sont pas envoyées.
- `categories` : UUID, nom, slug unique, parent facultatif, ordre et indicateur actif. Le client charge uniquement les catégories actives.
- `favorites` : clé composée user_id/listing_id, dates serveur et FK vers profiles/listings. Pas d’UPDATE.
- RLS distantes communiquées avant le delta : annonces publiées ou propres au vendeur/admin lisibles ; INSERT authenticated pour soi seulement en draft/pending, sans vues/publication/rejet privilégiés. Les triggers protègent les changements d’ownership et de modération. Catégories actives lisibles publiquement, administration seule en écriture. Favoris SELECT/DELETE pour soi ; INSERT pour soi et annonce publiée uniquement. Le delta préparé est nécessaire à l’INSERT published, sans changer ces autres protections.

Ces métadonnées sont celles communiquées par le propriétaire, pas une inspection distante par l’agent. Les versions complètes des fonctions/grants/politiques ne sont pas migrées ni modifiées. RLS reste l’autorité ; les filtres Flutter ne la remplacent pas.

## KIBO-008 — Publier une annonce

`features/listings/` contient modèles, validation et repository injectable communs, ainsi que le formulaire. L’onglet Publier exige la connexion. Le formulaire capture l’identité et disparaît lors d’un changement de session ; le repository vérifie cette identité et déduit le vendeur de la session avant INSERT. Champs : titre, description, prix, catégorie, produit/service, ville et quartier. Aucun identifiant de vendeur sélectionnable.

Le prix est normalisé comme chaîne décimale pour PostgreSQL sans calcul flottant : virgule ou point, jusqu’à 12 chiffres entiers et 2 décimales. Le zéro explicite est autorisé ; un prix vide ne devient jamais zéro. Les validations de longueur comptent les points de code Unicode.

Les doubles soumissions sont désactivées pendant l’envoi. Succès uniquement après retour published daté du serveur : « Annonce publiée », puis retour au catalogue relu. Une erreur réseau après envoi peut laisser une création effective sans réponse : le message indique une publication non confirmée et invite à vérifier avant réessai ; pas de retry automatique ni de garantie d’idempotence inventée. Un refus RLS ne retombe jamais sur pending.

Recette après revue/application explicitement autorisée du delta SQL : compte de test connecté, catégorie active, validation puis publication. Vérifier propriétaire, published et heure serveur, présence immédiate au catalogue puis détail et favori. Tester visiteur, refus RLS, réseau interrompu et changement de compte. Aucun scénario réel de publication directe n’est validé par les tests simulés ou PostgreSQL local. L’annonce pending créée lors de la recette précédente n’est pas promue par la migration.

## KIBO-009 — Catalogue public

Liste réelle paginée par 20, tri published_at DESC puis id, détail relu à l’ouverture et rafraîchissement explicite. Les deux requêtes filtrent `status = published`, y compris pour un vendeur/admin dont RLS permet d’autres statuts. Projection explicite des seuls champs affichables : pas d’attributes, motif de rejet ou données de profil privées. Le détail indisponible ne réutilise pas la donnée de la carte.

La bannière et le thème existants sont conservés ; cartes, hauteurs bornées et texte extensible sont extraits dans des composants réutilisables. Les quatre annonces fictives sont désormais des fixtures injectées dans les tests, sans fallback de production. L’onglet Recherche donne accès au catalogue sans recherche avancée. Pas de galerie Storage.

Recette en lecture seule : visiteurs et comptes connectés doivent voir les annonces published existantes ; naviguer au détail et revenir, actualiser, parcourir plusieurs pages, tester liste vide/erreur réseau. Une annonce connue en pending/archived/rejected ne doit pas être ouverte via son ID dans ce catalogue, même pour le propriétaire. L’agent ne publie ni ne modifie une annonce distante pour créer des fixtures ; prévoir des données de test déjà autorisées. Les changements de modération ne sont visibles qu’à la prochaine lecture/actualisation, pas par Realtime.

## KIBO-010 — Favoris

Repository distinct, même client Supabase injecté et même session. Les lectures filtrent user_id courant ; INSERT ne contient que cette identité et listing_id ; DELETE filtre les deux. La clé composée rend un ajout déjà effectué idempotent (seul le code unique 23505 est accepté comme doublon). Les autres erreurs restent des échecs, sans UPDATE ni contournement RLS.

Les IDs personnels sont chargés par pages de 500 ; l’écran charge par 20 les annonces liées via jointure interne et filtre published. Les favoris d’annonces archivées/masquées restent en base et ne rendent pas leur contenu accessible depuis cet écran. Le détail relit encore le statut public. Les champs privés ne sont pas sélectionnés.

Un contrôleur partagé synchronise cartes, détail et onglet Favoris. Les actions concurrentes sont bloquées pendant l’envoi/relecture. Échec : pas de faux succès, message générique et actualisation possible ; une coupure après envoi peut nécessiter cette réconciliation. Une déconnexion/changement de compte vide immédiatement les données privées et invalide les réponses précédentes. Un visiteur reçoit une invitation à se connecter depuis Profil, sans écriture.

Recette à autoriser (INSERT/DELETE réels) : deux comptes existants et annonce published, éventuellement créée directement après application autorisée du delta. Ajouter depuis la carte, retrouver le cœur sélectionné au détail et la ligne dans Favoris ; retirer puis vérifier les trois vues. Tester double pression, hors réseau/reprise, relance et compte B sans favoris du compte A. Aucun passage en published/archived ni changement RLS distant n’est effectué par l’agent ; l’archivage attend un protocole distinct.

## Recette TECNO et limites de sécurité

Les tests Flutter sont simulés. Le delta de publication est également testé sur PostgreSQL local avec une fixture réduite ; aucune vérification distante de publication directe ni déclaration de disponibilité production. Les corps complets des triggers déployés restent à auditer. Une migration incrémentale est préparée sous `supabase/migrations/`, sans schéma initial ni application distante. Résultats de la recette historique et limites : [DIRECT_PUBLICATION.md](DIRECT_PUBLICATION.md).

Avant une recette réelle, autoriser explicitement la création d’annonces et la modification des favoris de comptes de test. Ne pas utiliser de données personnelles. En attente de cette autorisation, ne lancer que les tests locaux. Après accord, dans PowerShell, saisir les paramètres publics sans les publier ni les enregistrer dans un fichier :

```powershell
flutter devices
$urlInput = Read-Host 'URL HTTPS publique Supabase' -AsSecureString
$keyInput = Read-Host 'Cle publique publishable/anon uniquement' -AsSecureString
try {
  $env:SUPABASE_URL = [Net.NetworkCredential]::new('', $urlInput).Password
  $env:SUPABASE_ANON_KEY = [Net.NetworkCredential]::new('', $keyInput).Password
  flutter run -d H6929CK6NU012345 --debug --no-resident "--dart-define=SUPABASE_URL=$env:SUPABASE_URL" "--dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY" 2>&1 | ForEach-Object {
    $safeLine = $_.ToString()
    if ($safeLine -notmatch 'dart-defines|SUPABASE_|sb_publishable_|eyJ|Dart VM Service|DevTools' -and
        -not $safeLine.Contains($env:SUPABASE_URL) -and
        -not $safeLine.Contains($env:SUPABASE_ANON_KEY)) { Write-Host $safeLine }
  }
} finally {
  Remove-Item Env:SUPABASE_URL, Env:SUPABASE_ANON_KEY -ErrorAction SilentlyContinue
  $urlInput.Dispose()
  $keyInput.Dispose()
}
```

L’installation doit préserver les données (pas de désinstallation/effacement). Pour relancer ensuite sans effacement :

```powershell
$recipeAdb = "$env:LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
& $recipeAdb -s H6929CK6NU012345 shell am force-stop com.kibo.kibo
& $recipeAdb -s H6929CK6NU012345 shell am start -n com.kibo.kibo/.MainActivity
```

Tests RLS distants restants après migration autorisée : INSERT published de son propre compte accepté avec date serveur, vendeur usurpé et champs de modération refusés, lecture non publiée refusée à un tiers, favoris d’un autre compte non lisibles/modifiables, ajout sur annonce non publiée refusé et favori conservé mais contenu inaccessible après archivage. Les déclencheurs UPDATE doivent être audités séparément ; aucune transition UPDATE d’annonce n’est implémentée ici. Les tests locaux et filtres client ne certifient aucun de ces résultats distants.

Limites fonctionnelles : pas de recherche avancée, édition/archivage de ses annonces, interface administrative, upload ou galerie ; pas de Realtime des changements de modération. Le prix obligatoire est conservé, la publication directe remplace pending pour le nouveau client. Aucun nouveau test KIBO-006 de confirmation email.

## Isolation et livraison

Travail séquentiel sur main pour préserver le socle non committé KIBO-005/006/007 : de nouveaux worktrees depuis HEAD ne le contiendraient pas, et les trois tâches partagent modèles, navigation et tests. Aucun déplacement de changements, commit ni push ; aucune dépendance ajoutée. Les tests utilisent exclusivement des identités, catégories et annonces fictives.

## Historique — validation et état Git avant publication directe

- Formatage : 49 fichiers, conforme ; analyse stricte : aucune anomalie (2,3 s).
- Tests : 91 réussis, dont les 67 précédents conservés/adaptés et 24 supplémentaires.
- Build debug ARM64 final : réussi, code 0, assemblage en 21,8 s, sans paramètres réels ; APK non installé.
- Diff check : réussi. Pas de migration SQL ni de nouvelle dépendance.
- HEAD et référence locale origin/main : bca1aa2b3ced41c2de3fb8f80f3d8dc88aac15a0, aucun fetch pendant le lot. Index vide, un seul worktree main. Aucun commit ni push et aucune CI distante déclenchée par ce travail.
- Comparaison avec l’état de départ : aucun fichier préexistant supprimé ; sources auth/profil, configuration/service Supabase, stockage chiffré, pubspec/lock, manifestes et registrants préexistants inchangés pendant le lot. Les tests auth/profil ont seulement reçu les injections de repositories fictifs. La navigation et les cartes de main.dart ont été adaptées au catalogue réel.
- État cumulatif (inclut les travaux locaux antérieurs KIBO-004/005/006/007) : 23 fichiers suivis modifiés, 39 non suivis ; rien préparé dans l’index.

```text
## main...origin/main
 M AGENTS.md
 M README.md
 M android/app/src/main/AndroidManifest.xml
 M docs/ARCHITECTURE.md
 M docs/CAHIER_DES_CHARGES.md
 M docs/DECISIONS_TECHNIQUES.md
 M docs/NEXT_TASK.md
 M docs/PROGRESS.md
 M docs/SUPABASE_SETUP.md
 M lib/core/supabase/supabase_service.dart
 M lib/main.dart
 M linux/flutter/generated_plugin_registrant.cc
 M linux/flutter/generated_plugins.cmake
 M macos/Flutter/GeneratedPluginRegistrant.swift
 M pubspec.lock
 M pubspec.yaml
 M test/kibo_layout_regression_test.dart
 M test/kibo_responsive_test.dart
 M test/support/supabase_fakes.dart
 M test/theme/kibo_theme_test.dart
 M test/widget_test.dart
 M windows/flutter/generated_plugin_registrant.cc
 M windows/flutter/generated_plugins.cmake
?? android/app/src/main/res/xml/data_extraction_rules.xml
?? docs/AUTHENTICATION.md
?? docs/LISTINGS.md
?? docs/PROFILE.md
?? lib/core/config/auth_callback.dart
?? lib/core/supabase/secure_session_storage.dart
?? lib/features/auth/auth_controller.dart
?? lib/features/auth/auth_page.dart
?? lib/features/auth/auth_repository.dart
?? lib/features/auth/auth_validation.dart
?? lib/features/auth/profile_page.dart
?? lib/features/favorites/favorite_button.dart
?? lib/features/favorites/favorites_controller.dart
?? lib/features/favorites/favorites_page.dart
?? lib/features/favorites/favorites_repository.dart
?? lib/features/listings/listing_card.dart
?? lib/features/listings/listing_detail_page.dart
?? lib/features/listings/listing_feed.dart
?? lib/features/listings/listing_models.dart
?? lib/features/listings/listing_repository.dart
?? lib/features/listings/publish_listing_page.dart
?? lib/features/profile/edit_profile_page.dart
?? lib/features/profile/profile_validation.dart
?? test/auth/auth_callback_test.dart
?? test/auth/auth_controller_test.dart
?? test/auth/auth_repository_test.dart
?? test/auth/auth_widgets_test.dart
?? test/auth/secure_session_storage_test.dart
?? test/favorites/favorites_controller_test.dart
?? test/favorites/favorites_repository_test.dart
?? test/favorites/favorites_widgets_test.dart
?? test/listings/catalogue_test.dart
?? test/listings/listing_repository_test.dart
?? test/listings/publication_test.dart
?? test/profile/profile_controller_test.dart
?? test/profile/profile_widgets_test.dart
?? test/support/auth_fake.dart
?? test/support/listing_fake.dart
?? test/support/listing_session.dart
```
