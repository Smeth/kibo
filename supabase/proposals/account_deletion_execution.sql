-- Depends on listing_media_management.sql + retained_history.sql.
-- Deploying this contract never executes a deletion.
BEGIN;
CREATE TABLE kibo_lifecycle_private.jobs(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),subject uuid NOT NULL UNIQUE,actor uuid NOT NULL,
 request_version bigint NOT NULL,phase text NOT NULL DEFAULT 'frozen' CHECK(phase IN('frozen','purged','completed')),
 created_at timestamptz NOT NULL DEFAULT now(),requested_at timestamptz NOT NULL,completed_at timestamptz);
CREATE TABLE kibo_lifecycle_private.objects(
 job_id uuid REFERENCES kibo_lifecycle_private.jobs ON DELETE CASCADE,bucket text,path text,
 PRIMARY KEY(job_id,bucket,path));
ALTER TABLE kibo_lifecycle_private.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE kibo_lifecycle_private.objects ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON ALL TABLES IN SCHEMA kibo_lifecycle_private FROM PUBLIC,anon,authenticated;

-- Stop old JWTs even when calling SECURITY DEFINER REST RPCs.
CREATE FUNCTION public.kibo_request_guard() RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT private.kibo_account_active(auth.uid()) THEN RAISE EXCEPTION 'Compte supprime ou suppression en cours' USING ERRCODE='42501';END IF;
END $$;
REVOKE ALL ON FUNCTION public.kibo_request_guard() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.kibo_request_guard() TO anon,authenticated,service_role;
DO $$ DECLARE existing text; r record; BEGIN
 SELECT split_part(setting,'=',2) INTO existing FROM pg_roles CROSS JOIN LATERAL unnest(rolconfig) setting
 WHERE rolname='authenticator' AND setting LIKE 'pgrst.db_pre_request=%';
 IF EXISTS(SELECT 1 FROM pg_db_role_setting d CROSS JOIN LATERAL unnest(d.setconfig) s
  WHERE d.setrole IN(0,(SELECT oid FROM pg_roles WHERE rolname='authenticator'))
  AND d.setdatabase IN(0,(SELECT oid FROM pg_database WHERE datname=current_database()))
  AND s LIKE 'pgrst.db_pre_request=%' AND s<>'pgrst.db_pre_request=public.kibo_request_guard') THEN
  RAISE EXCEPTION 'Database pre-request guard must be preserved';END IF;
 IF existing IS NOT NULL AND existing<>'public.kibo_request_guard' THEN RAISE EXCEPTION 'Existing pre-request guard must be preserved';END IF;
 IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname='authenticator') THEN
  ALTER ROLE authenticator SET pgrst.db_pre_request='public.kibo_request_guard';
 END IF;
 FOR r IN SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='public' AND c.relkind='r' LOOP
  IF NOT EXISTS(SELECT 1 FROM pg_class WHERE oid=format('public.%I',r.relname)::regclass AND relrowsecurity) THEN
   RAISE EXCEPTION 'RLS missing on %',r.relname;END IF;
  EXECUTE format('CREATE POLICY kibo_active_account ON public.%I AS RESTRICTIVE FOR ALL TO authenticated USING(private.kibo_account_active(auth.uid())) WITH CHECK(private.kibo_account_active(auth.uid()))',r.relname);
 END LOOP;
END $$;
CREATE POLICY kibo_active_seller ON public.listings AS RESTRICTIVE FOR SELECT TO anon,authenticated USING(private.kibo_account_active(seller_id));
CREATE POLICY kibo_active_profile ON public.profiles AS RESTRICTIVE FOR SELECT TO anon,authenticated USING(private.kibo_account_active(id));
CREATE OR REPLACE FUNCTION kibo_mvp_private.can_contact(p_peer uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT auth.uid() IS NOT NULL AND p_peer<>auth.uid()
 AND private.kibo_account_active(auth.uid()) AND private.kibo_account_active(p_peer)
 AND NOT EXISTS(SELECT 1 FROM public.kibo_user_blocks WHERE (owner_id=auth.uid() AND blocked_id=p_peer) OR (owner_id=p_peer AND blocked_id=auth.uid()))
$$;
CREATE POLICY kibo_active_comment_context ON public.listing_comments AS RESTRICTIVE FOR INSERT TO authenticated
 WITH CHECK(EXISTS(SELECT 1 FROM public.listings l WHERE l.id=listing_id AND private.kibo_account_active(l.seller_id)));
-- Serialize writes with freezing, including writes that started before the freeze.
CREATE FUNCTION private.kibo_exchange_write_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE owners uuid[];o uuid;
BEGIN
 IF TG_TABLE_NAME='messages' THEN
  SELECT ARRAY[buyer_id,seller_id] INTO owners FROM public.conversations WHERE id=NEW.conversation_id;
 ELSIF TG_TABLE_NAME='conversations' THEN owners:=ARRAY[NEW.buyer_id,NEW.seller_id];
 ELSE
  SELECT ARRAY[NEW.user_id,seller_id] INTO owners FROM public.listings WHERE id=NEW.listing_id;
  WITH RECURSIVE parents AS (
   SELECT id,parent_id,user_id FROM public.listing_comments WHERE id=NEW.parent_id
   UNION SELECT c.id,c.parent_id,c.user_id FROM public.listing_comments c JOIN parents p ON c.id=p.parent_id
  ) SELECT owners||coalesce(array_agg(user_id),'{}') INTO owners FROM parents;
 END IF;
 FOR o IN SELECT DISTINCT x FROM unnest(owners)x WHERE x IS NOT NULL ORDER BY x LOOP
  PERFORM pg_advisory_xact_lock(hashtextextended('kibo-account-'||o::text,0));
  IF NOT private.kibo_account_active(o) THEN RAISE EXCEPTION 'Compte indisponible' USING ERRCODE='42501';END IF;
 END LOOP;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION private.kibo_exchange_write_guard() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER kibo_exchange_write_guard BEFORE INSERT OR UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION private.kibo_exchange_write_guard();
CREATE TRIGGER kibo_exchange_write_guard BEFORE INSERT OR UPDATE ON public.conversations FOR EACH ROW EXECUTE FUNCTION private.kibo_exchange_write_guard();
CREATE TRIGGER kibo_exchange_write_guard BEFORE INSERT OR UPDATE ON public.listing_comments FOR EACH ROW EXECUTE FUNCTION private.kibo_exchange_write_guard();
CREATE FUNCTION private.kibo_frozen_request_guard() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT private.kibo_account_active(OLD.owner_id) AND current_setting('role',true)<>'service_role' THEN
  RAISE EXCEPTION 'Suppression deja commencee';END IF;
 IF TG_OP='DELETE' THEN RETURN OLD;END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION private.kibo_frozen_request_guard() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER kibo_frozen_request_guard BEFORE UPDATE OR DELETE ON public.kibo_account_requests
FOR EACH ROW EXECUTE FUNCTION private.kibo_frozen_request_guard();
CREATE POLICY kibo_active_storage ON storage.objects AS RESTRICTIVE FOR ALL TO authenticated
 USING(private.kibo_account_active(auth.uid())) WITH CHECK(private.kibo_account_active(auth.uid()));
CREATE FUNCTION private.kibo_storage_owner_active(p_name text) RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF split_part(p_name,'/',1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
  RETURN private.kibo_account_active(split_part(p_name,'/',1)::uuid);
 END IF;
 RETURN true;
END $$;
REVOKE ALL ON FUNCTION private.kibo_storage_owner_active(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.kibo_storage_owner_active(text) TO anon,authenticated;
CREATE POLICY kibo_active_storage_owner ON storage.objects AS RESTRICTIVE FOR SELECT TO anon,authenticated USING(private.kibo_storage_owner_active(name));

CREATE FUNCTION public.kibo_deletion_begin(p_subject uuid,p_actor uuid,p_version bigint) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE j kibo_lifecycle_private.jobs;req public.kibo_account_requests;
BEGIN
 IF current_setting('role',true)<>'service_role' THEN RAISE EXCEPTION 'Service requis' USING ERRCODE='42501';END IF;
 IF p_subject IS NULL OR p_actor IS NULL OR p_subject=p_actor THEN RAISE EXCEPTION 'Suppression propre admin interdite';END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('kibo-account-'||p_subject::text,0));
 SELECT * INTO j FROM kibo_lifecycle_private.jobs WHERE subject=p_subject FOR UPDATE;
 IF FOUND THEN
  IF j.request_version IS DISTINCT FROM p_version THEN RAISE EXCEPTION 'Version differente';END IF;
  RETURN to_jsonb(j);
 END IF;
 SELECT * INTO req FROM public.kibo_account_requests WHERE owner_id=p_subject FOR UPDATE;
 IF NOT FOUND OR req.status<>'processing' OR req.version IS DISTINCT FROM p_version THEN RAISE EXCEPTION 'Demande non approuvee ou modifiee';END IF;
 IF EXISTS(SELECT 1 FROM kibo_media_private.transfers WHERE owner_id=p_subject) THEN RAISE EXCEPTION 'Envoi photo encore actif, verification requise';END IF;
 INSERT INTO kibo_lifecycle_private.accounts(owner_id,frozen) VALUES(p_subject,true)
 ON CONFLICT(owner_id) DO UPDATE SET frozen=true;
 INSERT INTO kibo_lifecycle_private.jobs(subject,actor,request_version,requested_at) VALUES(p_subject,p_actor,p_version,req.requested_at) RETURNING * INTO j;
 INSERT INTO kibo_lifecycle_private.objects(job_id,bucket,path)
 SELECT j.id,bucket_id,name FROM storage.objects WHERE owner_id=p_subject::text OR split_part(name,'/',1)=p_subject::text
 ON CONFLICT DO NOTHING;
 INSERT INTO kibo_lifecycle_private.objects(job_id,bucket,path)
 SELECT j.id,'kibo-listing-photos',path FROM public.kibo_listing_photos WHERE owner_id=p_subject ON CONFLICT DO NOTHING;
 RETURN to_jsonb(j);
END $$;
CREATE FUNCTION public.kibo_deletion_purge(p_job uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE j kibo_lifecycle_private.jobs;subject uuid;comment_ids uuid[];listing_ids uuid[];thread_ids uuid[];expiry timestamptz:=now()+interval '15 days';
BEGIN
 IF current_setting('role',true)<>'service_role' THEN RAISE EXCEPTION 'Service requis' USING ERRCODE='42501';END IF;
 SELECT * INTO j FROM kibo_lifecycle_private.jobs WHERE id=p_job FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Operation inconnue';END IF;
 IF j.phase<>'frozen' THEN RETURN;END IF;
 subject:=j.subject;
 IF private.kibo_account_active(subject) THEN RAISE EXCEPTION 'Compte non gele';END IF;
 SELECT coalesce(array_agg(id),'{}') INTO listing_ids FROM public.listings WHERE seller_id=subject;
 SELECT coalesce(array_agg(id),'{}') INTO thread_ids FROM public.conversations WHERE subject IN(buyer_id,seller_id) OR listing_id=ANY(listing_ids);
 WITH RECURSIVE affected AS (
  SELECT id FROM public.listing_comments WHERE user_id=subject OR listing_id=ANY(listing_ids)
  UNION SELECT c.id FROM public.listing_comments c JOIN affected a ON c.parent_id=a.id
 ) SELECT coalesce(array_agg(id),'{}') INTO comment_ids FROM affected;
 INSERT INTO public.kibo_retained_threads(owner_id,id,last_at,expires_at,policy_version)
 SELECT p.owner,c.id,c.updated_at,expiry,'deletion-15d-v1' FROM public.conversations c
 CROSS JOIN LATERAL unnest(ARRAY[c.buyer_id,c.seller_id])p(owner)
 WHERE c.id=ANY(thread_ids) AND p.owner<>subject ON CONFLICT DO NOTHING;
 INSERT INTO public.kibo_retained_messages(owner_id,thread_id,id,from_survivor,content,created_at)
 SELECT t.owner_id,m.conversation_id,m.id,m.sender_id=t.owner_id,
 CASE WHEN m.sender_id=t.owner_id THEN m.content ELSE 'Message anonymisé' END,m.created_at
 FROM public.messages m JOIN public.kibo_retained_threads t ON t.id=m.conversation_id
 WHERE m.conversation_id=ANY(thread_ids) ON CONFLICT DO NOTHING;
 INSERT INTO public.kibo_retained_comments(owner_id,id,context_id,parent_id,from_survivor,content,created_at,expires_at,policy_version)
 SELECT user_id,id,listing_id,NULL,true,content,created_at,expiry,'deletion-15d-v1'
 FROM public.listing_comments WHERE id=ANY(comment_ids) AND user_id<>subject AND deleted_at IS NULL
 ON CONFLICT DO NOTHING;
 DELETE FROM public.reports WHERE reporter_id=subject OR reported_user_id=subject OR listing_id=ANY(listing_ids) OR comment_id=ANY(comment_ids);
 DELETE FROM public.notifications WHERE user_id=subject OR data::text LIKE '%'||subject::text||'%'
 OR EXISTS(SELECT 1 FROM unnest(listing_ids||thread_ids||comment_ids)x WHERE data::text LIKE '%'||x::text||'%');
 DELETE FROM public.messages WHERE conversation_id=ANY(thread_ids);
 DELETE FROM public.conversations WHERE id=ANY(thread_ids);
 DELETE FROM public.listing_comments WHERE id=ANY(comment_ids);
 DELETE FROM public.kibo_listing_photos WHERE owner_id=subject;
 DELETE FROM public.listings WHERE seller_id=subject;
 DELETE FROM public.profiles WHERE id=subject;
 UPDATE kibo_lifecycle_private.jobs SET phase='purged' WHERE id=p_job;
END $$;
CREATE FUNCTION public.kibo_deletion_objects(p_job uuid) RETURNS SETOF jsonb
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT jsonb_build_object('bucket',bucket,'path',path) FROM kibo_lifecycle_private.objects
 WHERE job_id=p_job AND current_setting('role',true)='service_role' ORDER BY bucket,path LIMIT 50
$$;
CREATE FUNCTION public.kibo_deletion_object_ack(p_job uuid,p_bucket text,p_path text) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF current_setting('role',true)<>'service_role' THEN RAISE EXCEPTION 'Service requis' USING ERRCODE='42501';END IF;
 IF EXISTS(SELECT 1 FROM storage.objects WHERE bucket_id=p_bucket AND name=p_path) THEN RAISE EXCEPTION 'Objet encore present';END IF;
 DELETE FROM kibo_lifecycle_private.objects WHERE job_id=p_job AND bucket=p_bucket AND path=p_path;
END $$;
CREATE FUNCTION public.kibo_deletion_ready(p_job uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT current_setting('role',true)='service_role' AND EXISTS(SELECT 1 FROM kibo_lifecycle_private.jobs j
 WHERE id=p_job AND phase IN('purged','completed') AND NOT private.kibo_account_active(subject)
 AND NOT EXISTS(SELECT 1 FROM kibo_lifecycle_private.objects WHERE job_id=j.id)
 AND NOT EXISTS(SELECT 1 FROM storage.objects WHERE owner_id=j.subject::text OR split_part(name,'/',1)=j.subject::text)
 AND NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=j.subject)
 AND NOT EXISTS(SELECT 1 FROM public.listings WHERE seller_id=j.subject))
$$;
CREATE FUNCTION public.kibo_deletion_complete(p_job uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF current_setting('role',true)<>'service_role' OR NOT public.kibo_deletion_ready(p_job) THEN RAISE EXCEPTION 'Verification incomplete';END IF;
 IF EXISTS(SELECT 1 FROM auth.users u JOIN kibo_lifecycle_private.jobs j ON j.subject=u.id WHERE j.id=p_job) THEN RAISE EXCEPTION 'Compte Auth encore present';END IF;
 UPDATE kibo_lifecycle_private.jobs SET phase='completed',completed_at=coalesce(completed_at,now()) WHERE id=p_job;
END $$;
CREATE FUNCTION public.kibo_retained_expire() RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF current_setting('role',true) NOT IN('service_role','none') THEN RAISE EXCEPTION 'Service requis' USING ERRCODE='42501';END IF;
 DELETE FROM public.kibo_retained_threads WHERE expires_at<=now();
 DELETE FROM public.kibo_retained_comments WHERE expires_at<=now();
END $$;
CREATE OR REPLACE FUNCTION kibo_mvp_private.account_queue(p_status text,p_offset integer) RETURNS SETOF jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF auth.uid() IS NULL OR NOT private.is_admin() OR NOT private.kibo_account_active(auth.uid()) THEN RAISE EXCEPTION 'Acces administrateur requis' USING ERRCODE='42501';END IF;
 IF p_status NOT IN('pending','processing','needs_info','rejected','completed') OR p_offset IS NULL OR p_offset<0 OR p_offset>100000 THEN RAISE EXCEPTION 'Filtre invalide';END IF;
 RETURN QUERY SELECT x.payload FROM (
  SELECT to_jsonb(r)||jsonb_build_object('name',coalesce(nullif(trim(p.full_name),''),'Membre KIBO')) AS payload,r.requested_at AS stamp,r.owner_id AS subject
  FROM public.kibo_account_requests r JOIN public.profiles p ON p.id=r.owner_id WHERE r.status=p_status
  UNION ALL
  SELECT jsonb_build_object('owner_id',j.subject,'name',CASE WHEN j.phase='completed' THEN 'Compte supprimé' ELSE 'Suppression en cours' END,
   'status',CASE WHEN j.phase='completed' THEN 'completed' ELSE 'processing' END,'version',j.request_version,'requested_at',j.requested_at),j.requested_at,j.subject
  FROM kibo_lifecycle_private.jobs j WHERE NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=j.subject)
  AND ((p_status='processing' AND j.phase='purged') OR (p_status='completed' AND j.phase='completed'))
 )x ORDER BY x.stamp,x.subject LIMIT 20 OFFSET p_offset;
END $$;
REVOKE ALL ON FUNCTION public.kibo_deletion_begin(uuid,uuid,bigint),public.kibo_deletion_purge(uuid),
 public.kibo_deletion_objects(uuid),public.kibo_deletion_object_ack(uuid,text,text),public.kibo_deletion_ready(uuid),
 public.kibo_deletion_complete(uuid),public.kibo_retained_expire() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_deletion_begin(uuid,uuid,bigint),public.kibo_deletion_purge(uuid),
 public.kibo_deletion_objects(uuid),public.kibo_deletion_object_ack(uuid,text,text),public.kibo_deletion_ready(uuid),
 public.kibo_deletion_complete(uuid),public.kibo_retained_expire() TO service_role;
NOTIFY pgrst,'reload config';
NOTIFY pgrst,'reload schema';
COMMIT;
