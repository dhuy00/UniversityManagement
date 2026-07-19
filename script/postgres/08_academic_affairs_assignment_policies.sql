-- CS#3 Academic Affairs teaching-assignment policies.
-- In this faculty-scoped database, OFFICE means all teaching assignments.

BEGIN;
SET search_path TO university, public;

DROP POLICY IF EXISTS assignments_select_all_affairs ON teaching_assignments;
CREATE POLICY assignments_select_all_affairs
ON teaching_assignments
FOR SELECT
USING (has_permission('ASSIGNMENT_READ_ALL'));

DROP POLICY IF EXISTS assignments_update_office_affairs ON teaching_assignments;
CREATE POLICY assignments_update_office_affairs
ON teaching_assignments
FOR UPDATE
USING (has_permission('ASSIGNMENT_UPDATE_OFFICE'))
WITH CHECK (has_permission('ASSIGNMENT_UPDATE_OFFICE'));

COMMIT;
