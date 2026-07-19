-- CS#4 Unit Head teaching-assignment scope.

BEGIN;
SET search_path TO university, public;

DROP POLICY IF EXISTS assignments_select_own_unit ON teaching_assignments;
DROP FUNCTION IF EXISTS assignment_in_current_unit(varchar, varchar);

-- Read scope follows the lecturer's unit. Course ownership is deliberately
-- reserved for the separate create/update/delete management policies below.
CREATE OR REPLACE FUNCTION assignment_in_current_unit(
    p_lecturer_id varchar
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT university.current_unit_id() IS NOT NULL
       AND EXISTS (
           SELECT 1 FROM university.staff AS s
           WHERE s.staff_id = p_lecturer_id
             AND s.unit_id = university.current_unit_id()
       );
$$;

CREATE OR REPLACE FUNCTION course_in_current_unit(p_course_id varchar)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT university.current_unit_id() IS NOT NULL
       AND EXISTS (
           SELECT 1 FROM university.courses AS c
           WHERE c.course_id = p_course_id
             AND c.unit_id = university.current_unit_id()
       );
$$;

CREATE OR REPLACE FUNCTION staff_can_teach(p_staff_id varchar)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, university
SET row_security = off
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM university.staff AS s
        JOIN university.app_user_roles AS ur ON ur.user_id = s.user_id
        JOIN university.app_users AS u ON u.user_id = s.user_id
        WHERE s.staff_id = p_staff_id
          AND ur.role_code IN ('LECTURER', 'UNIT_HEAD')
          AND u.is_active
    );
$$;

CREATE POLICY assignments_select_own_unit
ON teaching_assignments
FOR SELECT
USING (
    has_permission('ASSIGNMENT_READ_OWN_UNIT')
    AND assignment_in_current_unit(lecturer_id)
);

DROP POLICY IF EXISTS assignments_insert_own_unit ON teaching_assignments;
CREATE POLICY assignments_insert_own_unit
ON teaching_assignments
FOR INSERT
WITH CHECK (
    has_permission('ASSIGNMENT_MANAGE_OWN_UNIT')
    AND course_in_current_unit(course_id)
    AND staff_can_teach(lecturer_id)
);

DROP POLICY IF EXISTS assignments_update_own_unit ON teaching_assignments;
CREATE POLICY assignments_update_own_unit
ON teaching_assignments
FOR UPDATE
USING (
    has_permission('ASSIGNMENT_MANAGE_OWN_UNIT')
    AND course_in_current_unit(course_id)
)
WITH CHECK (
    has_permission('ASSIGNMENT_MANAGE_OWN_UNIT')
    AND course_in_current_unit(course_id)
    AND staff_can_teach(lecturer_id)
);

DROP POLICY IF EXISTS assignments_delete_own_unit ON teaching_assignments;
CREATE POLICY assignments_delete_own_unit
ON teaching_assignments
FOR DELETE
USING (
    has_permission('ASSIGNMENT_MANAGE_OWN_UNIT')
    AND course_in_current_unit(course_id)
);

COMMIT;
