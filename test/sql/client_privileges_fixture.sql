-- Fixture locale seulement : tables vides pour les surfaces hors annonces.
CREATE TABLE public.notifications(id integer);
CREATE TABLE public.listing_images(id integer);
CREATE TABLE public.conversations(id integer);
CREATE TABLE public.messages(id integer);
CREATE TABLE public.listing_comments(id integer);
CREATE TABLE public.reports(id integer);
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listing_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listing_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;
GRANT ALL ON public.categories, public.notifications, public.listing_images, public.favorites, public.conversations, public.messages, public.listing_comments, public.reports, public.listings TO anon,authenticated,service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon,authenticated,service_role;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon,authenticated,service_role;
CREATE TABLE private.fixture_privilege_preserve AS
 SELECT c.oid AS relation,a.* FROM pg_class c CROSS JOIN LATERAL aclexplode(c.relacl) a
 WHERE c.oid IN ('public.categories'::regclass,'public.notifications'::regclass,'public.listing_images'::regclass,'public.favorites'::regclass,'public.conversations'::regclass,'public.messages'::regclass,'public.listing_comments'::regclass,'public.reports'::regclass,'public.listings'::regclass)
 AND NOT (a.grantee IN ('anon'::regrole,'authenticated'::regrole)
  AND a.privilege_type IN ('TRUNCATE','REFERENCES','TRIGGER'));
