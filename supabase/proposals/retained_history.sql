-- Proposition locale NON DEPLOYEE. Aucun import ou effacement automatique.
-- Seuls des contenus revus peuvent etre verses par un futur worker serveur.
BEGIN;
CREATE SCHEMA kibo_history_private;
REVOKE ALL ON SCHEMA kibo_history_private FROM PUBLIC,anon,authenticated;
GRANT USAGE ON SCHEMA kibo_history_private TO authenticated;
CREATE TABLE public.kibo_retained_threads(
 owner_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 id uuid NOT NULL, created_at timestamptz NOT NULL DEFAULT now(),last_at timestamptz,
 expires_at timestamptz NOT NULL,policy_version text NOT NULL,
 PRIMARY KEY(owner_id,id), CHECK(expires_at>created_at),
 CHECK(char_length(trim(policy_version)) BETWEEN 1 AND 64)
);
CREATE TABLE public.kibo_retained_messages(
 owner_id uuid NOT NULL,thread_id uuid NOT NULL,id uuid NOT NULL,
 from_survivor boolean NOT NULL,content text NOT NULL,created_at timestamptz NOT NULL,
 PRIMARY KEY(owner_id,id),FOREIGN KEY(owner_id,thread_id) REFERENCES public.kibo_retained_threads(owner_id,id) ON DELETE CASCADE,
 CHECK(char_length(trim(content)) BETWEEN 1 AND 5000),
 CHECK(from_survivor OR content='Message anonymisé')
);
CREATE TABLE public.kibo_retained_comments(
 owner_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 id uuid NOT NULL,context_id uuid NOT NULL,parent_id uuid,
 from_survivor boolean NOT NULL,content text NOT NULL,created_at timestamptz NOT NULL,
 expires_at timestamptz NOT NULL,policy_version text NOT NULL,
 PRIMARY KEY(owner_id,id),CHECK(expires_at>created_at),
 CHECK(char_length(trim(policy_version)) BETWEEN 1 AND 64),
 CHECK(char_length(trim(content)) BETWEEN 1 AND 2000),
 CHECK(from_survivor OR content='Commentaire anonymisé')
);
ALTER TABLE public.kibo_retained_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kibo_retained_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kibo_retained_comments ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kibo_retained_threads,public.kibo_retained_messages,public.kibo_retained_comments FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.kibo_retained_threads,public.kibo_retained_messages,public.kibo_retained_comments TO authenticated;
CREATE POLICY kibo_retained_threads_own ON public.kibo_retained_threads FOR SELECT TO authenticated USING(owner_id=(SELECT auth.uid()) AND expires_at>now());
CREATE POLICY kibo_retained_comments_own ON public.kibo_retained_comments FOR SELECT TO authenticated USING(owner_id=(SELECT auth.uid()) AND expires_at>now());
CREATE POLICY kibo_retained_messages_own ON public.kibo_retained_messages FOR SELECT TO authenticated USING(owner_id=(SELECT auth.uid()) AND EXISTS(SELECT 1 FROM public.kibo_retained_threads t WHERE t.owner_id=kibo_retained_messages.owner_id AND t.id=thread_id AND t.expires_at>now()));
CREATE INDEX kibo_retained_threads_expiry ON public.kibo_retained_threads(expires_at);
CREATE INDEX kibo_retained_messages_thread_date ON public.kibo_retained_messages(owner_id,thread_id,created_at DESC,id);
CREATE INDEX kibo_retained_comments_expiry ON public.kibo_retained_comments(expires_at);
CREATE FUNCTION kibo_history_private.threads(p_offset integer) RETURNS SETOF jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT jsonb_build_object('id',id,'listing_id',NULL,'buyer_id',owner_id,'seller_id',NULL,
 'title','Annonce retirée','peer_name','Compte supprimé','last_content',NULL,'last_at',last_at,
 'unread_count',0,'blocked',true,'blocked_by_me',false,'peer_deleted',true)
 FROM public.kibo_retained_threads WHERE owner_id=auth.uid() AND expires_at>now()
 ORDER BY last_at DESC NULLS LAST,id LIMIT 20 OFFSET greatest(0,least(coalesce(p_offset,0),100000))
$$;
CREATE FUNCTION kibo_history_private.messages(p_thread uuid,p_offset integer) RETURNS SETOF jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT jsonb_build_object('id',m.id,'sender_id',CASE WHEN m.from_survivor THEN m.owner_id ELSE NULL END,
 'sender_deleted',NOT m.from_survivor,'content',m.content,'created_at',m.created_at,'read_at',NULL)
 FROM public.kibo_retained_messages m JOIN public.kibo_retained_threads t ON t.owner_id=m.owner_id AND t.id=m.thread_id
 WHERE m.owner_id=auth.uid() AND t.expires_at>now() AND m.thread_id=p_thread
 ORDER BY m.created_at DESC,m.id DESC LIMIT 30 OFFSET greatest(0,least(coalesce(p_offset,0),100000))
$$;
CREATE FUNCTION kibo_history_private.comments(p_offset integer) RETURNS SETOF jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT jsonb_build_object('id',id,'user_id',CASE WHEN from_survivor THEN owner_id ELSE NULL END,
 'author_deleted',NOT from_survivor,'content',content,'created_at',created_at,'parent_id',parent_id,
 'status','published','deleted_at',NULL,'retained',true)
 FROM public.kibo_retained_comments WHERE owner_id=auth.uid() AND expires_at>now()
 ORDER BY created_at DESC,id DESC LIMIT 20 OFFSET greatest(0,least(coalesce(p_offset,0),100000))
$$;
CREATE FUNCTION public.kibo_retained_threads(p_offset integer DEFAULT 0) RETURNS SETOF jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT * FROM kibo_history_private.threads(p_offset) $$;
CREATE FUNCTION public.kibo_retained_messages(p_thread uuid,p_offset integer DEFAULT 0) RETURNS SETOF jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT * FROM kibo_history_private.messages(p_thread,p_offset) $$;
CREATE FUNCTION public.kibo_retained_comments(p_offset integer DEFAULT 0) RETURNS SETOF jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT * FROM kibo_history_private.comments(p_offset) $$;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA kibo_history_private FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA kibo_history_private TO authenticated;
REVOKE ALL ON FUNCTION public.kibo_retained_threads(integer),public.kibo_retained_messages(uuid,integer),public.kibo_retained_comments(integer) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.kibo_retained_threads(integer),public.kibo_retained_messages(uuid,integer),public.kibo_retained_comments(integer) TO authenticated;
-- Pas de droits d'ecriture client ni de role/endpoint de worker cree ici.
COMMIT;
