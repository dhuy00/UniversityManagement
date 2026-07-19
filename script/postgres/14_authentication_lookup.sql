-- Trusted authentication lookup for the API login flow.
-- Apply after 13_api_role.sql. The dedicated authentication login receives
-- EXECUTE on this function, not direct access to password or protected tables.

BEGIN;
SET search_path TO university, public;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'university_authenticator'
    ) THEN
        CREATE ROLE university_authenticator NOLOGIN NOSUPERUSER NOCREATEDB
            NOCREATEROLE NOINHERIT NOBYPASSRLS;
    END IF;
END;
$$;

ALTER ROLE university_authenticator NOLOGIN NOSUPERUSER NOCREATEDB
    NOCREATEROLE NOINHERIT NOBYPASSRLS;

CREATE OR REPLACE FUNCTION find_active_authentication_candidate(
    p_username varchar
)
RETURNS TABLE (
    user_id bigint,
    username varchar(128),
    password_hash varchar(255),
    role_codes text[],
    identity_type text,
    staff_id varchar(20),
    student_id varchar(20),
    unit_id varchar(20),
    program_id varchar(20),
    major_id varchar(20),
    campus_id varchar(20)
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT
        u.user_id,
        u.username,
        u.password_hash,
        ARRAY(
            SELECT ur.role_code::text
            FROM university.app_user_roles AS ur
            WHERE ur.user_id = u.user_id
            ORDER BY ur.role_code
        ),
        CASE
            WHEN s.staff_id IS NOT NULL AND st.student_id IS NULL THEN 'STAFF'
            WHEN st.student_id IS NOT NULL AND s.staff_id IS NULL THEN 'STUDENT'
            ELSE NULL
        END,
        s.staff_id,
        st.student_id,
        s.unit_id,
        st.program_id,
        st.major_id,
        COALESCE(s.campus_id, st.campus_id)
    FROM university.app_users AS u
    LEFT JOIN university.staff AS s ON s.user_id = u.user_id
    LEFT JOIN university.students AS st ON st.user_id = u.user_id
    WHERE lower(u.username) = lower(btrim(p_username))
      AND u.is_active;
$$;

REVOKE ALL ON FUNCTION find_active_authentication_candidate(varchar)
    FROM PUBLIC;
GRANT USAGE ON SCHEMA university TO university_authenticator;
GRANT EXECUTE ON FUNCTION find_active_authentication_candidate(varchar)
    TO university_authenticator;

COMMIT;
