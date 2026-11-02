-- Local proposal: official identity and participant-scoped abuse reports.
BEGIN;
SET LOCAL lock_timeout='5s';
ALTER TABLE public.reports ADD COLUMN message_id uuid REFERENCES public.messages(id) ON DELETE CASCADE;
ALTER TABLE public.reports DROP CONSTRAINT reports_check;
ALTER TABLE public.reports ADD CONSTRAINT reports_check CHECK(num_nonnulls(listing_id,reported_user_id,comment_id,message_id)>=1);
ALTER TABLE public.kibo_moderation_log DROP CONSTRAINT kibo_moderation_log_target_type_check;
ALTER TABLE public.kibo_moderation_log ADD CONSTRAINT kibo_moderation_log_target_type_check CHECK(target_type IN('listing','comment','message','profile'));
CREATE INDEX kibo_reports_message ON public.reports(message_id) WHERE message_id IS NOT NULL;
CREATE INDEX kibo_reports_rate ON public.reports(reporter_id,created_at DESC);
CREATE OR REPLACE FUNCTION kibo_safety_private.validate_report()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
 IF current_setting('role',true) <> 'authenticated' THEN RETURN new; END IF;
 IF auth.uid() IS NULL OR new.reporter_id<>auth.uid()
    OR num_nonnulls(new.listing_id,new.comment_id,new.reported_user_id,new.message_id)<>1 OR new.status<>'pending'
    OR char_length(trim(new.reason)) NOT BETWEEN 3 AND 120 OR char_length(coalesce(new.details,''))>2000 THEN
   RAISE EXCEPTION 'Signalement invalide' USING ERRCODE='22023';
 END IF;
 IF new.listing_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.listings WHERE id=new.listing_id AND status='published') THEN RAISE EXCEPTION 'Contenu indisponible'; END IF;
 IF new.comment_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.listing_comments c JOIN public.listings l ON l.id=c.listing_id WHERE c.id=new.comment_id AND c.status='published' AND c.deleted_at IS NULL AND l.status='published') THEN RAISE EXCEPTION 'Contenu indisponible'; END IF;
 IF new.reported_user_id IS NOT NULL AND (new.reported_user_id=auth.uid() OR NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=new.reported_user_id)) THEN RAISE EXCEPTION 'Profil indisponible'; END IF;
 IF new.message_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.messages m JOIN public.conversations c ON c.id=m.conversation_id
   WHERE m.id=new.message_id AND m.sender_id<>auth.uid() AND m.deleted_at IS NULL AND auth.uid() IN(c.buyer_id,c.seller_id)) THEN RAISE EXCEPTION 'Message indisponible';END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('kibo-report-rate-'||new.reporter_id::text,0));
 IF (SELECT count(*) FROM public.reports WHERE reporter_id=new.reporter_id AND created_at>now()-interval '1 hour')>=10 THEN RAISE EXCEPTION 'Trop de signalements, reessayez plus tard';END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended(new.reporter_id::text||coalesce(new.listing_id,new.comment_id,new.reported_user_id,new.message_id)::text,0));
 IF EXISTS(SELECT 1 FROM public.reports r WHERE r.reporter_id=new.reporter_id AND r.status IN('pending','reviewed') AND (r.listing_id=new.listing_id OR r.comment_id=new.comment_id OR r.reported_user_id=new.reported_user_id OR r.message_id=new.message_id)) THEN RAISE EXCEPTION 'Signalement deja en cours' USING ERRCODE='23505'; END IF;
 new.reason=trim(new.reason); new.details=nullif(trim(new.details),''); RETURN new;
END $function$;

CREATE OR REPLACE FUNCTION kibo_safety_private.report_content(p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE r public.reports%ROWTYPE; result jsonb;
BEGIN
 IF auth.uid() IS NULL OR NOT private.is_admin() THEN RAISE EXCEPTION 'Acces administrateur requis' USING ERRCODE='42501'; END IF;
 SELECT * INTO r FROM public.reports WHERE id=p_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Signalement indisponible'; END IF;
 IF r.message_id IS NOT NULL THEN
  SELECT jsonb_build_object('title','Message signale','content',content,'status',CASE WHEN deleted_at IS NULL THEN 'visible' ELSE 'supprime' END) INTO result FROM public.messages WHERE id=r.message_id;
 ELSIF r.reported_user_id IS NOT NULL THEN
  SELECT jsonb_build_object('title','Profil signale','content',coalesce(full_name,'Membre KIBO')||' - '||city,'status','profil') INTO result FROM public.profiles WHERE id=r.reported_user_id;
 ELSIF r.comment_id IS NOT NULL THEN
   SELECT jsonb_build_object('title','Commentaire signalé','content',content,'status',status) INTO result FROM public.listing_comments WHERE id=r.comment_id;
 ELSE
   SELECT jsonb_build_object('title',title,'content',description,'status',status) INTO result FROM public.listings WHERE id=r.listing_id;
 END IF;
 RETURN result;
END $function$;

CREATE OR REPLACE FUNCTION kibo_safety_private.review_report(p_id uuid, p_action text, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE r public.reports%ROWTYPE; target_type_value text; target uuid; author uuid;
BEGIN
 IF auth.uid() IS NULL OR NOT private.is_admin() THEN RAISE EXCEPTION 'Acces administrateur requis' USING ERRCODE='42501'; END IF;
 IF p_action NOT IN('dismiss','resolve','hide') OR p_action IS NULL OR p_reason IS NULL OR char_length(trim(p_reason)) NOT BETWEEN 3 AND 1000 THEN RAISE EXCEPTION 'Decision invalide' USING ERRCODE='22023'; END IF;
 SELECT * INTO r FROM public.reports WHERE id=p_id FOR UPDATE;
 IF NOT FOUND OR r.status NOT IN('pending','reviewed') THEN RAISE EXCEPTION 'Signalement deja traite ou indisponible'; END IF;
 IF r.message_id IS NOT NULL OR r.reported_user_id IS NOT NULL THEN
  IF p_action='hide' THEN RAISE EXCEPTION 'Masquage non applicable : cloturez avec motif et contactez le support';END IF;
  target_type_value=CASE WHEN r.message_id IS NOT NULL THEN 'message' ELSE 'profile' END;
  target=coalesce(r.message_id,r.reported_user_id);
  UPDATE public.reports SET status=CASE WHEN p_action='dismiss' THEN 'dismissed'::public.report_status ELSE 'resolved'::public.report_status END WHERE id=r.id;
  INSERT INTO public.kibo_moderation_log(report_id,moderator_id,target_type,target_id,action,reason) VALUES(r.id,auth.uid(),target_type_value,target,p_action,trim(p_reason));
  INSERT INTO public.notifications(user_id,notification_type,title,body,data) VALUES(r.reporter_id,'system','Signalement traite','Votre signalement a ete examine. Motif : '||trim(p_reason),jsonb_build_object('report_id',r.id));
  RETURN;
 END IF;
 IF num_nonnulls(r.listing_id,r.comment_id)<>1 THEN RAISE EXCEPTION 'Type de signalement non pris en charge'; END IF;
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
END $function$;

CREATE FUNCTION kibo_safety_private.report_target(p_kind text,p_target uuid,p_reason text,p_details text DEFAULT '') RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result uuid;
BEGIN
 IF auth.uid() IS NULL OR p_kind NOT IN('profile','message') OR p_kind IS NULL OR p_target IS NULL OR
  p_reason NOT IN('Arnaque présumée','Contenu interdit','Harcèlement ou propos offensants','Annonce trompeuse','Autre motif') OR p_reason IS NULL
 THEN RAISE EXCEPTION 'Signalement invalide' USING ERRCODE='42501';END IF;
 INSERT INTO public.reports(reporter_id,reported_user_id,message_id,reason,details)
 VALUES(auth.uid(),CASE WHEN p_kind='profile' THEN p_target END,CASE WHEN p_kind='message' THEN p_target END,p_reason,nullif(trim(p_details),''))
 RETURNING id INTO result;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION kibo_safety_private.report_target(text,uuid,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION kibo_safety_private.report_target(text,uuid,text,text) TO authenticated;
CREATE FUNCTION public.kibo_report_target(p_kind text,p_target uuid,p_reason text,p_details text DEFAULT '') RETURNS uuid
LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_safety_private.report_target(p_kind,p_target,p_reason,p_details) $$;
REVOKE ALL ON FUNCTION public.kibo_report_target(text,uuid,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_report_target(text,uuid,text,text) TO authenticated;
CREATE TABLE public.kibo_official_accounts(
 user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
 assigned_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.kibo_official_accounts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kibo_official_accounts FROM PUBLIC,anon,authenticated;
GRANT ALL ON public.kibo_official_accounts TO service_role;
CREATE FUNCTION kibo_safety_private.is_official(p_user uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM public.kibo_official_accounts WHERE user_id=p_user)
$$;
GRANT USAGE ON SCHEMA kibo_safety_private TO anon;
REVOKE ALL ON FUNCTION kibo_safety_private.is_official(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION kibo_safety_private.is_official(uuid) TO anon,authenticated;
CREATE FUNCTION public.kibo_is_official(p_user uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path=''
AS $$ SELECT kibo_safety_private.is_official(p_user) $$;
REVOKE ALL ON FUNCTION public.kibo_is_official(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_is_official(uuid) TO anon,authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
