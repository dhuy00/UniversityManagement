-- CS#3 trusted enrollment maintenance for Academic Affairs.
-- Definer-rights functions allow INSERT/DELETE without granting enrollment
-- SELECT access or permitting callers to supply score columns.

BEGIN;
SET search_path TO university, public;

CREATE OR REPLACE FUNCTION create_enrollment_for_student(
    p_student_id varchar,
    p_lecturer_id varchar,
    p_course_id varchar,
    p_semester smallint,
    p_academic_year smallint,
    p_program_id varchar
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
BEGIN
    IF NOT university.has_permission('ENROLLMENT_CREATE_DELETE_ALL') THEN
        RAISE EXCEPTION 'Enrollment maintenance permission is required'
            USING ERRCODE = '42501';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM university.students AS s
        WHERE s.student_id = p_student_id
          AND s.program_id = p_program_id
    ) THEN
        RAISE EXCEPTION 'Student and enrollment program must match'
            USING ERRCODE = '23514';
    END IF;

    IF NOT university.is_registration_open(
        p_course_id, p_semester, p_academic_year, p_program_id
    ) THEN
        RAISE EXCEPTION 'Enrollment registration window is closed'
            USING ERRCODE = '23514';
    END IF;

    INSERT INTO university.enrollments (
        student_id, lecturer_id, course_id, semester, academic_year, program_id
    ) VALUES (
        p_student_id, p_lecturer_id, p_course_id, p_semester,
        p_academic_year, p_program_id
    );
END;
$$;

CREATE OR REPLACE FUNCTION delete_enrollment_for_student(
    p_student_id varchar,
    p_lecturer_id varchar,
    p_course_id varchar,
    p_semester smallint,
    p_academic_year smallint,
    p_program_id varchar
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
BEGIN
    IF NOT university.has_permission('ENROLLMENT_CREATE_DELETE_ALL') THEN
        RAISE EXCEPTION 'Enrollment maintenance permission is required'
            USING ERRCODE = '42501';
    END IF;

    IF NOT university.is_registration_open(
        p_course_id, p_semester, p_academic_year, p_program_id
    ) THEN
        RAISE EXCEPTION 'Enrollment registration window is closed'
            USING ERRCODE = '23514';
    END IF;

    DELETE FROM university.enrollments
    WHERE student_id = p_student_id
      AND lecturer_id = p_lecturer_id
      AND course_id = p_course_id
      AND semester = p_semester
      AND academic_year = p_academic_year
      AND program_id = p_program_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Enrollment does not exist'
            USING ERRCODE = 'P0002';
    END IF;
END;
$$;

REVOKE ALL ON FUNCTION create_enrollment_for_student(
    varchar, varchar, varchar, smallint, smallint, varchar
) FROM PUBLIC;
REVOKE ALL ON FUNCTION delete_enrollment_for_student(
    varchar, varchar, varchar, smallint, smallint, varchar
) FROM PUBLIC;

COMMIT;
