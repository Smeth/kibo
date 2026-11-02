-- NON APPLIQUE : auto-review a refuse le volet MAINTAIN global. Ne pas rejouer.
-- Les protections chat ont ete appliquees via mvp_chat_hardening.sql.
-- Le seul delta encore propose est client_maintain_pending_review.sql, sur accord specifique.
-- Durcissement additif lots 6-8. Aucune suppression de donnée.
BEGIN;
CREATE FUNCTION kibo_mvp_private.thread_state(p_thread uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE peer uuid;
BEGIN
 SELECT CASE WHEN buyer_id=auth.uid() THEN seller_id ELSE buyer_id END INTO peer FROM public.conversations WHERE id=p_thread AND auth.uid() IN(buyer_id,seller_id);
 IF auth.uid() IS NULL OR NOT FOUND THEN RAISE EXCEPTION 'Conversation indisponible' USING ERRCODE='42501';END IF;
 RETURN jsonb_build_object('blocked',NOT kibo_mvp_private.can_send(p_thread),'blocked_by_me',EXISTS(SELECT 1 FROM public.kibo_user_blocks WHERE owner_id=auth.uid() AND blocked_id=peer));
END $$;
REVOKE ALL ON FUNCTION kibo_mvp_private.thread_state(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION kibo_mvp_private.thread_state(uuid) TO authenticated;
CREATE FUNCTION public.kibo_chat_thread_state(p_thread uuid) RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_mvp_private.thread_state(p_thread) $$;
REVOKE ALL ON FUNCTION public.kibo_chat_thread_state(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_chat_thread_state(uuid) TO authenticated;

-- Dates/accusés contrôlés par le serveur ; conserver les colonnes utiles au contrat.
REVOKE INSERT,UPDATE,DELETE ON public.messages,public.conversations FROM anon,authenticated;
GRANT INSERT(id,conversation_id,sender_id,content,message_type,attachment_path) ON public.messages TO authenticated;
GRANT INSERT(id,listing_id,buyer_id,seller_id) ON public.conversations TO authenticated;
CREATE INDEX kibo_messages_sender_recent ON public.messages(sender_id,created_at DESC);
CREATE INDEX kibo_reports_reporter_recent ON public.reports(reporter_id,created_at DESC);
CREATE FUNCTION kibo_mvp_private.limit_inserts() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE recent integer;
BEGIN
 IF current_setting('role',true)<>'authenticated' THEN RETURN new;END IF;
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501';END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('kibo-rate-'||TG_TABLE_NAME||auth.uid()::text,0));
 IF TG_TABLE_NAME='messages' THEN
   IF new.sender_id<>auth.uid() THEN RAISE EXCEPTION 'Expediteur invalide' USING ERRCODE='42501';END IF;
   -- Un retry du même ID doit atteindre la contrainte unique, sans nouvel événement.
   IF EXISTS(SELECT 1 FROM public.messages WHERE id=new.id AND sender_id=auth.uid()) THEN RETURN new;END IF;
   SELECT count(*) INTO recent FROM public.messages WHERE sender_id=auth.uid() AND created_at>now()-interval '1 minute';
   IF recent>=30 THEN RAISE EXCEPTION 'Trop de messages, patientez' USING ERRCODE='P0001';END IF;
   new.created_at=now();new.read_at=NULL;
 ELSE
   SELECT count(*) INTO recent FROM public.reports WHERE reporter_id=auth.uid() AND created_at>now()-interval '1 minute';
   IF recent>=5 THEN RAISE EXCEPTION 'Trop de signalements, patientez' USING ERRCODE='P0001';END IF;
   new.created_at=now();
 END IF;
 RETURN new;
END $$;
REVOKE ALL ON FUNCTION kibo_mvp_private.limit_inserts() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER kibo_messages_rate BEFORE INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION kibo_mvp_private.limit_inserts();
CREATE TRIGGER kibo_reports_rate BEFORE INSERT ON public.reports FOR EACH ROW EXECUTE FUNCTION kibo_mvp_private.limit_inserts();

-- MAINTAIN n'existe qu'à partir de PG17. Tests PG13 : branche ignorée et annoncée.
DO $$ DECLARE item record;BEGIN
 IF current_setting('server_version_num')::integer>=170000 THEN
  FOR item IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relkind='r' LOOP
   EXECUTE format('REVOKE MAINTAIN ON TABLE public.%I FROM anon,authenticated',item.relname);
  END LOOP;
  EXECUTE 'ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public REVOKE MAINTAIN ON TABLES FROM anon,authenticated';
 ELSE RAISE NOTICE 'MAINTAIN unavailable on this fixture server; remote PG17 verification required';END IF;
END $$;
COMMIT;
