# Parcours, photos et recherche — implémentation locale

## Actualisation du serveur — 2026-11-01

Le backend a depuis été réparé/déployé avec autorisation explicite : droit public is_admin, nouveau contrat photos privé compatible avec le bucket historique listing-images conservé, vecteur/index et fonction kibo-upload-listing-photo. Lecture200 et contrôles d'auth401 réels. Les paragraphes ci-dessous décrivent le lot initial local ; [SUPABASE_REPAIR_20261101.md](SUPABASE_REPAIR_20261101.md) donne l'état distant actuel, sans revendiquer une recette physique complète. L'APK photos déjà installé peut retenter sur le même formulaire ; ne pas recréer l'annonce.

## État et contrat

Travail sur le dépôt existant, sans commit/push, installation Android ou appel Supabase distant. Aucun bucket ou table photo n'était défini dans les migrations, modèles et services locaux. Aucun outil Supabase n'est exposé dans cette session ; les politiques Storage réellement déployées n'ont donc pas été vérifiées. L'utilisateur a confirmé ne pas connaître ce contrat et autorisé une proposition locale isolée. Les noms suivants sont **proposés**, pas déclarés existants sur le serveur.

Le fonctionnement sans photo utilise le contrat annonces/favoris existant. Le delta de publication directe reste nécessaire côté distant tant qu'il n'a pas été appliqué par un opérateur autorisé. La réussite des simulations ne remplace pas la recette physique bloquée précédemment par 42501.

## 1. Parcours vendeur et acheteur

Le test intégré de widgets crée sous A, ouvre l'annonce publique sous B, ajoute un favori, actualise, recrée KiboApp et ses contrôleurs avec les mêmes repositories fictifs, vérifie la persistance, alterne A/B puis retire le favori. Le fake stocke désormais les favoris par compte ; le test de réponse tardive a été adapté à cette séparation. C'est une persistance simulée côté repository, pas un redémarrage réel du téléphone.

Les tests existants conservent date/statut de publication, refus RLS, absence de session, erreurs et réponses tardives. Les assertions PostgreSQL vérifient la propriété et les champs protégés avec les guards de fixture, pas les fonctions Supabase distantes.

## 2. Photos

### Client

- `ListingPhotoRepository` et `ListingPhotoPicker` injectés via `ListingPhotoScope`, avec le même client Supabase. Scope conservé lors des navigations catalogue/Favoris vers le détail.
- Sélection multiple depuis la photothèque, maximum **3** photos. Aperçus, suppression et déplacement avant publication ; première photo principale. Déduplication par SHA-256 du JPEG compressé.
- Formats d'entrée JPEG/PNG/WebP, source limitée à 20 Mio et 24 mégapixels. Décodage borné au premier frame, orientation corrigée, dimension maximale 1600 px, fond blanc pour la transparence, métadonnées retirées puis JPEG qualité 82, maximum **4 Mio = 4 194 304 octets**. Traitement dans un isolate.
- KIBO ne crée pas de copie temporaire persistante des images : travail en mémoire, libéré avec le formulaire. Les sources de la photothèque ne sont jamais supprimées. Le cache éventuel du sélecteur appartient au plugin/OS ; son comportement natif reste à vérifier sur appareil.
- Récupération Android d'une sélection interrompue lorsque le formulaire est rouvert. Un marqueur propriétaire est conservé dans le stockage sécurisé existant, sans chemins/image ; les résultats d'un ancien compte sont rejetés. La reprise native et le stockage du marqueur ne sont pas validés physiquement.
- Après INSERT confirmé, l'identifiant d'annonce est gardé dans le formulaire. Si une photo échoue, message distinct « annonce publiée, photos incomplètes » et bouton de reprise ; aucun nouvel INSERT d'annonce. Les champs/photos sont figés pendant cette reprise. Les trois chemins sont déterministes ; pas d'upsert ni de doublon d'objet sur une réponse perdue. Une erreur ambiguë d'INSERT d'annonce conserve le comportement antérieur, sans retry automatique.
- La reprise d'envoi est limitée au formulaire vivant. Après fermeture/processus détruit, les images en mémoire et l'identifiant partiel ne constituent pas une file d'upload persistante ; ne pas republier aveuglément une annonce déjà confirmée. Aucune édition des photos d'une annonce existante n'est ajoutée à ce lot.
- Photos dans les cartes, Favoris et détail ; image absente : illustration existante ; erreur : icône et reprise, sans erreur fournisseur brute. URL signée privée valable 60 s, renouvelable en cas d'échec. Une URL déjà émise peut rester utilisable jusqu'à expiration après modération ; pas de révocation instantanée ni de Realtime ajouté.

### Contrat serveur proposé, sans déploiement

Migration `20261031220517_listing_photos.sql`, générée par CLI officielle :

- Bucket **privé** `kibo-listing-photos`, limite 4 Mio, MIME JPEG pour les fichiers normalisés.
- Table `public.kibo_listing_photos`, FK vers listings/profiles, PK `(listing_id, position)`, position 0–2, owner fourni par `auth.uid()` et chemin contraint `owner/listing/position-sha256.jpg`. Unicité des emplacements, même en concurrence.
- RLS : réserver uniquement pour son annonce draft/pending/published ; lire une photo publiée ou la sienne. Colonnes INSERT limitées, aucune modification/suppression des réservations par le client. Ni nouvel ownership ni élargissement des politiques listings/favorites.
- Storage : SELECT uniquement si objet référencé par une annonce accessible. **Aucun INSERT/UPDATE/DELETE direct client** ; l'upload passe par la fonction validante.
- Préflight refuse collisions de bucket/table, absence de RLS Storage et **toute politique Storage existante**. Ce dernier refus est volontairement strict : une politique permissive existante pourrait contourner le validateur. L'audit distant et une éventuelle adaptation ciblée du projet de migration sont obligatoires, sans suppression/affaiblissement de règles existantes.

Fonction locale `supabase/functions/kibo-upload-listing-photo/` : valide la session via Auth, limite le corps JSON à 6 Mio, vérifie taille/hash, décode complètement le JPEG (3 mégapixels/64 Mio de mémoire maximum), borne les dimensions, réencode sans EXIF/GPS, vérifie vendeur/statut et réservation avec le JWT utilisateur, puis écrit avec ses droits **serveur uniquement**. Le secret `SUPABASE_SERVICE_ROLE_KEY` est lu dans l'environnement Edge ; aucun secret n'est présent dans Flutter ou dans les fichiers. Aucun appel/deploiement ni saisie de secret fait ici. Le contrôle serveur de taille ne dépend pas seulement du MIME ou de métadonnées déclarées. Dépendance `jpeg-js` fixée à 0.4.4 et verrou Deno versionné.

Les objets validés restent attachés à leurs réservations ; une interruption ne déclenche pas de suppression risquant d'effacer un upload réellement réussi. Réservations sans objet possibles après échec. Pas de GC distant automatique : `listing_photos_orphans_readonly.sql` inventorie ces réservations et les objets éventuellement orphelins après suppression administrative d'une annonce. Toute purge ultérieure exige un protocole et une autorisation distincts.

### Activation conditionnelle

`KIBO_LISTING_PHOTOS_ENABLED` vaut **false par défaut** : ni jointure vers la nouvelle table ni sélection/upload proposés sur un serveur non migré ; les annonces sans photo continuent à fonctionner. Après audit Storage, revue/application **autorisées** du contrat et déploiement **autorisé** du validateur, un build avec `--dart-define=KIBO_LISTING_PHOTOS_ENABLED=true` active le flux et la projection imbriquée des chemins, sans récupérer toutes les annonces. Aucun de ces gestes distants n'a été effectué. Les tests injectent les services ou activent ce paramètre de compilation sur leurs fixtures uniquement.

## 3. Recherche, filtres et tri

L'onglet Recherche propose titre/description, catégorie active, ville exacte (même orthographe/casse que les données), prix min/max XAF, plus récentes/prix croissant/prix décroissant et effacement global. Contrôles empilés, libellés accessibles, critères dans une section repliable et validation de fourchette sans calcul flottant. Les erreurs de catégories n'empêchent pas une recherche sans catégorie.

`ListingQuery` transmet tous les critères au repository. Requêtes published uniquement, 20 lignes par page, offset remis à zéro à chaque recherche, ordre secondaire date puis ID explicite ; réponses anciennes ignorées. Aucun filtrage production en mémoire de tout le catalogue. États chargement/vide initial/aucun résultat/erreur distincts, reprise explicite et conservation des critères à l'ouverture/retour du détail. Les critères de l'écran sont réinitialisés lorsqu'on quitte cet onglet ; pas de préférences de recherche persistantes ajoutées.

Migration locale `20261031220520_catalogue_search.sql` : vecteur tsvector français généré à partir de titre (poids A) et description (B), index GIN partiel published et index prix/date/ID partiel published. Requête websearch_to_tsquery via le SDK, sans concaténation de syntaxe OR fournie par l'utilisateur. La **recherche textuelle exige cette migration** ; catégorie/ville/prix/tri utilisent les colonnes existantes. Sans migration, une recherche textuelle échoue explicitement, sans repli local silencieux. Aucun RLS/grant existant modifié par ce delta ; la visibilité de la nouvelle colonne devra être compatible avec les grants déployés.

## Vérifications et limites

Voir PROGRESS pour les résultats finaux exécutés. Tests Flutter : données/services fictifs et HTTP SDK simulé ; tests Edge : fetch Auth/Storage simulés, pas de requêtes externes ; SQL : PostgreSQL 13 isolé avec stub des catalogues Storage, pas de serveur HTTP Storage réel. La limite du bucket est relue comme configuration, pas certifiée par un upload Supabase réel. Aucun APK installé/reconstruit pour ce lot, aucun test physique, iOS ni test distant de JWT/RLS/signature/expiration/réseau/concurrence Storage effectué.

## Inventaire des fichiers de cette tâche

- Modifié : .gitignore
- Modifié : docs/ARCHITECTURE.md
- Modifié : docs/LISTINGS.md
- Modifié : docs/NEXT_TASK.md
- Modifié : docs/PROGRESS.md
- Modifié : ios/Runner/Info.plist
- Modifié : lib/features/favorites/favorites_page.dart
- Modifié : lib/features/listings/listing_card.dart
- Modifié : lib/features/listings/listing_detail_page.dart
- Modifié : lib/features/listings/listing_feed.dart
- Modifié : lib/features/listings/listing_models.dart
- Modifié : lib/features/listings/listing_repository.dart
- Modifié : lib/features/listings/publish_listing_page.dart
- Modifié : lib/main.dart
- Modifié : linux/flutter/generated_plugin_registrant.cc
- Modifié : linux/flutter/generated_plugins.cmake
- Modifié : macos/Flutter/GeneratedPluginRegistrant.swift
- Modifié : pubspec.lock
- Modifié : pubspec.yaml
- Modifié : README.md
- Modifié : test/favorites/favorites_controller_test.dart
- Modifié : test/listings/direct_publication_flow_test.dart
- Modifié : test/support/listing_fake.dart
- Modifié : windows/flutter/generated_plugin_registrant.cc
- Modifié : windows/flutter/generated_plugins.cmake
- Nouveau : docs/LISTING_PHOTOS_SEARCH.md
- Nouveau : lib/features/listings/catalogue_search_form.dart
- Nouveau : lib/features/listings/listing_photo_widgets.dart
- Nouveau : lib/features/listings/listing_photos.dart
- Nouveau : lib/features/listings/listing_query.dart
- Nouveau : supabase/audits/listing_photos_orphans_readonly.sql
- Nouveau : supabase/audits/listing_photos_readonly.sql
- Nouveau : supabase/functions/deno.lock
- Nouveau : supabase/functions/kibo-upload-listing-photo/index.ts
- Nouveau : supabase/functions/kibo-upload-listing-photo/index_test.ts
- Nouveau : supabase/migrations/20261031220517_listing_photos.sql
- Nouveau : supabase/migrations/20261031220520_catalogue_search.sql
- Nouveau : test/listings/catalogue_search_test.dart
- Nouveau : test/listings/listing_photo_widgets_test.dart
- Nouveau : test/listings/listing_photos_test.dart
- Nouveau : test/listings/photo_publication_test.dart
- Nouveau : test/sql/listing_photos_assertions.sql
- Nouveau : test/sql/listing_photos_storage_fixture.sql
