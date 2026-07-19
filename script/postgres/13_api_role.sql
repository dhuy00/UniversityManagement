-- Least-privilege database role used by the PostgreSQL-backed API.
-- Keep login credentials in deployment configuration: this group role is
-- deliberately NOLOGIN and should be granted to one environment-specific
-- login role.

BEGIN;
SET search_path TO university, public;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'university_api') THEN
        CREATE ROLE university_api NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
            NOINHERIT NOBYPASSRLS;
    END IF;
END;
$$;

ALTER ROLE university_api NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
    NOINHERIT NOBYPASSRLS;

GRANT USAGE ON SCHEMA university TO university_api;

GRANT SELECT ON
    staff,
    students,
    courses,
    units,
    course_plans,
    teaching_assignments,
    enrollments
TO university_api;

GRANT UPDATE (address, phone) ON students TO university_api;
GRANT INSERT (
    student_id, lecturer_id, course_id, semester, academic_year, program_id
) ON enrollments TO university_api;
GRANT DELETE ON enrollments TO university_api;

-- Staff self-service and Dean management share this table. RLS determines
-- which rows each identity may change; the trigger below preserves the
-- phone-only rule for non-Deans despite the Dean's full-row table grant.
GRANT INSERT, UPDATE, DELETE ON staff TO university_api;
GRANT INSERT, UPDATE, DELETE ON teaching_assignments TO university_api;
GRANT UPDATE (
    practice_score, process_score, final_exam_score, final_score
) ON enrollments TO university_api;

GRANT EXECUTE ON FUNCTION set_security_context(bigint) TO university_api;
GRANT EXECUTE ON FUNCTION create_enrollment_for_student(
    varchar, varchar, varchar, smallint, smallint, varchar
) TO university_api;
GRANT EXECUTE ON FUNCTION delete_enrollment_for_student(
    varchar, varchar, varchar, smallint, smallint, varchar
) TO university_api;

CREATE OR REPLACE FUNCTION enforce_staff_update_columns()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, university
AS $$
BEGIN
    IF university.has_permission('STAFF_MANAGE_ALL') THEN
        RETURN NEW;
    END IF;

    IF ROW(NEW.staff_id, NEW.user_id, NEW.full_name, NEW.gender,
           NEW.date_of_birth, NEW.allowance, NEW.unit_id, NEW.campus_id)
       IS DISTINCT FROM
       ROW(OLD.staff_id, OLD.user_id, OLD.full_name, OLD.gender,
           OLD.date_of_birth, OLD.allowance, OLD.unit_id, OLD.campus_id) THEN
        RAISE EXCEPTION 'Only phone may be updated for staff self-service'
            USING ERRCODE = '42501';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS staff_update_column_guard ON staff;
CREATE TRIGGER staff_update_column_guard
BEFORE UPDATE ON staff
FOR EACH ROW
EXECUTE FUNCTION enforce_staff_update_columns();

COMMIT;
