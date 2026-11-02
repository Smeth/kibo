-- Index limité à la nouvelle table MVP ; aucune donnée ni permission changée.
BEGIN;
CREATE INDEX kibo_blocks_blocked_owner_idx ON public.kibo_user_blocks(blocked_id,owner_id);
COMMIT;
