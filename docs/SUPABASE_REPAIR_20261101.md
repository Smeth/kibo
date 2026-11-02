# Intervention Supabase autorisée — 2026-11-01

## Autorisation, accès et conservation

L'utilisateur a explicitement autorisé les corrections distantes : « je t'autorise à tout faire », dans le cadre du rétablissement de KIBO. Intervention sur **fcfmfpywpurrvppxdltm**, branche de projet **main / PRODUCTION**, via la session Dashboard KIBO déjà authentifiée dans Chrome. Aucun secret, cookie, jeton de session ou mot de passe extrait, aucune clé créée/copiante dans le dépôt. Le plugin Supabase était installé mais ses outils SQL non exposés ; l'accès natif à l'onglet existant a permis de poursuivre. Les précédents blocages d'accès sont donc levés, pas une raison de réinstaller le plugin.

Les requêtes ont été exécutées dans un nouveau brouillon SQL de l'assistant ; aucun ancien brouillon utilisateur remplacé. Le contexte des autres onglets n'a pas servi à l'intervention. Des changements de focus/dimensions ont interrompu le contrôle, puis l'utilisateur a confirmé laisser Chrome disponible. Les saisies ont été relues avant exécution ; le lot SQL a été constaté appliqué dans l'éditeur et n'a pas été rejoué. Les contrôles REST indépendants confirment ses effets.

**Aucune annonce supprimée/recréée et aucune image utilisateur téléversée.** Compteurs avant/après : listings **6 → 6**, listing_images **0 → 0** ; nouvelles réservations **0** au contrôle final. Aucun changement Auth de compte, commit, push, installation Android ou effacement de données.

## Définitions distantes relevées avant correction

Fonction observée, mise en forme pour lecture (corps conservé sans modification) :

```sql
CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
  select coalesce(auth.jwt() -> 'app_metadata' ->> 'role' = 'admin', false);
$function$;
```

ACL initiale `{postgres=X/postgres,authenticated=X/postgres}` : anon EXECUTE **false**, authenticated **true**. L'admin provient de app_metadata signé, pas de user_metadata modifiable. Le prédicat ne mute rien et son search_path est vide. RLS listings SELECT observée : published OU seller_id=auth.uid() OU private.is_admin(), pour anon/authenticated. INSERT est déjà le contrat de publication directe avec horodatage statement_timestamp ; il n'a pas été réappliqué.

Triggers listings réellement inspectés : kibo_stamp_listing_publication BEFORE INSERT ; listings_guard, listings_guard_owner_update et listings_updated_at BEFORE UPDATE. Les guards protègent explicitement vendeur/statut/vues/date/rejet, sans comparaison d'un enregistrement complet. L'ajout du vecteur ne nécessite donc pas de les remplacer. Taille totale listings relevée : **139264 octets**.

Contrat historique présent : table public.listing_images(id, listing_id, storage_path, position, created_at), bucket **listing-images public**, JPEG/PNG/WebP ≤5242880 octets. Deux politiques Storage :

- listing_storage_upload, INSERT authenticated, seulement bucket listing-images et dossier propriétaire/annonce correspondants ; MIME et taille metadata contrôlés ; parent propriétaire draft/pending/rejected.
- listing_storage_delete, DELETE authenticated, même bucket/dossiers et annonce propriétaire.

Aucune de ces politiques n'autorise le nouveau bucket. Le contrat kibo_listing_photos était réellement **absent** dans pg_class et le vecteur absent des colonnes. Storage.objects a RLS active. Les anciennes politiques et le bucket sont conservés.

## Modifications réellement appliquées

1. **Lecture publique :** `supabase/proposals/restore_listing_read_execute.sql`, garde sur signature/corps/sécurité/configuration exacts audités, puis **GRANT EXECUTE seulement à anon**. authenticated possédait déjà ce droit. Aucun changement du corps ou rôle administrateur. Contrôle Dashboard anon_execute=true, puis GET listings limit=0 : **200** au lieu de 401/42501.
2. **Photos :** variante locale créée par CLI puis testée : `supabase/migrations/20261101022728_listing_photos_existing_storage.sql`. Elle reprend le contrat table/bucket/RLS de la proposition originale sans supprimer les politiques préexistantes, et ajoute **quatre gardes AS RESTRICTIVE** SELECT/INSERT/UPDATE/DELETE sur le nouveau bucket seulement. Aucun write client direct ; le validateur serveur reste seul écrivain. La proposition originale `20261031220517_listing_photos.sql` est conservée intacte et **n'a pas été exécutée** : son preflight aurait refusé le Storage historique.
3. **Recherche :** application de `20261031220520_catalogue_search.sql` : colonne française STORED, index GIN et prix/date/ID, partiels published. Aucun changement des politiques listings/favorites ni des six annonces.
4. **Transaction :** photos/recherche appliquées ensemble avec lock_timeout=5s, statement_timeout=120s, garde vérifiant l'empreinte des politiques Storage avant intervention, historique des deux fichiers et NOTIFY pgrst/reload schema, COMMIT. Lot source conservé dans `.dart_tool/kibo-verifications/remote-photos-search-20261101.sql`, SHA-256 `6FB8CE5B752E385A08654B5650A1733D9340BE268A1F00AA2B7ED02F83CCB4AF`.
5. **Edge :** création/déploiement Dashboard de **kibo-upload-listing-photo**, auparavant aucune fonction déployée. Source index.ts locale testée, deno.json et deno.lock autonome inclus. La copie du verrou partagé est identique à l'original, conservé ; le chemin de verrou du deno.json local devient ./deno.lock pour ce paquet autonome. Le verrou affiché a été comparé au JSON du fichier local avant déploiement. Aucun secret serveur lu ou recréé ; le runtime utilise les variables réservées fournies par la plateforme.

L'historique distant contient désormais les versions **20261101022728 listing_photos_existing_storage** et **20261031220520 catalogue_search**, avec leur source dans statements. Historique ancien conservé : publication directe déployée sous version serveur **20261031214815**, nom **20261031050000_direct_listing_publication**, plus deux migrations de durcissement antérieures absentes du socle local. **Ne pas faire de db push/reset global** : les versions locales originales publication/photos ne sont pas des fichiers à réappliquer. La réconciliation/baseline globale du schéma historique reste une opération séparée ; aucun faux statut d'application de l'ancienne migration photos n'a été ajouté.

## Sécurité et vérifications finales observées

Contrôles SQL via `supabase/audits/photos_search_postdeploy_readonly.sql` :

| Contrôle | Résultat |
|---|---|
| Bucket kibo-listing-photos | public=false, JPEG seul, limite4194304 |
| Empreinte des deux anciennes policies Storage | **3d072f7988e307137d9abd57c16e5a8a**, identique avant/après |
| Gardes Storage restrictives du nouveau bucket | **4** |
| RLS kibo_listing_photos | **true** |
| INSERT owner_id par authenticated | **false** |
| UPDATE path par authenticated | **false** |
| Index kibo_listings_search_gin et kibo_listings_price | tous deux **valid=true** |
| Compteurs | listings 6, anciennes images 0, réservations 0 |

Contrôles réseau réels, sans lignes/écriture métier :

- GET listings published limit=0 : **200**.
- GET listings avec relation kibo_listing_photos limit=0 : **200**.
- GET table photos limit=0 : **200**.
- GET colonne kibo_search_vector limit=0 : **200**.
- OPTIONS fonction : **200** ; cela confirme le démarrage effectif, les dépendances et le listener Deno.serve.
- POST sans credentials : **401**, Missing authorization header de la passerelle.
- POST avec faux jeton, sans clé API : **401**, Invalid JWT de la passerelle.
- POST avec clé publique seulement, sans JWT utilisateur : **401**, `authentication` du handler. La compatibilité API-key de la passerelle n'autorise donc pas un upload utilisateur ; le handler exige encore un utilisateur validé par Auth.

`verify_jwt=true` local est conservé ; aucun réglage JWT n'a été désactivé. Les algorithmes du JWKS public exposent ES256 ; aucune clé/JWT n'a été copiée. La documentation actuelle confirme que la vérification plateforme accepte les JWT asymétriques et que le contrôle applicatif reste nécessaire pour les appels avec clé API seule : [Authorization headers](https://supabase.com/docs/guides/functions/auth-headers).

## Vérifications locales exécutées pour cette intervention

Nouvelle fixture PostgreSQL 13.22 isolée, 127.0.0.1:53225, fichiers conservés et cluster arrêté. Séquence : fixture publication → migration publication → stub Storage → fixture ancien bucket/policy → nouvelle variante photos → migration recherche → assertions photos/recherche → assertions ancien Storage → assertions propriété/champs protégés/favoris. **Toutes réussies**. Le test ajoute aussi une policy globale permissive fictive et démontre qu'elle ne contourne pas les nouvelles gardes, tout en laissant INSERT/UPDATE/DELETE fonctionner sur l'ancien bucket. Transactions d'assertions annulées.

Deno 2.5.6 check du paquet autonome et **4 tests Edge réussis** (dernier passage ~414ms), services Auth/Storage simulés. Flutter/Android inchangés pendant cette intervention : les **129+129 tests**, analyse stricte et APK corrigé du lot précédent restent leur dernière validation ; pas de nouvelle compilation/installation revendiquée. Diff et inventaire finaux contrôlés.

## Prochain geste physique

Si le formulaire d'origine conserve ses aperçus : **Réessayer les photos une seule fois**, sur le même ID, attendre la réponse ; après succès le catalogue se recharge. Ne pas redémarrer/réinstaller/changer de compte avant cette reprise. Si l'écran est déjà Accueil, actualiser les annonces pour vérifier le chargement rétabli ; cela ne restaure pas un ancien brouillon photo détruit. Aucune récupération persistante de photos n'est inventée.

L'APK déjà installé avec photos activées peut utiliser le backend réparé : aucune installation n'est nécessaire pour constater ces corrections serveur. Le binaire corrigé local FC17FAEE… reste disponible mais non installé. L'upload authentifié d'images réelles, la charge CPU hébergée, l'expiration des URLs et le parcours A/B complet restent à constater sur appareil ; ne pas les déclarer testés à partir des contrôles 200/401. Aucune photo de test envoyée sur une annonce existante pour vérifier artificiellement un succès.
