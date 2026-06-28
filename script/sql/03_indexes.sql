-- Phase 1 - Step 3: Application indexes
-- Target database: Oracle Database 21c
-- Prerequisites:
--   1. Run 01_schema.sql
--   2. Run 02_constraints.sql
--
-- Primary key and unique-constraint indexes are created automatically by
-- Oracle. This file only adds indexes needed by foreign keys and expected
-- application/security-policy access paths.

SET DEFINE OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('SYS', 'SYSTEM') THEN
        RAISE_APPLICATION_ERROR(
            -20000,
            'Run application scripts as UNIVERSITY_APP, not SYS or SYSTEM.'
        );
    END IF;
END;
/

-- Supports:
--   - FK_STAFF_UNIT
--   - listing staff in a unit
--   - resolving staff by unit and role for CS#4/CS#5
CREATE INDEX IX_STAFF_UNIT_ROLE
    ON STAFF (UNIT_ID, ROLE_CODE);

-- Supports FK_UNITS_HEAD_IN_UNIT. The table is small, but indexing the child
-- key also avoids unnecessary locking/scans when a referenced staff key changes.
CREATE INDEX IX_UNITS_HEAD_STAFF
    ON UNITS (HEAD_STAFF_ID, UNIT_ID);

-- Supports:
--   - FK_COURSES_UNIT
--   - finding courses managed by a unit for CS#3/CS#4/CS#5
CREATE INDEX IX_COURSES_UNIT
    ON COURSES (UNIT_ID);

-- Supports student and academic-affairs searches by program, major, and campus.
CREATE INDEX IX_STUDENTS_PROGRAM_MAJOR_CAMPUS
    ON STUDENTS (PROGRAM_ID, MAJOR_ID, CAMPUS_ID);

-- Supports CS#6 when a student lists course plans for their program and term.
-- START_DATE is included for the 14-day enrollment-window calculation.
CREATE INDEX IX_COURSE_PLANS_PROGRAM_TERM
    ON COURSE_PLANS (
        PROGRAM_ID,
        ACADEMIC_YEAR,
        SEMESTER,
        START_DATE
    );

-- Supports FK_ASSIGNMENTS_COURSE_PLAN. The assignment primary key starts with
-- LECTURER_ID, so it cannot efficiently support this foreign-key access path.
CREATE INDEX IX_ASSIGNMENTS_COURSE_PLAN
    ON TEACHING_ASSIGNMENTS (
        COURSE_ID,
        SEMESTER,
        ACADEMIC_YEAR,
        PROGRAM_ID
    );

-- Supports lecturer-specific assignment queries grouped by academic term.
CREATE INDEX IX_ASSIGNMENTS_LECTURER_TERM
    ON TEACHING_ASSIGNMENTS (
        LECTURER_ID,
        ACADEMIC_YEAR,
        SEMESTER
    );

-- Supports:
--   - FK_ENROLLMENTS_ASSIGNMENT
--   - CS#2 lecturer access to students and scores in assigned classes
CREATE INDEX IX_ENROLLMENTS_ASSIGNMENT
    ON ENROLLMENTS (
        LECTURER_ID,
        COURSE_ID,
        SEMESTER,
        ACADEMIC_YEAR,
        PROGRAM_ID
    );

-- Supports CS#6 student enrollment/history queries filtered by term.
CREATE INDEX IX_ENROLLMENTS_STUDENT_TERM
    ON ENROLLMENTS (
        STUDENT_ID,
        ACADEMIC_YEAR,
        SEMESTER
    );

-- Supports newest-first notification feeds. The future OLS label column will
-- receive a separate index only if execution-plan testing shows it is useful.
CREATE INDEX IX_NOTIFICATIONS_CREATED_AT
    ON NOTIFICATIONS (CREATED_AT DESC);

PROMPT Phase 1 - Step 3 completed: application indexes created.
