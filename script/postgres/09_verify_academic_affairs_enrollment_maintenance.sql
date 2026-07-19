-- Rollback-only verification for trusted Academic Affairs enrollment DML.

BEGIN;
SET search_path TO university, public;

CREATE ROLE verify_affairs_enrollment NOLOGIN;
GRANT USAGE ON SCHEMA university TO verify_affairs_enrollment;
GRANT EXECUTE ON FUNCTION create_enrollment_for_student(
    varchar, varchar, varchar, smallint, smallint, varchar
) TO verify_affairs_enrollment;
GRANT EXECUTE ON FUNCTION delete_enrollment_for_student(
    varchar, varchar, varchar, smallint, smallint, varchar
) TO verify_affairs_enrollment;

INSERT INTO units (unit_id, unit_name)
VALUES ('V_AE_UNIT', 'Affairs enrollment verification unit');

INSERT INTO app_users (username, password_hash)
VALUES
    ('V_AE_AFFAIRS', 'test-only'),
    ('V_AE_LECTURER', 'test-only'),
    ('V_AE_STUDENT_1', 'test-only'),
    ('V_AE_STUDENT_2', 'test-only');

INSERT INTO staff (
    staff_id, user_id, full_name, gender, date_of_birth, allowance,
    unit_id, campus_id
)
SELECT
    'V_AE_AFFAIRS', user_id, 'Verification Academic Affairs', 'OTHER',
    DATE '1990-01-01', 0, 'V_AE_UNIT', 'CAMPUS_1'
FROM app_users WHERE username = 'V_AE_AFFAIRS'
UNION ALL
SELECT
    'V_AE_LECTURER', user_id, 'Verification Lecturer', 'OTHER',
    DATE '1990-01-02', 0, 'V_AE_UNIT', 'CAMPUS_1'
FROM app_users WHERE username = 'V_AE_LECTURER';

INSERT INTO students (
    student_id, user_id, full_name, gender, date_of_birth,
    program_id, major_id, campus_id
)
SELECT
    'V_AE_STUDENT_1', user_id, 'Verification Student 1', 'OTHER',
    DATE '2000-01-01', 'REGULAR', 'IS', 'CAMPUS_1'
FROM app_users WHERE username = 'V_AE_STUDENT_1'
UNION ALL
SELECT
    'V_AE_STUDENT_2', user_id, 'Verification Student 2', 'OTHER',
    DATE '2000-01-02', 'HIGH_QUALITY', 'SE', 'CAMPUS_2'
FROM app_users WHERE username = 'V_AE_STUDENT_2';

INSERT INTO app_user_roles (user_id, role_code)
SELECT user_id, 'ACADEMIC_AFFAIRS'
FROM app_users WHERE username = 'V_AE_AFFAIRS'
UNION ALL
SELECT user_id, 'LECTURER'
FROM app_users WHERE username = 'V_AE_LECTURER'
UNION ALL
SELECT user_id, 'STUDENT'
FROM app_users WHERE username IN ('V_AE_STUDENT_1', 'V_AE_STUDENT_2');

INSERT INTO courses (
    course_id, course_name, credits, theory_periods, practice_periods,
    max_students, unit_id
) VALUES
    ('V_AE_OPEN', 'Open Enrollment Course', 3, 30, 15, 50, 'V_AE_UNIT'),
    ('V_AE_CLOSED', 'Closed Enrollment Course', 3, 30, 15, 50, 'V_AE_UNIT'),
    ('V_AE_OTHER', 'Other Program Course', 3, 30, 15, 50, 'V_AE_UNIT');

INSERT INTO course_plans (
    course_id, semester, academic_year, program_id, start_date
) VALUES
    ('V_AE_OPEN', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CURRENT_DATE),
    ('V_AE_CLOSED', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CASE
         WHEN CURRENT_DATE < make_date(extract(year FROM CURRENT_DATE)::int, 7, 1)
             THEN make_date(extract(year FROM CURRENT_DATE)::int, 12, 1)
         ELSE make_date(extract(year FROM CURRENT_DATE)::int, 1, 1)
     END),
    ('V_AE_OTHER', 1, extract(year FROM CURRENT_DATE)::smallint,
     'HIGH_QUALITY', CURRENT_DATE);

INSERT INTO teaching_assignments (
    lecturer_id, course_id, semester, academic_year, program_id
) VALUES
    ('V_AE_LECTURER', 'V_AE_OPEN', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'),
    ('V_AE_LECTURER', 'V_AE_CLOSED', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'),
    ('V_AE_LECTURER', 'V_AE_OTHER', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'HIGH_QUALITY');

-- Closed-window row exists only to test DELETE rejection.
INSERT INTO enrollments (
    student_id, lecturer_id, course_id, semester, academic_year, program_id
) VALUES (
    'V_AE_STUDENT_1', 'V_AE_LECTURER', 'V_AE_CLOSED', 1,
    extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'
);

SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_AE_AFFAIRS';
SET LOCAL ROLE verify_affairs_enrollment;

DO $$
DECLARE
    current_year smallint := extract(year FROM CURRENT_DATE)::smallint;
BEGIN
    ASSERT NOT has_table_privilege(
        current_user, 'university.enrollments', 'SELECT'
    ), 'Verification role unexpectedly received enrollment SELECT';
    ASSERT NOT has_table_privilege(
        current_user, 'university.enrollments', 'INSERT'
    ), 'Verification role unexpectedly received direct enrollment INSERT';
    ASSERT NOT has_table_privilege(
        current_user, 'university.enrollments', 'DELETE'
    ), 'Verification role unexpectedly received direct enrollment DELETE';

    PERFORM university.create_enrollment_for_student(
        'V_AE_STUDENT_1', 'V_AE_LECTURER', 'V_AE_OPEN', 1::smallint,
        current_year, 'REGULAR'
    );
    PERFORM university.delete_enrollment_for_student(
        'V_AE_STUDENT_1', 'V_AE_LECTURER', 'V_AE_OPEN', 1::smallint,
        current_year, 'REGULAR'
    );

    BEGIN
        PERFORM university.create_enrollment_for_student(
            'V_AE_STUDENT_1', 'V_AE_LECTURER', 'V_AE_CLOSED', 1::smallint,
            current_year, 'REGULAR'
        );
        RAISE EXCEPTION 'Closed-window enrollment creation was accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    BEGIN
        PERFORM university.create_enrollment_for_student(
            'V_AE_STUDENT_1', 'V_AE_LECTURER', 'V_AE_OTHER', 1::smallint,
            current_year, 'HIGH_QUALITY'
        );
        RAISE EXCEPTION 'Student/program mismatch was accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;

    BEGIN
        PERFORM university.delete_enrollment_for_student(
            'V_AE_STUDENT_1', 'V_AE_LECTURER', 'V_AE_CLOSED', 1::smallint,
            current_year, 'REGULAR'
        );
        RAISE EXCEPTION 'Closed-window enrollment deletion was accepted';
    EXCEPTION WHEN check_violation THEN NULL;
    END;
END;
$$;

RESET ROLE;

DO $$
BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM enrollments
        WHERE student_id = 'V_AE_STUDENT_1' AND course_id = 'V_AE_OPEN'
    ), 'Valid open-window create/delete did not complete';
    ASSERT EXISTS (
        SELECT 1 FROM enrollments
        WHERE student_id = 'V_AE_STUDENT_1' AND course_id = 'V_AE_CLOSED'
    ), 'Closed-window enrollment was deleted';
END;
$$;

-- A lecturer can execute the function at the database level but is rejected
-- by its application permission check.
SELECT set_security_context(user_id)
FROM app_users WHERE username = 'V_AE_LECTURER';
SET LOCAL ROLE verify_affairs_enrollment;

DO $$
BEGIN
    BEGIN
        PERFORM university.create_enrollment_for_student(
            'V_AE_STUDENT_1', 'V_AE_LECTURER', 'V_AE_OPEN', 1::smallint,
            extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'
        );
        RAISE EXCEPTION 'Lecturer used Academic Affairs enrollment maintenance';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;

RESET ROLE;
SELECT clear_security_context();
SET LOCAL ROLE verify_affairs_enrollment;

DO $$
BEGIN
    BEGIN
        PERFORM university.create_enrollment_for_student(
            'V_AE_STUDENT_1', 'V_AE_LECTURER', 'V_AE_OPEN', 1::smallint,
            extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'
        );
        RAISE EXCEPTION 'Missing context used enrollment maintenance';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;

RESET ROLE;
SELECT 'Academic Affairs enrollment maintenance verification passed' AS result;
ROLLBACK;
