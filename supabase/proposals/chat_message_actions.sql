-- Proposition locale uniquement. Appliquer après audit/autorisation explicite.
-- Aucun contenu existant modifié à l'installation ; suppression logique seulement.
BEGIN;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='messages' AND column_name IN('edited_at','deleted_at'))
 OR to_regclass('public.kibo_message_action_log') IS NOT NULL THEN
   RAISE EXCEPTION 'Message actions already installed or baseline changed';
 END IF;
 IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.messages'::regclass)
 OR has_any_column_privilege('authenticated','public.messages','UPDATE')
 OR has_table_privilege('authenticated','public.messages','DELETE') THEN
   RAISE EXCEPTION 'Message RLS or privileges baseline changed';
 END IF;
END $$;
ALTER TABLE public.messages ADD COLUMN edited_at timestamptz, ADD COLUMN deleted_at timestamptz;
ALTER TABLE public.messages ADD CONSTRAINT kibo_deleted_message_content CHECK(deleted_at IS NULL OR (content='Message supprimé' AND message_type='text'));

CREATE TABLE public.kibo_message_action_log(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 actor_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 message_id uuid NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
 action text NOT NULL CHECK(action IN('edit','delete')),
 created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.kibo_message_action_log ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kibo_message_action_log FROM PUBLIC,anon,authenticated;

CREATE FUNCTION kibo_mvp_private.message_actions(p_thread uuid) RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF auth.uid() IS NULL OR NOT EXISTS(SELECT 1 FROM public.conversations WHERE id=p_thread AND auth.uid() IN(buyer_id,seller_id)) THEN
   RAISE EXCEPTION 'Conversation indisponible' USING ERRCODE='42501';
 END IF;
 RETURN true;
END $$;

CREATE FUNCTION kibo_mvp_private.change_message(p_thread uuid,p_message uuid,p_content text,p_delete boolean,p_expected_content text,p_expected_edited_at timestamptz)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE m public.messages%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL OR p_delete IS NULL THEN RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501';END IF;
 PERFORM 1 FROM public.conversations WHERE id=p_thread AND auth.uid() IN(buyer_id,seller_id) FOR UPDATE;
 IF NOT FOUND OR NOT kibo_mvp_private.can_send(p_thread) THEN RAISE EXCEPTION 'Conversation indisponible' USING ERRCODE='42501';END IF;
 SELECT * INTO m FROM public.messages WHERE id=p_message AND conversation_id=p_thread FOR UPDATE;
 IF NOT FOUND OR m.sender_id IS DISTINCT FROM auth.uid() OR m.message_type<>'text' OR m.deleted_at IS NOT NULL THEN
   RAISE EXCEPTION 'Message indisponible' USING ERRCODE='42501';
 END IF;
 IF m.content IS DISTINCT FROM p_expected_content OR m.edited_at IS DISTINCT FROM p_expected_edited_at THEN
   RAISE EXCEPTION 'Message modifié, actualisez' USING ERRCODE='40001';
 END IF;
 IF p_delete THEN
   IF p_content IS NOT NULL THEN RAISE EXCEPTION 'Contenu de suppression invalide' USING ERRCODE='22023';END IF;
   UPDATE public.messages SET content='Message supprimé',deleted_at=clock_timestamp() WHERE id=m.id RETURNING * INTO m;
 ELSE
   IF p_content IS NULL OR char_length(trim(p_content)) NOT BETWEEN 1 AND 5000 THEN RAISE EXCEPTION 'Message invalide' USING ERRCODE='22023';END IF;
   IF trim(p_content)=m.content THEN RETURN to_jsonb(m);END IF;
   UPDATE public.messages SET content=trim(p_content),edited_at=clock_timestamp() WHERE id=m.id RETURNING * INTO m;
 END IF;
 INSERT INTO public.kibo_message_action_log(actor_id,message_id,action) VALUES(auth.uid(),m.id,CASE WHEN p_delete THEN 'delete' ELSE 'edit' END);
 RETURN to_jsonb(m);
END $$;
REVOKE ALL ON FUNCTION kibo_mvp_private.message_actions(uuid),kibo_mvp_private.change_message(uuid,uuid,text,boolean,text,timestamptz) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION kibo_mvp_private.message_actions(uuid),kibo_mvp_private.change_message(uuid,uuid,text,boolean,text,timestamptz) TO authenticated;
CREATE FUNCTION public.kibo_chat_message_actions(p_thread uuid) RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_mvp_private.message_actions(p_thread) $$;
CREATE FUNCTION public.kibo_chat_change_message(p_thread uuid,p_message uuid,p_content text,p_delete boolean,p_expected_content text,p_expected_edited_at timestamptz) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_mvp_private.change_message(p_thread,p_message,p_content,p_delete,p_expected_content,p_expected_edited_at) $$;
REVOKE ALL ON FUNCTION public.kibo_chat_message_actions(uuid),public.kibo_chat_change_message(uuid,uuid,text,boolean,text,timestamptz) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_chat_message_actions(uuid),public.kibo_chat_change_message(uuid,uuid,text,boolean,text,timestamptz) TO authenticated;
COMMIT;
