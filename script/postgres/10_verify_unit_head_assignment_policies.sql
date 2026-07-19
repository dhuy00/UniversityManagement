-- Rollback-only verification for CS#4 Unit Head assignment scope.

BEGIN;
SET search_path TO university, public;

CREATE ROLE verify_unit_head_assignment NOLOGIN;
GRANT USAGE ON SCHEMA university TO verify_unit_head_assignment;
GRANT SELECT, INSERT, UPDATE, DELETE ON teaching_assignments
    TO verify_unit_head_assignment;

DO $$
BEGIN
    ASSERT (
        SELECT count(*) = 4
        FROM pg_catalog.pg_policies
        WHERE schemaname = 'university'
          AND policyname IN (
              'assignments_select_own_unit',
              'assignments_insert_own_unit',
              'assignments_update_own_unit',
              'assignments_delete_own_unit'
          )
    ), 'Expected all four Unit Head assignment policies';
END;
$$;

INSERT INTO units (unit_id, unit_name)
VALUES
    ('V_HEAD_UNIT_1', 'Unit Head verification unit 1'),
    ('V_HEAD_UNIT_2', 'Unit Head verification unit 2');

INSERT INTO app_users (username, password_hash)
VALUES
    ('V_HEAD_USER', 'test-only'),
    ('V_HEAD_LECT_1', 'test-only'),
    ('V_HEAD_LECT_2', 'test-only'),
    ('V_HEAD_BASIC', 'test-only');

INSERT INTO staff (
    staff_id, user_id, full_name, gender, date_of_birth, allowance,
    unit_id, campus_id
)
SELECT
    'V_HEAD_STAFF', user_id, 'Verification Unit Head', 'OTHER',
    DATE '1985-01-01', 0, 'V_HEAD_UNIT_1', 'CAMPUS_1'
FROM app_users WHERE username = 'V_HEAD_USER'
UNION ALL
SELECT
    'V_HEAD_LECT_1', user_id, 'Verification Lecturer 1', 'OTHER',
    DATE '1990-01-01', 0, 'V_HEAD_UNIT_1', 'CAMPUS_1'
FROM app_users WHERE username = 'V_HEAD_LECT_1'
UNION ALL
SELECT
    'V_HEAD_LECT_2', user_id, 'Verification Lecturer 2', 'OTHER',
    DATE '1990-01-02', 0, 'V_HEAD_UNIT_2', 'CAMPUS_2'
FROM app_users WHERE username = 'V_HEAD_LECT_2'
UNION ALL
SELECT
    'V_HEAD_BASIC', user_id, 'Verification Basic Staff', 'OTHER',
    DATE '1990-01-03', 0, 'V_HEAD_UNIT_1', 'CAMPUS_1'
FROM app_users WHERE username = 'V_HEAD_BASIC';

INSERT INTO app_user_roles (user_id, role_code)
SELECT user_id, 'UNIT_HEAD'
FROM app_users WHERE username = 'V_HEAD_USER'
UNION ALL
SELECT user_id, 'LECTURER'
FROM app_users WHERE username IN ('V_HEAD_LECT_1', 'V_HEAD_LECT_2')
UNION ALL
SELECT user_id, 'BASIC_STAFF'
FROM app_users WHERE username = 'V_HEAD_BASIC';

UPDATE units SET head_staff_id = 'V_HEAD_STAFF'
WHERE unit_id = 'V_HEAD_UNIT_1';

INSERT INTO courses (
    course_id, course_name, credits, theory_periods, practice_periods,
    max_students, unit_id
) VALUES
    ('V_HEAD_COURSE_1', 'Unit 1 Course', 3, 30, 15, 50, 'V_HEAD_UNIT_1'),
    ('V_HEAD_COURSE_2', 'Unit 2 Course', 3, 30, 15, 50, 'V_HEAD_UNIT_2'),
    ('V_HEAD_COURSE_3', 'Unit 1 Additional Course', 3, 30, 15, 50,
     'V_HEAD_UNIT_1');

INSERT INTO course_plans (
    course_id, semester, academic_year, program_id, start_date
) VALUES
    ('V_HEAD_COURSE_1', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CURRENT_DATE),
    ('V_HEAD_COURSE_2', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CURRENT_DATE),
    ('V_HEAD_COURSE_3', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CURRENT_DATE);

-- Only the assignment whose lecturer is in Unit 1 is visible. Course
-- ownership alone must not widen the Unit Head's SELECT scope.
INSERT INTO teaching_assignments (
    lecturer_id, course_id, semester, academic_year, program_id
) VALUES
    ('V_HEAD_LECT_1', 'V_HEAD_COURSE_2', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'),
    ('V_HEAD_LECT_2', 'V_HEAD_COURSE_1', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'),
    ('V_HEAD_LECT_2', 'V_HEAD_COURSE_2', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR');

SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_HEAD_USER';
SET LOCAL ROLE verify_unit_head_assignment;

DO $$
BEGIN
    ASSERT (
        SELECT array_agg(course_id ORDER BY course_id)
        FROM university.teaching_assignments
    ) = ARRAY['V_HEAD_COURSE_2']::varchar[],
        'Unit Head visibility was not limited to lecturers in their unit';
END;
$$;

INSERT INTO university.teaching_assignments (
    lecturer_id, course_id, semester, academic_year, program_id
) VALUES (
    'V_HEAD_LECT_1', 'V_HEAD_COURSE_3', 1,
    extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'
);

DO $$
BEGIN
    BEGIN
        INSERT INTO university.teaching_assignments (
            lecturer_id, course_id, semester, academic_year, program_id
        ) VALUES (
            'V_HEAD_LECT_1', 'V_HEAD_COURSE_2', 2,
            extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'
        );
        RAISE EXCEPTION 'Unit Head inserted an assignment for another unit course';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;

UPDATE university.teaching_assignments
SET lecturer_id = 'V_HEAD_STAFF'
WHERE course_id = 'V_HEAD_COURSE_3';

DO $$
BEGIN
    BEGIN
        UPDATE university.teaching_assignments
        SET lecturer_id = 'V_HEAD_BASIC'
        WHERE course_id = 'V_HEAD_COURSE_3';
        RAISE EXCEPTION 'Unit Head assigned a non-teaching staff member';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;

DELETE FROM university.teaching_assignments
WHERE course_id = 'V_HEAD_COURSE_3';

DELETE FROM university.teaching_assignments
WHERE course_id = 'V_HEAD_COURSE_2';

RESET ROLE;

DO $$
BEGIN
    ASSERT (
        SELECT lecturer_id = 'V_HEAD_LECT_2'
        FROM teaching_assignments WHERE course_id = 'V_HEAD_COURSE_1'
    ), 'Course ownership incorrectly widened read/update visibility';
    ASSERT NOT EXISTS (
        SELECT 1 FROM teaching_assignments WHERE course_id = 'V_HEAD_COURSE_3'
    ), 'Unit Head could not delete their unit course assignment';
    ASSERT (
        SELECT count(*) FROM teaching_assignments
        WHERE course_id = 'V_HEAD_COURSE_2'
    ) = 2, 'Unit Head changed assignments for another unit course';
END;
$$;

SELECT clear_security_context();
SET LOCAL ROLE verify_unit_head_assignment;

UPDATE university.teaching_assignments
SET lecturer_id = 'V_HEAD_LECT_2';
DELETE FROM university.teaching_assignments;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM university.teaching_assignments) = 0,
        'Missing context exposed assignments';
END;
$$;

RESET ROLE;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM teaching_assignments) = 3,
        'Missing-context assignment DML changed data';
END;
$$;

SELECT 'Unit Head assignment policy verification passed' AS result;
ROLLBACK;
