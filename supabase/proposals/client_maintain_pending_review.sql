-- NON APPLIQUE : accord spécifique requis après refus auto-review de la portée globale.
-- Delta séparé des contrats MVP déjà appliqués ; aucun objet fonctionnel recréé.
-- PostgreSQL 17 uniquement : non exécuté sur la fixture locale PG13.
BEGIN;
DO $$ BEGIN IF current_setting('server_version_num')::integer<170000 THEN RAISE EXCEPTION 'PostgreSQL 17 requis';END IF;END $$;
REVOKE MAINTAIN ON TABLE public.categories,public.reports,public.messages,public.conversations,
 public.notifications,public.listing_images,public.favorites,public.listing_comments,public.listings
 FROM anon,authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE MAINTAIN ON TABLES FROM anon,authenticated;
COMMIT;
