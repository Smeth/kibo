-- Proposition ciblée : notifications, signalements et modération tracée.
-- Appliquer uniquement après validation locale et autorisation explicite.
BEGIN;
DO $$ BEGIN
 IF to_regclass('public.kibo_moderation_log') IS NOT NULL OR to_regnamespace('kibo_safety_private') IS NOT NULL THEN RAISE EXCEPTION 'Safety contract already exists'; END IF;
 IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname IN('notifications','reports','listings','listing_comments','messages') AND c.relrowsecurity) <> 5 THEN RAISE EXCEPTION 'Safety RLS baseline changed'; END IF;
END $$;
CREATE SCHEMA kibo_safety_private;
REVOKE ALL ON SCHEMA kibo_safety_private FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA kibo_safety_private TO authenticated;
CREATE TABLE public.kibo_moderation_log (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), report_id uuid NOT NULL,
 moderator_id uuid NOT NULL, target_type text NOT NULL CHECK(target_type IN('listing','comment')),
 target_id uuid NOT NULL, action text NOT NULL CHECK(action IN('dismiss','resolve','hide')),
 reason text NOT NULL CHECK(char_length(trim(reason)) BETWEEN 3 AND 1000),
 created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.kibo_moderation_log ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kibo_moderation_log FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.kibo_moderation_log TO authenticated;
CREATE POLICY kibo_log_admin_read ON public.kibo_moderation_log FOR SELECT TO authenticated USING((SELECT private.is_admin()));
CREATE INDEX kibo_log_report_date ON public.kibo_moderation_log(report_id,created_at DESC,id);

-- Limiter les INSERT clients ; le statut et les dates restent serveur.
REVOKE INSERT,UPDATE ON public.reports FROM anon,authenticated;
GRANT INSERT(reporter_id,listing_id,comment_id,reason,details) ON public.reports TO authenticated;
CREATE FUNCTION kibo_safety_private.validate_report() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF current_setting('role',true) <> 'authenticated' THEN RETURN new; END IF;
 IF auth.uid() IS NULL OR new.reporter_id<>auth.uid() OR new.reported_user_id IS NOT NULL
    OR num_nonnulls(new.listing_id,new.comment_id)<>1 OR new.status<>'pending'
    OR char_length(trim(new.reason)) NOT BETWEEN 3 AND 120 OR char_length(coalesce(new.details,''))>2000 THEN
   RAISE EXCEPTION 'Signalement invalide' USING ERRCODE='22023';
 END IF;
 IF new.listing_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.listings WHERE id=new.listing_id AND status='published') THEN RAISE EXCEPTION 'Contenu indisponible'; END IF;
 IF new.comment_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.listing_comments c JOIN public.listings l ON l.id=c.listing_id WHERE c.id=new.comment_id AND c.status='published' AND c.deleted_at IS NULL AND l.status='published') THEN RAISE EXCEPTION 'Contenu indisponible'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(new.reporter_id::text||coalesce(new.listing_id,new.comment_id)::text,0));
 IF EXISTS(SELECT 1 FROM public.reports r WHERE r.reporter_id=new.reporter_id AND r.status IN('pending','reviewed') AND (r.listing_id=new.listing_id OR r.comment_id=new.comment_id)) THEN RAISE EXCEPTION 'Signalement deja en cours' USING ERRCODE='23505'; END IF;
 new.reason=trim(new.reason); new.details=nullif(trim(new.details),''); RETURN new;
END $$;
CREATE TRIGGER kibo_reports_validate BEFORE INSERT ON public.reports FOR EACH ROW EXECUTE FUNCTION kibo_safety_private.validate_report();

CREATE FUNCTION kibo_safety_private.can_moderate() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$ SELECT auth.uid() IS NOT NULL AND private.is_admin() $$;
CREATE FUNCTION kibo_safety_private.report_content(p_id uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.reports%ROWTYPE; result jsonb;
BEGIN
 IF auth.uid() IS NULL OR NOT private.is_admin() THEN RAISE EXCEPTION 'Acces administrateur requis' USING ERRCODE='42501'; END IF;
 SELECT * INTO r FROM public.reports WHERE id=p_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Signalement indisponible'; END IF;
 IF r.comment_id IS NOT NULL THEN
   SELECT jsonb_build_object('title','Commentaire signalé','content',content,'status',status) INTO result FROM public.listing_comments WHERE id=r.comment_id;
 ELSE
   SELECT jsonb_build_object('title',title,'content',description,'status',status) INTO result FROM public.listings WHERE id=r.listing_id;
 END IF;
 RETURN result;
END $$;
CREATE FUNCTION kibo_safety_private.mark_read(p_id uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501'; END IF;
 UPDATE public.notifications SET read_at=coalesce(read_at,now()) WHERE id=p_id AND user_id=auth.uid();
 IF NOT FOUND THEN RAISE EXCEPTION 'Notification indisponible' USING ERRCODE='42501'; END IF;
END $$;
CREATE FUNCTION kibo_safety_private.review_report(p_id uuid,p_action text,p_reason text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.reports%ROWTYPE; target_type_value text; target uuid; author uuid;
BEGIN
 IF auth.uid() IS NULL OR NOT private.is_admin() THEN RAISE EXCEPTION 'Acces administrateur requis' USING ERRCODE='42501'; END IF;
 IF p_action NOT IN('dismiss','resolve','hide') OR p_action IS NULL OR p_reason IS NULL OR char_length(trim(p_reason)) NOT BETWEEN 3 AND 1000 THEN RAISE EXCEPTION 'Decision invalide' USING ERRCODE='22023'; END IF;
 SELECT * INTO r FROM public.reports WHERE id=p_id FOR UPDATE;
 IF NOT FOUND OR r.status NOT IN('pending','reviewed') THEN RAISE EXCEPTION 'Signalement deja traite ou indisponible'; END IF;
 IF r.reported_user_id IS NOT NULL OR num_nonnulls(r.listing_id,r.comment_id)<>1 THEN RAISE EXCEPTION 'Type de signalement non pris en charge'; END IF;
 target_type_value=CASE WHEN r.listing_id IS NOT NULL THEN 'listing' ELSE 'comment' END;
 target=coalesce(r.listing_id,r.comment_id);
 IF p_action='hide' THEN
   IF r.listing_id IS NOT NULL THEN
     UPDATE public.listings SET status='rejected',rejection_reason=trim(p_reason) WHERE id=target AND status='published' RETURNING seller_id INTO author;
   ELSE
     UPDATE public.listing_comments SET status='hidden' WHERE id=target AND status='published' AND deleted_at IS NULL RETURNING user_id INTO author;
   END IF;
   IF NOT FOUND THEN RAISE EXCEPTION 'Contenu deja masque ou indisponible'; END IF;
 END IF;
 UPDATE public.reports SET status=CASE WHEN p_action='dismiss' THEN 'dismissed'::public.report_status ELSE 'resolved'::public.report_status END WHERE id=r.id;
 INSERT INTO public.kibo_moderation_log(report_id,moderator_id,target_type,target_id,action,reason) VALUES(r.id,auth.uid(),target_type_value,target,p_action,trim(p_reason));
 INSERT INTO public.notifications(user_id,notification_type,title,body,data) VALUES(r.reporter_id,'system','Signalement traité','Votre signalement a été examiné.',jsonb_build_object('report_id',r.id));
 IF author IS NOT NULL THEN
   INSERT INTO public.notifications(user_id,notification_type,title,body,data) VALUES(author,'system','Contenu masqué','Un contenu a été masqué après modération. Motif : '||trim(p_reason),jsonb_build_object('report_id',r.id));
 END IF;
END $$;

CREATE FUNCTION kibo_safety_private.notify_message() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE recipient uuid;
BEGIN
 SELECT CASE WHEN new.sender_id=c.buyer_id THEN c.seller_id ELSE c.buyer_id END INTO recipient FROM public.conversations c WHERE c.id=new.conversation_id;
 IF recipient IS NOT NULL AND recipient<>new.sender_id THEN
 INSERT INTO public.notifications(user_id,notification_type,title,body,data) VALUES(recipient,'new_message','Nouveau message','Vous avez reçu un nouveau message.',jsonb_build_object('conversation_id',new.conversation_id)); END IF;
 RETURN new;
END $$;
CREATE FUNCTION kibo_safety_private.notify_comment() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE recipient uuid;
BEGIN
 IF new.status<>'published' OR new.deleted_at IS NOT NULL THEN RETURN new; END IF;
 FOR recipient IN SELECT seller_id FROM public.listings WHERE id=new.listing_id UNION SELECT user_id FROM public.listing_comments WHERE id=new.parent_id LOOP
 IF recipient<>new.user_id THEN INSERT INTO public.notifications(user_id,notification_type,title,body,data) VALUES(recipient,'new_comment','Nouveau commentaire','Une annonce ou une discussion vous concernant a reçu un commentaire.',jsonb_build_object('listing_id',new.listing_id,'parent_id',new.parent_id)); END IF;
 END LOOP; RETURN new;
END $$;
CREATE TRIGGER kibo_notify_message AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION kibo_safety_private.notify_message();
CREATE TRIGGER kibo_notify_comment AFTER INSERT ON public.listing_comments FOR EACH ROW EXECUTE FUNCTION kibo_safety_private.notify_comment();

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA kibo_safety_private FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION kibo_safety_private.can_moderate(),kibo_safety_private.report_content(uuid),kibo_safety_private.mark_read(uuid),kibo_safety_private.review_report(uuid,text,text) TO authenticated;
CREATE FUNCTION public.kibo_report_content(p_id uuid) RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_safety_private.report_content(p_id) $$;
CREATE FUNCTION public.kibo_can_moderate() RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_safety_private.can_moderate() $$;
CREATE FUNCTION public.kibo_mark_notification_read(p_id uuid) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_safety_private.mark_read(p_id) $$;
CREATE FUNCTION public.kibo_review_report(p_id uuid,p_action text,p_reason text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_safety_private.review_report(p_id,p_action,p_reason) $$;
REVOKE ALL ON FUNCTION public.kibo_report_content(uuid),public.kibo_can_moderate(),public.kibo_mark_notification_read(uuid),public.kibo_review_report(uuid,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_report_content(uuid),public.kibo_can_moderate(),public.kibo_mark_notification_read(uuid),public.kibo_review_report(uuid,text,text) TO authenticated;
COMMIT;
