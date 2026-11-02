-- Lots 6-8 : non lus, blocage chat et demande de suppression non destructive.
-- Autorisation autonome utilisateur du 2026-11-01 ; tester avant application.
BEGIN;
DO $$ BEGIN
 IF to_regnamespace('kibo_mvp_private') IS NOT NULL THEN RAISE EXCEPTION 'MVP extension already exists'; END IF;
 IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname IN('messages','conversations','profiles') AND c.relrowsecurity)<>3 THEN RAISE EXCEPTION 'MVP RLS baseline changed';END IF;
END $$;
CREATE SCHEMA kibo_mvp_private;
REVOKE ALL ON SCHEMA kibo_mvp_private FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA kibo_mvp_private TO authenticated;
CREATE TABLE public.kibo_user_blocks(
 owner_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 blocked_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 created_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(owner_id,blocked_id),CHECK(owner_id<>blocked_id)
);
ALTER TABLE public.kibo_user_blocks ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kibo_user_blocks FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.kibo_user_blocks TO authenticated;
CREATE POLICY kibo_blocks_own_read ON public.kibo_user_blocks FOR SELECT TO authenticated USING(owner_id=(SELECT auth.uid()));
CREATE TABLE public.kibo_account_requests(
 owner_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
 requested_at timestamptz NOT NULL DEFAULT now(),status text NOT NULL DEFAULT 'pending' CHECK(status IN('pending','processing','completed'))
);
ALTER TABLE public.kibo_account_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kibo_account_requests FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.kibo_account_requests TO authenticated;
CREATE POLICY kibo_requests_own_read ON public.kibo_account_requests FOR SELECT TO authenticated USING(owner_id=(SELECT auth.uid()));

CREATE FUNCTION kibo_mvp_private.can_contact(p_peer uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT auth.uid() IS NOT NULL AND p_peer<>auth.uid() AND NOT EXISTS(SELECT 1 FROM public.kibo_user_blocks WHERE (owner_id=auth.uid() AND blocked_id=p_peer) OR (owner_id=p_peer AND blocked_id=auth.uid()))
$$;
CREATE FUNCTION kibo_mvp_private.can_send(p_thread uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM public.conversations c WHERE c.id=p_thread AND auth.uid() IN(c.buyer_id,c.seller_id) AND kibo_mvp_private.can_contact(CASE WHEN c.buyer_id=auth.uid() THEN c.seller_id ELSE c.buyer_id END))
$$;
CREATE POLICY kibo_conversations_block_restrict ON public.conversations AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK(kibo_mvp_private.can_contact(seller_id));
CREATE POLICY kibo_messages_block_restrict ON public.messages AS RESTRICTIVE FOR INSERT TO authenticated WITH CHECK(kibo_mvp_private.can_send(conversation_id));
CREATE FUNCTION kibo_mvp_private.set_block(p_thread uuid,p_blocked boolean) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE peer uuid;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501';END IF;
 SELECT CASE WHEN buyer_id=auth.uid() THEN seller_id ELSE buyer_id END INTO peer FROM public.conversations WHERE id=p_thread AND auth.uid() IN(buyer_id,seller_id);
 IF NOT FOUND OR p_blocked IS NULL THEN RAISE EXCEPTION 'Conversation indisponible' USING ERRCODE='42501';END IF;
 IF p_blocked THEN INSERT INTO public.kibo_user_blocks(owner_id,blocked_id) VALUES(auth.uid(),peer) ON CONFLICT DO NOTHING;
 ELSE DELETE FROM public.kibo_user_blocks WHERE owner_id=auth.uid() AND blocked_id=peer;END IF;
END $$;
CREATE FUNCTION kibo_mvp_private.mark_read(p_thread uuid,p_through timestamptz) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.conversations WHERE id=p_thread AND auth.uid() IN(buyer_id,seller_id)) THEN RAISE EXCEPTION 'Conversation indisponible' USING ERRCODE='42501';END IF;
 IF p_through IS NULL THEN RAISE EXCEPTION 'Date requise';END IF;
 UPDATE public.messages SET read_at=now() WHERE conversation_id=p_thread AND sender_id<>auth.uid() AND read_at IS NULL AND created_at<=least(p_through,now());
END $$;
CREATE FUNCTION kibo_mvp_private.summaries(p_offset integer) RETURNS SETOF jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT jsonb_build_object('id',c.id,'listing_id',c.listing_id,'buyer_id',c.buyer_id,'seller_id',c.seller_id,
 'title',CASE WHEN l.status='published' OR l.seller_id=auth.uid() THEN l.title ELSE NULL END,
 'peer_name',coalesce(nullif(trim(p.full_name),''),'Membre KIBO'),'last_content',last_message.content,'last_at',last_message.created_at,
 'unread_count',(SELECT count(*) FROM public.messages m WHERE m.conversation_id=c.id AND m.sender_id<>auth.uid() AND m.read_at IS NULL),
 'blocked',NOT kibo_mvp_private.can_send(c.id),'blocked_by_me',EXISTS(SELECT 1 FROM public.kibo_user_blocks b WHERE b.owner_id=auth.uid() AND b.blocked_id=p.id))
 FROM public.conversations c LEFT JOIN public.listings l ON l.id=c.listing_id
 LEFT JOIN public.profiles p ON p.id=CASE WHEN c.buyer_id=auth.uid() THEN c.seller_id ELSE c.buyer_id END
 LEFT JOIN LATERAL(SELECT m.content,m.created_at FROM public.messages m WHERE m.conversation_id=c.id AND m.message_type='text' ORDER BY m.created_at DESC,m.id DESC LIMIT 1) last_message ON true
 WHERE auth.uid() IS NOT NULL AND auth.uid() IN(c.buyer_id,c.seller_id)
 ORDER BY c.updated_at DESC,c.id LIMIT 20 OFFSET greatest(0,least(coalesce(p_offset,0),100000))
$$;
CREATE FUNCTION kibo_mvp_private.account_request(p_cancel boolean) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL OR p_cancel IS NULL THEN RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501';END IF;
 IF p_cancel THEN DELETE FROM public.kibo_account_requests WHERE owner_id=auth.uid() AND status='pending';
 ELSE INSERT INTO public.kibo_account_requests(owner_id) VALUES(auth.uid()) ON CONFLICT DO NOTHING;END IF;
END $$;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA kibo_mvp_private FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION kibo_mvp_private.can_contact(uuid),kibo_mvp_private.can_send(uuid),kibo_mvp_private.set_block(uuid,boolean),kibo_mvp_private.mark_read(uuid,timestamptz),kibo_mvp_private.summaries(integer),kibo_mvp_private.account_request(boolean) TO authenticated;
CREATE FUNCTION public.kibo_chat_summaries(p_offset integer DEFAULT 0) RETURNS SETOF jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT * FROM kibo_mvp_private.summaries(p_offset) $$;
CREATE FUNCTION public.kibo_chat_mark_read(p_thread uuid,p_through timestamptz) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_mvp_private.mark_read(p_thread,p_through) $$;
CREATE FUNCTION public.kibo_chat_set_block(p_thread uuid,p_blocked boolean) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_mvp_private.set_block(p_thread,p_blocked) $$;
CREATE FUNCTION public.kibo_account_request(p_cancel boolean DEFAULT false) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_mvp_private.account_request(p_cancel) $$;
REVOKE ALL ON FUNCTION public.kibo_chat_summaries(integer),public.kibo_chat_mark_read(uuid,timestamptz),public.kibo_chat_set_block(uuid,boolean),public.kibo_account_request(boolean) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_chat_summaries(integer),public.kibo_chat_mark_read(uuid,timestamptz),public.kibo_chat_set_block(uuid,boolean),public.kibo_account_request(boolean) TO authenticated;
-- Index de support de la lecture des non lus ; aucune ligne métier modifiée.
CREATE INDEX kibo_messages_unread_thread ON public.messages(conversation_id,sender_id) WHERE read_at IS NULL;
COMMIT;
