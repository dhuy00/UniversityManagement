-- Verify that the first student-access tables have RLS enabled.

BEGIN;
SET search_path TO university, public;

CREATE ROLE verify_student_rls_reader NOLOGIN;
GRANT USAGE ON SCHEMA university TO verify_student_rls_reader;
GRANT SELECT ON students, course_plans, enrollments
    TO verify_student_rls_reader;

DO $$
DECLARE
    enabled_table_count integer;
BEGIN
    SELECT count(*)
    INTO enabled_table_count
    FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
    WHERE n.nspname = 'university'
      AND c.relname IN ('students', 'course_plans', 'enrollments')
      AND c.relkind = 'r'
      AND c.relrowsecurity;

    ASSERT enabled_table_count = 3,
        format(
            'Expected RLS on 3 student-access tables, but found %s',
            enabled_table_count
        );

    ASSERT NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_policies
        WHERE schemaname = 'university'
          AND tablename IN ('students', 'course_plans', 'enrollments')
    ), 'Student RLS policies already exist; update this migration verification';
END;
$$;

-- Seed one temporary row in each protected table. The schema owner can do
-- this because table owners bypass RLS unless FORCE ROW LEVEL SECURITY is set.
INSERT INTO units (unit_id, unit_name)
VALUES ('VERIFY_RLS_UNIT', 'RLS verification unit');

INSERT INTO app_users (username, password_hash)
VALUES
    ('VERIFY_RLS_LECTURER', 'test-only'),
    ('VERIFY_RLS_STUDENT', 'test-only');

INSERT INTO staff (
    staff_id, user_id, full_name, gender, date_of_birth, allowance,
    unit_id, campus_id
)
SELECT
    'VERIFY_RLS_STAFF', user_id, 'RLS Verification Lecturer', 'OTHER',
    DATE '1990-01-01', 0, 'VERIFY_RLS_UNIT', 'CAMPUS_1'
FROM app_users
WHERE username = 'VERIFY_RLS_LECTURER';

INSERT INTO students (
    student_id, user_id, full_name, gender, date_of_birth,
    program_id, major_id, campus_id
)
SELECT
    'VERIFY_RLS_STUDENT', user_id, 'RLS Verification Student', 'OTHER',
    DATE '2000-01-01', 'REGULAR', 'IS', 'CAMPUS_1'
FROM app_users
WHERE username = 'VERIFY_RLS_STUDENT';

INSERT INTO courses (
    course_id, course_name, credits, theory_periods, practice_periods,
    max_students, unit_id
) VALUES (
    'VERIFY_RLS_COURSE', 'RLS Verification Course', 3, 30, 15, 50,
    'VERIFY_RLS_UNIT'
);

INSERT INTO course_plans (
    course_id, semester, academic_year, program_id, start_date
) VALUES (
    'VERIFY_RLS_COURSE', 1, 2026, 'REGULAR', DATE '2026-01-01'
);

INSERT INTO teaching_assignments (
    lecturer_id, course_id, semester, academic_year, program_id
) VALUES (
    'VERIFY_RLS_STAFF', 'VERIFY_RLS_COURSE', 1, 2026, 'REGULAR'
);

INSERT INTO enrollments (
    student_id, lecturer_id, course_id, semester, academic_year, program_id
) VALUES (
    'VERIFY_RLS_STUDENT', 'VERIFY_RLS_STAFF', 'VERIFY_RLS_COURSE',
    1, 2026, 'REGULAR'
);

-- RLS is enabled but has no policies yet, so PostgreSQL's default-deny rule
-- must hide every temporary row from this restricted non-owner role.
SET LOCAL ROLE verify_student_rls_reader;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM university.students) = 0,
        'Default-deny RLS exposed a student row';
    ASSERT (SELECT count(*) FROM university.course_plans) = 0,
        'Default-deny RLS exposed a course-plan row';
    ASSERT (SELECT count(*) FROM university.enrollments) = 0,
        'Default-deny RLS exposed an enrollment row';
END;
$$;

RESET ROLE;

SELECT 'student RLS enablement verification passed' AS result;
ROLLBACK;
