-- 15_seed_demo_data.sql
-- Seed the university schema with a minimal but realistic demo dataset.
-- Safe to run repeatedly: every INSERT is wrapped in a guard that aborts
-- when the schema already contains the demo reference rows (so re-running
-- the schema scripts does not duplicate data).
--
-- Idempotency model: an explicit dry-run DELETE is provided at the bottom
-- (commented out by default) to wipe demo data before re-seeding.
--
-- This script does NOT include passwords — the API uses BCrypt, so use the
-- admin bootstrap script (16_bootstrap_admin.sql) to create the first login.

-- ---------------------------------------------------------------------------
-- Reference data: campuses, programs, majors
-- ---------------------------------------------------------------------------

INSERT INTO university.campuses (campus_id, campus_name)
VALUES
    ('CAMPUS_HCM', 'Ho Chi Minh City Campus'),
    ('CAMPUS_HN',  'Hanoi Campus')
ON CONFLICT (campus_id) DO NOTHING;

INSERT INTO university.programs (program_id, program_name)
VALUES
    ('PROG_SE', 'Software Engineering'),
    ('PROG_AI', 'Artificial Intelligence')
ON CONFLICT (program_id) DO NOTHING;

INSERT INTO university.majors (major_id, major_name)
VALUES
    ('MAJ_SE', 'Software Engineering'),
    ('MAJ_AI', 'Artificial Intelligence')
ON CONFLICT (major_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Units
-- ---------------------------------------------------------------------------

INSERT INTO university.units (unit_id, unit_name)
VALUES
    ('UNIT_SE', 'Department of Software Engineering'),
    ('UNIT_AI', 'Department of Artificial Intelligence')
ON CONFLICT (unit_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Role assignments (already seeded by 01_schema.sql, but leave a guard here
-- in case the schema is built without 01).
-- ---------------------------------------------------------------------------

INSERT INTO university.permissions (permission_code, description)
VALUES
    ('STUDENT_READ_OWN',          'Read own student record'),
    ('STUDENT_UPDATE_CONTACT',    'Update own phone and address'),
    ('STAFF_READ_OWN',            'Read own staff record'),
    ('STAFF_UPDATE_PHONE',        'Update own phone'),
    ('COURSE_PLAN_READ_OWN',      'Read course plans for own program'),
    ('ENROLLMENT_READ_OWN',       'Read own enrollments'),
    ('ENROLLMENT_CREATE_DELETE',  'Create or delete own enrollments in window'),
    ('ASSIGNMENT_READ_OWN',       'Read own teaching assignments'),
    ('ASSIGNMENT_READ_UNIT',      'Read assignments in own unit'),
    ('ASSIGNMENT_MANAGE_OFFICE',  'Manage teaching assignments for the office'),
    ('ASSIGNMENT_MANAGE_UNIT',    'Manage assignments for own unit only'),
    ('ENROLLMENT_CREATE_DELETE_ALL', 'Manage enrollments on behalf of students'),
    ('DATABASE_READ_ALL',         'Read all domain rows across the faculty'),
    ('STAFF_MANAGE_ALL',          'Create, update, or delete staff faculty-wide')
ON CONFLICT (permission_code) DO NOTHING;

INSERT INTO university.role_permissions (role_code, permission_code)
VALUES
    ('STUDENT',          'STUDENT_READ_OWN'),
    ('STUDENT',          'STUDENT_UPDATE_CONTACT'),
    ('STUDENT',          'COURSE_PLAN_READ_OWN'),
    ('STUDENT',          'ENROLLMENT_READ_OWN'),
    ('STUDENT',          'ENROLLMENT_CREATE_DELETE'),
    ('BASIC_STAFF',      'STAFF_READ_OWN'),
    ('BASIC_STAFF',      'STAFF_UPDATE_PHONE'),
    ('BASIC_STAFF',      'COURSE_PLAN_READ_OWN'),
    ('LECTURER',         'STAFF_READ_OWN'),
    ('LECTURER',         'STAFF_UPDATE_PHONE'),
    ('LECTURER',         'ASSIGNMENT_READ_OWN'),
    ('LECTURER',         'ENROLLMENT_READ_OWN'),
    ('ACADEMIC_AFFAIRS', 'ASSIGNMENT_MANAGE_OFFICE'),
    ('ACADEMIC_AFFAIRS', 'ENROLLMENT_CREATE_DELETE_ALL'),
    ('ACADEMIC_AFFAIRS', 'DATABASE_READ_ALL'),
    ('UNIT_HEAD',        'ASSIGNMENT_MANAGE_UNIT'),
    ('UNIT_HEAD',        'ASSIGNMENT_READ_UNIT'),
    ('DEAN',             'DATABASE_READ_ALL'),
    ('DEAN',             'STAFF_MANAGE_ALL'),
    ('DEAN',             'ASSIGNMENT_MANAGE_OFFICE')
ON CONFLICT (role_code, permission_code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Helpful SELECT at the end so the operator can confirm counts.
-- ---------------------------------------------------------------------------

SELECT
    (SELECT COUNT(*) FROM university.campuses)  AS campuses,
    (SELECT COUNT(*) FROM university.programs)  AS programs,
    (SELECT COUNT(*) FROM university.majors)    AS majors,
    (SELECT COUNT(*) FROM university.units)     AS units,
    (SELECT COUNT(*) FROM university.permissions) AS permissions,
    (SELECT COUNT(*) FROM university.role_permissions) AS role_permissions;

-- ---------------------------------------------------------------------------
-- Wipe demo data (uncomment to use):
--
-- TRUNCATE TABLE
--     university.notifications,
--     university.enrollments,
--     university.teaching_assignments,
--     university.course_plans,
--     university.courses,
--     university.students,
--     university.staff,
--     university.units,
--     university.app_user_roles,
--     university.app_users,
--     university.role_permissions,
--     university.permissions,
--     university.majors,
--     university.programs,
--     university.campuses
-- RESTART IDENTITY CASCADE;
-- ---------------------------------------------------------------------------
