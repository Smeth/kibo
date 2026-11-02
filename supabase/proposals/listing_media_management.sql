-- Edition atomique de la galerie ; les fichiers sont purges via Storage API.
BEGIN;
CREATE SCHEMA kibo_lifecycle_private;
REVOKE ALL ON SCHEMA kibo_lifecycle_private FROM PUBLIC,anon,authenticated;
CREATE TABLE kibo_lifecycle_private.accounts(owner_id uuid PRIMARY KEY,frozen boolean NOT NULL DEFAULT false);
ALTER TABLE kibo_lifecycle_private.accounts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON kibo_lifecycle_private.accounts FROM PUBLIC,anon,authenticated;
CREATE FUNCTION private.kibo_account_active(p_owner uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT p_owner IS NULL OR NOT EXISTS(SELECT 1 FROM kibo_lifecycle_private.accounts WHERE owner_id=p_owner AND frozen)
$$;
REVOKE ALL ON FUNCTION private.kibo_account_active(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.kibo_account_active(uuid) TO anon,authenticated,service_role;
CREATE SCHEMA kibo_media_private;
REVOKE ALL ON SCHEMA kibo_media_private FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA kibo_media_private TO authenticated;
CREATE TABLE kibo_media_private.revisions(
 listing_id uuid PRIMARY KEY REFERENCES public.listings ON DELETE CASCADE,
 revision bigint NOT NULL DEFAULT 0 CHECK(revision>=0));
CREATE TABLE kibo_media_private.edits(
 id uuid PRIMARY KEY,listing_id uuid NOT NULL REFERENCES public.listings ON DELETE CASCADE,
 owner_id uuid NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
 expected_revision bigint NOT NULL,digests text[] NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),applied boolean NOT NULL DEFAULT false,
 response jsonb, CHECK(cardinality(digests)<=3));
CREATE TABLE kibo_media_private.garbage(
 path text PRIMARY KEY,owner_id uuid NOT NULL,listing_id uuid NOT NULL,created_at timestamptz NOT NULL DEFAULT now());
CREATE INDEX kibo_media_garbage_owner ON kibo_media_private.garbage(owner_id);
CREATE TABLE kibo_media_private.transfers(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),owner_id uuid NOT NULL,path text NOT NULL UNIQUE,
 created_at timestamptz NOT NULL DEFAULT now(),uncertain boolean NOT NULL DEFAULT false);
CREATE INDEX kibo_media_transfers_owner ON kibo_media_private.transfers(owner_id);
CREATE FUNCTION kibo_media_private.transfer_begin(p_path text) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE owner uuid:=auth.uid(); ticket uuid;
BEGIN
 IF owner IS NULL THEN RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('kibo-account-'||owner::text,0));
 IF NOT private.kibo_account_active(owner) THEN RAISE EXCEPTION 'Suppression du compte en cours' USING ERRCODE='42501';END IF;
 IF split_part(p_path,'/',1)<>owner::text THEN RAISE EXCEPTION 'Chemin refuse';END IF;
 PERFORM 1 FROM public.listings WHERE id=split_part(p_path,'/',2)::uuid AND seller_id=owner FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Annonce indisponible';END IF;
 IF NOT EXISTS(SELECT 1 FROM public.kibo_listing_photos WHERE owner_id=owner AND path=p_path)
 AND NOT EXISTS(SELECT 1 FROM kibo_media_private.edits e CROSS JOIN LATERAL unnest(e.digests)d
   WHERE e.owner_id=owner AND NOT e.applied AND e.created_at>now()-interval '24 hours'
   AND p_path=owner::text||'/'||e.listing_id::text||'/edit-'||e.id::text||'-'||d||'.jpg') THEN
  RAISE EXCEPTION 'Chemin photo refuse' USING ERRCODE='42501';END IF;
 IF (SELECT count(*) FROM kibo_media_private.transfers WHERE owner_id=owner)>=6 THEN
  RAISE EXCEPTION 'Des envois photos sont encore en cours';END IF;
 INSERT INTO kibo_media_private.transfers(owner_id,path) VALUES(owner,p_path) RETURNING id INTO ticket;
 RETURN ticket;
END $$;
CREATE FUNCTION public.kibo_photo_transfer_begin(p_path text) RETURNS uuid
LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_media_private.transfer_begin(p_path) $$;
CREATE FUNCTION public.kibo_photo_transfer_finish(p_ticket uuid,p_uncertain boolean DEFAULT false) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF current_setting('role',true)<>'service_role' THEN RAISE EXCEPTION 'Service requis' USING ERRCODE='42501';END IF;
 IF p_uncertain THEN UPDATE kibo_media_private.transfers SET uncertain=true WHERE id=p_ticket;
 ELSE DELETE FROM kibo_media_private.transfers WHERE id=p_ticket; END IF;
END $$;
CREATE FUNCTION kibo_media_private.state(p_listing uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE owner uuid:=auth.uid(); result jsonb;
BEGIN
 IF owner IS NULL OR NOT private.kibo_account_active(owner) OR NOT EXISTS(SELECT 1 FROM public.listings WHERE id=p_listing AND seller_id=owner) THEN
  RAISE EXCEPTION 'Annonce privee' USING ERRCODE='42501'; END IF;
 SELECT jsonb_build_object('revision',coalesce((SELECT revision FROM kibo_media_private.revisions WHERE listing_id=p_listing),0),
  'paths',(SELECT coalesce(jsonb_agg(path ORDER BY position),'[]'::jsonb) FROM public.kibo_listing_photos WHERE listing_id=p_listing),
  'updated_at',updated_at,'editable',status::text IN ('published','draft')) INTO result FROM public.listings WHERE id=p_listing;
 RETURN result;
END $$;
CREATE FUNCTION kibo_media_private.prepare(p_listing uuid,p_operation uuid,p_revision bigint,p_digests text[]) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE owner uuid:=auth.uid(); edit kibo_media_private.edits; current_revision bigint; d text; paths jsonb:='[]';
BEGIN
 IF owner IS NULL OR NOT private.kibo_account_active(owner) OR p_operation IS NULL OR p_revision IS NULL OR p_revision<0 OR p_digests IS NULL OR cardinality(p_digests)>3
 OR cardinality(p_digests)<>(SELECT count(DISTINCT x) FROM unnest(p_digests)x)
 OR EXISTS(SELECT 1 FROM unnest(p_digests)x WHERE x IS NULL OR x !~ '^[0-9a-f]{64}$') THEN
  RAISE EXCEPTION 'Preparation photo invalide'; END IF;
 PERFORM 1 FROM public.listings WHERE id=p_listing AND seller_id=owner AND status::text IN ('published','draft') FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Annonce non modifiable' USING ERRCODE='42501';END IF;
 SELECT * INTO edit FROM kibo_media_private.edits WHERE id=p_operation;
 IF FOUND THEN
  IF edit.owner_id<>owner OR edit.listing_id<>p_listing OR edit.expected_revision<>p_revision OR edit.digests<>p_digests THEN
   RAISE EXCEPTION 'Conflit de preparation';END IF;
 ELSE
  INSERT INTO kibo_media_private.revisions(listing_id) VALUES(p_listing) ON CONFLICT DO NOTHING;
  SELECT revision INTO current_revision FROM kibo_media_private.revisions WHERE listing_id=p_listing;
  IF current_revision<>p_revision THEN RAISE EXCEPTION 'Galerie modifiee, actualisez' USING ERRCODE='40001';END IF;
  INSERT INTO kibo_media_private.edits(id,listing_id,owner_id,expected_revision,digests)
    VALUES(p_operation,p_listing,owner,p_revision,p_digests) RETURNING * INTO edit;
 END IF;
 FOREACH d IN ARRAY edit.digests LOOP
  paths:=paths||jsonb_build_array(jsonb_build_object('digest',d,'path',owner::text||'/'||p_listing::text||'/edit-'||p_operation::text||'-'||d||'.jpg'));
 END LOOP;
 RETURN jsonb_build_object('uploads',paths,'applied',edit.applied);
END $$;
CREATE FUNCTION kibo_media_private.ticket(p_operation uuid,p_digest text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE e kibo_media_private.edits;
BEGIN
 SELECT * INTO e FROM kibo_media_private.edits WHERE id=p_operation AND owner_id=auth.uid()
  AND NOT applied AND created_at>now()-interval '24 hours';
 IF NOT FOUND OR NOT private.kibo_account_active(auth.uid()) OR NOT p_digest=ANY(e.digests) OR NOT EXISTS(SELECT 1 FROM public.listings
  WHERE id=e.listing_id AND seller_id=auth.uid() AND status::text IN ('published','draft')) THEN
  RAISE EXCEPTION 'Reservation photo refusee' USING ERRCODE='42501'; END IF;
 RETURN jsonb_build_object('path',e.owner_id::text||'/'||e.listing_id::text||'/edit-'||e.id::text||'-'||p_digest||'.jpg',
   'listing_id',e.listing_id);
END $$;
CREATE FUNCTION kibo_media_private.apply(p_listing uuid,p_operation uuid,p_revision bigint,p_paths text[]) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE owner uuid:=auth.uid();e kibo_media_private.edits; old_paths text[];allowed text[];
 revision_value bigint;listing_stamp timestamptz;result jsonb;
BEGIN
 PERFORM pg_advisory_xact_lock(hashtextextended('kibo-account-'||coalesce(owner::text,''),0));
 IF owner IS NULL OR NOT private.kibo_account_active(owner) OR p_revision IS NULL OR p_revision<0 OR p_paths IS NULL OR cardinality(p_paths)>3 OR
 cardinality(p_paths)<>(SELECT count(DISTINCT x) FROM unnest(p_paths)x) OR
 EXISTS(SELECT 1 FROM unnest(p_paths)x WHERE x IS NULL) THEN RAISE EXCEPTION 'Galerie invalide';END IF;
 PERFORM 1 FROM public.listings WHERE id=p_listing AND seller_id=owner AND status::text IN ('published','draft') FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Annonce non modifiable' USING ERRCODE='42501'; END IF;
 SELECT * INTO e FROM kibo_media_private.edits WHERE id=p_operation AND owner_id=owner AND listing_id=p_listing FOR UPDATE;
 IF NOT FOUND OR e.expected_revision IS DISTINCT FROM p_revision THEN RAISE EXCEPTION 'Operation photo inconnue'; END IF;
 IF e.applied THEN
  IF e.response->'paths'<>to_jsonb(p_paths) THEN RAISE EXCEPTION 'Reprise de contenu different';END IF;
  RETURN e.response;
 END IF;
 IF e.created_at<now()-interval '24 hours' THEN RAISE EXCEPTION 'Operation photo expiree';END IF;
 SELECT revision INTO revision_value FROM kibo_media_private.revisions WHERE listing_id=p_listing FOR UPDATE;
 IF EXISTS(SELECT 1 FROM kibo_media_private.transfers WHERE owner_id=owner AND split_part(path,'/',2)=p_listing::text) THEN
  RAISE EXCEPTION 'Envoi encore actif, verification requise';END IF;
 IF revision_value<>p_revision THEN RAISE EXCEPTION 'Galerie modifiee, actualisez' USING ERRCODE='40001';END IF;
 SELECT coalesce(array_agg(path ORDER BY position),'{}') INTO old_paths FROM public.kibo_listing_photos WHERE listing_id=p_listing;
 SELECT old_paths||coalesce(array_agg(owner::text||'/'||p_listing::text||'/edit-'||e.id::text||'-'||d||'.jpg'),'{}')
  INTO allowed FROM unnest(e.digests)d;
 IF EXISTS(SELECT 1 FROM unnest(p_paths)p WHERE NOT p=ANY(allowed)) THEN
  RAISE EXCEPTION 'Photo etrangere' USING ERRCODE='42501';END IF;
 IF EXISTS(SELECT 1 FROM unnest(p_paths)p WHERE NOT EXISTS(SELECT 1 FROM storage.objects o
    WHERE o.bucket_id='kibo-listing-photos' AND o.name=p
    AND o.metadata->>'mimetype'='image/jpeg' AND coalesce((o.metadata->>'size')::bigint,0)>0)) THEN
  RAISE EXCEPTION 'Envoi incomplet, galerie conservee';END IF;
 DELETE FROM public.kibo_listing_photos WHERE listing_id=p_listing;
 INSERT INTO public.kibo_listing_photos(listing_id,position,owner_id,path)
 SELECT p_listing,(ordinality-1)::smallint,owner,path FROM unnest(p_paths) WITH ORDINALITY AS x(path,ordinality);
 INSERT INTO kibo_media_private.garbage(path,owner_id,listing_id)
 SELECT path,owner,p_listing FROM unnest(allowed)path WHERE NOT path=ANY(p_paths)
 ON CONFLICT(path) DO NOTHING;
 UPDATE kibo_media_private.revisions SET revision=revision+1 WHERE listing_id=p_listing RETURNING revision INTO revision_value;
 UPDATE public.listings SET updated_at=clock_timestamp() WHERE id=p_listing RETURNING updated_at INTO listing_stamp;
 result:=jsonb_build_object('paths',to_jsonb(p_paths),'revision',revision_value,'updated_at',listing_stamp);
 UPDATE kibo_media_private.edits SET applied=true,response=result WHERE id=p_operation;
 RETURN result;
END $$;
CREATE FUNCTION kibo_media_private.cleanup_queue() RETURNS SETOF jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF auth.uid() IS NULL OR NOT private.kibo_account_active(auth.uid()) THEN RAISE EXCEPTION 'Connexion requise' USING ERRCODE='42501';END IF;
 INSERT INTO kibo_media_private.garbage(path,owner_id,listing_id)
 SELECT e.owner_id::text||'/'||e.listing_id::text||'/edit-'||e.id::text||'-'||d||'.jpg',e.owner_id,e.listing_id
 FROM kibo_media_private.edits e CROSS JOIN LATERAL unnest(e.digests)d
 WHERE e.owner_id=auth.uid() AND NOT e.applied AND e.created_at<now()-interval '24 hours'
 AND NOT EXISTS(SELECT 1 FROM public.kibo_listing_photos p WHERE p.path=e.owner_id::text||'/'||e.listing_id::text||'/edit-'||e.id::text||'-'||d||'.jpg')
 AND NOT EXISTS(SELECT 1 FROM kibo_media_private.transfers t WHERE t.path=e.owner_id::text||'/'||e.listing_id::text||'/edit-'||e.id::text||'-'||d||'.jpg')
 ON CONFLICT(path) DO NOTHING;
 RETURN QUERY SELECT jsonb_build_object('path',g.path) FROM kibo_media_private.garbage g
 WHERE g.owner_id=auth.uid() AND NOT EXISTS(SELECT 1 FROM public.kibo_listing_photos p WHERE p.path=g.path)
 ORDER BY g.created_at,g.path LIMIT 30;
END
$$;
CREATE FUNCTION public.kibo_photo_edit_state(p_listing uuid) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path=''
 AS $$ SELECT kibo_media_private.state(p_listing) $$;
CREATE FUNCTION public.kibo_prepare_photo_edit(p_listing uuid,p_operation uuid,p_revision bigint,p_digests text[]) RETURNS jsonb
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_media_private.prepare(p_listing,p_operation,p_revision,p_digests) $$;
CREATE FUNCTION public.kibo_photo_upload_ticket(p_operation uuid,p_digest text) RETURNS jsonb
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_media_private.ticket(p_operation,p_digest) $$;
CREATE FUNCTION public.kibo_apply_photo_edit(p_listing uuid,p_operation uuid,p_revision bigint,p_paths text[]) RETURNS jsonb
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT kibo_media_private.apply(p_listing,p_operation,p_revision,p_paths) $$;
CREATE FUNCTION public.kibo_photo_cleanup_queue() RETURNS SETOF jsonb
 LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT * FROM kibo_media_private.cleanup_queue() $$;
CREATE FUNCTION public.kibo_photo_cleanup_ack(p_path text) RETURNS void
LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 DELETE FROM kibo_media_private.garbage WHERE path=p_path
 AND NOT EXISTS(SELECT 1 FROM public.kibo_listing_photos p WHERE p.path=p_path)
$$;
REVOKE ALL ON ALL TABLES IN SCHEMA kibo_media_private FROM PUBLIC,anon,authenticated;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA kibo_media_private FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION kibo_media_private.state(uuid),kibo_media_private.prepare(uuid,uuid,bigint,text[]),
 kibo_media_private.ticket(uuid,text),kibo_media_private.apply(uuid,uuid,bigint,text[]),kibo_media_private.cleanup_queue(),
 kibo_media_private.transfer_begin(text) TO authenticated;
REVOKE ALL ON FUNCTION public.kibo_photo_edit_state(uuid),public.kibo_prepare_photo_edit(uuid,uuid,bigint,text[]),
 public.kibo_photo_upload_ticket(uuid,text),public.kibo_apply_photo_edit(uuid,uuid,bigint,text[]),
 public.kibo_photo_cleanup_queue(),public.kibo_photo_cleanup_ack(text),public.kibo_photo_transfer_begin(text),
 public.kibo_photo_transfer_finish(uuid,boolean) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_photo_edit_state(uuid),public.kibo_prepare_photo_edit(uuid,uuid,bigint,text[]),
 public.kibo_photo_upload_ticket(uuid,text),public.kibo_apply_photo_edit(uuid,uuid,bigint,text[]),public.kibo_photo_cleanup_queue(),
 public.kibo_photo_transfer_begin(text) TO authenticated;
GRANT USAGE ON SCHEMA kibo_media_private TO service_role;
GRANT SELECT,DELETE ON kibo_media_private.garbage TO service_role;
GRANT EXECUTE ON FUNCTION public.kibo_photo_cleanup_ack(text) TO service_role;
GRANT EXECUTE ON FUNCTION public.kibo_photo_transfer_finish(uuid,boolean) TO service_role;
ALTER TABLE kibo_media_private.revisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE kibo_media_private.edits ENABLE ROW LEVEL SECURITY;
ALTER TABLE kibo_media_private.garbage ENABLE ROW LEVEL SECURITY;
ALTER TABLE kibo_media_private.transfers ENABLE ROW LEVEL SECURITY;
CREATE FUNCTION private.kibo_legacy_photo_allowed(p_listing uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT NOT EXISTS(SELECT 1 FROM kibo_media_private.revisions WHERE listing_id=p_listing AND revision>0)
$$;
REVOKE ALL ON FUNCTION private.kibo_legacy_photo_allowed(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.kibo_legacy_photo_allowed(uuid) TO authenticated;
CREATE POLICY kibo_managed_photo_insert ON public.kibo_listing_photos AS RESTRICTIVE FOR INSERT TO authenticated
 WITH CHECK(private.kibo_legacy_photo_allowed(listing_id));
COMMIT;
