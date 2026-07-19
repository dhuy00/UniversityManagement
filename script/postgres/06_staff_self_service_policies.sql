-- CS#1 staff self-service policies.
-- All staff roles carry the permissions used here. More privileged role
-- policies are added separately so each organizational scope stays explicit.

BEGIN;
SET search_path TO university, public;

ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS staff_select_self ON staff;
CREATE POLICY staff_select_self
ON staff
FOR SELECT
USING (
    has_permission('STAFF_READ_SELF')
    AND staff_id = current_staff_id()
);

DROP POLICY IF EXISTS staff_update_phone_self ON staff;
CREATE POLICY staff_update_phone_self
ON staff
FOR UPDATE
USING (
    has_permission('STAFF_PHONE_UPDATE_SELF')
    AND staff_id = current_staff_id()
)
WITH CHECK (
    has_permission('STAFF_PHONE_UPDATE_SELF')
    AND staff_id = current_staff_id()
);

DROP POLICY IF EXISTS students_select_all_staff ON students;
CREATE POLICY students_select_all_staff
ON students
FOR SELECT
USING (has_permission('STUDENT_READ_ALL'));

DROP POLICY IF EXISTS course_plans_select_all_staff ON course_plans;
CREATE POLICY course_plans_select_all_staff
ON course_plans
FOR SELECT
USING (has_permission('COURSE_PLAN_READ_ALL'));

COMMIT;
