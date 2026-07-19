-- Trusted student write policies.
-- Apply after 02_security_context.sql, 03_enable_student_rls.sql, and
-- 04_student_select_policies.sql. The restricted API role must receive only
-- the column-level privileges documented in README.md.

BEGIN;
SET search_path TO university, public;

-- Centralize the database-date registration rule so INSERT and DELETE use
-- identical semantics. SECURITY DEFINER lets the check inspect course plans
-- without widening the caller's row visibility.
CREATE OR REPLACE FUNCTION is_registration_open(
    p_course_id varchar,
    p_semester smallint,
    p_academic_year smallint,
    p_program_id varchar
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM university.course_plans AS cp
        WHERE cp.course_id = p_course_id
          AND cp.semester = p_semester
          AND cp.academic_year = p_academic_year
          AND cp.program_id = p_program_id
          AND CURRENT_DATE BETWEEN cp.start_date AND cp.start_date + 14
    );
$$;

DROP POLICY IF EXISTS students_update_contact_self ON students;
CREATE POLICY students_update_contact_self
ON students
FOR UPDATE
USING (
    has_permission('STUDENT_CONTACT_UPDATE_SELF')
    AND student_id = current_student_id()
)
WITH CHECK (
    has_permission('STUDENT_CONTACT_UPDATE_SELF')
    AND student_id = current_student_id()
);

DROP POLICY IF EXISTS enrollments_insert_self_open ON enrollments;
CREATE POLICY enrollments_insert_self_open
ON enrollments
FOR INSERT
WITH CHECK (
    has_permission('ENROLLMENT_CREATE_DELETE_SELF')
    AND student_id = current_student_id()
    AND program_id = current_program_id()
    AND is_registration_open(
        course_id, semester, academic_year, program_id
    )
);

DROP POLICY IF EXISTS enrollments_delete_self_open ON enrollments;
CREATE POLICY enrollments_delete_self_open
ON enrollments
FOR DELETE
USING (
    has_permission('ENROLLMENT_CREATE_DELETE_SELF')
    AND student_id = current_student_id()
    AND program_id = current_program_id()
    AND is_registration_open(
        course_id, semester, academic_year, program_id
    )
);

COMMIT;
