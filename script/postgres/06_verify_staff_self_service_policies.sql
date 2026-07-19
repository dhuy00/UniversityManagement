-- Rollback-only verification for CS#1 staff self-service RLS.

BEGIN;
SET search_path TO university, public;

CREATE ROLE verify_staff_self_service NOLOGIN;
GRANT USAGE ON SCHEMA university TO verify_staff_self_service;
GRANT SELECT ON staff, students, course_plans TO verify_staff_self_service;
GRANT UPDATE (phone) ON staff TO verify_staff_self_service;

DO $$
BEGIN
    ASSERT (
        SELECT relrowsecurity
        FROM pg_catalog.pg_class AS c
        JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname = 'university' AND c.relname = 'staff'
    ), 'Expected RLS to be enabled on staff';

    ASSERT (
        SELECT count(*) = 4
        FROM pg_catalog.pg_policies
        WHERE schemaname = 'university'
          AND policyname IN (
              'staff_select_self',
              'staff_update_phone_self',
              'students_select_all_staff',
              'course_plans_select_all_staff'
          )
    ), 'Expected all four CS#1 staff policies';
END;
$$;

INSERT INTO units (unit_id, unit_name)
VALUES ('V_STAFF_UNIT', 'Staff self-service verification unit');

INSERT INTO app_users (username, password_hash)
VALUES
    ('V_BASIC_STAFF_1', 'test-only'),
    ('V_BASIC_STAFF_2', 'test-only'),
    ('V_STAFF_STUDENT_1', 'test-only'),
    ('V_STAFF_STUDENT_2', 'test-only');

INSERT INTO staff (
    staff_id, user_id, full_name, gender, date_of_birth, allowance, phone,
    unit_id, campus_id
)
SELECT
    'V_BASIC_STAFF_1', user_id, 'Verification Basic Staff 1', 'OTHER',
    DATE '1990-01-01', 100, '1001', 'V_STAFF_UNIT', 'CAMPUS_1'
FROM app_users WHERE username = 'V_BASIC_STAFF_1'
UNION ALL
SELECT
    'V_BASIC_STAFF_2', user_id, 'Verification Basic Staff 2', 'OTHER',
    DATE '1990-01-02', 200, '1002', 'V_STAFF_UNIT', 'CAMPUS_2'
FROM app_users WHERE username = 'V_BASIC_STAFF_2';

INSERT INTO students (
    student_id, user_id, full_name, gender, date_of_birth,
    program_id, major_id, campus_id
)
SELECT
    'V_STAFF_STUDENT_1', user_id, 'Verification Student 1', 'OTHER',
    DATE '2000-01-01', 'REGULAR', 'IS', 'CAMPUS_1'
FROM app_users WHERE username = 'V_STAFF_STUDENT_1'
UNION ALL
SELECT
    'V_STAFF_STUDENT_2', user_id, 'Verification Student 2', 'OTHER',
    DATE '2000-01-02', 'HIGH_QUALITY', 'SE', 'CAMPUS_2'
FROM app_users WHERE username = 'V_STAFF_STUDENT_2';

INSERT INTO app_user_roles (user_id, role_code)
SELECT user_id, 'BASIC_STAFF'
FROM app_users
WHERE username IN ('V_BASIC_STAFF_1', 'V_BASIC_STAFF_2')
UNION ALL
SELECT user_id, 'STUDENT'
FROM app_users
WHERE username IN ('V_STAFF_STUDENT_1', 'V_STAFF_STUDENT_2');

INSERT INTO courses (
    course_id, course_name, credits, theory_periods, practice_periods,
    max_students, unit_id
) VALUES
    ('V_STAFF_COURSE_1', 'Staff Verification Course 1', 3, 30, 15, 50,
     'V_STAFF_UNIT'),
    ('V_STAFF_COURSE_2', 'Staff Verification Course 2', 3, 30, 15, 50,
     'V_STAFF_UNIT');

INSERT INTO course_plans (
    course_id, semester, academic_year, program_id, start_date
) VALUES
    ('V_STAFF_COURSE_1', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CURRENT_DATE),
    ('V_STAFF_COURSE_2', 1, extract(year FROM CURRENT_DATE)::smallint,
     'HIGH_QUALITY', CURRENT_DATE);

SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_BASIC_STAFF_1';
SET LOCAL ROLE verify_staff_self_service;

DO $$
BEGIN
    ASSERT (
        SELECT array_agg(staff_id ORDER BY staff_id) FROM university.staff
    ) = ARRAY['V_BASIC_STAFF_1']::varchar[],
        'Basic staff could not see exactly their own staff profile';
    ASSERT (SELECT count(*) FROM university.students) = 2,
        'Basic staff could not read all student rows';
    ASSERT (SELECT count(*) FROM university.course_plans) = 2,
        'Basic staff could not read all course plans';
END;
$$;

UPDATE university.staff SET phone = '9999'
WHERE staff_id = 'V_BASIC_STAFF_1';
UPDATE university.staff SET phone = 'Cross overwrite'
WHERE staff_id = 'V_BASIC_STAFF_2';

DO $$
BEGIN
    ASSERT (
        SELECT phone = '9999'
        FROM university.staff WHERE staff_id = 'V_BASIC_STAFF_1'
    ), 'Basic staff could not update their own phone';

    BEGIN
        UPDATE university.staff SET allowance = 999999
        WHERE staff_id = 'V_BASIC_STAFF_1';
        RAISE EXCEPTION 'Protected staff allowance update was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;

RESET ROLE;

DO $$
BEGIN
    ASSERT (
        SELECT phone = '1002'
        FROM staff WHERE staff_id = 'V_BASIC_STAFF_2'
    ), 'Cross-staff phone update changed protected data';
END;
$$;

-- A student retains their existing own-row policies but receives no staff
-- visibility from the new CS#1 staff policies.
SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_STAFF_STUDENT_1';
SET LOCAL ROLE verify_staff_self_service;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM university.staff) = 0,
        'Student unexpectedly received staff visibility';
    ASSERT (
        SELECT array_agg(student_id ORDER BY student_id)
        FROM university.students
    ) = ARRAY['V_STAFF_STUDENT_1']::varchar[],
        'Student own-profile policy was changed by staff policies';
    ASSERT (
        SELECT array_agg(program_id ORDER BY program_id)
        FROM university.course_plans
    ) = ARRAY['REGULAR']::varchar[],
        'Student own-program policy was changed by staff policies';
END;
$$;

RESET ROLE;
SELECT clear_security_context();
SET LOCAL ROLE verify_staff_self_service;

UPDATE university.staff SET phone = 'No context'
WHERE staff_id = 'V_BASIC_STAFF_1';

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM university.staff) = 0,
        'Missing context exposed staff rows';
    ASSERT (SELECT count(*) FROM university.students) = 0,
        'Missing context exposed student rows';
    ASSERT (SELECT count(*) FROM university.course_plans) = 0,
        'Missing context exposed course-plan rows';
END;
$$;

RESET ROLE;

DO $$
BEGIN
    ASSERT (
        SELECT phone = '9999'
        FROM staff WHERE staff_id = 'V_BASIC_STAFF_1'
    ), 'Missing-context phone update changed data';
END;
$$;

SELECT 'staff self-service policy verification passed' AS result;
ROLLBACK;
