-- Métadonnées seulement, aucune lecture de contenu métier ou écriture.
SELECT to_regprocedure('kibo_mvp_private.can_send(uuid)')::text AS can_send,
 to_regprocedure('public.kibo_chat_message_actions(uuid)')::text AS message_actions,
 to_regclass('public.kibo_message_action_log')::text AS action_log,
 (SELECT relrowsecurity FROM pg_class WHERE oid='public.messages'::regclass) AS messages_rls,
 has_any_column_privilege('authenticated','public.messages','UPDATE') AS client_update,
 has_table_privilege('authenticated','public.messages','DELETE') AS client_delete,
 (SELECT jsonb_agg(jsonb_build_object('name',column_name,'type',data_type)) FROM information_schema.columns WHERE table_schema='public' AND table_name='messages') AS columns;

SELECT pg_get_functiondef('kibo_mvp_private.can_send(uuid)'::regprocedure) AS send_guard,
 (SELECT jsonb_agg(jsonb_build_object('name',tgname,'definition',pg_get_triggerdef(oid))) FROM pg_trigger WHERE tgrelid='public.messages'::regclass AND NOT tgisinternal) AS triggers,
 has_table_privilege('authenticated','public.messages','INSERT') AS table_insert,
 has_column_privilege('authenticated','public.messages','created_at','INSERT') AS created_at_insert,
 has_table_privilege('authenticated','public.messages','SELECT') AS table_select,
 (SELECT jsonb_agg(conname) FROM pg_constraint WHERE conrelid='public.messages'::regclass AND contype='c') AS checks;
