-- Recherche normalisee, prefixe, synonymes, fautes bornees et pertinence.
-- Les projections publiques restent SECURITY INVOKER et soumises a RLS.
BEGIN;
SET LOCAL lock_timeout='5s';
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA extensions;
GRANT USAGE ON SCHEMA extensions TO anon,authenticated;
CREATE SCHEMA kibo_discovery_private;
REVOKE ALL ON SCHEMA kibo_discovery_private FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA kibo_discovery_private TO anon,authenticated;
CREATE FUNCTION kibo_discovery_private.normalize(p_text text) RETURNS text
LANGUAGE sql IMMUTABLE PARALLEL SAFE SET search_path='' AS $$
 SELECT trim(regexp_replace(lower(extensions.unaccent('extensions.unaccent'::regdictionary,coalesce(p_text,''))),
   '[^[:alnum:]]+',' ','g'))
$$;
ALTER TABLE public.listings
 ADD COLUMN kibo_search_title text GENERATED ALWAYS AS
   (kibo_discovery_private.normalize(title)) STORED,
 ADD COLUMN kibo_search_text text GENERATED ALWAYS AS
   (kibo_discovery_private.normalize(title||' '||description)) STORED,
 ADD COLUMN kibo_search_simple tsvector GENERATED ALWAYS AS
   (setweight(to_tsvector('simple'::regconfig,kibo_discovery_private.normalize(title)),'A') ||
    setweight(to_tsvector('simple'::regconfig,kibo_discovery_private.normalize(description)),'B')) STORED;
CREATE INDEX kibo_search_simple_gin ON public.listings USING gin(kibo_search_simple) WHERE status='published';
CREATE INDEX kibo_search_title_trgm ON public.listings USING gin(kibo_search_title extensions.gin_trgm_ops) WHERE status='published';
-- Ces colonnes sont generees, jamais des champs modifiables par le client.
DO $guards$
DECLARE f regprocedure; definition text;
BEGIN
 FOREACH f IN ARRAY ARRAY['private.guard_listing_update()'::regprocedure,
   'public.guard_listing_owner_update()'::regprocedure] LOOP
  definition:=pg_get_functiondef(f);
  IF position('Separate content and status' in definition)=0 OR
     position('Listing owner required' in definition)=0 OR
     position('''kibo_search_vector''' in definition)=0 THEN
    RAISE EXCEPTION 'Listing guard baseline changed'; END IF;
  EXECUTE replace(definition,'''kibo_search_vector''',
    '''kibo_search_vector'',''kibo_search_title'',''kibo_search_text'',''kibo_search_simple''');
 END LOOP;
END $guards$;
CREATE TABLE kibo_discovery_private.terms(term text PRIMARY KEY,refs bigint NOT NULL CHECK(refs>=0));
CREATE INDEX kibo_search_terms_trgm ON kibo_discovery_private.terms USING gin(term extensions.gin_trgm_ops);
CREATE TABLE kibo_discovery_private.synonyms(group_id text NOT NULL,term text NOT NULL,
 PRIMARY KEY(group_id,term));
INSERT INTO kibo_discovery_private.synonyms VALUES
 ('telephone','telephone'),('telephone','tel'),('telephone','smartphone'),('telephone','gsm'),('telephone','cellulaire'),
 ('ordinateur','ordinateur'),('ordinateur','ordi'),('ordinateur','pc'),('ordinateur','laptop'),
 ('voiture','voiture'),('voiture','auto'),('voiture','automobile'),
 ('moto','moto'),('moto','motocycle'),('moto','motocyclette'),
 ('canape','canape'),('canape','sofa'),
 ('logement','logement'),('logement','appartement'),('logement','appart'),
 ('emploi','emploi'),('emploi','travail'),('emploi','job'),
 ('formation','formation'),('formation','cours');
INSERT INTO kibo_discovery_private.terms(term,refs)
SELECT term,count(*) FROM public.listings l CROSS JOIN LATERAL
 (SELECT DISTINCT unnest(string_to_array(l.kibo_search_text,' ')) term) t
WHERE status='published' AND char_length(term) BETWEEN 3 AND 40 GROUP BY term;
CREATE FUNCTION kibo_discovery_private.update_terms() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE old_terms text[]:='{}';new_terms text[]:='{}';t text;
BEGIN
 IF TG_OP<>'INSERT' AND OLD.status::text='published' THEN
  old_terms:=string_to_array(OLD.kibo_search_text,' '); END IF;
 IF TG_OP<>'DELETE' AND NEW.status::text='published' THEN
  new_terms:=string_to_array(NEW.kibo_search_text,' '); END IF;
 FOR t IN SELECT DISTINCT x FROM unnest(old_terms||new_terms)x
   WHERE char_length(x) BETWEEN 3 AND 40 ORDER BY x LOOP
  IF t=ANY(old_terms) AND NOT t=ANY(new_terms) THEN
   UPDATE kibo_discovery_private.terms SET refs=refs-1 WHERE term=t;
   DELETE FROM kibo_discovery_private.terms WHERE term=t AND refs=0;
  ELSIF t=ANY(new_terms) AND NOT t=ANY(old_terms) THEN
   INSERT INTO kibo_discovery_private.terms VALUES(t,1)
   ON CONFLICT(term) DO UPDATE SET refs=kibo_discovery_private.terms.refs+1;
  END IF;
 END LOOP;
 RETURN NULL;
END $$;
CREATE TRIGGER kibo_search_terms AFTER INSERT OR UPDATE OF title,description,status OR DELETE
ON public.listings FOR EACH ROW EXECUTE FUNCTION kibo_discovery_private.update_terms();
CREATE FUNCTION kibo_discovery_private.plan(p_text text) RETURNS tsquery
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE norm text:=kibo_discovery_private.normalize(p_text);token text;alternatives text[];
 expression text:='';part text;words text[];
BEGIN
 IF char_length(coalesce(p_text,''))>120 THEN RAISE EXCEPTION 'Recherche trop longue'; END IF;
 IF norm='' THEN RETURN NULL; END IF;
 words:=string_to_array(norm,' ');
 IF cardinality(words)>60 THEN RAISE EXCEPTION 'Recherche trop longue'; END IF;
 FOREACH token IN ARRAY words LOOP
  alternatives:=ARRAY[token];
  alternatives:=alternatives||ARRAY(SELECT DISTINCT s2.term
    FROM kibo_discovery_private.synonyms s1 JOIN kibo_discovery_private.synonyms s2 USING(group_id)
    WHERE s1.term=token);
  IF char_length(token) BETWEEN 4 AND 40 AND token !~ '^[0-9]+$' THEN
   alternatives:=alternatives||ARRAY(SELECT term FROM kibo_discovery_private.terms
    WHERE refs>0 AND abs(char_length(term)-char_length(token))<=2
     AND extensions.similarity(term,token)>=0.25
     AND extensions.levenshtein_less_equal(term,token,CASE WHEN char_length(token)<6 THEN 1 ELSE 2 END)
       <=CASE WHEN char_length(token)<6 THEN 1 ELSE 2 END
    ORDER BY extensions.similarity(term,token) DESC,refs DESC,term LIMIT 3);
  END IF;
  SELECT string_agg(quote_literal(x)||':*',' | ' ORDER BY x) INTO part
   FROM (SELECT DISTINCT unnest(alternatives)x) a;
  expression:=expression||CASE WHEN expression='' THEN '' ELSE ' & ' END||'('||part||')';
 END LOOP;
 RETURN to_tsquery('simple'::regconfig,expression);
END $$;
CREATE FUNCTION kibo_discovery_private.score(p_title text,p_document tsvector,p_text text,p_query tsquery)
RETURNS real LANGUAGE sql STABLE SET search_path='' AS $$
 SELECT CASE WHEN p_query IS NULL THEN 0 ELSE
  (CASE WHEN p_title=kibo_discovery_private.normalize(p_text) THEN 100 ELSE 0 END)+
  (CASE WHEN strpos(p_title,kibo_discovery_private.normalize(p_text))>0 THEN 15 ELSE 0 END)+
  (CASE WHEN to_tsvector('simple'::regconfig,p_title) @@ p_query THEN 5 ELSE 0 END)+
  ts_rank_cd(p_document,p_query)*5+
  extensions.similarity(p_title,kibo_discovery_private.normalize(p_text))*2 END::real
$$;
CREATE FUNCTION public.kibo_search_listings(p_text text DEFAULT '',p_category uuid DEFAULT NULL,
 p_city text DEFAULT '',p_min numeric DEFAULT NULL,p_max numeric DEFAULT NULL,
 p_sort text DEFAULT 'relevance',p_offset integer DEFAULT 0)
RETURNS SETOF jsonb LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path='' AS $$
DECLARE query tsquery:=kibo_discovery_private.plan(p_text);
BEGIN
 IF p_offset<0 OR p_offset>100000 OR p_sort NOT IN ('relevance','newest','priceAscending','priceDescending')
 OR p_min<0 OR p_max<0 OR p_min>p_max OR char_length(coalesce(p_city,''))>120 THEN
  RAISE EXCEPTION 'Criteres invalides'; END IF;
 RETURN QUERY
 SELECT jsonb_build_object('id',l.id,'seller_id',l.seller_id,'title',l.title,
  'description',l.description,'price',l.price,'currency',l.currency,'city',l.city,
  'neighborhood',l.neighborhood,'listing_type',l.listing_type,'status',l.status,
  'published_at',l.published_at,'category',jsonb_build_object('name',c.name),
  'photos',(SELECT coalesce(jsonb_agg(jsonb_build_object('path',p.path,'position',p.position)
     ORDER BY p.position),'[]'::jsonb) FROM public.kibo_listing_photos p WHERE p.listing_id=l.id))
 FROM public.listings l JOIN public.categories c ON c.id=l.category_id
 WHERE l.status::text='published' AND (query IS NULL OR l.kibo_search_simple @@ query)
 AND (p_category IS NULL OR l.category_id=p_category) AND (coalesce(p_city,'')='' OR l.city=p_city)
 AND (p_min IS NULL OR l.price>=p_min) AND (p_max IS NULL OR l.price<=p_max)
 ORDER BY CASE WHEN p_sort='relevance' THEN kibo_discovery_private.score(l.kibo_search_title,l.kibo_search_simple,p_text,query) END DESC NULLS LAST,
 CASE WHEN p_sort='priceAscending' THEN l.price END ASC NULLS LAST,
 CASE WHEN p_sort='priceDescending' THEN l.price END DESC NULLS LAST,
 l.published_at DESC NULLS LAST,l.id LIMIT 20 OFFSET p_offset;
END $$;
CREATE FUNCTION public.kibo_search_suggestions(p_text text,p_category uuid DEFAULT NULL,
 p_city text DEFAULT '',p_min numeric DEFAULT NULL,p_max numeric DEFAULT NULL)
RETURNS SETOF jsonb LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path='' AS $$
DECLARE norm text:=kibo_discovery_private.normalize(p_text);last_word text;
 query tsquery:=kibo_discovery_private.plan(p_text);
BEGIN
 IF char_length(coalesce(p_text,''))>120 THEN RAISE EXCEPTION 'Recherche trop longue'; END IF;
 IF char_length(norm)<3 THEN RETURN; END IF;
 last_word:=regexp_replace(norm,'^.* ','');
 RETURN QUERY WITH candidates AS (
  SELECT l.title,l.kibo_search_title,
   kibo_discovery_private.score(l.kibo_search_title,l.kibo_search_simple,p_text,query) score
  FROM public.listings l WHERE l.status::text='published'
   AND l.kibo_search_simple @@ query
   AND (p_category IS NULL OR l.category_id=p_category) AND (coalesce(p_city,'')='' OR l.city=p_city)
   AND (p_min IS NULL OR l.price>=p_min) AND (p_max IS NULL OR l.price<=p_max)
 ) SELECT jsonb_build_object('text',title,'correction',strpos(kibo_search_title,last_word)=0)
 FROM candidates GROUP BY title,kibo_search_title,score ORDER BY score DESC,title LIMIT 5;
END $$;
CREATE FUNCTION public.kibo_search_owned(p_text text,p_status text DEFAULT NULL,p_offset integer DEFAULT 0)
RETURNS SETOF jsonb LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path='' AS $$
DECLARE query tsquery:=kibo_discovery_private.plan(p_text);
BEGIN
 IF auth.uid() IS NULL OR p_offset<0 OR p_offset>100000 THEN RAISE EXCEPTION 'Connexion et pagination requises'; END IF;
 RETURN QUERY SELECT jsonb_build_object('id',l.id,'seller_id',l.seller_id,'title',l.title,
  'description',l.description,'price',l.price,'city',l.city,'neighborhood',l.neighborhood,
  'category_id',l.category_id,'listing_type',l.listing_type,'status',l.status,'updated_at',l.updated_at,
  'photos',(SELECT coalesce(jsonb_agg(jsonb_build_object('path',p.path,'position',p.position) ORDER BY p.position),'[]'::jsonb)
    FROM public.kibo_listing_photos p WHERE p.listing_id=l.id))
 FROM public.listings l WHERE l.seller_id=auth.uid()
 AND (p_status IS NULL OR l.status::text=p_status) AND (query IS NULL OR l.kibo_search_simple @@ query)
 ORDER BY l.created_at DESC,l.id LIMIT 20 OFFSET p_offset;
END $$;
REVOKE ALL ON ALL TABLES IN SCHEMA kibo_discovery_private FROM PUBLIC,anon,authenticated;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA kibo_discovery_private FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION kibo_discovery_private.normalize(text),kibo_discovery_private.plan(text),
 kibo_discovery_private.score(text,tsvector,text,tsquery) TO anon,authenticated;
REVOKE ALL ON FUNCTION public.kibo_search_listings(text,uuid,text,numeric,numeric,text,integer),
 public.kibo_search_suggestions(text,uuid,text,numeric,numeric),public.kibo_search_owned(text,text,integer)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_search_listings(text,uuid,text,numeric,numeric,text,integer),
 public.kibo_search_suggestions(text,uuid,text,numeric,numeric) TO anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_search_owned(text,text,integer) TO authenticated;
COMMIT;
