# Correctifs catalogue, recherche et photos — 2026-11-01

## État actualisé après autorisation distante

Le serveur a depuis été **réparé et contrôlé**, via la session Dashboard KIBO existante : droit is_admin, variante photos compatible avec le Storage historique, recherche et fonction d'upload déployés. Catalogue/photos/vecteur200, OPTIONS200, refus401 des appels non authentifiés. Six annonces et anciennes policies conservées. Voir [SUPABASE_REPAIR_20261101.md](SUPABASE_REPAIR_20261101.md) pour les actions effectivement appliquées ; les propositions et blocages ci-dessous décrivent l'état antérieur, pas des opérations restant à rejouer. La recette physique complète n'est pas encore validée.

## Causes vérifiées à distance en lecture seule

Projet configuré localement : `fcfmfpywpurrvppxdltm`. Requêtes utilisant uniquement la clé publique déjà disponible, jamais affichée. GET REST avec **limit=0** : aucune ligne d'annonce/photo téléchargée, aucun token utilisateur extrait. OPTIONS sur la fonction : aucun upload. Aucun SQL distant exécuté.

| Contrôle | Résultat réellement observé |
|---|---|
| GET listings, select=id, limit=0, rôle public | **401 / 42501**, `permission denied for function is_admin`. |
| Projection listings → kibo_listing_photos(path,position), limit=0 | **400 / PGRST200**, `Could not find a relationship between 'listings' and 'kibo_listing_photos' in the schema cache`. |
| GET kibo_listing_photos, select=listing_id, limit=0 | **404 / PGRST205**, `Could not find the table 'public.kibo_listing_photos' in the schema cache`. |
| GET listings, select=kibo_search_vector, limit=0 | **400 / 42703**, `column listings.kibo_search_vector does not exist`. |
| OPTIONS kibo-upload-listing-photo | **404 / NOT_FOUND**, `Requested function was not found`. |

**Conclusion : le backend accessible ne fournit pas le contrat de l'APK photos/recherche.** La projection photos suffit à casser le catalogue avant tout affichage ; sans cette projection, la lecture publique reste bloquée par EXECUTE sur is_admin. Le contrat de recherche dédié manque et la route d'upload est introuvable. Cela explique plusieurs échecs distincts, pas une panne unique de compression d'image.

Limites : PGRST200/PGRST205 ne sont pas une inspection de pg_class ; table/FK peuvent manquer ou ne pas être exposées/reconnues dans le cache. Les requêtes ont le rôle public, pas la session du TECNO : les droits exacts authenticated ne sont pas certifiés. Le schéma et le corps qualifiés de is_admin, son propriétaire/ACL et les buckets réels ne sont pas accessibles avec la clé publique. Aucun statut exact de l'ancienne tentative d'upload du téléphone n'est déduit de ces lectures ultérieures. Références : [codes PostgREST](https://docs.postgrest.org/en/stable/references/errors.html).

## Corrections effectuées localement

1. **Catalogue, détail, favoris :** si et seulement si une erreur de schéma identifie la relation optionnelle kibo_listing_photos, une seconde lecture reprend la projection historique sans photos. Tous les filtres published, propriétaire des favoris, prix/catégorie/ville, tri et pagination restent actifs. Une erreur 42501 ou une autre relation absente n'est jamais contournée. Carte/détail affichent « Photos momentanément indisponibles. » afin de distinguer cette situation d'une annonce réellement sans photo. Le détail utilise une lecture de liste limitée à un ID pour conserver les codes d'erreur que maybeSingle peut masquer dans le SDK actuel.
2. **Recherche :** si seule la colonne kibo_search_vector manque, la recherche reste côté serveur via websearch français sur title OU description, avec texte cité/échappé en JSON pour éviter l'injection de syntaxe PostgREST. Aucun retour silencieux à un catalogue non filtré et aucune récupération de toutes les annonces. Critères et pages de 20 inchangés. Ce mode transitoire recherche l'expression entière dans chaque champ séparément : il ne remplace pas les termes répartis entre titre et description du vecteur combiné et peut être moins rapide sans index. La migration reste la solution cible. [Conversion text → tsvector](https://docs.postgrest.org/en/stable/references/api/tables_views.html#automatic-tsvector-conversion).
3. **Avant nouvelle publication avec photos :** préflight GET de la table photos sans lignes et OPTIONS sur la fonction, sans réservation/annonce/upload. Si indisponible, création bloquée, texte et images conservés, message explicite « Aucune annonce créée ». L'utilisateur peut attendre ou retirer lui-même les images pour publier sans photo. Le préflight n'est pas une preuve de validation Storage complète ni une transaction atomique : une panne ultérieure peut encore produire une annonce avec photos incomplètes.
4. **Reprise existante :** le préflight est réservé à la création initiale ; il ne réinitialise jamais l'ID existant. Réessayer conserve l'annonce, les octets, positions et chemins immuables. Aucun DELETE, UPSERT d'objet ou republication automatique ajouté.
5. **Droits :** un 42501 de lecture a désormais un message dédié. Aucun GRANT serveur ou changement de RLS exécuté par l'application.
6. **Préparation Edge :** configuration locale `supabase/config.toml`, verify_jwt=true et entrypoint explicite ; `deno.json` référence le lock existant. Deno vérifie cette configuration ; cela ne prouve pas un bundle ou un déploiement Supabase réel.

## Intervention distante nécessaire, non exécutée

### 1. Audit autorisé des droits et du contrat

Exécuter **uniquement** `supabase/audits/catalogue_compatibility_readonly.sql` avec une connexion opérateur autorisée, puis le script photos readonly existant. Conserver les corps de fonctions localement s'ils contiennent des données sensibles ; aucune clé/mot de passe dans le chat. La connexion Supabase est confirmée installée/activée par la gestion des plugins, mais aucun outil SQL Supabase n'est exposé ici. Variables de connexion PG/admin absentes de l'environnement courant ; inventaire navigateur : hôte d'accès navigateur indisponible. Cela ne justifie pas une nouvelle installation du plugin ni l'extraction de credentials.

Vérifier que la politique appelle effectivement **private.is_admin()**, signature sans argument, retour boolean ; examiner son propriétaire, search_path, SECURITY DEFINER/INVOKER et son corps. Il doit contrôler les droits côté serveur, sans mutation, user_metadata éditable ou rôle fourni par le client. Ne jamais remplacer cette fonction par `true`/`false` pour faire passer l'écran.

### 2. Delta minimal conditionnel pour la lecture

Fichier préparé : `supabase/proposals/restore_listing_read_execute.sql`, **pas une migration appliquée**. Après vérification du point précédent seulement :

```sql
GRANT EXECUTE ON FUNCTION private.is_admin() TO anon, authenticated;
```

Ce droit permet à la politique RLS d'évaluer son prédicat ; il ne donne aucun rôle administrateur, aucun droit d'écrire une annonce et ne désactive aucune politique. Le fichier vérifie l'existence/signature boolean sans argument et s'arrête sinon. La qualification private reste une hypothèse issue du contrat local, pas une définition distante observée : si la politique appelle une autre fonction, ne pas appliquer ce fichier tel quel. Une table/ACL différente doit faire l'objet d'un delta séparé après audit.

Validation après application autorisée : lecture limit=0 publique réussie, puis jeu de recette autorisé pour visibilité published et refus d'accès aux annonces/favoris d'autrui. Ne pas appliquer le grant à toutes les fonctions d'un schéma et ne pas ajouter de policy OR.

### 3. Photos et recherche

Comparer l'état réel/historique avec le [plan de déploiement](DEPLOYMENT_PLAN_PHOTOS_SEARCH.md). Ne pas rejouer la publication directe à l'aveugle : des annonces ont déjà été publiées et son état peut avoir changé hors de l'assistant.

- Photos : préparer/approuver la variante appropriée de `20261031220517_listing_photos.sql`. Le preflight refuse tout bucket/table ou policy Storage préexistant ; ne pas supprimer ces objets pour le contourner. Bucket privé kibo-listing-photos, limites JPEG/4 Mio et réservations owner/listing/position-hash.jpg. Aucune politique client d'upload direct à ouvrir.
- Recherche : `20261031220520_catalogue_search.sql`, en tenant compte de la réécriture/verrou de listings et des droits SELECT de colonne. Fenêtre et espace à valider ; pas de reset/push global.
- Edge : après revue de la configuration et du bundle/lockfile, déployer uniquement kibo-upload-listing-photo avec JWT exigé et variables serveur fournies par la plateforme. La commande proposée reste celle du plan ; aucun déploiement ou secret serveur saisi ici. Le bucket seul ne suffit pas sans la fonction et les réservations.
- Contrôles : relire cache/FK/ACL et présence de la route ; rejouer les lectures sans lignes. Après autorisation séparée, retenter les seules photos de l'annonce existante, puis catalogue/détail/recherche/favoris/isolation. Ne supprimer aucune annonce, réservation ou fichier pour « repartir de zéro ».

## Tests réellement exécutés et limites

- Tests de compatibilité nouveaux : catalogue/détail/favoris sans relation photos, refus de droits et autre relation non contournés, recherche sans vecteur avec critères/tri/page et texte contenant de la syntaxe, autre colonne manquante non masquée, préflight sans écriture, rendu explicite photos indisponibles.
- Test widget photo renforcé : préflight refusé → **zéro annonce créée**, images conservées ; préflight disponible → création unique ; échecs/reprises ultérieurs avec même ID et sans rejouer le préflight.
- Analyse stricte réussie, **129 tests avec photos activées et 129 en configuration standard réussis**. Tests ciblés finaux : **17 réussis**. Premiers passages ont signalé des erreurs de compilation/style, un libellé de détail régressé et un clic de test hors écran après ajout du message ; corrigés avant les suites finales, aucune assertion retirée pour masquer un refus.
- PostgreSQL 13.22 fixture isolée 127.0.0.1:53215 : nouveau `catalogue_read_permissions_assertions.sql` reproduit le refus en retirant EXECUTE, puis vérifie la lecture après le GRANT minimal ; ROLLBACK. Assertions propriété/champs protégés/favoris réussies ensuite, ROLLBACK, cluster arrêté. Fonction de fixture = prédicat faux réduit, pas une validation du corps distant. Premier lanceur Start-Process -Wait attendait aussi le processus serveur descendant ; exécution SQL reprise séparément, réussie, arrêt effectué ; l'ancien lanceur a ensuite signalé une connexion refusée sur le cluster déjà arrêté. Aucun serveur/donnée distant touché.
- Deux lectures de validation syntaxique du fallback recherche (terme simple et terme avec caractères réservés), limit=0 : requêtes acceptées par le parseur puis **401/42501** ; le problème is_admin reste donc bloquant. Ce n'est pas une recette de résultats réels.
- Deno 2.5.6 check avec nouvelle configuration et **4 tests Edge réussis** (319 ms), services simulés. Aucun upload réel.

## APK et conservation de l'état

APK corrigé compilé avec succès : assembleDebug 43,1 s, `C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk`, 110696428 octets, SHA-256 `FC17FAEE2E8C22E77896AF006A5907FDA10ADEAB4C422DEE288E5E11938CB93C`. Ancien APK archivé avant compilation dans le dossier ignoré, hash 775B66D2… ; aucune installation. **Ne pas installer/restart tant que le formulaire actuel contient les seules photos en attente.** Aucun transfert persistant de cette file n'est implémenté et aucune annonce n'est recréée pour contourner cette limite. Le nouveau code ne corrige pas à lui seul le serveur déjà configuré : tant que le droit is_admin et le backend photos ne sont pas réparés, la recette intégrée reste bloquée.

Aucun SQL/donnée/objet distant modifié, aucune installation ou nouvelle tentative effectuée, aucun commit/push. Les migrations originales restent intactes ; tous les changements préexistants sont conservés.
