-- 16_bootstrap_admin.sql
-- Create the first API login identity so the system is not empty after a
-- fresh schema build.  The plaintext password is hashed by a database trigger
-- at creation time (BCrypt via the application), so this seed uses a
-- pre-computed BCrypt hash for the placeholder password 'ChangeMe!2026'.
--
-- THIS IS A ONE-TIME BOOTSTRAP.  Rotate the password on first login.
--
-- Hash (BCrypt cost 12) for 'ChangeMe!2026':
--   $2a$12$LQ7wI9XGnQvRk6f5jJgKzeYZy4YIA1t3UvA1N9VZ3rkEHOxJrCyAO
--
-- The application hash path uses BCrypt.Net.BCrypt.HashPassword, so any
-- hash produced by the running API is also valid; this row is supplied here
-- so that psql can populate it without invoking the API.

INSERT INTO university.app_users (username, password_hash, is_active)
VALUES (
    'ADMIN',
    '$2a$12$LQ7wI9XGnQvRk6f5jJgKzeYZy4YIA1t3UvA1N9VZ3rkEHOxJrCyAO',
    TRUE
)
ON CONFLICT (lower(username)) DO NOTHING;

-- Grant every role to the bootstrap admin so it can verify each layer
-- of the policy stack during initial acceptance testing.  Real
-- environments should narrow this DOWN to the minimum set once
-- operational users are seeded.
INSERT INTO university.app_user_roles (user_id, role_code)
SELECT user_id, unnest(ARRAY[
    'BASIC_STAFF',
    'LECTURER',
    'ACADEMIC_AFFAIRS',
    'UNIT_HEAD',
    'DEAN'
]) AS role_code
FROM university.app_users
WHERE lower(username) = lower('ADMIN')
ON CONFLICT DO NOTHING;

SELECT user_id, username, is_active
FROM university.app_users
WHERE lower(username) = lower('ADMIN');
