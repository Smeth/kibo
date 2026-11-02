-- Historical delta. Must be followed by request_guard_anon_safe.sql on this project.
BEGIN;
ALTER FUNCTION public.kibo_request_guard() SECURITY INVOKER;
COMMIT;
