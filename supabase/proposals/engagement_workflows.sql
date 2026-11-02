-- Préférences des futures notifications et instruction des demandes de compte.
-- Aucun effacement de compte Auth, aucune modification des lignes existantes.
BEGIN;
DO $$ BEGIN
 IF to_regclass('public.kibo_notification_preferences') IS NOT NULL THEN RAISE EXCEPTION 'Engagement already installed'; END IF;
 IF (SELECT md5(prosrc) FROM pg_proc WHERE oid='kibo_safety_private.notify_message()'::regprocedure) <> '650dd0fe9fb48a1b3aad798884c9587e'
 OR (SELECT md5(prosrc) FROM pg_proc WHERE oid='kibo_safety_private.notify_comment()'::regprocedure) <> '13435a4f0508771789fa9c83c0475e72'
 OR (SELECT md5(prosrc) FROM pg_proc WHERE oid='kibo_mvp_private.account_request(boolean)'::regprocedure) <> '51efae1d304717315b5e7123350a85ce' THEN RAISE EXCEPTION 'Function baseline changed'; END IF;
END $$;
CREATE TABLE public.kibo_notification_preferences (
 owner_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
 messages_enabled boolean NOT NULL DEFAULT true, comments_enabled boolean NOT NULL DEFAULT true,
 updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.kibo_notification_preferences ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kibo_notification_preferences FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.kibo_notification_preferences TO authenticated;
CREATE POLICY kibo_preferences_own ON public.kibo_notification_preferences FOR SELECT TO authenticated USING(owner_id=(SELECT auth.uid()));
CREATE FUNCTION kibo_mvp_private.preferences(p_messages boolean,p_comments boolean) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501'; END IF;
 IF (p_messages IS NULL) <> (p_comments IS NULL) THEN RAISE EXCEPTION 'Deux choix requis'; END IF;
 IF p_messages IS NOT NULL THEN
 INSERT INTO public.kibo_notification_preferences(owner_id,messages_enabled,comments_enabled) VALUES(auth.uid(),p_messages,p_comments)
 ON CONFLICT(owner_id) DO UPDATE SET messages_enabled=excluded.messages_enabled,comments_enabled=excluded.comments_enabled,updated_at=now();
 END IF;
 RETURN coalesce((SELECT jsonb_build_object('messages',messages_enabled,'comments',comments_enabled) FROM public.kibo_notification_preferences WHERE owner_id=auth.uid()),'{"messages":true,"comments":true}'::jsonb);
END $$;
CREATE OR REPLACE FUNCTION kibo_safety_private.notify_message() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE recipient uuid;
BEGIN
 SELECT CASE WHEN new.sender_id=c.buyer_id THEN c.seller_id ELSE c.buyer_id END INTO recipient FROM public.conversations c WHERE c.id=new.conversation_id;
 IF recipient IS NOT NULL AND recipient<>new.sender_id AND coalesce((SELECT messages_enabled FROM public.kibo_notification_preferences WHERE owner_id=recipient),true) THEN
 INSERT INTO public.notifications(user_id,notification_type,title,body,data) VALUES(recipient,'new_message','Nouveau message','Vous avez reçu un nouveau message.',jsonb_build_object('conversation_id',new.conversation_id)); END IF;
 RETURN new;
END $$;
CREATE OR REPLACE FUNCTION kibo_safety_private.notify_comment() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE recipient uuid;
BEGIN
 IF new.status<>'published' OR new.deleted_at IS NOT NULL THEN RETURN new; END IF;
 FOR recipient IN SELECT seller_id FROM public.listings WHERE id=new.listing_id UNION SELECT user_id FROM public.listing_comments WHERE id=new.parent_id LOOP
 IF recipient<>new.user_id AND coalesce((SELECT comments_enabled FROM public.kibo_notification_preferences WHERE owner_id=recipient),true) THEN
 INSERT INTO public.notifications(user_id,notification_type,title,body,data) VALUES(recipient,'new_comment','Nouveau commentaire','Une annonce ou une discussion vous concernant a reçu un commentaire.',jsonb_build_object('listing_id',new.listing_id,'parent_id',new.parent_id)); END IF;
 END LOOP; RETURN new;
END $$;
-- Le compteur porte sur toutes les conversations propres, indépendamment des préférences.
CREATE FUNCTION kibo_mvp_private.chat_unread() RETURNS bigint LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT count(*) FROM public.messages m JOIN public.conversations c ON c.id=m.conversation_id
 WHERE auth.uid() IS NOT NULL AND auth.uid() IN(c.buyer_id,c.seller_id) AND m.sender_id<>auth.uid() AND m.read_at IS NULL
$$;
CREATE SEQUENCE kibo_mvp_private.account_request_version;
REVOKE ALL ON SEQUENCE kibo_mvp_private.account_request_version FROM PUBLIC,anon,authenticated;
ALTER TABLE public.kibo_account_requests ADD COLUMN version bigint NOT NULL DEFAULT nextval('kibo_mvp_private.account_request_version'::regclass),
 ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now(), ADD COLUMN operator_note text, ADD COLUMN owner_note text;
ALTER TABLE public.kibo_account_requests DROP CONSTRAINT kibo_account_requests_status_check;
ALTER TABLE public.kibo_account_requests ADD CONSTRAINT kibo_account_requests_status_check CHECK(status IN('pending','processing','completed','needs_info','rejected'));
CREATE TABLE public.kibo_account_request_events (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),owner_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 actor_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL, action text NOT NULL,
 note text,created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.kibo_account_request_events ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kibo_account_request_events FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.kibo_account_request_events TO authenticated;
CREATE POLICY kibo_request_events_read ON public.kibo_account_request_events FOR SELECT TO authenticated USING(owner_id=(SELECT auth.uid()) OR (SELECT private.is_admin()));
CREATE INDEX kibo_request_events_owner_date ON public.kibo_account_request_events(owner_id,created_at DESC,id);
CREATE INDEX kibo_request_events_actor ON public.kibo_account_request_events(actor_id);
CREATE INDEX kibo_requests_status_date ON public.kibo_account_requests(status,requested_at,owner_id);
CREATE OR REPLACE FUNCTION kibo_mvp_private.account_request(p_cancel boolean) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE changed uuid;
BEGIN
 IF auth.uid() IS NULL OR p_cancel IS NULL THEN RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501'; END IF;
 IF p_cancel THEN
 DELETE FROM public.kibo_account_requests WHERE owner_id=auth.uid() AND status IN('pending','needs_info') RETURNING owner_id INTO changed;
 ELSE
 INSERT INTO public.kibo_account_requests(owner_id) VALUES(auth.uid()) ON CONFLICT DO NOTHING RETURNING owner_id INTO changed;
 END IF;
 IF changed IS NOT NULL THEN INSERT INTO public.kibo_account_request_events(owner_id,actor_id,action) VALUES(auth.uid(),auth.uid(),CASE WHEN p_cancel THEN 'cancelled' ELSE 'requested' END); END IF;
END $$;
CREATE FUNCTION kibo_mvp_private.account_tracking() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501'; END IF;
 RETURN jsonb_build_object('request',(SELECT to_jsonb(r) FROM public.kibo_account_requests r WHERE owner_id=auth.uid()),'events',coalesce((SELECT jsonb_agg(x ORDER BY x.created_at DESC,x.id) FROM (SELECT id,action,note,created_at FROM public.kibo_account_request_events WHERE owner_id=auth.uid() ORDER BY created_at DESC,id LIMIT 50) x),'[]'::jsonb));
END $$;
CREATE FUNCTION kibo_mvp_private.account_queue(p_status text,p_offset integer) RETURNS SETOF jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL OR private.is_admin() IS NOT TRUE THEN RAISE EXCEPTION 'Accès administrateur requis' USING ERRCODE='42501'; END IF;
 IF p_status NOT IN('pending','processing','needs_info','rejected','completed') OR p_status IS NULL OR p_offset IS NULL OR p_offset<0 OR p_offset>100000 THEN RAISE EXCEPTION 'Filtre invalide'; END IF;
 RETURN QUERY SELECT to_jsonb(r)||jsonb_build_object('name',coalesce(nullif(trim(p.full_name),''),'Membre KIBO')) FROM public.kibo_account_requests r JOIN public.profiles p ON p.id=r.owner_id WHERE r.status=p_status ORDER BY r.requested_at,r.owner_id LIMIT 20 OFFSET p_offset;
END $$;
CREATE FUNCTION kibo_mvp_private.account_review(p_owner uuid,p_version bigint,p_action text,p_note text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE current_request public.kibo_account_requests;
BEGIN
 IF auth.uid() IS NULL OR private.is_admin() IS NOT TRUE THEN RAISE EXCEPTION 'Accès administrateur requis' USING ERRCODE='42501'; END IF;
 IF p_action NOT IN('processing','needs_info','rejected') OR p_action IS NULL OR p_note IS NULL OR char_length(trim(p_note)) NOT BETWEEN 3 AND 1000 THEN RAISE EXCEPTION 'Décision invalide'; END IF;
 SELECT * INTO current_request FROM public.kibo_account_requests WHERE owner_id=p_owner FOR UPDATE;
 IF NOT FOUND OR p_version IS DISTINCT FROM current_request.version OR current_request.status NOT IN('pending','processing','needs_info') OR current_request.status=p_action THEN RAISE EXCEPTION 'Demande modifiée; actualisez' USING ERRCODE='40001'; END IF;
 UPDATE public.kibo_account_requests SET status=p_action,operator_note=trim(p_note),version=nextval('kibo_mvp_private.account_request_version'::regclass),updated_at=now() WHERE owner_id=p_owner;
 INSERT INTO public.kibo_account_request_events(owner_id,actor_id,action,note) VALUES(p_owner,auth.uid(),p_action,trim(p_note));
 INSERT INTO public.notifications(user_id,notification_type,title,body,data) VALUES(p_owner,'system','Votre demande de compte','Votre demande a été examinée. Consultez son suivi.',jsonb_build_object('account_request',true));
END $$;
CREATE FUNCTION kibo_mvp_private.account_reply(p_version bigint,p_note text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE changed uuid;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501'; END IF;
 IF p_note IS NULL OR char_length(trim(p_note)) NOT BETWEEN 3 AND 1000 THEN RAISE EXCEPTION 'Précisions requises'; END IF;
 UPDATE public.kibo_account_requests SET owner_note=trim(p_note),status='pending',version=nextval('kibo_mvp_private.account_request_version'::regclass),updated_at=now() WHERE owner_id=auth.uid() AND version=p_version AND status='needs_info' RETURNING owner_id INTO changed;
 IF changed IS NULL THEN RAISE EXCEPTION 'Demande modifiée; actualisez' USING ERRCODE='40001'; END IF;
 INSERT INTO public.kibo_account_request_events(owner_id,actor_id,action,note) VALUES(auth.uid(),auth.uid(),'reply',trim(p_note));
END $$;
CREATE FUNCTION public.kibo_notification_preferences(p_messages boolean DEFAULT NULL,p_comments boolean DEFAULT NULL) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_mvp_private.preferences(p_messages,p_comments) $$;
CREATE FUNCTION public.kibo_chat_unread_count() RETURNS bigint LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_mvp_private.chat_unread() $$;
CREATE FUNCTION public.kibo_account_tracking() RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_mvp_private.account_tracking() $$;
CREATE FUNCTION public.kibo_account_queue(p_status text,p_offset integer DEFAULT 0) RETURNS SETOF jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT * FROM kibo_mvp_private.account_queue(p_status,p_offset) $$;
CREATE FUNCTION public.kibo_account_review(p_owner uuid,p_version bigint,p_action text,p_note text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_mvp_private.account_review(p_owner,p_version,p_action,p_note) $$;
CREATE FUNCTION public.kibo_account_reply(p_version bigint,p_note text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_mvp_private.account_reply(p_version,p_note) $$;
REVOKE ALL ON FUNCTION public.kibo_notification_preferences(boolean,boolean),public.kibo_chat_unread_count(),public.kibo_account_tracking(),public.kibo_account_queue(text,integer),public.kibo_account_review(uuid,bigint,text,text),public.kibo_account_reply(bigint,text),kibo_mvp_private.preferences(boolean,boolean),kibo_mvp_private.chat_unread(),kibo_mvp_private.account_tracking(),kibo_mvp_private.account_queue(text,integer),kibo_mvp_private.account_review(uuid,bigint,text,text),kibo_mvp_private.account_reply(bigint,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_notification_preferences(boolean,boolean),public.kibo_chat_unread_count(),public.kibo_account_tracking(),public.kibo_account_queue(text,integer),public.kibo_account_review(uuid,bigint,text,text),public.kibo_account_reply(bigint,text),kibo_mvp_private.preferences(boolean,boolean),kibo_mvp_private.chat_unread(),kibo_mvp_private.account_tracking(),kibo_mvp_private.account_queue(text,integer),kibo_mvp_private.account_review(uuid,bigint,text,text),kibo_mvp_private.account_reply(bigint,text) TO authenticated;
COMMIT;
