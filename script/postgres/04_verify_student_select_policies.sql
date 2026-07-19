-- Rollback-only verification for the student SELECT policies.

BEGIN;
SET search_path TO university, public;

CREATE ROLE verify_student_policy_reader NOLOGIN;
GRANT USAGE ON SCHEMA university TO verify_student_policy_reader;
GRANT SELECT ON students, course_plans, enrollments
    TO verify_student_policy_reader;

DO $$
BEGIN
    ASSERT (
        SELECT count(*) = 3
        FROM pg_catalog.pg_policies
        WHERE schemaname = 'university'
          AND policyname IN (
              'students_select_self',
              'course_plans_select_own_program',
              'enrollments_select_self'
          )
    ), 'Expected all three student SELECT policies';
END;
$$;

INSERT INTO units (unit_id, unit_name)
VALUES ('VERIFY_POLICY_UNIT', 'Student policy verification unit');

INSERT INTO app_users (username, password_hash)
VALUES
    ('VERIFY_POLICY_LECTURER', 'test-only'),
    ('VERIFY_POLICY_STUDENT_1', 'test-only'),
    ('VERIFY_POLICY_STUDENT_2', 'test-only');

INSERT INTO staff (
    staff_id, user_id, full_name, gender, date_of_birth, allowance,
    unit_id, campus_id
)
SELECT
    'V_POLICY_STAFF', user_id, 'Policy Verification Lecturer', 'OTHER',
    DATE '1990-01-01', 0, 'VERIFY_POLICY_UNIT', 'CAMPUS_1'
FROM app_users
WHERE username = 'VERIFY_POLICY_LECTURER';

INSERT INTO students (
    student_id, user_id, full_name, gender, date_of_birth,
    program_id, major_id, campus_id
)
SELECT
    'V_POLICY_STUDENT_1', user_id, 'Policy Verification Student 1',
    'OTHER', DATE '2000-01-01', 'REGULAR', 'IS', 'CAMPUS_1'
FROM app_users
WHERE username = 'VERIFY_POLICY_STUDENT_1'
UNION ALL
SELECT
    'V_POLICY_STUDENT_2', user_id, 'Policy Verification Student 2',
    'OTHER', DATE '2000-01-02', 'HIGH_QUALITY', 'SE', 'CAMPUS_2'
FROM app_users
WHERE username = 'VERIFY_POLICY_STUDENT_2';

INSERT INTO app_user_roles (user_id, role_code)
SELECT user_id, 'STUDENT'
FROM app_users
WHERE username IN ('VERIFY_POLICY_STUDENT_1', 'VERIFY_POLICY_STUDENT_2');

INSERT INTO courses (
    course_id, course_name, credits, theory_periods, practice_periods,
    max_students, unit_id
) VALUES
    ('V_POLICY_COURSE_1', 'Policy Verification Course 1', 3, 30, 15, 50,
     'VERIFY_POLICY_UNIT'),
    ('V_POLICY_COURSE_2', 'Policy Verification Course 2', 3, 30, 15, 50,
     'VERIFY_POLICY_UNIT');

INSERT INTO course_plans (
    course_id, semester, academic_year, program_id, start_date
) VALUES
    ('V_POLICY_COURSE_1', 1, 2026, 'REGULAR', DATE '2026-01-01'),
    ('V_POLICY_COURSE_2', 1, 2026, 'HIGH_QUALITY', DATE '2026-01-01');

INSERT INTO teaching_assignments (
    lecturer_id, course_id, semester, academic_year, program_id
) VALUES
    ('V_POLICY_STAFF', 'V_POLICY_COURSE_1', 1, 2026, 'REGULAR'),
    ('V_POLICY_STAFF', 'V_POLICY_COURSE_2', 1, 2026, 'HIGH_QUALITY');

INSERT INTO enrollments (
    student_id, lecturer_id, course_id, semester, academic_year, program_id
) VALUES
    ('V_POLICY_STUDENT_1', 'V_POLICY_STAFF',
     'V_POLICY_COURSE_1', 1, 2026, 'REGULAR'),
    ('V_POLICY_STUDENT_2', 'V_POLICY_STAFF',
     'V_POLICY_COURSE_2', 1, 2026, 'HIGH_QUALITY');

-- Student 1 sees only their identity, program, and enrollment.
SELECT set_security_context(user_id)
FROM app_users
WHERE username = 'VERIFY_POLICY_STUDENT_1';
SET LOCAL ROLE verify_student_policy_reader;

DO $$
BEGIN
    ASSERT (SELECT array_agg(student_id ORDER BY student_id) FROM university.students)
        = ARRAY['V_POLICY_STUDENT_1']::varchar[],
        'Student 1 could not see exactly their own profile';
    ASSERT (SELECT array_agg(program_id ORDER BY program_id) FROM university.course_plans)
        = ARRAY['REGULAR']::varchar[],
        'Student 1 could not see exactly their own program course plan';
    ASSERT (SELECT array_agg(student_id ORDER BY student_id) FROM university.enrollments)
        = ARRAY['V_POLICY_STUDENT_1']::varchar[],
        'Student 1 could not see exactly their own enrollment';
END;
$$;

RESET ROLE;

-- Student 2 proves that the policies follow the current context rather than
-- accidentally hard-coding or leaking Student 1's rows.
SELECT set_security_context(user_id)
FROM app_users
WHERE username = 'VERIFY_POLICY_STUDENT_2';
SET LOCAL ROLE verify_student_policy_reader;

DO $$
BEGIN
    ASSERT (SELECT array_agg(student_id ORDER BY student_id) FROM university.students)
        = ARRAY['V_POLICY_STUDENT_2']::varchar[],
        'Student 2 could not see exactly their own profile';
    ASSERT (SELECT array_agg(program_id ORDER BY program_id) FROM university.course_plans)
        = ARRAY['HIGH_QUALITY']::varchar[],
        'Student 2 could not see exactly their own program course plan';
    ASSERT (SELECT array_agg(student_id ORDER BY student_id) FROM university.enrollments)
        = ARRAY['V_POLICY_STUDENT_2']::varchar[],
        'Student 2 could not see exactly their own enrollment';
END;
$$;

RESET ROLE;
SELECT clear_security_context();
SET LOCAL ROLE verify_student_policy_reader;

-- Missing request identity must fail closed and expose no protected rows.
DO $$
BEGIN
    ASSERT (SELECT count(*) FROM university.students) = 0,
        'Missing context exposed student rows';
    ASSERT (SELECT count(*) FROM university.course_plans) = 0,
        'Missing context exposed course-plan rows';
    ASSERT (SELECT count(*) FROM university.enrollments) = 0,
        'Missing context exposed enrollment rows';
END;
$$;

RESET ROLE;
SELECT 'student SELECT policy verification passed' AS result;
ROLLBACK;
