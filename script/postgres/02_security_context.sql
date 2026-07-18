-- PostgreSQL request security context. Apply after 01_schema.sql.
-- The API must set context and run repository work in the same transaction.
-- Transaction-local context prevents identity leaks through pooled connections.

BEGIN;
SET search_path TO university, public;

CREATE OR REPLACE FUNCTION current_app_user_id()
RETURNS bigint
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    context_value text := current_setting('university.app_user_id', true);
BEGIN
    IF context_value IS NULL OR context_value !~ '^[1-9][0-9]*$' THEN
        RETURN NULL;
    END IF;
    RETURN context_value::bigint;
END;
$$;

CREATE OR REPLACE FUNCTION set_security_context(p_user_id bigint)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
BEGIN
    IF p_user_id IS NULL OR NOT EXISTS (
        SELECT 1 FROM university.app_users AS u
        WHERE u.user_id = p_user_id AND u.is_active
    ) THEN
        RAISE EXCEPTION 'Active application user % does not exist', p_user_id
            USING ERRCODE = '28000';
    END IF;

    PERFORM pg_catalog.set_config(
        'university.app_user_id', p_user_id::text, true
    );
END;
$$;

CREATE OR REPLACE FUNCTION clear_security_context()
RETURNS void
LANGUAGE sql
VOLATILE
AS $$
    SELECT set_config('university.app_user_id', '', true)::void;
$$;

CREATE OR REPLACE FUNCTION current_app_username()
RETURNS varchar(128)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT u.username FROM university.app_users AS u
    WHERE u.user_id = university.current_app_user_id() AND u.is_active;
$$;

CREATE OR REPLACE FUNCTION current_staff_id()
RETURNS varchar(20)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT s.staff_id
    FROM university.staff AS s
    JOIN university.app_users AS u ON u.user_id = s.user_id
    WHERE s.user_id = university.current_app_user_id() AND u.is_active;
$$;

CREATE OR REPLACE FUNCTION current_student_id()
RETURNS varchar(20)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT s.student_id
    FROM university.students AS s
    JOIN university.app_users AS u ON u.user_id = s.user_id
    WHERE s.user_id = university.current_app_user_id() AND u.is_active;
$$;

CREATE OR REPLACE FUNCTION current_unit_id()
RETURNS varchar(20)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT s.unit_id
    FROM university.staff AS s
    JOIN university.app_users AS u ON u.user_id = s.user_id
    WHERE s.user_id = university.current_app_user_id() AND u.is_active;
$$;

CREATE OR REPLACE FUNCTION current_program_id()
RETURNS varchar(20)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT s.program_id
    FROM university.students AS s
    JOIN university.app_users AS u ON u.user_id = s.user_id
    WHERE s.user_id = university.current_app_user_id() AND u.is_active;
$$;

CREATE OR REPLACE FUNCTION current_major_id()
RETURNS varchar(20)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT s.major_id
    FROM university.students AS s
    JOIN university.app_users AS u ON u.user_id = s.user_id
    WHERE s.user_id = university.current_app_user_id() AND u.is_active;
$$;

CREATE OR REPLACE FUNCTION current_campus_id()
RETURNS varchar(20)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT identity.campus_id
    FROM (
        SELECT s.campus_id FROM university.staff AS s
        WHERE s.user_id = university.current_app_user_id()
        UNION ALL
        SELECT s.campus_id FROM university.students AS s
        WHERE s.user_id = university.current_app_user_id()
    ) AS identity
    LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION has_role(p_role_code varchar)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM university.app_user_roles AS ur
        JOIN university.app_users AS u ON u.user_id = ur.user_id
        WHERE ur.user_id = university.current_app_user_id()
          AND ur.role_code = p_role_code
          AND u.is_active
    );
$$;

CREATE OR REPLACE FUNCTION has_permission(p_permission_code varchar)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM university.app_user_roles AS ur
        JOIN university.role_permissions AS rp ON rp.role_code = ur.role_code
        JOIN university.app_users AS u ON u.user_id = ur.user_id
        WHERE ur.user_id = university.current_app_user_id()
          AND rp.permission_code = p_permission_code
          AND u.is_active
    );
$$;

-- Grant this explicitly to the future restricted API database role.
REVOKE ALL ON FUNCTION set_security_context(bigint) FROM PUBLIC;

COMMIT;
