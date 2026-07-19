-- Rollback-only verification for CS#2 lecturer RLS and grade updates.

BEGIN;
SET search_path TO university, public;

CREATE ROLE verify_lecturer_policy NOLOGIN;
GRANT USAGE ON SCHEMA university TO verify_lecturer_policy;
GRANT SELECT ON teaching_assignments, enrollments
    TO verify_lecturer_policy;
GRANT UPDATE (
    practice_score, process_score, final_exam_score, final_score
) ON enrollments TO verify_lecturer_policy;

DO $$
BEGIN
    ASSERT (
        SELECT relrowsecurity
        FROM pg_catalog.pg_class AS c
        JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname = 'university'
          AND c.relname = 'teaching_assignments'
    ), 'Expected RLS to be enabled on teaching_assignments';

    ASSERT (
        SELECT count(*) = 3
        FROM pg_catalog.pg_policies
        WHERE schemaname = 'university'
          AND policyname IN (
              'assignments_select_self',
              'enrollments_select_assigned',
              'enrollments_update_grades_assigned'
          )
    ), 'Expected all three CS#2 lecturer policies';
END;
$$;

INSERT INTO units (unit_id, unit_name)
VALUES ('V_LECT_UNIT', 'Lecturer policy verification unit');

INSERT INTO app_users (username, password_hash)
VALUES
    ('V_LECTURER_1', 'test-only'),
    ('V_LECTURER_2', 'test-only'),
    ('V_LECT_STUDENT_1', 'test-only'),
    ('V_LECT_STUDENT_2', 'test-only');

INSERT INTO staff (
    staff_id, user_id, full_name, gender, date_of_birth, allowance,
    unit_id, campus_id
)
SELECT
    'V_LECTURER_1', user_id, 'Verification Lecturer 1', 'OTHER',
    DATE '1990-01-01', 0, 'V_LECT_UNIT', 'CAMPUS_1'
FROM app_users WHERE username = 'V_LECTURER_1'
UNION ALL
SELECT
    'V_LECTURER_2', user_id, 'Verification Lecturer 2', 'OTHER',
    DATE '1990-01-02', 0, 'V_LECT_UNIT', 'CAMPUS_2'
FROM app_users WHERE username = 'V_LECTURER_2';

INSERT INTO students (
    student_id, user_id, full_name, gender, date_of_birth,
    program_id, major_id, campus_id
)
SELECT
    'V_LECT_STUDENT_1', user_id, 'Lecturer Verification Student 1', 'OTHER',
    DATE '2000-01-01', 'REGULAR', 'IS', 'CAMPUS_1'
FROM app_users WHERE username = 'V_LECT_STUDENT_1'
UNION ALL
SELECT
    'V_LECT_STUDENT_2', user_id, 'Lecturer Verification Student 2', 'OTHER',
    DATE '2000-01-02', 'REGULAR', 'SE', 'CAMPUS_2'
FROM app_users WHERE username = 'V_LECT_STUDENT_2';

INSERT INTO app_user_roles (user_id, role_code)
SELECT user_id, 'LECTURER'
FROM app_users
WHERE username IN ('V_LECTURER_1', 'V_LECTURER_2')
UNION ALL
SELECT user_id, 'STUDENT'
FROM app_users
WHERE username IN ('V_LECT_STUDENT_1', 'V_LECT_STUDENT_2');

INSERT INTO courses (
    course_id, course_name, credits, theory_periods, practice_periods,
    max_students, unit_id
) VALUES
    ('V_LECT_COURSE_1', 'Lecturer Verification Course 1', 3, 30, 15, 50,
     'V_LECT_UNIT'),
    ('V_LECT_COURSE_2', 'Lecturer Verification Course 2', 3, 30, 15, 50,
     'V_LECT_UNIT');

INSERT INTO course_plans (
    course_id, semester, academic_year, program_id, start_date
) VALUES
    ('V_LECT_COURSE_1', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CURRENT_DATE),
    ('V_LECT_COURSE_2', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CURRENT_DATE);

INSERT INTO teaching_assignments (
    lecturer_id, course_id, semester, academic_year, program_id
) VALUES
    ('V_LECTURER_1', 'V_LECT_COURSE_1', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'),
    ('V_LECTURER_2', 'V_LECT_COURSE_2', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR');

INSERT INTO enrollments (
    student_id, lecturer_id, course_id, semester, academic_year, program_id,
    practice_score, process_score, final_exam_score, final_score
) VALUES
    ('V_LECT_STUDENT_1', 'V_LECTURER_1', 'V_LECT_COURSE_1', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR', 1, 2, 3, 4),
    ('V_LECT_STUDENT_2', 'V_LECTURER_2', 'V_LECT_COURSE_2', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR', 5, 6, 7, 8);

SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_LECTURER_1';
SET LOCAL ROLE verify_lecturer_policy;

DO $$
BEGIN
    ASSERT (
        SELECT array_agg(lecturer_id ORDER BY lecturer_id)
        FROM university.teaching_assignments
    ) = ARRAY['V_LECTURER_1']::varchar[],
        'Lecturer could not see exactly their own assignment';
    ASSERT (
        SELECT array_agg(student_id ORDER BY student_id)
        FROM university.enrollments
    ) = ARRAY['V_LECT_STUDENT_1']::varchar[],
        'Lecturer could not see exactly their assigned enrollment';
END;
$$;

UPDATE university.enrollments
SET practice_score = 9, process_score = 8,
    final_exam_score = 7, final_score = 8
WHERE student_id = 'V_LECT_STUDENT_1';

UPDATE university.enrollments SET final_score = 0
WHERE student_id = 'V_LECT_STUDENT_2';

DO $$
BEGIN
    ASSERT (
        SELECT practice_score = 9 AND process_score = 8
           AND final_exam_score = 7 AND final_score = 8
        FROM university.enrollments
        WHERE student_id = 'V_LECT_STUDENT_1'
    ), 'Lecturer could not update scores for an assigned enrollment';

    BEGIN
        UPDATE university.enrollments
        SET student_id = 'V_LECT_STUDENT_2'
        WHERE student_id = 'V_LECT_STUDENT_1';
        RAISE EXCEPTION 'Lecturer changed a protected enrollment key';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;

RESET ROLE;

DO $$
BEGIN
    ASSERT (
        SELECT final_score = 8
        FROM enrollments WHERE student_id = 'V_LECT_STUDENT_2'
    ), 'Lecturer changed another lecturer''s enrollment';
END;
$$;

-- Student SELECT behavior must remain scoped to their own enrollment and must
-- not expose teaching assignments.
SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_LECT_STUDENT_1';
SET LOCAL ROLE verify_lecturer_policy;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM university.teaching_assignments) = 0,
        'Student unexpectedly received assignment visibility';
    ASSERT (
        SELECT array_agg(student_id ORDER BY student_id)
        FROM university.enrollments
    ) = ARRAY['V_LECT_STUDENT_1']::varchar[],
        'Lecturer policies changed student enrollment isolation';
END;
$$;

RESET ROLE;
SELECT clear_security_context();
SET LOCAL ROLE verify_lecturer_policy;

UPDATE university.enrollments SET final_score = 0
WHERE student_id = 'V_LECT_STUDENT_1';

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM university.teaching_assignments) = 0,
        'Missing context exposed assignments';
    ASSERT (SELECT count(*) FROM university.enrollments) = 0,
        'Missing context exposed enrollments';
END;
$$;

RESET ROLE;

DO $$
BEGIN
    ASSERT (
        SELECT final_score = 8
        FROM enrollments WHERE student_id = 'V_LECT_STUDENT_1'
    ), 'Missing-context grade update changed data';
END;
$$;

SELECT 'lecturer policy verification passed' AS result;
ROLLBACK;
