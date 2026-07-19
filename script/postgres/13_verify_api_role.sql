-- Rollback-only catalogue verification for the restricted API group role.

BEGIN;
SET search_path TO university, public;

DO $$
DECLARE
    v_role record;
BEGIN
    SELECT * INTO v_role FROM pg_roles WHERE rolname = 'university_api';
    ASSERT FOUND, 'university_api role is missing';
    ASSERT NOT v_role.rolcanlogin, 'university_api must be NOLOGIN';
    ASSERT NOT v_role.rolsuper, 'university_api must not be superuser';
    ASSERT NOT v_role.rolcreatedb, 'university_api must not create databases';
    ASSERT NOT v_role.rolcreaterole, 'university_api must not create roles';
    ASSERT NOT v_role.rolbypassrls, 'university_api must not bypass RLS';

    ASSERT has_schema_privilege('university_api', 'university', 'USAGE'),
        'API role needs university schema usage';
    ASSERT NOT has_schema_privilege('university_api', 'university', 'CREATE'),
        'API role must not create schema objects';

    ASSERT has_table_privilege('university_api', 'students', 'SELECT'),
        'API role needs student reads';
    ASSERT has_column_privilege('university_api', 'students', 'address', 'UPDATE'),
        'API role needs student address updates';
    ASSERT has_column_privilege('university_api', 'students', 'phone', 'UPDATE'),
        'API role needs student phone updates';
    ASSERT NOT has_column_privilege(
        'university_api', 'students', 'full_name', 'UPDATE'
    ), 'API role must not update protected student columns';

    ASSERT has_column_privilege(
        'university_api', 'enrollments', 'student_id', 'INSERT'
    ) AND has_column_privilege(
        'university_api', 'enrollments', 'lecturer_id', 'INSERT'
    ) AND has_column_privilege(
        'university_api', 'enrollments', 'course_id', 'INSERT'
    ) AND has_column_privilege(
        'university_api', 'enrollments', 'semester', 'INSERT'
    ) AND has_column_privilege(
        'university_api', 'enrollments', 'academic_year', 'INSERT'
    ) AND has_column_privilege(
        'university_api', 'enrollments', 'program_id', 'INSERT'
    ), 'API role needs all enrollment identity-column inserts';
    ASSERT NOT has_column_privilege(
        'university_api', 'enrollments', 'final_score', 'INSERT'
    ), 'API role must not insert enrollment scores';
    ASSERT has_column_privilege(
        'university_api', 'enrollments', 'final_score', 'UPDATE'
    ), 'API role needs lecturer score updates';

    ASSERT has_function_privilege(
        'university_api', 'set_security_context(bigint)', 'EXECUTE'
    ), 'API role needs request-context initialization';
    ASSERT NOT has_table_privilege('university_api', 'app_users', 'SELECT'),
        'Domain API role must not read password hashes directly';

    ASSERT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'staff_update_column_guard' AND NOT tgisinternal
    ), 'Staff update column guard is missing';
END;
$$;

INSERT INTO units (unit_id, unit_name)
VALUES ('V_API_ROLE_UNIT', 'API role verification unit');

INSERT INTO app_users (username, password_hash)
VALUES ('V_API_BASIC', 'test-only'), ('V_API_DEAN', 'test-only');

INSERT INTO staff (
    staff_id, user_id, full_name, gender, date_of_birth, allowance,
    phone, unit_id, campus_id
)
SELECT 'V_API_BASIC', user_id, 'API Verification Basic', 'OTHER',
       DATE '1990-01-01', 10, '100', 'V_API_ROLE_UNIT', 'CAMPUS_1'
FROM app_users WHERE username = 'V_API_BASIC'
UNION ALL
SELECT 'V_API_DEAN', user_id, 'API Verification Dean', 'OTHER',
       DATE '1980-01-01', 20, '200', 'V_API_ROLE_UNIT', 'CAMPUS_1'
FROM app_users WHERE username = 'V_API_DEAN';

INSERT INTO app_user_roles (user_id, role_code)
SELECT user_id, 'BASIC_STAFF' FROM app_users WHERE username = 'V_API_BASIC'
UNION ALL
SELECT user_id, 'DEAN' FROM app_users WHERE username = 'V_API_DEAN';

-- The combined table grant must not widen Basic Staff beyond phone-only.
SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_API_BASIC';
SET LOCAL ROLE university_api;
UPDATE university.staff SET phone = '101' WHERE staff_id = 'V_API_BASIC';

DO $$
BEGIN
    BEGIN
        UPDATE university.staff
        SET allowance = allowance + 1
        WHERE staff_id = 'V_API_BASIC';
        RAISE EXCEPTION 'Basic Staff unexpectedly updated allowance';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;
RESET ROLE;

-- Dean management retains legitimate full-row updates through the same role.
SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_API_DEAN';
SET LOCAL ROLE university_api;
UPDATE university.staff
SET full_name = 'API Verification Dean Updated', allowance = 25
WHERE staff_id = 'V_API_BASIC';
RESET ROLE;

DO $$
BEGIN
    ASSERT EXISTS (
        SELECT 1 FROM staff
        WHERE staff_id = 'V_API_BASIC'
          AND full_name = 'API Verification Dean Updated'
          AND allowance = 25
          AND phone = '101'
    ), 'Staff column guard did not preserve Basic Staff and Dean behavior';
END;
$$;

SELECT 'restricted API role verification passed' AS result;
ROLLBACK;
