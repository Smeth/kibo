# Adaptations proposées après audit — non appliquées

**État ultérieur 2026-11-01 :** les gardes restrictives proposées ont été intégrées dans `20261101022728_listing_photos_existing_storage.sql`, testées avec un ancien bucket et une policy globale fictive puis appliquées au projet autorisé. Le validateur a été déployé, avec configuration Deno autonome. Les anciennes propositions de ce document ne sont pas à appliquer de nouveau. Voir [SUPABASE_REPAIR_20261101.md](SUPABASE_REPAIR_20261101.md).

Ce document sépare les propositions des migrations originales inchangées. Aucun SQL de ce document n'est exécuté sur le serveur ou ajouté à une migration pendant cet audit. Ne pas copier ces extraits dans une procédure de production sans une revue de l'état réel et des tests de la variante complète.

## P1 — Storage existant et évolution future des politiques

**Fait** : le preflight actuel refuse toute politique sur storage.objects, y compris une règle d'un autre bucket. Test local confirmé. C'est un arrêt de sécurité, pas une raison de supprimer des règles. **Inconnu** : politiques réellement présentes à distance.

Si l'audit confirme des règles existantes, préparer une **variante locale séparée complète** du delta photos qui conserve celles-ci et renforce le nouveau bucket avec des gardes restrictives. Il ne suffit pas d'enlever le preflight : une règle permissive large s'ajouterait en OR et pourrait contourner le validateur. Exemple à intégrer/revoir/tester, pas à appliquer avant le fichier original (son preflight refuserait alors ces politiques) :

```sql
-- Proposition seulement ; suppose la table et la politique SELECT du nouveau
-- contrat creees dans cette meme variante transactionnelle.
CREATE POLICY kibo_photo_read_scope ON storage.objects AS RESTRICTIVE
FOR SELECT TO anon, authenticated
USING (bucket_id IS DISTINCT FROM 'kibo-listing-photos' OR EXISTS (
  SELECT 1 FROM public.kibo_listing_photos p JOIN public.listings l ON l.id = p.listing_id
  WHERE p.path = name AND (l.status::text = 'published' OR l.seller_id = auth.uid())
));
CREATE POLICY kibo_photo_no_client_insert ON storage.objects AS RESTRICTIVE
FOR INSERT TO anon, authenticated
WITH CHECK (bucket_id IS DISTINCT FROM 'kibo-listing-photos');
CREATE POLICY kibo_photo_no_client_update ON storage.objects AS RESTRICTIVE
FOR UPDATE TO anon, authenticated
USING (bucket_id IS DISTINCT FROM 'kibo-listing-photos')
WITH CHECK (bucket_id IS DISTINCT FROM 'kibo-listing-photos');
CREATE POLICY kibo_photo_no_client_delete ON storage.objects AS RESTRICTIVE
FOR DELETE TO anon, authenticated
USING (bucket_id IS DISTINCT FROM 'kibo-listing-photos');
```

Les gardes sont vraies pour les autres buckets et pour bucket_id NULL : leurs règles existantes continuent à décider. Elles ne créent pas un droit permissif d'écriture. La lecture du nouveau bucket exige toujours une politique permissive SELECT appropriée. Vérifier rôles hérités, bypassrls et toute fonction privilégiée séparément. Les identifiants de politiques et les objets parents doivent être sans collision. Cette proposition **n'a pas été appliquée ni testée comme variante complète** : tests obligatoires avec politiques globales et autres buckets avant adoption.

## P1 conditionnel — SELECT sur le vecteur de recherche

**Fait** : un rôle limité aux anciennes colonnes ne lit pas automatiquement kibo_search_vector ; reproduit localement. **Inconnu** : grant de table ou grant par colonne des rôles déployés.

Si l'audit/post-contrôle révèle un droit manquant, proposer uniquement le grant de colonne aux rôles identifiés. Exemple à restreindre au besoin réel :

```sql
-- Seulement apres existence de la colonne et revue des ACL reelles.
GRANT SELECT (kibo_search_vector) ON public.listings TO anon, authenticated;
```

Ne pas remplacer par GRANT ALL ni modifier RLS. Les triggers BEFORE UPDATE qui comparent un enregistrement entier doivent aussi être relus : la colonne générée est calculée après ces triggers. Le test local ne certifie pas leurs corps distants.

## P1 opérationnel — fenêtre de verrou et gros catalogue

**Fait** : le delta recherche réécrit la table sur la fixture et reste en transaction pendant les deux index ; lock_timeout reproduit. Taille/durée/versions distantes inconnues.

Choisir après mesure : conserver le delta original dans une courte fenêtre approuvée, ou concevoir une migration progressive distincte pour un gros catalogue (colonne ordinaire + maintenance serveur et backfill par lots, index CONCURRENTLY hors transaction, validation puis bascule). Cette seconde option doit réauditer les guards UPDATE et la concurrence ; elle n'est pas équivalente à ajouter simplement CONCURRENTLY dans le fichier BEGIN/COMMIT actuel. Ne pas l'implémenter ou lancer un backfill pendant cet audit.

## P1 de validation — configuration et bundle Edge

**Fait** : pas de config.toml ou deno.json versionné pour la fonction ; verrou v5 testé avec Deno 2.5.6. Les tests du handler ne prouvent pas le démarrage, le packaging ou le respect de la limite CPU sur l'hôte Supabase. Aucun défaut de import.meta.main n'est démontré ; le runtime source courant charge un module principal, version distante inconnue.

Proposer une configuration locale dédiée, puis la vérifier avec la CLI/runtime réellement retenus avant déploiement. Exemples **non créés par cet audit** :

```toml
# supabase/config.toml, a fusionner avec tout fichier deja existant au moment voulu
project_id = "kibo"
[functions.kibo-upload-listing-photo]
verify_jwt = true
entrypoint = "./functions/kibo-upload-listing-photo/index.ts"
```

```json
{
  "lock": "../deno.lock"
}
```

Le JSON serait `supabase/functions/kibo-upload-listing-photo/deno.json`. Confirmer la découverte/compatibilité du verrou dans le bundle, ne pas le contourner. Aucun besoin de rendre la fonction publique ou de mettre une clé serveur dans Flutter. Le test local maximal a passé ~1044 ms de temps mural sur ce poste ; imposer une mesure hébergée représentative et une limite de concurrence adaptée avant ouverture.

## P2 — diagnostics et reprise

Le catch générique du handler convertit aussi les exceptions de transport en 400 ; cela préserve la confidentialité mais réduit le diagnostic. Proposition séparée : garder 400 pour image/JSON invalides, distinguer indisponibilité/réseau avec 502/503 et un identifiant de corrélation sans jeton/image/erreur brute. Tester ces cas avant de modifier le protocole.

Le client conserve le même ID pour reprendre les photos seulement tant que le formulaire vit ; pas de file persistante d'upload. Ne pas présenter le rollback comme un effacement des fichiers ou une nouvelle publication automatique. Une amélioration de reprise durable et un GC contrôlé demanderaient des tâches distinctes, sans élargir les droits directs d'écriture/suppression Storage.
