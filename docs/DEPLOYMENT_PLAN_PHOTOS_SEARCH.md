# Plan de déploiement photos et recherche — KIBO

Date : 2026-10-31. Projet cible : `fcfmfpywpurrvppxdltm`.

**Mise à jour 2026-11-01 :** après autorisation explicite ultérieure, le serveur a été corrigé : lecture publique, variante photos compatible avec le Storage historique, recherche et fonction Edge appliquées/déployées et contrôlées. Ne pas exécuter à nouveau la liste de ce plan initial. Le fichier photos original a été remplacé pour cette intervention par une variante séparée, sans être modifié. Résultats effectifs et limites : [SUPABASE_REPAIR_20261101.md](SUPABASE_REPAIR_20261101.md).

**Document de préparation uniquement. Aucun ordre de déploiement n'est autorisé par ce document.** Les commandes SQL/Storage/Edge/Flutter ci-dessous ne sont pas exécutées pendant l'audit. Aucun objet distant ni donnée distante modifié. Les migrations originales et le code applicatif sont conservés sans modification.

## Décision de l'audit

**Compatible avec la fixture locale, pas encore validé pour un déploiement distant.** Les autorisations humaines de revue du Storage réel, de fenêtre SQL, de déploiement Edge, puis de recette et de diffusion Flutter sont requises séparément.

| Statut | Constat |
|---|---|
| Vérifié localement | Les trois migrations s'enchaînent sur le schéma réduit et les assertions annonces/propriété/photos/recherche passent. Aucun changement des champs métier demandé par les deux nouveaux deltas. |
| Vérifié localement | Photos : collision table/bucket ou politique Storage existante fait échouer le preflight ; réexécution refusée. Recherche : réexécution refusée, transaction annulée. |
| Vérifié localement | L'ajout de la colonne STORED change le filenode de listings ; un lecteur concurrent fait échouer l'ALTER après lock_timeout. Ce n'est pas une migration sans interruption garantie. |
| Vérifié localement | Des SELECT accordés uniquement sur les anciennes colonnes ne permettent pas de lire la nouvelle colonne générée. Les rôles réels peuvent cependant avoir un SELECT de table suffisant. |
| Confirmé par l'utilisateur, audit précédent | Politique INSERT distante limitée à draft/pending et date NULL ; authenticated dispose d'INSERT ; triggers listings relevés BEFORE UPDATE. Le delta de publication directe reste le prérequis s'il n'a pas déjà été appliqué ailleurs avec autorisation. |
| Non vérifié ici | Buckets, politiques, ACL, schéma complet, historique de migrations et version PostgreSQL réellement déployés. Aucun outil Supabase actif n'est exposé dans cette session. |
| Non vérifié ici | Runtime/bundle Edge hébergé, JWT réels, signature/expiration des URLs Storage, quotas et concurrence HTTP, rendu/natif Android et iOS. Les tests locaux ne prouvent pas ces éléments. |

Les corrections/adaptations **proposées mais non appliquées** sont dans [PROPOSED_PHOTOS_SEARCH_CORRECTIONS.md](PROPOSED_PHOTOS_SEARCH_CORRECTIONS.md). Aucun prérequis distant manquant ne doit être remplacé par une valeur inventée ou un relâchement des politiques.

## Fichiers examinés et dépendances

- `AGENTS.md`, `WORKFLOW.md`, `NEXT_TASK.md`, `PROGRESS.md`, `DEVELOPMENT_SETUP.md`, `ARCHITECTURE.md`, `CAHIER_DES_CHARGES.md`, `LISTINGS.md`, `DIRECT_PUBLICATION.md`, `RLS_PUBLICATION_AUDIT.md` et `LISTING_PHOTOS_SEARCH.md`.
- Les trois fichiers de `supabase/migrations/`, audits readonly Storage/publication/orphelins, fonction `kibo-upload-listing-photo/index.ts`, ses tests et `supabase/functions/deno.lock`.
- Flutter : `listing_photos.dart`, `listing_photo_widgets.dart`, `listing_models.dart`, `listing_repository.dart`, `publish_listing_page.dart`, `listing_feed.dart`, `catalogue_search_form.dart`, `listing_query.dart`, intégration main et favoris ; tests annonces/photos/recherche/favoris et fixtures SQL.
- Configuration présente : URL publique et fichier local ignoré ; le code lit les paramètres à la compilation. Aucune configuration serveur de bucket/policy n'y est contenue. Aucun `supabase/config.toml` ni `deno.json` propre à la fonction n'est versionné à cet instant.

Le dépôt contient des **deltas**, pas le schéma initial Supabase complet. Les tables listings/profiles/categories/favorites, auth.uid, schéma private, rôles et catalogues Storage doivent déjà exister. Ne jamais reconstruire le distant par reset ou par push global de ce répertoire.

## A. Prérequis et décisions humaines avant toute écriture

1. Confirmer le projet cible, le compte opérateur et l'accès SQL/Management approprié. Utiliser l'authentification locale ou OAuth existante, jamais une clé/mot de passe dans le chat, dans une commande littérale ou dans Flutter.
2. Récupérer et archiver avec un accès autorisé en lecture seule les sorties de `direct_publication_readonly.sql` et `listing_photos_readonly.sql`. Examiner aussi les fonctions appelées indirectement, droits effectifs/hérités, politiques restrictives/permissives, version, schémas exposés et droits de la nouvelle colonne. Ne pas exporter de secrets éventuellement intégrés aux corps de fonctions.
3. Vérifier les noms, types et contraintes des tables parentes ; vérifier que leurs guards UPDATE tolèrent l'ajout d'une colonne générée. Le seul fait d'être BEFORE UPDATE ne décrit pas le corps du trigger. La fixture protège explicitement certains champs ; elle n'est pas une copie du serveur.
4. Si une politique Storage existe, **arrêt** de la voie originale photos. Faire relire une adaptation séparée qui préserve les autres buckets et interdit tout contournement du validateur. Ne supprimer aucune politique pour faire passer le preflight. S'il existe déjà un bucket/table photos, intégrer son contrat plutôt que créer un doublon.
5. Vérifier les droits SELECT de table ou de colonnes de anon/authenticated. Préparer seulement le GRANT ciblé éventuellement nécessaire ; aucune attribution globale par anticipation.
6. Vérifier sauvegarde exploitable et restauration sur environnement isolé, conserver les définitions avant intervention et les versions des trois fichiers. Mesurer taille/volumétrie, espace libre, sessions/transactions longues et durée sur un environnement représentatif. Faire approuver une fenêtre de verrouillage. Une restauration globale n'est pas le rollback normal de ce lot.
7. Réconcilier l'historique réellement enregistré dans `supabase_migrations` avec les objets présents et les deltas locaux. L'application directe via psql ne crée pas de ligne d'historique Supabase. Ne pas faire de `migration repair`, de `db push` ou de réapplication automatique sans plan distinct validé.
8. Valider CLI, configuration de fonction et bundle/lockfile avec le runtime cible. L'aide de CLI 2.54.11 a été vérifiée ici ; cela ne prouve pas qu'elle sait embarquer le lockfile Deno v5. Choisir une version officiellement prise en charge et vérifier son aide avant l'opération. Aucun Docker/Edge Runtime Supabase local complet n'a été utilisé pour cet audit.

## B. SQL — ordre exact et effets

| Ordre | Fichier | Effet | Garde / limite |
|---|---|---|---|
| 1, uniquement si non déjà appliqué et équivalent | `20261031050000_direct_listing_publication.sql` | Fonction SECURITY INVOKER + BEFORE INSERT d'horodatage et ALTER de listings_insert_own. | Aucun ancien pending publié. Preflight refuse politiques/triggers INSERT inattendus. Corps intégral de l'ancien prédicat non comparé automatiquement. |
| 2 | `20261031220517_listing_photos.sql` | Table photos, FK, contraintes/PK, grants de colonnes, RLS, bucket privé et politique Storage SELECT. | Exige un contrat sans collision et aucune politique Storage préexistante ; sinon adaptation distincte obligatoire. |
| 3 | `20261031220520_catalogue_search.sql` | tsvector français généré STORED ; index GIN et index prix/date/ID, partiels published. | Calcul sur les lignes existantes, réécriture et verrou exclusif sur listings conservé pendant la transaction et les index. Pas de CONCURRENTLY dans ce fichier. |

Les deux nouveaux deltas n'ajoutent ni extension, ni fonction PostgreSQL, ni trigger listings. Le vecteur utilise des fonctions/configurations PostgreSQL intégrées. Ses valeurs sont dérivées de title/description ; les contraintes existantes restent actives. La FK des réservations fait un CASCADE **sur les métadonnées seulement** si une annonce est physiquement supprimée ; elle ne purge pas le fichier Storage.

Les fichiers sont transactionnels mais **non idempotents**. Une erreur/collision doit conduire à un arrêt et une comparaison des définitions, pas à ajouter IF NOT EXISTS aveuglément. Les transactions sont séparées : si le fichier 3 échoue, le fichier 2 peut déjà être committé. Ne pas rejouer le fichier 2 pour cette raison.

Sur la fixture PostgreSQL 13, la réécriture et l'attente de verrou ont été reproduites. L'ALTER bloque les accès incompatibles jusqu'au commit ; prévoir lock_timeout et statement_timeout approuvés. Les index actuels sont construits dans cette même transaction. [ALTER TABLE](https://www.postgresql.org/docs/17/sql-altertable.html), [CREATE INDEX](https://www.postgresql.org/docs/current/sql-createindex.html).

### Commandes SQL proposées — NON EXÉCUTÉES

L'opérateur configure **localement** un service libpq `kibo_deploy` pour le bon projet et un utilisateur de migration, avec TLS/certificats et authentification hors historique. Ce service n'est pas configuré par cet audit. Adapter les délais seulement après estimation de la fenêtre ; les valeurs ci-dessous sont des bornes d'exemple à approuver.

```powershell
$psql = 'C:\Program Files\PostgreSQL\13\bin\psql.exe'
$connection = "service=kibo_deploy sslmode=verify-full options='-c lock_timeout=5s -c statement_timeout=120s'"
# Liste à valider selon les définitions ET l'historique réellement déployés.
# Retirer le premier fichier uniquement si son application équivalente est prouvée.
$approvedFiles = @(
  'supabase/migrations/20261031050000_direct_listing_publication.sql',
  'supabase/migrations/20261031220517_listing_photos.sql',
  'supabase/migrations/20261031220520_catalogue_search.sql'
)
foreach ($file in $approvedFiles) {
  & $psql $connection -X -v ON_ERROR_STOP=1 -f $file
  if ($LASTEXITCODE -ne 0) { throw "Arrêt de la séquence après $file" }
}
```

**Le fichier photos original ne doit pas figurer dans une séquence approuvée si son preflight est incompatible avec le Storage réel.** Une variante corrigée séparément devra remplacer cette entrée après revue et tests, sans changer subrepticement le fichier audité. Jamais de `test/sql/*fixture.sql` sur le serveur.

Après chaque commit approuvé, relever les seules définitions modifiées, vérifier contraintes/index valides et ACL. Valider le cache PostgREST avant la nouvelle projection FK/colonne ; si un rechargement explicite s'avère nécessaire, `NOTIFY pgrst, 'reload schema';` est une opération SQL à autoriser séparément, non exécutée ici. La comparaison de grants reste requise : une colonne générée a ses droits propres. [Colonnes générées PostgreSQL](https://www.postgresql.org/docs/current/ddl-generated-columns.html).

## C. Storage — contrat précis et contrôle après SQL

Le fichier photos configure déjà le bucket et la politique : **ne pas créer manuellement un bucket identique dans le Dashboard avant cette migration**.

| Élément | Contrat attendu |
|---|---|
| Bucket | `kibo-listing-photos`, `public=false`, file_size_limit=4194304, allowed_mime_types={image/jpeg}. |
| Table | `public.kibo_listing_photos(listing_id uuid, position smallint 0..2, owner_id uuid default auth.uid(), path text unique, created_at timestamptz)` ; PK listing_id/position, FK listings/profiles. |
| Chemin | `<owner UUID>/<listing UUID>/<position>-<SHA256 du JPEG client>.jpg` ; empreinte vérifiée par le serveur. Le serveur réencode les pixels ; le hash du fichier stocké n'est donc pas nécessairement ce hash source. |
| Réservation | INSERT de listing_id/position/path pour son annonce draft/pending/published ; owner_id imposé par défaut/contrôle RLS. Trois emplacements uniques, y compris en concurrence. |
| Upload / écrasement | Aucun INSERT/UPDATE client direct sur storage.objects. POST serveur après validation, x-upsert=false. Une reprise de même fichier utilise le même chemin ; conflit pris comme déjà traité. |
| Lecture | Métadonnées et objet référencé pour annonce published ou propriétaire ; les autres utilisateurs ne voient pas les pending/rejected/archived. URLs signées 60 s ; pas d'URL de bucket public. |
| Mise à jour / suppression | Aucun UPDATE/DELETE client des réservations ou objets. Aucune édition de photos déjà publiées dans ce lot. Les opérations administratives et purges sont hors périmètre. |
| Limites | Flutter accepte JPEG/PNG/WebP source ≤20 Mio/24 MP, réencode JPEG ≤1600 px/4 Mio ; Edge impose corps JSON ≤6 Mio, JPEG ≤4 Mio, décodage ≤3 MP/64 Mio puis réencodage sans EXIF/GPS. |

Contrôler tous les grants et politiques, pas seulement leurs noms. Des politiques permissives globales ajoutées **ultérieurement** pourraient contourner l'interdiction initiale d'upload/lecture ; la proposition de garde restrictive est documentée séparément. Aucun bucket n'est rendu public pour résoudre une erreur.

Une réservation peut exister sans objet après échec réseau. Une suppression administrative d'annonce peut laisser un objet orphelin. Utiliser `listing_photos_orphans_readonly.sql` pour un inventaire, sans lancer de GC ni suppression automatique. Une URL déjà signée peut rester valide jusqu'à ses 60 s après masquage ; la suppression du cache déjà téléchargé n'est pas garantie.

## D. Edge Functions — configuration puis déploiement approuvés

Avant déploiement :

1. Résoudre la configuration d'entrée et l'empaquetage du lockfile dans une **proposition locale séparée**, puis valider le bundle réel. Le code utilise import.meta.main pour enregistrer Deno.serve ; les tests importent le handler et ne prouvent pas le listener hébergé. Le runtime source actuel charge un module principal, mais sa version sur le projet n'a pas été contrôlée. [Source officielle Edge Runtime](https://github.com/supabase/edge-runtime/blob/main/crates/base/src/runtime/mod.rs).
2. Conserver `verify_jwt=true` pour cet endpoint utilisateur ; le handler valide également le jeton avec Auth puis l'ownership/réservation via le JWT utilisateur. Vérifier le comportement réel de la passerelle avec les clés/signatures du projet, sans utiliser --no-verify-jwt comme dépannage automatique. [Configuration](https://supabase.com/docs/guides/functions/function-configuration), [en-têtes d'autorisation](https://supabase.com/docs/guides/functions/auth-headers).
3. Vérifier uniquement la présence et la nature des variables **serveur** SUPABASE_URL, SUPABASE_ANON_KEY et SUPABASE_SERVICE_ROLE_KEY, sans les lire dans le chat ni les intégrer au build Flutter. Ne pas essayer de recréer des secrets réservés SUPABASE_* via une commande. Si leur fourniture par la plateforme est différente, arrêter et faire revoir l'adaptateur.
4. Faire approuver le code qui détient le droit serveur Storage. Les limites et la validation doivent précéder cette écriture ; aucun accès aux métadonnées d'autrui ne doit suffire. Les erreurs fournisseurs ne sont pas journalisées avec données/jetons. Les exceptions réseau sont actuellement regroupées avec les erreurs d'entrée sous 400 : amélioration distincte proposée pour le diagnostic.
5. Mesurer le CPU/mémoire sur préproduction autorisée avec des images réalistes/maximales. Le test local bruité 1600×1600 accepte 3 743 980 octets, HTTP simulé 200 et une seule écriture, en environ 1044 ms de temps mural sur ce poste. Cela ne certifie pas la limite CPU hébergée ni la charge concurrente. [Limites Edge](https://supabase.com/docs/guides/functions/limits).

Commande proposée après validation des points précédents, **NON EXÉCUTÉE** :

```powershell
# Exemple basé sur l'aide CLI vérifiée ; version à faire valider avec le bundle.
npx.cmd --yes supabase@2.54.11 functions deploy kibo-upload-listing-photo --project-ref fcfmfpywpurrvppxdltm --use-api
```

Cette commande cible une seule fonction, sans --prune, sans --no-verify-jwt, sans db push et sans changement de données demandé. Ne pas l'exécuter si cette version ne prend pas en charge le bundle/lockfile retenu. Le fichier lock v5 a été vérifié par Deno 2.5.6, pas par un déploiement CLI/serveur. Si le bundle n'est pas validé, arrêter ; ne pas ignorer le verrou ou retirer l'authentification pour passer.

## E. Flutter — build, canari et diffusion

Après SQL, Storage et Edge validés :

```powershell
flutter build apk --debug --target-platform android-arm64 --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true
```

Build proposé uniquement, non exécuté pendant cet audit. Vérifier les versions et la signature, conserver l'APK précédent et ne pas effacer les données applicatives. Contrôler ensuite l'appareil cible et demander l'autorisation d'installation du canari avant `adb install -r`. Une publication en store nécessite une autorisation de diffusion distincte ; aucun build release ni publication automatique prévu ici.

Sans le paramètre photos, sa valeur est false : ancienne projection et aucun upload photo proposé. La recherche texte n'a pas de coupe-circuit distinct dans le code courant : elle nécessite la colonne/index avant diffusion du client. Les filtres/tri sans texte utilisent les colonnes existantes. Le SDK transmet un JWT utilisateur, jamais service_role.

## F. Contrôles post-déploiement et recette à autoriser

Les contrôles readonly sont réalisés d'abord ; **les scénarios qui écrivent exigent une autorisation des comptes et données de test**. Ils ne sont pas exécutés pendant cet audit.

- SQL : RLS active, droits par rôle/colonne, PK/FK/CHECK, valeurs par défaut, unicité des slots/paths, index valides, expression vectorielle, politiques listings/favorites inchangées hors delta prévu. Vérifier que le retour INSERT id/status/published_at fonctionne. Contrôler schéma cache FK et plans réels pour les recherches/tri ; le plan de quelques lignes fictives n'est pas un benchmark.
- Auth/Edge : visiteur, JWT expiré, token d'un autre projet et propriétaire usurpé refusés sans écriture ; token A valide accepté seulement sur son annonce et sa réservation. Contrôler en-têtes, CORS et disponibilité sans afficher des jetons.
- Photos : 0/1/3 images, première principale, suppression/réorganisation avant publication, JPEG/PNG/WebP client, format interdit, fichier tronqué, >20 Mio client, >4 Mio serveur, dimensions hors limite et mauvais digest. Tester un upload direct/malformé via Storage pour confirmer son refus malgré tout autre bucket.
- Réseau : perte de réponse après réservation/upload, erreur Edge et stockage, reprise même chemin et même ID d'annonce sans upsert ni nouvelle annonce. Fermer le formulaire pour documenter la limite de reprise en mémoire ; récupération native Android uniquement pour le même compte. Tester annulation, double appui et changement de session.
- Visibilité : carte/détail/Favoris, URLs signées renouvelées après expiration ; parent pending/rejected/archived invisible à B/visiteur, propriétaire selon contrat. Après masquage d'une annonce publiée, tester une nouvelle URL et relever l'expiration de l'ancienne ; aucune promesse de révocation instantanée.
- Limites/concurrence : deux réservations du même slot concurrentes, quatrième slot, tentative de changer owner/path et d'écraser/supprimer l'objet d'autrui refusées. Ne pas effectuer ces tests sur des annonces réelles.
- Recherche : titre, description, français/accents selon comportement réellement retenu, catégorie, ville exacte, prix min/max (zéro, décimales, bornes inversées), tri récent/croissant/décroissant avec égalités et plusieurs pages. Aucune annonce non publiée, même pour son vendeur, dans ce catalogue. Effacement, vide, erreur, retry et anciennes réponses ; 320 px, texte 150 %, clavier et navigation accessible.
- Favoris : A publie, B ouvre/ajoute, actualise puis relance, retire et vérifie les trois vues ; A ne voit/modifie pas les favoris B et inversement. Après accord séparé, vérifier les transitions de modération et droits UPDATE de l'annonce.

## G. Arrêts et retour arrière sans perte

**Arrêter immédiatement la séquence** en cas de cible/historique incertain, échec du preflight, politique Storage globale non revue, droits manquants, collision, verrou/durée/espace non approuvés, test de sécurité échoué, bundle/runtime/JWT non validé ou exposition publique inattendue. Aucun contournement RLS, changement de public=false, grant global, reset, suppression de politique ou --prune.

Avant COMMIT : l'échec d'un fichier transactionnel annule ses changements ; vérifier l'état puis arrêter. Après COMMIT : conserver les objets additifs et les données. Ne pas supprimer bucket, table, réservations, colonne/index ou annonces pour « revenir en arrière ». Ne pas réappliquer le schéma initial ni restaurer globalement une sauvegarde par défaut : cela pourrait perdre les écritures légitimes intervenues depuis.

1. **Avant diffusion Flutter** : conserver l'ancien client/flag false, arrêter les étapes suivantes et corriger en avant. Les données historiques et nouveaux objets restent présents. Ne pas annuler la publication directe par une dépublication d'annonces.
2. **Après diffusion** : préparer un build de repli validé (photos false et client recherche compatible) et organiser son installation/diffusion autorisée. Un booléen de compilation n'est pas un interrupteur distant : les anciens binaires restent actifs jusqu'à mise à jour.
3. **Si un gel immédiat des uploads est nécessaire** : proposer et faire approuver une version maintenance de cette seule fonction qui répond 503 sans écrire, avec JWT toujours exigé, puis déployer sous autorisation distincte. Ne pas ouvrir Storage. Attention : le client crée l'annonce avant les photos ; ce gel n'empêche pas à lui seul les annonces sans photo/réservations incomplètes. Un gel global de publication serait une décision distincte.
4. **Si la fonction remplace une version existante** : restaurer uniquement un artefact antérieur validé et compatible, après approbation ; si première version, conserver un endpoint fermé aux écritures plutôt que supprimer des ressources. Conserver les logs utiles sans données sensibles.
5. **Données et reprise** : inventaire readonly, conservation des objets/métadonnées et reconciliation avant reprise. Aucune purge automatique de réservation/objet après erreur réseau ou simple collision ; elle pourrait supprimer un upload réussi. Les nettoyages ou migrations descendantes éventuels restent hors de ce plan et nécessitent une nouvelle revue/autorisation.

## H. Vérifications réellement exécutées pendant l'audit

- `flutter analyze --no-pub --fatal-infos` : code 0, aucune anomalie (3,3 s).
- `flutter test --no-pub --reporter expanded` : **106 tests réussis**, code 0, environ 14 s. Suite complète utilisée, donc annonces/photos/recherche/favoris inclus.
- Deno 2.5.6 check et tests du handler avec lockfile : **3 tests réussis**, services simulés.
- Nouveau `test/audit/edge_photo_boundary_test.ts` : **1 test réussi**, image synthétique bruitée 1600×1600, handler réel et services simulés, aucune requête externe.
- PostgreSQL 13.22 neuf sur 127.0.0.1:53215, utilisateur fictif kibo_audit : ordre complet des migrations intactes, assertions publication/propriété/photos/recherche réussis. Refus de réapplication code 3 attendu pour les deux nouvelles migrations, assertions toujours réussies ensuite. Une base de garde distincte prouve le refus si une politique Storage existe, sans création de table photos ni suppression de politique.
- Test de lock_timeout=500ms : refus attendu, puis reprise réussie après fin du lecteur ; réécriture observée par changement de filenode. Test de rôle à SELECT par colonnes : accès à la nouvelle colonne refusé, comme attendu. Tests fictifs annulés ; cluster arrêté et fichiers conservés, service existant intact.
- Premier lanceur PowerShell a traité le stderr du refus de verrou attendu comme une exception : il a arrêté proprement le cluster. Reprise du même cluster sans reset, refus attendu ensuite traité explicitement ; toute la séquence a réussi. Aucun échec des migrations corrigé en modifiant leurs fichiers.
- `git diff --check` et comparaison d'empreintes des migrations : contrôlés avant conclusion. Aucun test distant, Docker/Storage HTTP réel, Edge Runtime hébergé, build ou installation Android effectué.

Les commandes de déploiement du plan n'ont pas été exécutées. Les seuls fichiers applicatifs nouveaux de cet audit sont un test local supplémentaire ; les autres changements sont documentaires. Les faits distants de l'audit antérieur restent attribués à l'utilisateur, pas à une nouvelle lecture du serveur.
