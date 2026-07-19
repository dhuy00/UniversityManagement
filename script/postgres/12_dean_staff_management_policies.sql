-- CS#5 Dean faculty-wide staff management scope.

BEGIN;
SET search_path TO university, public;

DROP POLICY IF EXISTS staff_insert_all_dean ON staff;
CREATE POLICY staff_insert_all_dean
ON staff FOR INSERT
WITH CHECK (has_permission('STAFF_MANAGE_ALL'));

DROP POLICY IF EXISTS staff_update_all_dean ON staff;
CREATE POLICY staff_update_all_dean
ON staff FOR UPDATE
USING (has_permission('STAFF_MANAGE_ALL'))
WITH CHECK (has_permission('STAFF_MANAGE_ALL'));

DROP POLICY IF EXISTS staff_delete_all_dean ON staff;
CREATE POLICY staff_delete_all_dean
ON staff FOR DELETE
USING (has_permission('STAFF_MANAGE_ALL'));

COMMIT;
