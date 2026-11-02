CREATE TABLE auth.users(id uuid PRIMARY KEY,raw_app_meta_data jsonb);
CREATE TABLE auth.mfa_factors(user_id uuid,status text);
INSERT INTO auth.users VALUES('33333333-3333-4333-8333-333333333333','{"role":"admin"}');
