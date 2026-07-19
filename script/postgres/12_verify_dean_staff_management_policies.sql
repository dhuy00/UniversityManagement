-- Rollback-only verification for CS#5 Dean staff management policies.

BEGIN;
SET search_path TO university, public;

CREATE ROLE verify_dean_staff NOLOGIN;
GRANT USAGE ON SCHEMA university TO verify_dean_staff;
GRANT SELECT, INSERT, UPDATE, DELETE ON staff TO verify_dean_staff;
GRANT SELECT ON app_users TO verify_dean_staff;

DO $$
BEGIN
    ASSERT (
        SELECT count(*) = 3
        FROM pg_catalog.pg_policies
        WHERE schemaname = 'university'
          AND policyname IN (
              'staff_insert_all_dean',
              'staff_update_all_dean',
              'staff_delete_all_dean'
          )
    ), 'Expected all three Dean staff management policies';
END;
$$;

INSERT INTO units (unit_id, unit_name)
VALUES
    ('V_DSM_UNIT_1', 'Dean staff verification unit 1'),
    ('V_DSM_UNIT_2', 'Dean staff verification unit 2');

INSERT INTO app_users (username, password_hash)
VALUES
    ('V_DSM_DEAN', 'test-only'),
    ('V_DSM_BASIC', 'test-only'),
    ('V_DSM_TARGET', 'test-only'),
    ('V_DSM_NEW', 'test-only'),
    ('V_DSM_DENIED', 'test-only');

INSERT INTO staff (
    staff_id, user_id, full_name, gender, date_of_birth, allowance,
    phone, unit_id, campus_id
)
SELECT 'V_DSM_DEAN', user_id, 'Verification Dean', 'OTHER',
       DATE '1980-01-01', 0, NULL, 'V_DSM_UNIT_1', 'CAMPUS_1'
FROM app_users WHERE username = 'V_DSM_DEAN'
UNION ALL
SELECT 'V_DSM_BASIC', user_id, 'Verification Basic Staff', 'OTHER',
       DATE '1990-01-01', 0, '100', 'V_DSM_UNIT_1', 'CAMPUS_1'
FROM app_users WHERE username = 'V_DSM_BASIC'
UNION ALL
SELECT 'V_DSM_TARGET', user_id, 'Verification Target Staff', 'OTHER',
       DATE '1991-01-01', 10, '200', 'V_DSM_UNIT_2', 'CAMPUS_2'
FROM app_users WHERE username = 'V_DSM_TARGET';

INSERT INTO app_user_roles (user_id, role_code)
SELECT user_id, 'DEAN' FROM app_users WHERE username = 'V_DSM_DEAN'
UNION ALL
SELECT user_id, 'BASIC_STAFF' FROM app_users
WHERE username IN ('V_DSM_BASIC', 'V_DSM_TARGET');

-- A Dean can change every mutable staff attribute and create staff globally.
SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_DSM_DEAN';
SET LOCAL ROLE verify_dean_staff;

UPDATE university.staff
SET full_name = 'Dean Updated Target',
    gender = 'FEMALE',
    date_of_birth = DATE '1992-02-02',
    allowance = 250,
    phone = '999',
    unit_id = 'V_DSM_UNIT_1',
    campus_id = 'CAMPUS_1'
WHERE staff_id = 'V_DSM_TARGET';

INSERT INTO university.staff (
    staff_id, user_id, full_name, gender, date_of_birth, allowance,
    phone, unit_id, campus_id
)
SELECT 'V_DSM_NEW', user_id, 'Dean Created Staff', 'OTHER',
       DATE '1993-03-03', 25, '300', 'V_DSM_UNIT_2', 'CAMPUS_2'
FROM university.app_users WHERE username = 'V_DSM_NEW';

DELETE FROM university.staff WHERE staff_id = 'V_DSM_NEW';
RESET ROLE;

DO $$
BEGIN
    ASSERT EXISTS (
        SELECT 1 FROM staff
        WHERE staff_id = 'V_DSM_TARGET'
          AND full_name = 'Dean Updated Target'
          AND gender = 'FEMALE'
          AND date_of_birth = DATE '1992-02-02'
          AND allowance = 250
          AND phone = '999'
          AND unit_id = 'V_DSM_UNIT_1'
          AND campus_id = 'CAMPUS_1'
    ), 'Dean could not update all staff attributes';
    ASSERT NOT EXISTS (
        SELECT 1 FROM staff WHERE staff_id = 'V_DSM_NEW'
    ), 'Dean staff create/delete workflow did not complete';
END;
$$;

-- A basic staff member remains limited to the existing self-service policy.
SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_DSM_BASIC';
SET LOCAL ROLE verify_dean_staff;

UPDATE university.staff SET allowance = 999
WHERE staff_id = 'V_DSM_TARGET';
DELETE FROM university.staff WHERE staff_id = 'V_DSM_TARGET';

DO $$
BEGIN
    BEGIN
        INSERT INTO university.staff (
            staff_id, user_id, full_name, gender, date_of_birth,
            allowance, unit_id, campus_id
        )
        SELECT 'V_DSM_DENIED', user_id, 'Denied Staff', 'OTHER',
               DATE '1994-04-04', 0, 'V_DSM_UNIT_1', 'CAMPUS_1'
        FROM university.app_users WHERE username = 'V_DSM_DENIED';
        RAISE EXCEPTION 'Basic staff created a staff row';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;

RESET ROLE;

DO $$
BEGIN
    ASSERT (SELECT allowance FROM staff WHERE staff_id = 'V_DSM_TARGET') = 250,
        'Basic staff changed another staff member';
    ASSERT EXISTS (SELECT 1 FROM staff WHERE staff_id = 'V_DSM_TARGET'),
        'Basic staff deleted another staff member';
    ASSERT NOT EXISTS (SELECT 1 FROM staff WHERE staff_id = 'V_DSM_DENIED'),
        'Basic staff created a staff member';
END;
$$;

-- Missing identity context must fail closed for every write operation.
SELECT clear_security_context();
SET LOCAL ROLE verify_dean_staff;

UPDATE university.staff SET allowance = 777;
DELETE FROM university.staff;

DO $$
BEGIN
    BEGIN
        INSERT INTO university.staff (
            staff_id, user_id, full_name, gender, date_of_birth,
            allowance, unit_id, campus_id
        )
        SELECT 'V_DSM_DENIED', user_id, 'Missing Context Staff', 'OTHER',
               DATE '1994-04-04', 0, 'V_DSM_UNIT_1', 'CAMPUS_1'
        FROM university.app_users WHERE username = 'V_DSM_DENIED';
        RAISE EXCEPTION 'Missing context created a staff row';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;

RESET ROLE;

DO $$
BEGIN
    ASSERT (SELECT allowance FROM staff WHERE staff_id = 'V_DSM_TARGET') = 250,
        'Missing context updated staff data';
    ASSERT EXISTS (SELECT 1 FROM staff WHERE staff_id = 'V_DSM_TARGET'),
        'Missing context deleted staff data';
    ASSERT NOT EXISTS (SELECT 1 FROM staff WHERE staff_id = 'V_DSM_DENIED'),
        'Missing context inserted staff data';
END;
$$;

SELECT 'Dean staff management policy verification passed' AS result;
ROLLBACK;
