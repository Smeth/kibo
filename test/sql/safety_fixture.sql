-- Base locale jetable : guards annonces réels, contrat chat, puis socle audité ci-dessous.
CREATE TYPE public.comment_status AS ENUM('published','hidden');
CREATE TYPE public.notification_type AS ENUM('new_message','new_comment','listing_published','listing_rejected','system');
CREATE TYPE public.report_status AS ENUM('pending','reviewed','resolved','dismissed');
CREATE TABLE public.listing_comments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), listing_id uuid NOT NULL REFERENCES public.listings,
 user_id uuid NOT NULL REFERENCES public.profiles, parent_id uuid REFERENCES public.listing_comments,
 content text NOT NULL, status public.comment_status NOT NULL DEFAULT 'published',
 created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now(),deleted_at timestamptz
);
ALTER TABLE public.listing_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY comments_read ON public.listing_comments FOR SELECT TO anon,authenticated USING(status='published' OR private.is_admin());
CREATE POLICY comments_insert ON public.listing_comments FOR INSERT TO authenticated WITH CHECK(user_id=auth.uid() AND status='published');
GRANT SELECT,INSERT ON public.listing_comments TO anon,authenticated;
CREATE FUNCTION private.guard_comment_update() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
BEGIN
 IF NOT private.is_admin() AND (new.user_id IS DISTINCT FROM old.user_id OR new.listing_id IS DISTINCT FROM old.listing_id OR new.parent_id IS DISTINCT FROM old.parent_id OR new.status IS DISTINCT FROM old.status OR new.deleted_at IS DISTINCT FROM old.deleted_at) THEN RAISE EXCEPTION 'Modification protegee';END IF;
 RETURN new;
END $$;
CREATE TRIGGER comments_guard BEFORE UPDATE ON public.listing_comments FOR EACH ROW EXECUTE FUNCTION private.guard_comment_update();
CREATE TABLE public.notifications (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
 notification_type public.notification_type NOT NULL,title text NOT NULL,body text NOT NULL,data jsonb NOT NULL DEFAULT '{}',read_at timestamptz,created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY notifications_read_own ON public.notifications FOR SELECT TO authenticated USING(user_id=auth.uid());
CREATE TABLE public.reports (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),reporter_id uuid NOT NULL REFERENCES public.profiles ON DELETE RESTRICT,
 listing_id uuid REFERENCES public.listings ON DELETE SET NULL,comment_id uuid REFERENCES public.listing_comments ON DELETE SET NULL,
 reported_user_id uuid REFERENCES public.profiles ON DELETE SET NULL,reason text NOT NULL CHECK(char_length(trim(reason)) BETWEEN 3 AND 120),details text,
 status public.report_status NOT NULL DEFAULT 'pending',created_at timestamptz NOT NULL DEFAULT now(),CHECK(listing_id IS NOT NULL OR comment_id IS NOT NULL OR reported_user_id IS NOT NULL)
);
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY reports_insert_own ON public.reports FOR INSERT TO authenticated WITH CHECK(reporter_id=auth.uid() AND status='pending');
CREATE POLICY reports_read_own_admin ON public.reports FOR SELECT TO authenticated USING(reporter_id=auth.uid() OR private.is_admin());
CREATE POLICY reports_update_admin ON public.reports FOR UPDATE TO authenticated USING(private.is_admin()) WITH CHECK(private.is_admin());
GRANT SELECT,INSERT,UPDATE,DELETE ON public.notifications,public.reports TO anon,authenticated;
