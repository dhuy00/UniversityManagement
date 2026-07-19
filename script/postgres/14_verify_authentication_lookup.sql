-- Rollback-only verification for 14_authentication_lookup.sql.
-- Run as the schema owner after applying the authentication lookup.

BEGIN;
SET search_path TO university, public;

DO $$
DECLARE
    active_user_id bigint;
    inactive_user_id bigint;
    missing_role_user_id bigint;
    malformed_user_id bigint;
    candidate record;
BEGIN
    INSERT INTO campuses (campus_id, campus_name)
    VALUES ('AUTH_TEST_CAMP', 'Authentication Test Campus')
    ON CONFLICT (campus_id) DO NOTHING;

    INSERT INTO units (unit_id, unit_name)
    VALUES ('AUTH_TEST_UNIT', 'Authentication Test Unit')
    ON CONFLICT (unit_id) DO NOTHING;

    INSERT INTO app_users (username, password_hash)
    VALUES ('AUTH_TEST_ACTIVE', '$2a$12$authentication.test.hash.active')
    RETURNING user_id INTO active_user_id;

    INSERT INTO app_user_roles (user_id, role_code)
    VALUES (active_user_id, 'BASIC_STAFF');

    INSERT INTO staff (
        staff_id, user_id, full_name, gender, date_of_birth,
        allowance, unit_id, campus_id
    ) VALUES (
        'AUTH_TEST_STAFF', active_user_id, 'Authentication Test Staff',
        'OTHER', DATE '1990-01-01', 0, 'AUTH_TEST_UNIT', 'AUTH_TEST_CAMP'
    );

    INSERT INTO app_users (username, password_hash, is_active)
    VALUES ('AUTH_TEST_INACTIVE', '$2a$12$authentication.test.hash.inactive', false)
    RETURNING user_id INTO inactive_user_id;

    INSERT INTO app_users (username, password_hash)
    VALUES ('AUTH_TEST_NO_ROLE', '$2a$12$authentication.test.hash.no.role')
    RETURNING user_id INTO missing_role_user_id;

    INSERT INTO staff (
        staff_id, user_id, full_name, gender, date_of_birth,
        allowance, unit_id, campus_id
    ) VALUES (
        'AUTH_TEST_NOROLE', missing_role_user_id, 'Authentication Test No Role',
        'OTHER', DATE '1990-01-01', 0, 'AUTH_TEST_UNIT', 'AUTH_TEST_CAMP'
    );

    INSERT INTO app_users (username, password_hash)
    VALUES ('AUTH_TEST_NO_ID', '$2a$12$authentication.test.hash.no.identity')
    RETURNING user_id INTO malformed_user_id;

    EXECUTE 'SET LOCAL ROLE university_authenticator';

    IF has_table_privilege('university_authenticator',
                           'university.app_users', 'SELECT') THEN
        RAISE EXCEPTION 'Authenticator must not have direct app_users SELECT';
    END IF;

    SELECT * INTO candidate
    FROM university.find_active_authentication_candidate(' auth_test_active ');

    IF candidate.user_id IS DISTINCT FROM active_user_id OR
       candidate.username IS DISTINCT FROM 'AUTH_TEST_ACTIVE' OR
       candidate.password_hash IS DISTINCT FROM
           '$2a$12$authentication.test.hash.active' OR
       candidate.role_codes IS DISTINCT FROM ARRAY['BASIC_STAFF']::text[] OR
       candidate.identity_type IS DISTINCT FROM 'STAFF' OR
       candidate.staff_id IS DISTINCT FROM 'AUTH_TEST_STAFF' OR
       candidate.student_id IS NOT NULL OR
       candidate.unit_id IS DISTINCT FROM 'AUTH_TEST_UNIT' OR
       candidate.campus_id IS DISTINCT FROM 'AUTH_TEST_CAMP' THEN
        RAISE EXCEPTION 'Active authentication candidate mapping is incorrect';
    END IF;

    IF EXISTS (
        SELECT 1 FROM university.find_active_authentication_candidate(
            'AUTH_TEST_INACTIVE'
        )
    ) THEN
        RAISE EXCEPTION 'Inactive user must not be returned';
    END IF;

    IF EXISTS (
        SELECT 1 FROM university.find_active_authentication_candidate(
            'AUTH_TEST_UNKNOWN'
        )
    ) THEN
        RAISE EXCEPTION 'Unknown user must not be returned';
    END IF;

    SELECT * INTO candidate
    FROM university.find_active_authentication_candidate('AUTH_TEST_NO_ROLE');
    IF candidate.user_id IS DISTINCT FROM missing_role_user_id OR
       cardinality(candidate.role_codes) <> 0 THEN
        RAISE EXCEPTION 'Missing-role candidate mapping is incorrect';
    END IF;

    SELECT * INTO candidate
    FROM university.find_active_authentication_candidate('AUTH_TEST_NO_ID');
    IF candidate.user_id IS DISTINCT FROM malformed_user_id OR
       candidate.identity_type IS NOT NULL THEN
        RAISE EXCEPTION 'Malformed identity must remain unresolved';
    END IF;

    RAISE NOTICE 'authentication lookup verification passed';
END;
$$;

ROLLBACK;
