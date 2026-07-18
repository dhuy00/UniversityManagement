-- PostgreSQL development reset and schema installation.
-- WARNING: this permanently deletes every object and every row in schema
-- university. Run only against the local development database.

BEGIN;

DROP SCHEMA IF EXISTS university CASCADE;
CREATE SCHEMA university;
SET search_path TO university, public;

-- Reference data: these replace hard-coded values and make the model extensible.
CREATE TABLE campuses (
    campus_id   varchar(20)  PRIMARY KEY,
    campus_name varchar(150) NOT NULL UNIQUE
);

CREATE TABLE programs (
    program_id   varchar(20)  PRIMARY KEY,
    program_name varchar(150) NOT NULL UNIQUE
);

CREATE TABLE majors (
    major_id   varchar(20)  PRIMARY KEY,
    major_name varchar(150) NOT NULL UNIQUE
);

-- RBAC. Roles grant permissions; users can receive one or more roles.
CREATE TABLE roles (
    role_code   varchar(30)  PRIMARY KEY,
    role_name   varchar(100) NOT NULL UNIQUE,
    description text
);

CREATE TABLE permissions (
    permission_code varchar(80)  PRIMARY KEY,
    description     varchar(255) NOT NULL
);

CREATE TABLE app_users (
    user_id       bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      varchar(128) NOT NULL,
    password_hash varchar(255) NOT NULL,
    is_active     boolean      NOT NULL DEFAULT true,
    created_at    timestamptz  NOT NULL DEFAULT now(),
    updated_at    timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT ck_app_users_username
        CHECK (username ~ '^[A-Za-z][A-Za-z0-9_$#]{0,127}$')
);

CREATE UNIQUE INDEX ux_app_users_username_ci
    ON app_users (lower(username));

CREATE TABLE role_permissions (
    role_code       varchar(30) NOT NULL REFERENCES roles(role_code) ON DELETE CASCADE,
    permission_code varchar(80) NOT NULL REFERENCES permissions(permission_code) ON DELETE CASCADE,
    PRIMARY KEY (role_code, permission_code)
);

CREATE TABLE app_user_roles (
    user_id     bigint      NOT NULL REFERENCES app_users(user_id) ON DELETE CASCADE,
    role_code   varchar(30) NOT NULL REFERENCES roles(role_code),
    granted_at  timestamptz NOT NULL DEFAULT now(),
    granted_by  bigint      REFERENCES app_users(user_id) ON DELETE SET NULL,
    PRIMARY KEY (user_id, role_code)
);

-- University domain.
CREATE TABLE units (
    unit_id       varchar(20)  PRIMARY KEY,
    unit_name     varchar(150) NOT NULL UNIQUE,
    head_staff_id varchar(20)
);

CREATE TABLE staff (
    staff_id      varchar(20)   PRIMARY KEY,
    user_id       bigint        NOT NULL UNIQUE REFERENCES app_users(user_id),
    full_name     varchar(150)  NOT NULL,
    gender        varchar(10)   NOT NULL,
    date_of_birth date          NOT NULL,
    allowance     numeric(12,2) NOT NULL DEFAULT 0,
    phone         varchar(20),
    unit_id       varchar(20)   NOT NULL,
    campus_id     varchar(20)   NOT NULL REFERENCES campuses(campus_id),
    created_at    timestamptz   NOT NULL DEFAULT now(),
    updated_at    timestamptz   NOT NULL DEFAULT now(),

    -- A referenced unique constraint must be non-deferrable in PostgreSQL.
    -- The circular unit/head relationship remains deferrable on its FKs.
    CONSTRAINT uq_staff_id_unit UNIQUE (staff_id, unit_id),
    CONSTRAINT ck_staff_gender CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    CONSTRAINT ck_staff_allowance CHECK (allowance >= 0),
    CONSTRAINT fk_staff_unit FOREIGN KEY (unit_id)
        REFERENCES units(unit_id) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE students (
    student_id          varchar(20)  PRIMARY KEY,
    user_id             bigint       NOT NULL UNIQUE REFERENCES app_users(user_id),
    full_name           varchar(150) NOT NULL,
    gender              varchar(10)  NOT NULL,
    date_of_birth       date         NOT NULL,
    address             varchar(500),
    phone               varchar(20),
    program_id          varchar(20)  NOT NULL REFERENCES programs(program_id),
    major_id            varchar(20)  NOT NULL REFERENCES majors(major_id),
    accumulated_credits smallint     NOT NULL DEFAULT 0,
    cumulative_gpa      numeric(4,2) NOT NULL DEFAULT 0,
    campus_id           varchar(20)  NOT NULL REFERENCES campuses(campus_id),
    created_at          timestamptz  NOT NULL DEFAULT now(),
    updated_at          timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT ck_students_gender CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    CONSTRAINT ck_students_credits CHECK (accumulated_credits BETWEEN 0 AND 300),
    CONSTRAINT ck_students_gpa CHECK (cumulative_gpa BETWEEN 0 AND 10)
);

ALTER TABLE units
    ADD CONSTRAINT fk_units_head_in_unit
    FOREIGN KEY (head_staff_id, unit_id)
    REFERENCES staff(staff_id, unit_id)
    DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE courses (
    course_id        varchar(20)  PRIMARY KEY,
    course_name      varchar(200) NOT NULL,
    credits          smallint     NOT NULL,
    theory_periods   smallint     NOT NULL DEFAULT 0,
    practice_periods smallint     NOT NULL DEFAULT 0,
    max_students     smallint     NOT NULL,
    unit_id          varchar(20)  NOT NULL REFERENCES units(unit_id),
    created_at       timestamptz  NOT NULL DEFAULT now(),
    updated_at       timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT ck_courses_credits CHECK (credits BETWEEN 1 AND 10),
    CONSTRAINT ck_courses_periods CHECK (
        theory_periods >= 0 AND practice_periods >= 0
        AND theory_periods + practice_periods > 0
    ),
    CONSTRAINT ck_courses_max_students CHECK (max_students BETWEEN 1 AND 1000)
);

CREATE TABLE course_plans (
    course_id     varchar(20) NOT NULL REFERENCES courses(course_id),
    semester      smallint    NOT NULL,
    academic_year smallint    NOT NULL,
    program_id    varchar(20) NOT NULL REFERENCES programs(program_id),
    start_date    date        NOT NULL,
    PRIMARY KEY (course_id, semester, academic_year, program_id),
    CONSTRAINT ck_course_plans_semester CHECK (semester IN (1, 2, 3)),
    CONSTRAINT ck_course_plans_year CHECK (academic_year BETWEEN 2000 AND 9999),
    CONSTRAINT ck_course_plans_start_date CHECK (extract(year FROM start_date) = academic_year)
);

CREATE TABLE teaching_assignments (
    lecturer_id   varchar(20) NOT NULL REFERENCES staff(staff_id),
    course_id     varchar(20) NOT NULL,
    semester      smallint    NOT NULL,
    academic_year smallint    NOT NULL,
    program_id    varchar(20) NOT NULL,
    PRIMARY KEY (lecturer_id, course_id, semester, academic_year, program_id),
    FOREIGN KEY (course_id, semester, academic_year, program_id)
        REFERENCES course_plans(course_id, semester, academic_year, program_id)
);

CREATE TABLE enrollments (
    student_id       varchar(20) NOT NULL REFERENCES students(student_id),
    lecturer_id      varchar(20) NOT NULL,
    course_id        varchar(20) NOT NULL,
    semester         smallint    NOT NULL,
    academic_year    smallint    NOT NULL,
    program_id       varchar(20) NOT NULL,
    practice_score   numeric(4,2),
    process_score    numeric(4,2),
    final_exam_score numeric(4,2),
    final_score      numeric(4,2),
    PRIMARY KEY (student_id, lecturer_id, course_id, semester, academic_year, program_id),
    FOREIGN KEY (lecturer_id, course_id, semester, academic_year, program_id)
        REFERENCES teaching_assignments(lecturer_id, course_id, semester, academic_year, program_id),
    CONSTRAINT ck_enrollments_practice_score CHECK (practice_score BETWEEN 0 AND 10),
    CONSTRAINT ck_enrollments_process_score CHECK (process_score BETWEEN 0 AND 10),
    CONSTRAINT ck_enrollments_final_exam_score CHECK (final_exam_score BETWEEN 0 AND 10),
    CONSTRAINT ck_enrollments_final_score CHECK (final_score BETWEEN 0 AND 10)
);

CREATE TABLE notifications (
    notification_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    content         text        NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    created_by      bigint      NOT NULL REFERENCES app_users(user_id)
);

-- Access paths for the planned API queries and foreign-key maintenance.
CREATE INDEX ix_staff_unit ON staff(unit_id);
CREATE INDEX ix_staff_campus ON staff(campus_id);
CREATE INDEX ix_units_head_staff ON units(head_staff_id, unit_id);
CREATE INDEX ix_courses_unit ON courses(unit_id);
CREATE INDEX ix_students_program_major_campus ON students(program_id, major_id, campus_id);
CREATE INDEX ix_course_plans_program_term ON course_plans(program_id, academic_year, semester, start_date);
CREATE INDEX ix_assignments_course_plan ON teaching_assignments(course_id, semester, academic_year, program_id);
CREATE INDEX ix_assignments_lecturer_term ON teaching_assignments(lecturer_id, academic_year, semester);
CREATE INDEX ix_enrollments_assignment ON enrollments(lecturer_id, course_id, semester, academic_year, program_id);
CREATE INDEX ix_enrollments_student_term ON enrollments(student_id, academic_year, semester);
CREATE INDEX ix_notifications_created_at ON notifications(created_at DESC);

-- Maintains update timestamps without duplicating this logic in every query.
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_app_users_updated_at
    BEFORE UPDATE ON app_users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_staff_updated_at
    BEFORE UPDATE ON staff
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_students_updated_at
    BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_courses_updated_at
    BEFORE UPDATE ON courses
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Initial reference data and RBAC catalogue.
INSERT INTO campuses (campus_id, campus_name) VALUES
    ('CAMPUS_1', 'Campus 1'),
    ('CAMPUS_2', 'Campus 2');

INSERT INTO programs (program_id, program_name) VALUES
    ('REGULAR', 'Regular'),
    ('HIGH_QUALITY', 'High Quality'),
    ('ADVANCED', 'Advanced'),
    ('VIETNAM_FRANCE', 'Vietnam France');

INSERT INTO majors (major_id, major_name) VALUES
    ('IS', 'Information Systems'),
    ('SE', 'Software Engineering'),
    ('CS', 'Computer Science'),
    ('IT', 'Information Technology'),
    ('CV', 'Computer Vision'),
    ('NET', 'Computer Networks and Telecommunications');

INSERT INTO roles (role_code, role_name, description) VALUES
    ('STUDENT', 'Student', 'Student self-service access'),
    ('BASIC_STAFF', 'Basic Staff', 'Staff self-service access'),
    ('LECTURER', 'Lecturer', 'Teaching and grading access'),
    ('ACADEMIC_AFFAIRS', 'Academic Affairs', 'Academic operations access'),
    ('UNIT_HEAD', 'Unit Head', 'Unit management access'),
    ('DEAN', 'Dean', 'Faculty-wide administration access');

INSERT INTO permissions (permission_code, description) VALUES
    -- CS#1: common staff access. Row and column scopes are enforced by RLS
    -- and trusted write paths in later migration steps.
    ('STAFF_READ_SELF', 'Read own staff profile'),
    ('STAFF_PHONE_UPDATE_SELF', 'Update only own staff phone number'),
    ('STUDENT_READ_ALL', 'Read all student records'),
    ('UNIT_READ_ALL', 'Read all units'),
    ('COURSE_READ_ALL', 'Read all courses'),
    ('COURSE_PLAN_READ_ALL', 'Read all course plans'),

    -- CS#2: lecturer access to assigned teaching and grades.
    ('ASSIGNMENT_READ_SELF', 'Read own teaching assignments'),
    ('ENROLLMENT_READ_ASSIGNED', 'Read enrollments for assigned classes'),
    ('GRADE_UPDATE_ASSIGNED', 'Update grades for assigned classes'),

    -- CS#3: Academic Affairs operations.
    ('STUDENT_CREATE_UPDATE', 'Create students and update student records'),
    ('UNIT_CREATE_UPDATE', 'Create units and update unit records'),
    ('COURSE_CREATE_UPDATE', 'Create courses and update course records'),
    ('COURSE_PLAN_CREATE_UPDATE', 'Create course plans and update course plans'),
    ('ASSIGNMENT_READ_ALL', 'Read all teaching assignments'),
    ('ASSIGNMENT_UPDATE_OFFICE', 'Update assignments for courses managed by the faculty office'),
    ('ENROLLMENT_CREATE_DELETE_ALL', 'Create or delete enrollments during an open registration period'),

    -- CS#4 and CS#5: assignment administration by organizational scope.
    ('ASSIGNMENT_READ_OWN_UNIT', 'Read assignments of lecturers in own unit'),
    ('ASSIGNMENT_MANAGE_OWN_UNIT', 'Create, update, or delete assignments for courses managed by own unit'),
    ('ASSIGNMENT_MANAGE_OFFICE', 'Create, update, or delete assignments for courses managed by the faculty office'),
    ('STAFF_MANAGE_ALL', 'Create, read, update, or delete all staff records'),
    ('DATABASE_READ_ALL', 'Read all university domain data without row restrictions'),

    -- CS#6: student self-service access.
    ('STUDENT_READ_SELF', 'Read own student profile'),
    ('STUDENT_CONTACT_UPDATE_SELF', 'Update only own student address and phone number'),
    ('COURSE_PLAN_READ_OWN_PROGRAM', 'Read course plans for own academic program'),
    ('ENROLLMENT_READ_SELF', 'Read own enrollments and grades'),
    ('ENROLLMENT_CREATE_DELETE_SELF', 'Create or delete own enrollments during an open registration period');

INSERT INTO role_permissions (role_code, permission_code)
SELECT role_code, permission_code
FROM (VALUES
    -- CS#1: Basic Staff.
    ('BASIC_STAFF', 'STAFF_READ_SELF'),
    ('BASIC_STAFF', 'STAFF_PHONE_UPDATE_SELF'),
    ('BASIC_STAFF', 'STUDENT_READ_ALL'),
    ('BASIC_STAFF', 'UNIT_READ_ALL'),
    ('BASIC_STAFF', 'COURSE_READ_ALL'),
    ('BASIC_STAFF', 'COURSE_PLAN_READ_ALL'),

    -- CS#2: Lecturer, including every CS#1 permission.
    ('LECTURER', 'STAFF_READ_SELF'),
    ('LECTURER', 'STAFF_PHONE_UPDATE_SELF'),
    ('LECTURER', 'STUDENT_READ_ALL'),
    ('LECTURER', 'UNIT_READ_ALL'),
    ('LECTURER', 'COURSE_READ_ALL'),
    ('LECTURER', 'COURSE_PLAN_READ_ALL'),
    ('LECTURER', 'ASSIGNMENT_READ_SELF'),
    ('LECTURER', 'ENROLLMENT_READ_ASSIGNED'),
    ('LECTURER', 'GRADE_UPDATE_ASSIGNED'),

    -- CS#3: Academic Affairs, including every CS#1 permission.
    ('ACADEMIC_AFFAIRS', 'STAFF_READ_SELF'),
    ('ACADEMIC_AFFAIRS', 'STAFF_PHONE_UPDATE_SELF'),
    ('ACADEMIC_AFFAIRS', 'STUDENT_READ_ALL'),
    ('ACADEMIC_AFFAIRS', 'UNIT_READ_ALL'),
    ('ACADEMIC_AFFAIRS', 'COURSE_READ_ALL'),
    ('ACADEMIC_AFFAIRS', 'COURSE_PLAN_READ_ALL'),
    ('ACADEMIC_AFFAIRS', 'STUDENT_CREATE_UPDATE'),
    ('ACADEMIC_AFFAIRS', 'UNIT_CREATE_UPDATE'),
    ('ACADEMIC_AFFAIRS', 'COURSE_CREATE_UPDATE'),
    ('ACADEMIC_AFFAIRS', 'COURSE_PLAN_CREATE_UPDATE'),
    ('ACADEMIC_AFFAIRS', 'ASSIGNMENT_READ_ALL'),
    ('ACADEMIC_AFFAIRS', 'ASSIGNMENT_UPDATE_OFFICE'),
    ('ACADEMIC_AFFAIRS', 'ENROLLMENT_CREATE_DELETE_ALL'),

    -- CS#4: Unit Head, including every CS#2 permission.
    ('UNIT_HEAD', 'STAFF_READ_SELF'),
    ('UNIT_HEAD', 'STAFF_PHONE_UPDATE_SELF'),
    ('UNIT_HEAD', 'STUDENT_READ_ALL'),
    ('UNIT_HEAD', 'UNIT_READ_ALL'),
    ('UNIT_HEAD', 'COURSE_READ_ALL'),
    ('UNIT_HEAD', 'COURSE_PLAN_READ_ALL'),
    ('UNIT_HEAD', 'ASSIGNMENT_READ_SELF'),
    ('UNIT_HEAD', 'ENROLLMENT_READ_ASSIGNED'),
    ('UNIT_HEAD', 'GRADE_UPDATE_ASSIGNED'),
    ('UNIT_HEAD', 'ASSIGNMENT_READ_OWN_UNIT'),
    ('UNIT_HEAD', 'ASSIGNMENT_MANAGE_OWN_UNIT'),

    -- CS#5: Dean, including every CS#2 permission.
    ('DEAN', 'STAFF_READ_SELF'),
    ('DEAN', 'STAFF_PHONE_UPDATE_SELF'),
    ('DEAN', 'STUDENT_READ_ALL'),
    ('DEAN', 'UNIT_READ_ALL'),
    ('DEAN', 'COURSE_READ_ALL'),
    ('DEAN', 'COURSE_PLAN_READ_ALL'),
    ('DEAN', 'ASSIGNMENT_READ_SELF'),
    ('DEAN', 'ENROLLMENT_READ_ASSIGNED'),
    ('DEAN', 'GRADE_UPDATE_ASSIGNED'),
    ('DEAN', 'ASSIGNMENT_MANAGE_OFFICE'),
    ('DEAN', 'STAFF_MANAGE_ALL'),
    ('DEAN', 'DATABASE_READ_ALL'),

    -- CS#6: Student.
    ('STUDENT', 'STUDENT_READ_SELF'),
    ('STUDENT', 'STUDENT_CONTACT_UPDATE_SELF'),
    ('STUDENT', 'COURSE_READ_ALL'),
    ('STUDENT', 'COURSE_PLAN_READ_OWN_PROGRAM'),
    ('STUDENT', 'ENROLLMENT_READ_SELF'),
    ('STUDENT', 'ENROLLMENT_CREATE_DELETE_SELF')
) AS grants(role_code, permission_code);

COMMIT;
