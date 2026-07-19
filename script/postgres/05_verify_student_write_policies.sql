-- Rollback-only verification for trusted student contact and enrollment DML.

BEGIN;
SET search_path TO university, public;

CREATE ROLE verify_student_policy_writer NOLOGIN;
GRANT USAGE ON SCHEMA university TO verify_student_policy_writer;
GRANT SELECT ON students, course_plans, enrollments
    TO verify_student_policy_writer;
GRANT UPDATE (address, phone) ON students
    TO verify_student_policy_writer;
GRANT INSERT (
    student_id, lecturer_id, course_id, semester, academic_year, program_id
) ON enrollments TO verify_student_policy_writer;
GRANT DELETE ON enrollments TO verify_student_policy_writer;

DO $$
BEGIN
    ASSERT (
        SELECT count(*) = 3
        FROM pg_catalog.pg_policies
        WHERE schemaname = 'university'
          AND policyname IN (
              'students_update_contact_self',
              'enrollments_insert_self_open',
              'enrollments_delete_self_open'
          )
    ), 'Expected all three student write policies';
END;
$$;

INSERT INTO units (unit_id, unit_name)
VALUES ('V_WRITE_UNIT', 'Student write verification unit');

INSERT INTO app_users (username, password_hash)
VALUES
    ('V_WRITE_LECTURER', 'test-only'),
    ('V_WRITE_STUDENT_1', 'test-only'),
    ('V_WRITE_STUDENT_2', 'test-only');

INSERT INTO staff (
    staff_id, user_id, full_name, gender, date_of_birth, allowance,
    unit_id, campus_id
)
SELECT
    'V_WRITE_STAFF', user_id, 'Write Verification Lecturer', 'OTHER',
    DATE '1990-01-01', 0, 'V_WRITE_UNIT', 'CAMPUS_1'
FROM app_users
WHERE username = 'V_WRITE_LECTURER';

INSERT INTO students (
    student_id, user_id, full_name, gender, date_of_birth, address, phone,
    program_id, major_id, campus_id
)
SELECT
    'V_WRITE_STUDENT_1', user_id, 'Write Verification Student 1', 'OTHER',
    DATE '2000-01-01', 'Original address 1', '1001',
    'REGULAR', 'IS', 'CAMPUS_1'
FROM app_users
WHERE username = 'V_WRITE_STUDENT_1'
UNION ALL
SELECT
    'V_WRITE_STUDENT_2', user_id, 'Write Verification Student 2', 'OTHER',
    DATE '2000-01-02', 'Original address 2', '1002',
    'HIGH_QUALITY', 'SE', 'CAMPUS_2'
FROM app_users
WHERE username = 'V_WRITE_STUDENT_2';

INSERT INTO app_user_roles (user_id, role_code)
SELECT user_id, 'STUDENT'
FROM app_users
WHERE username IN ('V_WRITE_STUDENT_1', 'V_WRITE_STUDENT_2');

INSERT INTO courses (
    course_id, course_name, credits, theory_periods, practice_periods,
    max_students, unit_id
) VALUES
    ('V_WRITE_OPEN', 'Open Registration Course', 3, 30, 15, 50,
     'V_WRITE_UNIT'),
    ('V_WRITE_CLOSED', 'Closed Registration Course', 3, 30, 15, 50,
     'V_WRITE_UNIT'),
    ('V_WRITE_OTHER', 'Other Program Course', 3, 30, 15, 50,
     'V_WRITE_UNIT');

INSERT INTO course_plans (
    course_id, semester, academic_year, program_id, start_date
) VALUES
    ('V_WRITE_OPEN', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CURRENT_DATE),
    ('V_WRITE_CLOSED', 1, extract(year FROM CURRENT_DATE)::smallint,
     'REGULAR', CASE
         WHEN CURRENT_DATE < make_date(extract(year FROM CURRENT_DATE)::int, 7, 1)
             THEN make_date(extract(year FROM CURRENT_DATE)::int, 12, 1)
         ELSE make_date(extract(year FROM CURRENT_DATE)::int, 1, 1)
     END),
    ('V_WRITE_OTHER', 1, extract(year FROM CURRENT_DATE)::smallint,
     'HIGH_QUALITY', CURRENT_DATE);

INSERT INTO teaching_assignments (
    lecturer_id, course_id, semester, academic_year, program_id
) VALUES
    ('V_WRITE_STAFF', 'V_WRITE_OPEN', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'),
    ('V_WRITE_STAFF', 'V_WRITE_CLOSED', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'),
    ('V_WRITE_STAFF', 'V_WRITE_OTHER', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'HIGH_QUALITY');

-- Rows used to prove cross-student and closed-window DELETE denial.
INSERT INTO enrollments (
    student_id, lecturer_id, course_id, semester, academic_year, program_id
) VALUES
    ('V_WRITE_STUDENT_2', 'V_WRITE_STAFF', 'V_WRITE_OTHER', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'HIGH_QUALITY'),
    ('V_WRITE_STUDENT_1', 'V_WRITE_STAFF', 'V_WRITE_CLOSED', 1,
     extract(year FROM CURRENT_DATE)::smallint, 'REGULAR');

SELECT set_security_context(user_id)
FROM app_users
WHERE username = 'V_WRITE_STUDENT_1';
SET LOCAL ROLE verify_student_policy_writer;

UPDATE university.students
SET address = 'Updated own address', phone = '9999'
WHERE student_id = 'V_WRITE_STUDENT_1';

DO $$
BEGIN
    ASSERT (
        SELECT address = 'Updated own address' AND phone = '9999'
        FROM university.students
        WHERE student_id = 'V_WRITE_STUDENT_1'
    ), 'Student could not update their own contact fields';

    ASSERT NOT EXISTS (
        SELECT 1 FROM university.students
        WHERE student_id = 'V_WRITE_STUDENT_2'
    ), 'Student could see another student while testing writes';

    BEGIN
        UPDATE university.students
        SET full_name = 'Forbidden name change'
        WHERE student_id = 'V_WRITE_STUDENT_1';
        RAISE EXCEPTION 'Protected student column update was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;

UPDATE university.students
SET address = 'Cross-student overwrite'
WHERE student_id = 'V_WRITE_STUDENT_2';

INSERT INTO university.enrollments (
    student_id, lecturer_id, course_id, semester, academic_year, program_id
) VALUES (
    'V_WRITE_STUDENT_1', 'V_WRITE_STAFF', 'V_WRITE_OPEN', 1,
    extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'
);

DO $$
BEGIN
    ASSERT EXISTS (
        SELECT 1 FROM university.enrollments
        WHERE student_id = 'V_WRITE_STUDENT_1'
          AND course_id = 'V_WRITE_OPEN'
    ), 'Student could not create their own open-window enrollment';

    BEGIN
        INSERT INTO university.enrollments (
            student_id, lecturer_id, course_id, semester, academic_year,
            program_id
        ) VALUES (
            'V_WRITE_STUDENT_2', 'V_WRITE_STAFF', 'V_WRITE_OTHER', 1,
            extract(year FROM CURRENT_DATE)::smallint, 'HIGH_QUALITY'
        );
        RAISE EXCEPTION 'Cross-student enrollment insert was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;

    BEGIN
        INSERT INTO university.enrollments (
            student_id, lecturer_id, course_id, semester, academic_year,
            program_id
        ) VALUES (
            'V_WRITE_STUDENT_1', 'V_WRITE_STAFF', 'V_WRITE_OTHER', 1,
            extract(year FROM CURRENT_DATE)::smallint, 'HIGH_QUALITY'
        );
        RAISE EXCEPTION 'Wrong-program enrollment insert was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;

    BEGIN
        INSERT INTO university.enrollments (
            student_id, lecturer_id, course_id, semester, academic_year,
            program_id
        ) VALUES (
            'V_WRITE_STUDENT_1', 'V_WRITE_STAFF', 'V_WRITE_CLOSED', 1,
            extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'
        );
        RAISE EXCEPTION 'Closed-window enrollment insert was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;

    BEGIN
        INSERT INTO university.enrollments (
            student_id, lecturer_id, course_id, semester, academic_year,
            program_id, final_score
        ) VALUES (
            'V_WRITE_STUDENT_1', 'V_WRITE_STAFF', 'V_WRITE_OPEN', 1,
            extract(year FROM CURRENT_DATE)::smallint, 'REGULAR', 10
        );
        RAISE EXCEPTION 'Student enrollment score insert was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;

DELETE FROM university.enrollments
WHERE student_id = 'V_WRITE_STUDENT_1'
  AND course_id = 'V_WRITE_OPEN';

DELETE FROM university.enrollments
WHERE student_id = 'V_WRITE_STUDENT_2';

DELETE FROM university.enrollments
WHERE student_id = 'V_WRITE_STUDENT_1'
  AND course_id = 'V_WRITE_CLOSED';

RESET ROLE;

DO $$
BEGIN
    ASSERT (
        SELECT address = 'Original address 2'
        FROM students WHERE student_id = 'V_WRITE_STUDENT_2'
    ), 'Cross-student contact update changed protected data';
    ASSERT NOT EXISTS (
        SELECT 1 FROM enrollments
        WHERE student_id = 'V_WRITE_STUDENT_1'
          AND course_id = 'V_WRITE_OPEN'
    ), 'Open-window own enrollment was not deleted';
    ASSERT EXISTS (
        SELECT 1 FROM enrollments
        WHERE student_id = 'V_WRITE_STUDENT_2'
          AND course_id = 'V_WRITE_OTHER'
    ), 'Cross-student enrollment was deleted';
    ASSERT EXISTS (
        SELECT 1 FROM enrollments
        WHERE student_id = 'V_WRITE_STUDENT_1'
          AND course_id = 'V_WRITE_CLOSED'
    ), 'Closed-window enrollment was deleted';
END;
$$;

SELECT clear_security_context();
SET LOCAL ROLE verify_student_policy_writer;

UPDATE university.students SET phone = 'No context'
WHERE student_id = 'V_WRITE_STUDENT_1';
DELETE FROM university.enrollments
WHERE student_id = 'V_WRITE_STUDENT_1';

DO $$
BEGIN
    BEGIN
        INSERT INTO university.enrollments (
            student_id, lecturer_id, course_id, semester, academic_year,
            program_id
        ) VALUES (
            'V_WRITE_STUDENT_1', 'V_WRITE_STAFF', 'V_WRITE_OPEN', 1,
            extract(year FROM CURRENT_DATE)::smallint, 'REGULAR'
        );
        RAISE EXCEPTION 'Missing-context enrollment insert was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN NULL;
    END;
END;
$$;

RESET ROLE;

DO $$
BEGIN
    ASSERT (
        SELECT phone = '9999'
        FROM students WHERE student_id = 'V_WRITE_STUDENT_1'
    ), 'Missing-context contact update changed data';
    ASSERT EXISTS (
        SELECT 1 FROM enrollments
        WHERE student_id = 'V_WRITE_STUDENT_1'
          AND course_id = 'V_WRITE_CLOSED'
    ), 'Missing-context DELETE changed data';
END;
$$;

SELECT 'student write policy verification passed' AS result;
ROLLBACK;
