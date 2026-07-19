-- Rollback-only verification for CS#3 Academic Affairs assignment access.

BEGIN;
SET search_path TO university, public;

CREATE ROLE verify_affairs_assignment NOLOGIN;
GRANT USAGE ON SCHEMA university TO verify_affairs_assignment;
GRANT SELECT, UPDATE ON teaching_assignments
    TO verify_affairs_assignment;

DO $$
BEGIN
    ASSERT (
        SELECT count(*) = 2
        FROM pg_catalog.pg_policies
        WHERE schemaname = 'university'
          AND policyname IN (
              'assignments_select_all_affairs',
              'assignments_update_office_affairs'
          )
    ), 'Expected both Academic Affairs assignment policies';
END;
$$;

INSERT INTO units (unit_id, unit_name)
VALUES ('V_AFFAIRS_UNIT', 'Academic Affairs verification unit');

INSERT INTO app_users (username, password_hash)
VALUES
    ('V_AFFAIRS_USER', 'test-only'),
    ('V_AFFAIRS_LECT_1', 'test-only'),
    ('V_AFFAIRS_LECT_2', 'test-only');

INSERT INTO staff (
    staff_id, user_id, full_name, gender, date_of_birth, allowance,
    unit_id, campus_id
)
SELECT
    'V_AFFAIRS_STAFF', user_id, 'Verification Academic Affairs', 'OTHER',
    DATE '1990-01-01', 0, 'V_AFFAIRS_UNIT', 'CAMPUS_1'
FROM app_users WHERE username = 'V_AFFAIRS_USER'
UNION ALL
SELECT
    'V_AFFAIRS_LECT_1', user_id, 'Verification Lecturer 1', 'OTHER',
    DATE '1990-01-02', 0, 'V_AFFAIRS_UNIT', 'CAMPUS_1'
FROM app_users WHERE username = 'V_AFFAIRS_LECT_1'
UNION ALL
SELECT
    'V_AFFAIRS_LECT_2', user_id, 'Verification Lecturer 2', 'OTHER',
    DATE '1990-01-03', 0, 'V_AFFAIRS_UNIT', 'CAMPUS_2'
FROM app_users WHERE username = 'V_AFFAIRS_LECT_2';

INSERT INTO app_user_roles (user_id, role_code)
SELECT user_id, 'ACADEMIC_AFFAIRS'
FROM app_users WHERE username = 'V_AFFAIRS_USER'
UNION ALL
SELECT user_id, 'LECTURER'
FROM app_users WHERE username IN ('V_AFFAIRS_LECT_1', 'V_AFFAIRS_LECT_2');

INSERT INTO courses (
    course_id, course_name, credits, theory_periods, practice_periods,
    max_students, unit_id
) VALUES
    ('V_AFFAIRS_COURSE_1', 'Affairs Verification Course 1', 3, 30, 15, 50,
     'V_AFFAIRS_UNIT'),
    ('V_AFFAIRS_COURSE_2', 'Affairs Verification Course 2', 3, 30, 15, 50,
     'V_AFFAIRS_UNIT');

INSERT INTO course_plans (
    course_id, semester, academic_year, program_id, start_date
) VALUES
    ('V_AFFAIRS_COURSE_1', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CURRENT_DATE),
    ('V_AFFAIRS_COURSE_2', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CURRENT_DATE);

INSERT INTO teaching_assignments (
    lecturer_id, course_id, semester, academic_year, program_id
) VALUES
    ('V_AFFAIRS_LECT_1', 'V_AFFAIRS_COURSE_1', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'),
    ('V_AFFAIRS_LECT_2', 'V_AFFAIRS_COURSE_2', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR');

SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_AFFAIRS_USER';
SET LOCAL ROLE verify_affairs_assignment;

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM university.teaching_assignments) = 2,
        'Academic Affairs could not read all assignments';
END;
$$;

UPDATE university.teaching_assignments
SET lecturer_id = 'V_AFFAIRS_LECT_2'
WHERE course_id = 'V_AFFAIRS_COURSE_1';

DO $$
BEGIN
    ASSERT (
        SELECT lecturer_id = 'V_AFFAIRS_LECT_2'
        FROM university.teaching_assignments
        WHERE course_id = 'V_AFFAIRS_COURSE_1'
    ), 'Academic Affairs could not update a faculty assignment';
END;
$$;

RESET ROLE;

-- Lecturer 2 now owns both assignments, proving the earlier lecturer policy
-- composes with the Academic Affairs update.
SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_AFFAIRS_LECT_2';
SET LOCAL ROLE verify_affairs_assignment;

DO $$
BEGIN
    ASSERT (
        SELECT count(*) FROM university.teaching_assignments
    ) = 2, 'Lecturer did not see exactly their updated assignments';

    UPDATE university.teaching_assignments
    SET lecturer_id = 'V_AFFAIRS_LECT_1'
    WHERE course_id = 'V_AFFAIRS_COURSE_2';
    ASSERT NOT EXISTS (
        SELECT 1 FROM university.teaching_assignments
        WHERE course_id = 'V_AFFAIRS_COURSE_2'
          AND lecturer_id = 'V_AFFAIRS_LECT_1'
    ), 'Lecturer unexpectedly updated an assignment';
END;
$$;

RESET ROLE;
SELECT clear_security_context();
SET LOCAL ROLE verify_affairs_assignment;

UPDATE university.teaching_assignments
SET lecturer_id = 'V_AFFAIRS_LECT_1';

DO $$
BEGIN
    ASSERT (SELECT count(*) FROM university.teaching_assignments) = 0,
        'Missing context exposed assignments';
END;
$$;

RESET ROLE;

DO $$
BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM teaching_assignments
        WHERE course_id = 'V_AFFAIRS_COURSE_2'
          AND lecturer_id = 'V_AFFAIRS_LECT_1'
    ), 'Missing-context assignment update changed data';
END;
$$;

SELECT 'Academic Affairs assignment policy verification passed' AS result;
ROLLBACK;
