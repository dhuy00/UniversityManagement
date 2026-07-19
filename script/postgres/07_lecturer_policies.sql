-- CS#2 lecturer policies. Unit heads and deans inherit these permissions;
-- their wider organizational scopes are added in later migrations.

BEGIN;
SET search_path TO university, public;

ALTER TABLE teaching_assignments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS assignments_select_self ON teaching_assignments;
CREATE POLICY assignments_select_self
ON teaching_assignments
FOR SELECT
USING (
    has_permission('ASSIGNMENT_READ_SELF')
    AND lecturer_id = current_staff_id()
);

DROP POLICY IF EXISTS enrollments_select_assigned ON enrollments;
CREATE POLICY enrollments_select_assigned
ON enrollments
FOR SELECT
USING (
    has_permission('ENROLLMENT_READ_ASSIGNED')
    AND lecturer_id = current_staff_id()
);

DROP POLICY IF EXISTS enrollments_update_grades_assigned ON enrollments;
CREATE POLICY enrollments_update_grades_assigned
ON enrollments
FOR UPDATE
USING (
    has_permission('GRADE_UPDATE_ASSIGNED')
    AND lecturer_id = current_staff_id()
)
WITH CHECK (
    has_permission('GRADE_UPDATE_ASSIGNED')
    AND lecturer_id = current_staff_id()
);

COMMIT;
