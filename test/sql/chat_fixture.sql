-- Fixture locale uniquement : contrat public audité, aucune donnée réelle.
CREATE TYPE public.message_type AS ENUM ('text','image');
CREATE TABLE public.conversations (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), listing_id uuid NOT NULL REFERENCES public.listings ON DELETE RESTRICT,
 buyer_id uuid NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
 seller_id uuid NOT NULL REFERENCES public.profiles ON DELETE CASCADE,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 CHECK (buyer_id <> seller_id), UNIQUE(listing_id,buyer_id)
);
CREATE TABLE public.messages (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), conversation_id uuid NOT NULL REFERENCES public.conversations ON DELETE CASCADE,
 sender_id uuid NOT NULL REFERENCES public.profiles ON DELETE RESTRICT,
 content text NOT NULL CHECK (char_length(trim(content)) BETWEEN 1 AND 5000),
 message_type public.message_type NOT NULL DEFAULT 'text', attachment_path text, read_at timestamptz, created_at timestamptz NOT NULL DEFAULT now(),
 CHECK ((message_type='text' AND attachment_path IS NULL) OR (message_type='image' AND attachment_path IS NOT NULL))
);
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY conversations_insert_buyer ON public.conversations FOR INSERT TO authenticated
 WITH CHECK (buyer_id=auth.uid() AND seller_id<>auth.uid());
CREATE POLICY conversations_read_participants ON public.conversations FOR SELECT TO authenticated
 USING (buyer_id=auth.uid() OR seller_id=auth.uid() OR private.is_admin());
CREATE POLICY messages_insert_participants ON public.messages FOR INSERT TO authenticated
 WITH CHECK (sender_id=auth.uid() AND EXISTS (SELECT 1 FROM public.conversations c WHERE c.id=conversation_id AND auth.uid() IN (c.buyer_id,c.seller_id)));
CREATE POLICY messages_read_participants ON public.messages FOR SELECT TO authenticated
 USING (EXISTS (SELECT 1 FROM public.conversations c WHERE c.id=conversation_id AND (auth.uid() IN(c.buyer_id,c.seller_id) OR private.is_admin())));
GRANT SELECT,INSERT,UPDATE,DELETE ON public.conversations,public.messages TO anon,authenticated;
CREATE FUNCTION private.validate_conversation() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actual_seller uuid; actual_status public.listing_status;
BEGIN
 SELECT seller_id,status INTO actual_seller,actual_status FROM public.listings WHERE id=new.listing_id;
 IF NOT FOUND OR actual_status<>'published' OR actual_seller<>new.seller_id THEN RAISE EXCEPTION 'Annonce ou vendeur invalide'; END IF;
 IF new.buyer_id=new.seller_id THEN RAISE EXCEPTION 'Conversation avec soi-même interdite'; END IF;
 RETURN new;
END $$;
CREATE FUNCTION private.validate_message_sender() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM public.conversations c WHERE c.id=new.conversation_id AND new.sender_id IN(c.buyer_id,c.seller_id)) THEN RAISE EXCEPTION 'Expéditeur non autorisé'; END IF;
 RETURN new;
END $$;
CREATE FUNCTION private.update_conversation_timestamp() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN UPDATE public.conversations SET updated_at=now() WHERE id=new.conversation_id; RETURN new; END $$;
CREATE TRIGGER conversations_validate BEFORE INSERT ON public.conversations FOR EACH ROW EXECUTE FUNCTION private.validate_conversation();
CREATE TRIGGER messages_validate BEFORE INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION private.validate_message_sender();
CREATE TRIGGER messages_update_conversation AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION private.update_conversation_timestamp();
CREATE PUBLICATION supabase_realtime;
INSERT INTO public.profiles VALUES ('33333333-3333-4333-8333-333333333333');
INSERT INTO public.listings(id,seller_id,category_id,title,description,price,status) VALUES
 ('cccccccc-cccc-4ccc-8ccc-cccccccccccc','11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Annonce chat test','Annonce fictive pour chat',1000,'published');
