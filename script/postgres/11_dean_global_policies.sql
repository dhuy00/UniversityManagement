-- CS#5 Dean global read and faculty-wide assignment management policies.

BEGIN;
SET search_path TO university, public;

DROP POLICY IF EXISTS staff_select_all_dean ON staff;
CREATE POLICY staff_select_all_dean
ON staff FOR SELECT
USING (has_permission('DATABASE_READ_ALL'));

DROP POLICY IF EXISTS students_select_all_dean ON students;
CREATE POLICY students_select_all_dean
ON students FOR SELECT
USING (has_permission('DATABASE_READ_ALL'));

DROP POLICY IF EXISTS course_plans_select_all_dean ON course_plans;
CREATE POLICY course_plans_select_all_dean
ON course_plans FOR SELECT
USING (has_permission('DATABASE_READ_ALL'));

DROP POLICY IF EXISTS assignments_select_all_dean ON teaching_assignments;
CREATE POLICY assignments_select_all_dean
ON teaching_assignments FOR SELECT
USING (has_permission('DATABASE_READ_ALL'));

DROP POLICY IF EXISTS enrollments_select_all_dean ON enrollments;
CREATE POLICY enrollments_select_all_dean
ON enrollments FOR SELECT
USING (has_permission('DATABASE_READ_ALL'));

DROP POLICY IF EXISTS assignments_insert_all_dean ON teaching_assignments;
CREATE POLICY assignments_insert_all_dean
ON teaching_assignments FOR INSERT
WITH CHECK (
    has_permission('ASSIGNMENT_MANAGE_OFFICE')
    AND staff_can_teach(lecturer_id)
);

DROP POLICY IF EXISTS assignments_update_all_dean ON teaching_assignments;
CREATE POLICY assignments_update_all_dean
ON teaching_assignments FOR UPDATE
USING (has_permission('ASSIGNMENT_MANAGE_OFFICE'))
WITH CHECK (
    has_permission('ASSIGNMENT_MANAGE_OFFICE')
    AND staff_can_teach(lecturer_id)
);

DROP POLICY IF EXISTS assignments_delete_all_dean ON teaching_assignments;
CREATE POLICY assignments_delete_all_dean
ON teaching_assignments FOR DELETE
USING (has_permission('ASSIGNMENT_MANAGE_OFFICE'));

COMMIT;
