-- Prepared only: no schedule, no FCM credentials, no outgoing sends.
BEGIN;
CREATE SCHEMA kibo_push_private;
REVOKE ALL ON SCHEMA kibo_push_private FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA kibo_push_private TO authenticated,service_role;
CREATE TABLE kibo_push_private.devices(
 token text PRIMARY KEY CHECK(char_length(token) BETWEEN 20 AND 4096),
 owner_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 updated_at timestamptz NOT NULL DEFAULT now());
CREATE INDEX kibo_push_devices_owner ON kibo_push_private.devices(owner_id);
CREATE TABLE kibo_push_private.outbox(
 id uuid PRIMARY KEY REFERENCES public.notifications(id) ON DELETE CASCADE,
 owner_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 created_at timestamptz NOT NULL DEFAULT now(),attempts integer NOT NULL DEFAULT 0,
 lease uuid,locked_until timestamptz,completed_at timestamptz);
ALTER TABLE kibo_push_private.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE kibo_push_private.outbox ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON ALL TABLES IN SCHEMA kibo_push_private FROM PUBLIC,anon,authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA kibo_push_private TO service_role;
CREATE FUNCTION kibo_push_private.register(p_token text) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF auth.uid() IS NULL OR NOT private.kibo_account_active(auth.uid()) OR p_token IS NULL OR char_length(p_token) NOT BETWEEN 20 AND 4096 THEN
  RAISE EXCEPTION 'Connexion ou appareil invalide' USING ERRCODE='42501';END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('kibo-push-'||auth.uid()::text,0));
 IF (SELECT count(*) FROM kibo_push_private.devices WHERE owner_id=auth.uid() AND token<>p_token)>=5 THEN
  RAISE EXCEPTION 'Limite appareils atteinte';END IF;
 INSERT INTO kibo_push_private.devices(token,owner_id) VALUES(p_token,auth.uid())
 ON CONFLICT(token) DO UPDATE SET owner_id=auth.uid(),updated_at=now();
END $$;
CREATE FUNCTION kibo_push_private.unregister(p_token text) RETURNS void
LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
 DELETE FROM kibo_push_private.devices WHERE owner_id=auth.uid() AND token=p_token
$$;
CREATE FUNCTION public.kibo_push_register(p_token text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path=''
AS $$ SELECT kibo_push_private.register(p_token) $$;
CREATE FUNCTION public.kibo_push_unregister(p_token text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path=''
AS $$ SELECT kibo_push_private.unregister(p_token) $$;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA kibo_push_private FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION kibo_push_private.register(text),kibo_push_private.unregister(text) TO authenticated;
REVOKE ALL ON FUNCTION public.kibo_push_register(text),public.kibo_push_unregister(text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_push_register(text),public.kibo_push_unregister(text) TO authenticated;
CREATE FUNCTION kibo_push_private.enqueue() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF EXISTS(SELECT 1 FROM kibo_push_private.devices WHERE owner_id=NEW.user_id) THEN
  INSERT INTO kibo_push_private.outbox(id,owner_id) VALUES(NEW.id,NEW.user_id) ON CONFLICT DO NOTHING;
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION kibo_push_private.enqueue() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER kibo_push_enqueue AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION kibo_push_private.enqueue();
CREATE FUNCTION public.kibo_push_claim() RETURNS SETOF jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE job kibo_push_private.outbox; current_lease uuid;
BEGIN
 IF current_setting('role',true)<>'service_role' THEN RAISE EXCEPTION 'Service requis' USING ERRCODE='42501';END IF;
 DELETE FROM kibo_push_private.outbox WHERE created_at<now()-interval '7 days';
 FOR job IN SELECT * FROM kibo_push_private.outbox WHERE completed_at IS NULL AND attempts<5 AND created_at>now()-interval '24 hours'
 AND (locked_until IS NULL OR locked_until<now()) ORDER BY created_at,id FOR UPDATE SKIP LOCKED LIMIT 10 LOOP
  current_lease:=gen_random_uuid();
  UPDATE kibo_push_private.outbox SET attempts=attempts+1,lease=current_lease,locked_until=now()+interval '5 minutes' WHERE id=job.id;
  RETURN NEXT jsonb_build_object('id',job.id,'lease',current_lease,'owner',job.owner_id,'tokens',
   (SELECT coalesce(jsonb_agg(token),'[]') FROM kibo_push_private.devices WHERE owner_id=job.owner_id));
 END LOOP;
END $$;
CREATE FUNCTION public.kibo_push_ack(p_id uuid,p_lease uuid,p_ok boolean,p_invalid text[] DEFAULT '{}') RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE owner uuid; BEGIN
 IF current_setting('role',true)<>'service_role' THEN RAISE EXCEPTION 'Service requis' USING ERRCODE='42501';END IF;
 SELECT owner_id INTO owner FROM kibo_push_private.outbox WHERE id=p_id AND lease=p_lease AND locked_until>now() FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Lease expire';END IF;
 DELETE FROM kibo_push_private.devices WHERE owner_id=owner AND token=ANY(p_invalid);
 UPDATE kibo_push_private.outbox SET completed_at=CASE WHEN p_ok THEN now() END,
 locked_until=CASE WHEN p_ok THEN NULL ELSE now()+interval '5 minutes' END WHERE id=p_id;
END $$;
REVOKE ALL ON FUNCTION public.kibo_push_claim(),public.kibo_push_ack(uuid,uuid,boolean,text[]) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_push_claim(),public.kibo_push_ack(uuid,uuid,boolean,text[]) TO service_role;
CREATE INDEX kibo_push_pending ON kibo_push_private.outbox(created_at,id) WHERE completed_at IS NULL;
COMMIT;
