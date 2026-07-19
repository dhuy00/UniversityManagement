-- Rollback-only verification for CS#5 Dean global policies.

BEGIN;
SET search_path TO university, public;

CREATE ROLE verify_dean_global NOLOGIN;
GRANT USAGE ON SCHEMA university TO verify_dean_global;
GRANT SELECT ON staff, students, course_plans, teaching_assignments,
    enrollments TO verify_dean_global;
GRANT INSERT, UPDATE, DELETE ON teaching_assignments TO verify_dean_global;

DO $$
BEGIN
    ASSERT (
        SELECT count(*) = 8
        FROM pg_catalog.pg_policies
        WHERE schemaname = 'university'
          AND policyname IN (
              'staff_select_all_dean',
              'students_select_all_dean',
              'course_plans_select_all_dean',
              'assignments_select_all_dean',
              'enrollments_select_all_dean',
              'assignments_insert_all_dean',
              'assignments_update_all_dean',
              'assignments_delete_all_dean'
          )
    ), 'Expected all eight Dean policies';
END;
$$;

INSERT INTO units (unit_id, unit_name)
VALUES
    ('V_DEAN_UNIT_1', 'Dean verification unit 1'),
    ('V_DEAN_UNIT_2', 'Dean verification unit 2');

INSERT INTO app_users (username, password_hash)
VALUES
    ('V_DEAN_USER', 'test-only'),
    ('V_DEAN_LECT_1', 'test-only'),
    ('V_DEAN_LECT_2', 'test-only'),
    ('V_DEAN_BASIC', 'test-only'),
    ('V_DEAN_STUDENT_1', 'test-only'),
    ('V_DEAN_STUDENT_2', 'test-only');

INSERT INTO staff (
    staff_id, user_id, full_name, gender, date_of_birth, allowance,
    unit_id, campus_id
)
SELECT 'V_DEAN_STAFF', user_id, 'Verification Dean', 'OTHER',
       DATE '1980-01-01', 0, 'V_DEAN_UNIT_1', 'CAMPUS_1'
FROM app_users WHERE username = 'V_DEAN_USER'
UNION ALL
SELECT 'V_DEAN_LECT_1', user_id, 'Verification Lecturer 1', 'OTHER',
       DATE '1990-01-01', 0, 'V_DEAN_UNIT_1', 'CAMPUS_1'
FROM app_users WHERE username = 'V_DEAN_LECT_1'
UNION ALL
SELECT 'V_DEAN_LECT_2', user_id, 'Verification Lecturer 2', 'OTHER',
       DATE '1990-01-02', 0, 'V_DEAN_UNIT_2', 'CAMPUS_2'
FROM app_users WHERE username = 'V_DEAN_LECT_2'
UNION ALL
SELECT 'V_DEAN_BASIC', user_id, 'Verification Basic Staff', 'OTHER',
       DATE '1990-01-03', 0, 'V_DEAN_UNIT_2', 'CAMPUS_2'
FROM app_users WHERE username = 'V_DEAN_BASIC';

INSERT INTO students (
    student_id, user_id, full_name, gender, date_of_birth,
    program_id, major_id, campus_id
)
SELECT 'V_DEAN_STUDENT_1', user_id, 'Verification Student 1', 'OTHER',
       DATE '2000-01-01', 'REGULAR', 'IS', 'CAMPUS_1'
FROM app_users WHERE username = 'V_DEAN_STUDENT_1'
UNION ALL
SELECT 'V_DEAN_STUDENT_2', user_id, 'Verification Student 2', 'OTHER',
       DATE '2000-01-02', 'HIGH_QUALITY', 'SE', 'CAMPUS_2'
FROM app_users WHERE username = 'V_DEAN_STUDENT_2';

INSERT INTO app_user_roles (user_id, role_code)
SELECT user_id, 'DEAN' FROM app_users WHERE username = 'V_DEAN_USER'
UNION ALL
SELECT user_id, 'LECTURER'
FROM app_users WHERE username IN ('V_DEAN_LECT_1', 'V_DEAN_LECT_2')
UNION ALL
SELECT user_id, 'BASIC_STAFF' FROM app_users WHERE username = 'V_DEAN_BASIC'
UNION ALL
SELECT user_id, 'STUDENT'
FROM app_users WHERE username IN ('V_DEAN_STUDENT_1', 'V_DEAN_STUDENT_2');

INSERT INTO courses (
    course_id, course_name, credits, theory_periods, practice_periods,
    max_students, unit_id
) VALUES
    ('V_DEAN_COURSE_1', 'Dean Verification Course 1', 3, 30, 15, 50,
     'V_DEAN_UNIT_1'),
    ('V_DEAN_COURSE_2', 'Dean Verification Course 2', 3, 30, 15, 50,
     'V_DEAN_UNIT_2'),
    ('V_DEAN_COURSE_3', 'Dean Verification Course 3', 3, 30, 15, 50,
     'V_DEAN_UNIT_2');

INSERT INTO course_plans (
    course_id, semester, academic_year, program_id, start_date
) VALUES
    ('V_DEAN_COURSE_1', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CURRENT_DATE),
    ('V_DEAN_COURSE_2', 1, extract(year FROM CURRENT_DATE)::smallint,
     'HIGH_QUALITY', CURRENT_DATE),
    ('V_DEAN_COURSE_3', 1, extract(year FROM CURRENT_DATE)::smallint,
     'HIGH_QUALITY', CURRENT_DATE);

INSERT INTO teaching_assignments (
    lecturer_id, course_id, semester, academic_year, program_id
) VALUES
    ('V_DEAN_LECT_1', 'V_DEAN_COURSE_1', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'),
    ('V_DEAN_LECT_2', 'V_DEAN_COURSE_2', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'HIGH_QUALITY');

INSERT INTO enrollments (
    student_id, lecturer_id, course_id, semester, academic_year, program_id
) VALUES
    ('V_DEAN_STUDENT_1', 'V_DEAN_LECT_1', 'V_DEAN_COURSE_1', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'),
    ('V_DEAN_STUDENT_2', 'V_DEAN_LECT_2', 'V_DEAN_COURSE_2', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'HIGH_QUALITY');

SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_DEAN_USER';
SET LOCAL ROLE verify_dean_global;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM university.staff) = 4,
        'Dean could not read all staff';
    ASSERT (SELECT count(*) FROM university.students) = 2,
        'Dean could not read all students';
    ASSERT (SELECT count(*) FROM university.course_plans) = 3,
        'Dean could not read all course plans';
    ASSERT (SELECT count(*) FROM university.teaching_assignments) = 2,
        'Dean could not read all assignments';
    ASSERT (SELECT count(*) FROM university.enrollments) = 2,
        'Dean could not read all enrollments';
END;
$$;

INSERT INTO university.teaching_assignments (
    lecturer_id, course_id, semester, academic_year, program_id
) VALUES (
    'V_DEAN_LECT_1', 'V_DEAN_COURSE_3', 1,
    extract(year FROM CURRENT_DATE)::smallint, 'HIGH_QUALITY'
);

UPDATE university.teaching_assignments
SET lecturer_id = 'V_DEAN_LECT_2'
WHERE course_id = 'V_DEAN_COURSE_3';

DO $$
BEGIN
    BEGIN
        UPDATE university.teaching_assignments
        SET lecturer_id = 'V_DEAN_BASIC'
        WHERE course_id = 'V_DEAN_COURSE_3';
        RAISE EXCEPTION 'Dean assigned non-teaching staff';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;

DELETE FROM university.teaching_assignments
WHERE course_id = 'V_DEAN_COURSE_3';

RESET ROLE;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM teaching_assignments) = 2,
        'Dean assignment create/update/delete workflow did not complete';
END;
$$;

-- Lecturer access remains self-scoped after the Dean policies are installed.
SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_DEAN_LECT_1';
SET LOCAL ROLE verify_dean_global;

DO $$
BEGIN
    ASSERT (
        SELECT array_agg(lecturer_id ORDER BY lecturer_id)
        FROM university.teaching_assignments
    ) = ARRAY['V_DEAN_LECT_1']::varchar[],
        'Dean policies widened lecturer assignment visibility';
    ASSERT (
        SELECT array_agg(student_id ORDER BY student_id)
        FROM university.enrollments
    ) = ARRAY['V_DEAN_STUDENT_1']::varchar[],
        'Dean policies widened lecturer enrollment visibility';
END;
$$;

RESET ROLE;
SELECT clear_security_context();
SET LOCAL ROLE verify_dean_global;

UPDATE university.teaching_assignments SET lecturer_id = 'V_DEAN_LECT_2';
DELETE FROM university.teaching_assignments;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM university.staff) = 0,
        'Missing context exposed staff';
    ASSERT (SELECT count(*) FROM university.students) = 0,
        'Missing context exposed students';
    ASSERT (SELECT count(*) FROM university.course_plans) = 0,
        'Missing context exposed course plans';
    ASSERT (SELECT count(*) FROM university.teaching_assignments) = 0,
        'Missing context exposed assignments';
    ASSERT (SELECT count(*) FROM university.enrollments) = 0,
        'Missing context exposed enrollments';
END;
$$;

RESET ROLE;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM teaching_assignments) = 2,
        'Missing-context assignment DML changed data';
END;
$$;

SELECT 'Dean global policy verification passed' AS result;
ROLLBACK;
