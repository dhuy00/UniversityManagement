-- Student read policies for the first PostgreSQL RLS slice.
-- Apply after 02_security_context.sql and 03_enable_student_rls.sql.

BEGIN;
SET search_path TO university, public;

DROP POLICY IF EXISTS students_select_self ON students;
CREATE POLICY students_select_self
ON students
FOR SELECT
USING (
    has_permission('STUDENT_READ_SELF')
    AND student_id = current_student_id()
);

DROP POLICY IF EXISTS course_plans_select_own_program ON course_plans;
CREATE POLICY course_plans_select_own_program
ON course_plans
FOR SELECT
USING (
    has_permission('COURSE_PLAN_READ_OWN_PROGRAM')
    AND program_id = current_program_id()
);

DROP POLICY IF EXISTS enrollments_select_self ON enrollments;
CREATE POLICY enrollments_select_self
ON enrollments
FOR SELECT
USING (
    has_permission('ENROLLMENT_READ_SELF')
    AND student_id = current_student_id()
);

COMMIT;
