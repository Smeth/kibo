-- Deploy only after the execution contract. Removes expired private copies hourly.
CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT cron.schedule('kibo-retained-history-expiry','17 * * * *','SELECT public.kibo_retained_expire()');
