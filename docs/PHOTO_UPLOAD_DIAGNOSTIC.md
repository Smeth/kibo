# Diagnostic « Annonce publiée, photos incomplètes » — 2026-11-01

## État actuel : corrections Supabase appliquées

Après autorisation explicite, accès au Dashboard existant, audit des vrais corps/ACL/Storage puis correction de la lecture publique, application du contrat photos adapté et du vecteur de recherche, déploiement du validateur Edge. Les réponses auparavant PGRST200/PGRST205/42703/404 sont remplacées par **200** sur les contrôles correspondants ; les appels sans authentification sont refusés401. Six annonces conservées, aucune image utilisateur envoyée par l'assistant. [Compte rendu réel](SUPABASE_REPAIR_20261101.md). Si le formulaire d'origine garde ses photos, l'utilisateur peut maintenant retenter une fois sur le même ID ; aucun besoin de réinstaller l'APK. Les anciennes limitations d'instrumentation restent vraies pour l'ancien binaire, mais ne bloquent plus cette reprise après réparation serveur.

## Mise à jour : incompatibilités distantes désormais démontrées

Les lectures publiques sans lignes du 2026-11-01 ont confirmé **PGRST200** sur la relation photos, **PGRST205** sur sa table API, **42703** sur kibo_search_vector et **404/NOT_FOUND** sur la route Edge. La lecture de base renvoie **42501, permission denied for function is_admin**. Détails, limites de rôle/cache, corrections locales et SQL minimal conditionnel dans [CATALOGUE_PHOTOS_FIX.md](CATALOGUE_PHOTOS_FIX.md). Cela remplace l'absence de preuve d'incompatibilité serveur ci-dessous ; le statut exact de l'ancienne requête d'upload sur le téléphone reste non capturé. Aucune modification distante effectuée.

## Journalisation locale ajoutée — état actuel

L'instrumentation est **implémentée et testée dans le dépôt**, pas installée ni chargée sur le TECNO. Elle ne démontre encore aucune cause réelle. Les constats de l'ancien APK ci-dessous restent historiques.

`PhotoUploadDiagnostics` produit des événements `[KIBO_PHOTO]` JSON, activés par défaut **uniquement en debug** :

- `attempt` : identifiant aléatoire local de 32 caractères hexadécimaux, différent à chaque appel attach/reprise ; jamais un ID d'utilisateur/annonce ni une empreinte d'image. Il regroupe les événements de cette tentative seulement.
- `stage` : validation, session, reservation_insert, reservation_lookup, edge_invoke, response_confirmation, complete ; `event` : start/http/failure/success.
- `http_status` : véritable statut reçu via le transport instrumenté ; null sans réponse/transport observable. Le SDK Functions fournit aussi son statut ; 0 signifie absence de réponse et est journalisé null. Aucun statut HTTP n'est inventé à partir de 42501 ou PGRST205.
- `code` : SQLSTATE/PostgREST de format strict ou code Edge d'une liste fermée. Aucun message, details, hint, reasonPhrase ou stack brut. Un code arbitraire/inconnu est null.
- `server_request_id` : seul sb-request-id de forme UUID, si reçu ; sinon null. L'identifiant local n'est pas envoyé au serveur et ne garantit pas une corrélation backend à lui seul.

Le client HTTP central observe uniquement les routes réservation/fonction dans la zone de l'appel attach ; il ne lit aucun corps, ne modifie aucun en-tête, ne consomme aucun flux, ne change pas les règles de retry. Il ne journalise ni refresh Auth, autre trafic, URL, chemin d'objet, nom de fichier, ID d'annonce/propriétaire, octets/base64, digest, token ou secret. Les exceptions originales sont relancées inchangées. Un sink de log défaillant ne doit pas transformer une réussite en échec métier. L'ID existant, les photos et leurs chemins restent gérés par le code de reprise préexistant.

La dépendance http 1.6.0 était déjà présente ; elle passe de dev à dépendance principale pour ce transport, via `flutter pub get --offline`, sans mise à niveau. Aucune modification Edge/SQL ni protocole distant.

### Blocage de mise en service sur l'annonce en cours

**Ne pas installer un nouvel APK, redémarrer, forcer l'arrêt ou fermer le formulaire pour activer ces logs.** L'APK courant ne contient pas cette instrumentation et ses photos en attente ne sont pas persistées. L'instrumentation de Supabase.initialize exige aussi un transport initialisé avec le wrapper ; un simple hot reload ne réexécute pas nécessairement cette initialisation et ne peut pas être présenté comme un moyen garanti d'obtenir tous les statuts tout en conservant l'état.

L'aide locale `flutter attach --help` a été lue, mais aucune connexion debugger/recharge à chaud n'a été effectuée. Aucun procédé de transfert/récupération sûre de cette file en mémoire vers un nouveau binaire n'est validé ici. **L'activation sur cette tentative existante est donc encore bloquée par la préservation de l'état.** Il faut valider séparément une activation en mémoire sans restart, ou obtenir l'erreur dans les logs distants existants en lecture seule. Ne jamais contourner ce blocage en recréant l'annonce. Une collecte vide sur l'ancien APK n'est pas une réussite du diagnostic.

### Collecte Android et nouvelle tentative — procédure conditionnelle exacte

À utiliser **seulement après validation de l'activation de l'instrumentation avec le même formulaire, le même ID et les photos encore présents**. Cette condition n'est pas remplie dans la présente session ; ne pas cliquer maintenant dans l'espoir d'obtenir les nouveaux logs.

1. Garder le compte et le formulaire actuels affichant **Réessayer les photos**, avec les aperçus conservés. Ne pas retourner à Publier pour créer un nouveau formulaire. Noter l'heure locale et l'ID connu dans un support local privé, sans l'inclure dans les logs partagés.
2. Depuis la racine du dépôt, ouvrir un terminal PowerShell et démarrer le collecteur :

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Collect-PhotoUploadLogs.ps1 -DeviceId H6929CK6NU012345
   ```

   Le Bypass ne concerne que ce processus exécutant notre script local ; il ne change pas la politique du poste. Aucun logcat effacé et aucun log brut archivé. Le collecteur trouve le PID existant (sans lancer l'app), lit `logcat --pid=<PID> -v raw -T 1 flutter:I *:S`, rejette les autres lignes et reconstruit seulement les champs autorisés. Nouveau fichier NDJSON unique sous `.dart_tool/kibo-verifications/`, ignoré, sans écrasement d'ancien journal. Ctrl+C arrête la collecte ; ne pas utiliser un dump logcat brut à la place.
3. Après autorisation de la tentative d'upload sur **cette annonce existante**, appuyer **une seule fois** sur **Réessayer les photos**. Ce geste peut écrire les réservations/objets manquants ; il n'est pas exécuté automatiquement par cette préparation. Ne pas toucher Publier une nouvelle annonce, changer l'ordre/les fichiers ou supprimer un objet.
4. Attendre la fin du chargement. Si échec, ne pas multiplier les essais : relever l'événement `failure`, son attempt, stage, http_status, code et server_request_id, ainsi que l'heure et le message UI. Les événements `http` précédents montrent le dernier statut reçu. Si succès, relever `complete/success` ; vérifier ensuite les photos uniquement dans une recette autorisée distincte.
5. Arrêter le collecteur avec Ctrl+C. Partager seulement ses événements reconstruits, jamais JWT, headers, corps, URL signée ou captures de galerie. S'il n'y a aucun événement, conserver le formulaire et vérifier l'activation/debug/PID ; ne pas conclure que le serveur n'a rien reçu.

Exemple **fictif**, pas un résultat TECNO : `stage=edge_invoke, http_status=502, code=storage`. Cela confirme un échec Storage remonté par l'Edge mais pas son statut amont ; l'opérateur doit rapprocher sb-request-id/heure et logs Edge/Storage en lecture seule. `reservation_insert/403/42501` oriente vers ACL/RLS de réservation ; `edge_invoke/404/NOT_FOUND` vers fonction/route ; `401/authentication` vers JWT/Auth ; `503/configuration` vers environnement serveur. Un statut null reste inconnu, en particulier pour validation/session ou panne réseau. Contrôles détaillés dans la section Vérifications distantes ci-dessous.

### Vérification locale de l'instrumentation

Nouveaux tests de confidentialité/statuts/corrélation, capture HTTP simulée de bout en bout et reprise : aucun corps/en-tête privé transmis aux logs, code arbitraire écarté, statut inconnu non déduit, réponse intacte, pas de log hors contexte, sink cassé sans effet métier. Les cas SDK existants vérifient maintenant stage/statut/code et nouvel attempt à la reprise, avec chemins/ID inchangés. Collecteur PowerShell testé sur données fictives : un événement valide conservé, lignes invalides et champs privés exclus ; aucune connexion Android pour ce test.

## Conclusion et provenance

**Cause du message démontrée dans le code :** l'INSERT de l'annonce est confirmé avant la réservation/envoi des photos. `_createdId ??= repository.create(...)` conserve l'ID ; `attach(...)` s'exécute ensuite. Une exception dans cette seconde étape affiche le message signalé. Il n'y a ni transaction atomique entre annonces/Storage/Edge, ni suppression/dépublication automatique. La réussite de l'annonce ne certifie pas la disponibilité du contrat photos.

**Cause exacte de l'échec photo physique : indéterminée.** L'utilisateur a observé ce message sur le TECNO ; l'assistant n'a soumis ni réessayé aucune annonce. ADB voit le TECNO CK6n H6929CK6NU012345, processus KIBO 13411. Lecture seule `logcat -d --pid=13411 -v brief -t 1500` : 32 lignes retournées, aucun marqueur FunctionException/PostgrestException/StorageException, 42501, PGRST205, NOT_FOUND, invalid_or_unavailable, FATAL EXCEPTION, Unhandled Exception ou E/flutter et aucun statut structuré exploitable. Aucun log brut conservé/affiché, aucune mémoire applicative/session/clé extraite. Cet extrait ne prouve pas l'absence d'échec antérieur.

Le catch du formulaire ne journalise pas l'exception. L'Edge ne journalise pas les erreurs fournisseurs et réduit leur précision. Aucun outil Supabase actif n'est exposé pour récupérer logs/configuration distante dans cette session. Les migrations proposées, un build et les anciennes réussites SQL sur fixture **ne prouvent pas leur application distante**. La publication observée n'établit pas non plus quelle version exacte du delta INSERT est déployée.

## Où le flux peut échouer

| Étape | Ce qui existe dans le code local | Ce qu'il faut observer avant de conclure |
|---|---|---|
| Contrôle client | Feature activée, session courante non expirée et owner identique, max 3 images distinctes, JPEG compressé ≤4 Mio. | Une exception de session/validation peut précéder tout appel réseau. |
| Réservation | POST REST `kibo_listing_photos`, listing_id/position/path ; 23505 traité par SELECT du chemin existant. | Statut et code PostgREST : 42501 possible pour ACL/RLS, PGRST205 possible pour table/cache absent ; pas des codes observés sur le TECNO. Collision de chemin différent refusée sans écrasement. |
| Invocation | POST `kibo-upload-listing-photo` avec JWT de session, listingId/position/digest/base64. | 404/NOT_FOUND : vérifier fonction/route du projet ; 401 : passerelle/Auth ; 503/configuration : environnement serveur. Aucun de ces statuts n'a été relevé physiquement ici. |
| Validation Edge | JWT validé via Auth, SHA-256, vrai JPEG décodé/réencodé sans métadonnées, taille/dimensions, propriété de listings et réservation. | 400 fields/digest/dimensions/body ; 413 size ; 403 listing/owner/reservation. Le catch global 400 invalid_or_unavailable couvre aussi des exceptions réseau : il ne prouve pas une mauvaise image. |
| Storage serveur | POST `/storage/v1/object/kibo-listing-photos/<path>` avec droit serveur, JPEG, x-upsert=false ; collision 409/duplicate admise comme reprise. | Le handler renvoie seulement **502/storage** pour les autres refus Storage. Le statut/message amont (403, bucket absent, indisponibilité…) n'est pas transmis au client. Il faut les traces serveur de la même requête. |
| Réponse | ok=true et chemin attendu exigés. | Réponse incorrecte/perdue peut faire afficher l'erreur même si l'objet a été effectivement créé. Ne pas supprimer cet objet ou réserver un autre chemin pour « réparer ». |

Ce tableau décrit les branches du code et les simulations, **pas des réponses distantes constatées**. Ne pas attribuer par défaut le problème à une politique INSERT Storage : le client ne fait volontairement aucun upload Storage direct.

## Correspondance du contrat local

- Migration `20261031220517_listing_photos.sql` : table `public.kibo_listing_photos`, PK (listing_id, position), positions 0..2, owner_id default auth.uid(), FK listings/profiles, path unique et contrainte regex. INSERT seulement listing_id/position/path pour authenticated ; RLS propriétaire et annonce draft/pending/published. Aucun UPDATE/DELETE client des réservations.
- Client et Edge : même chemin `<owner UUID>/<listing UUID>/<position>-<SHA256 JPEG client>.jpg`. L'Edge revérifie exactement la réservation. Il réencode le JPEG : le hash des octets stockés peut différer du hash client contenu dans le nom.
- Bucket SQL et Edge : `kibo-listing-photos`, privé, file_size_limit=4194304, allowed_mime_types=image/jpeg. Lecture des objets référencés si parent publié ou propriétaire. URLs signées client 60 s. Pas d'INSERT/UPDATE/DELETE client sur storage.objects ; seul le validateur écrit avec son droit serveur.
- La migration bloque si table/bucket ou **toute politique Storage** existe déjà. Ne pas supprimer ces objets/politiques ou ajouter une règle permissive pour faire passer le flux. Le déploiement doit être comparé aux définitions locales, pas aux seuls noms.
- Vecteur/recherche `20261031220520_catalogue_search.sql` indépendant de l'envoi des photos ; sa présence n'atteste pas le déploiement Edge/Storage.

## Reprise et conservation de l'annonce

Tant que **le même formulaire reste vivant**, `_createdId` et `_photos` sont conservés. Le bouton devient **Réessayer les photos** ; ordre/suppression/ajout et champs de création sont verrouillés. La reprise utilise le même ID et les mêmes octets/digests/positions. Les réservations existantes renvoient 23505, puis un SELECT confirme le même chemin. Les objets déjà téléversés ne sont pas écrasés : la collision est traitée dans l'Edge.

Les tests vérifient deux échecs successifs suivis d'un succès UI avec une seule création, photos/ordre conservés et suppression désactivée ; échec de la seconde photo puis reprise des deux mêmes réservations ; réservation refusée avant tout appel Edge ; statuts Edge 401/404/502/503 propagés puis reprise. Aucun endpoint INSERT listings, DELETE/PATCH ou upload Storage direct n'est admis par la fixture de reprise.

**Limite : aucune file persistante d'upload.** Fermer le formulaire, changer de compte, redémarrer/forcer l'arrêt ou réinstaller peut perdre l'état de reprise. La récupération native Android du sélecteur n'est pas une restauration de cette file. Garder l'écran ouvert ; ne pas republier, réinstaller, supprimer les réservations/objets ni recréer l'annonce. Ne pas réessayer automatiquement : le diagnostic actuel n'autorise aucune écriture distante.

## Vérifications distantes précises, en lecture seule, avant toute correction

1. Confirmer le projet utilisé par l'APK, puis l'heure de la tentative et l'ID de l'annonce déjà créée, sans demander de clé/jeton dans le chat. Ne pas renouveler la tentative pour obtenir une trace sans autorisation distincte. Les captures de statut HTTP doivent exclure headers Auth, corps base64 et URL signée.
2. Avec l'opérateur autorisé, lire les logs PostgREST/Edge/Storage autour de cette tentative. Déterminer si un POST réservation a été reçu, son statut/code, si l'invocation existe, son statut et request ID, puis si elle a atteint Storage. En cas de 502/storage, rapprocher le statut amont et son erreur dans les journaux disponibles ; ne pas inventer le statut s'il n'y figure pas. Pas de trace Edge peut signifier échec en amont ou logs indisponibles, pas forcément fonction absente.
3. Exécuter uniquement `supabase/audits/listing_photos_readonly.sql` avec un accès autorisé. Compléter en lecture seule par ACL table/colonnes, RLS active, contraintes/defaults et FK ; comparer aux trois sections précédentes. Vérifier que le profil du vendeur et le parent appartiennent au bon compte. Ne pas exporter de données tierces.
4. Lire pour **cette annonce seulement** les réservations listing_id/position/owner_id/path ; comparer aux objets du bucket et à leurs métadonnées sans les télécharger/exporter. Absence de réservation oriente vers client/REST ; réservation sans objet oriente vers Edge/Storage ; objet déjà présent peut indiquer réponse perdue. Aucun de ces indices seuls ne prouve la cause.
5. Vérifier existence/version et route de `kibo-upload-listing-photo`, JWT requis, configuration d'entrée et fourniture par la plateforme des variables serveur SUPABASE_URL/ANON_KEY/SERVICE_ROLE_KEY **par présence/nature uniquement**, sans afficher/copier leurs valeurs. Vérifier que le droit serveur est destiné au même projet. Ne pas désactiver verify_jwt et ne pas mettre service_role dans Flutter.
6. Vérifier bucket privé, limites MIME/taille, grants/rôles effectifs et toutes les politiques Storage permissives/restrictives. L'upload serveur ne doit pas nécessiter une ouverture INSERT à authenticated. Si un contrat différent existe, préparer une adaptation locale séparée revue et testée, jamais l'appliquer à l'aveugle.

Le premier échec de réservation/invocation/validation/Storage démontré guidera le correctif minimal. **Aucun correctif runtime/SQL proposé comme solution prouvée à ce stade.** Le manque de diagnostic structuré est connu ; ajouter ultérieurement une télémétrie expurgée par étape/statut pourrait être une tâche distincte, sans journaliser les octets, secrets ou erreurs brutes.

## Commandes et résultats locaux

Inventaire Git/empreintes avant intervention ; ADB devices/pidof et lecture logcat ci-dessus ; revue sources/migration/audit/tests. Nouveaux tests : `test/listings/photo_upload_failure_test.dart` (7 cas), renforcement `photo_publication_test.dart`, un cas Edge refus/reprise.

`dart format` sur les deux tests Dart ; Deno 2.5.6 fmt/test avec `--lock=supabase/functions/deno.lock`, aucun accès réseau des fixtures. **4 tests Edge réussis**, dont refus Storage 403/404/500 transformés en 502 puis succès, même chemin et x-upsert=false. Première exécution ciblée Flutter : 7 nouveaux tests réussis ; une assertion UI supplémentaire cherchait un IconButton via un Tooltip et a été corrigée en ciblant le bouton, sans modifier le code produit. Résultats finaux analyse/suite complète consignés dans PROGRESS/NEXT_TASK.

Aucune migration ou fonction appliquée, aucun upload réel, aucune suppression/recréation d'annonce, aucun clic de reprise, aucun commit/push. Les tests SQL locaux précédents restent historiques ; aucune nouvelle modification de schéma, même local, pendant ce diagnostic.
