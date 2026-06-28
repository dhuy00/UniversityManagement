-- Phase 1 - Step 6: Schema, data, and baseline-performance verification
-- Target database: Oracle Database 21c
-- Run as the application owner after scripts 01 through 05.
--
-- This script is read-only. It prints every assertion and exits with an error
-- when one or more required checks fail.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
SET FEEDBACK ON
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

PROMPT ============================================================
PROMPT Phase 1 verification
PROMPT ============================================================

DECLARE
    v_actual       PLS_INTEGER;
    v_failures     PLS_INTEGER := 0;

    PROCEDURE assert_equals(
        p_check_name  IN VARCHAR2,
        p_actual      IN PLS_INTEGER,
        p_expected    IN PLS_INTEGER
    )
    IS
    BEGIN
        IF p_actual = p_expected THEN
            DBMS_OUTPUT.PUT_LINE(
                '[PASS] ' || RPAD(p_check_name, 42) ||
                ' expected=' || p_expected || ', actual=' || p_actual
            );
        ELSE
            v_failures := v_failures + 1;
            DBMS_OUTPUT.PUT_LINE(
                '[FAIL] ' || RPAD(p_check_name, 42) ||
                ' expected=' || p_expected || ', actual=' || p_actual
            );
        END IF;
    END assert_equals;
BEGIN
    -- Schema objects
    SELECT COUNT(*)
    INTO v_actual
    FROM USER_TABLES
    WHERE TABLE_NAME IN (
        'UNITS',
        'STAFF',
        'STUDENTS',
        'COURSES',
        'COURSE_PLANS',
        'TEACHING_ASSIGNMENTS',
        'ENROLLMENTS',
        'NOTIFICATIONS'
    );
    assert_equals('Application tables', v_actual, 8);

    SELECT COUNT(*)
    INTO v_actual
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME IN (
        'UNITS',
        'STAFF',
        'STUDENTS',
        'COURSES',
        'COURSE_PLANS',
        'TEACHING_ASSIGNMENTS',
        'ENROLLMENTS',
        'NOTIFICATIONS'
    );
    assert_equals('Application columns', v_actual, 56);

    SELECT COUNT(*)
    INTO v_actual
    FROM USER_CONSTRAINTS
    WHERE CONSTRAINT_NAME IN (
        'PK_UNITS',
        'PK_STAFF',
        'PK_STUDENTS',
        'PK_COURSES',
        'PK_COURSE_PLANS',
        'PK_TEACHING_ASSIGNMENTS',
        'PK_ENROLLMENTS',
        'PK_NOTIFICATIONS'
    )
      AND CONSTRAINT_TYPE = 'P'
      AND STATUS = 'ENABLED'
      AND VALIDATED = 'VALIDATED';
    assert_equals('Enabled and validated primary keys', v_actual, 8);

    SELECT COUNT(*)
    INTO v_actual
    FROM USER_CONSTRAINTS
    WHERE CONSTRAINT_NAME LIKE 'UQ\_%' ESCAPE '\'
      AND CONSTRAINT_TYPE = 'U'
      AND STATUS = 'ENABLED'
      AND VALIDATED = 'VALIDATED';
    assert_equals('Enabled and validated unique constraints', v_actual, 4);

    SELECT COUNT(*)
    INTO v_actual
    FROM USER_CONSTRAINTS
    WHERE CONSTRAINT_NAME LIKE 'CK\_%' ESCAPE '\'
      AND CONSTRAINT_TYPE = 'C'
      AND STATUS = 'ENABLED'
      AND VALIDATED = 'VALIDATED';
    assert_equals('Enabled and validated check constraints', v_actual, 30);

    SELECT COUNT(*)
    INTO v_actual
    FROM USER_CONSTRAINTS
    WHERE CONSTRAINT_NAME LIKE 'FK\_%' ESCAPE '\'
      AND CONSTRAINT_TYPE = 'R'
      AND STATUS = 'ENABLED'
      AND VALIDATED = 'VALIDATED';
    assert_equals('Enabled and validated foreign keys', v_actual, 8);

    SELECT COUNT(*)
    INTO v_actual
    FROM USER_INDEXES
    WHERE INDEX_NAME IN (
        'IX_STAFF_UNIT_ROLE',
        'IX_UNITS_HEAD_STAFF',
        'IX_COURSES_UNIT',
        'IX_STUDENTS_PROGRAM_MAJOR_CAMPUS',
        'IX_COURSE_PLANS_PROGRAM_TERM',
        'IX_ASSIGNMENTS_COURSE_PLAN',
        'IX_ASSIGNMENTS_LECTURER_TERM',
        'IX_ENROLLMENTS_ASSIGNMENT',
        'IX_ENROLLMENTS_STUDENT_TERM',
        'IX_NOTIFICATIONS_CREATED_AT'
    )
      AND STATUS = 'VALID';
    assert_equals('Valid application indexes', v_actual, 10);

    SELECT COUNT(*)
    INTO v_actual
    FROM USER_OBJECTS
    WHERE STATUS <> 'VALID'
      AND OBJECT_NAME NOT LIKE 'BIN$%';
    assert_equals('Invalid schema objects', v_actual, 0);

    -- Required row counts
    SELECT COUNT(*) INTO v_actual FROM UNITS;
    assert_equals('UNITS rows', v_actual, 7);

    SELECT COUNT(*) INTO v_actual FROM STAFF;
    assert_equals('STAFF rows', v_actual, 107);

    SELECT COUNT(*) INTO v_actual FROM STUDENTS;
    assert_equals('STUDENTS rows', v_actual, 4000);

    SELECT COUNT(*) INTO v_actual FROM COURSES;
    assert_equals('COURSES rows', v_actual, 7);

    SELECT COUNT(*) INTO v_actual FROM COURSE_PLANS;
    assert_equals('COURSE_PLANS rows', v_actual, 10);

    SELECT COUNT(*) INTO v_actual FROM TEACHING_ASSIGNMENTS;
    assert_equals('TEACHING_ASSIGNMENTS rows', v_actual, 10);

    SELECT COUNT(*) INTO v_actual FROM ENROLLMENTS;
    assert_equals('ENROLLMENTS rows', v_actual, 4);

    SELECT COUNT(*) INTO v_actual FROM NOTIFICATIONS;
    assert_equals('NOTIFICATIONS rows', v_actual, 4);

    -- Role distribution from the project requirements
    SELECT COUNT(*) INTO v_actual
    FROM STAFF WHERE ROLE_CODE = 'BASIC_STAFF';
    assert_equals('BASIC_STAFF rows', v_actual, 10);

    SELECT COUNT(*) INTO v_actual
    FROM STAFF WHERE ROLE_CODE = 'LECTURER';
    assert_equals('LECTURER rows', v_actual, 80);

    SELECT COUNT(*) INTO v_actual
    FROM STAFF WHERE ROLE_CODE = 'ACADEMIC_AFFAIRS';
    assert_equals('ACADEMIC_AFFAIRS rows', v_actual, 10);

    SELECT COUNT(*) INTO v_actual
    FROM STAFF WHERE ROLE_CODE = 'UNIT_HEAD';
    assert_equals('UNIT_HEAD rows', v_actual, 6);

    SELECT COUNT(*) INTO v_actual
    FROM STAFF WHERE ROLE_CODE = 'DEAN';
    assert_equals('DEAN rows', v_actual, 1);

    -- Cross-table integrity. These checks complement the enabled FKs and make
    -- failures explicit in the verification output.
    SELECT
        (SELECT COUNT(*)
         FROM STAFF s
         LEFT JOIN UNITS u ON u.UNIT_ID = s.UNIT_ID
         WHERE u.UNIT_ID IS NULL)
        +
        (SELECT COUNT(*)
         FROM COURSES c
         LEFT JOIN UNITS u ON u.UNIT_ID = c.UNIT_ID
         WHERE u.UNIT_ID IS NULL)
        +
        (SELECT COUNT(*)
         FROM COURSE_PLANS cp
         LEFT JOIN COURSES c ON c.COURSE_ID = cp.COURSE_ID
         WHERE c.COURSE_ID IS NULL)
        +
        (SELECT COUNT(*)
         FROM TEACHING_ASSIGNMENTS ta
         LEFT JOIN STAFF s ON s.STAFF_ID = ta.LECTURER_ID
         WHERE s.STAFF_ID IS NULL)
        +
        (SELECT COUNT(*)
         FROM ENROLLMENTS e
         LEFT JOIN STUDENTS s ON s.STUDENT_ID = e.STUDENT_ID
         WHERE s.STUDENT_ID IS NULL)
    INTO v_actual
    FROM DUAL;
    assert_equals('Orphan rows across core relations', v_actual, 0);

    SELECT COUNT(*)
    INTO v_actual
    FROM UNITS u
    LEFT JOIN STAFF s
      ON s.STAFF_ID = u.HEAD_STAFF_ID
     AND s.UNIT_ID = u.UNIT_ID
    WHERE s.STAFF_ID IS NULL
       OR (
           u.UNIT_ID = 'OFFICE'
           AND s.ROLE_CODE <> 'DEAN'
       )
       OR (
           u.UNIT_ID <> 'OFFICE'
           AND s.ROLE_CODE <> 'UNIT_HEAD'
       );
    assert_equals('Unit heads belong to and lead their units', v_actual, 0);

    SELECT COUNT(*)
    INTO v_actual
    FROM TEACHING_ASSIGNMENTS ta
    JOIN STAFF s ON s.STAFF_ID = ta.LECTURER_ID
    WHERE s.ROLE_CODE NOT IN ('LECTURER', 'UNIT_HEAD', 'DEAN');
    assert_equals('Assignments use eligible teaching staff', v_actual, 0);

    SELECT COUNT(*)
    INTO v_actual
    FROM ENROLLMENTS e
    JOIN STUDENTS s ON s.STUDENT_ID = e.STUDENT_ID
    WHERE s.PROGRAM_ID <> e.PROGRAM_ID;
    assert_equals('Enrollment program matches student', v_actual, 0);

    SELECT COUNT(*)
    INTO v_actual
    FROM (
        SELECT ORACLE_USERNAME
        FROM (
            SELECT ORACLE_USERNAME FROM STAFF
            UNION ALL
            SELECT ORACLE_USERNAME FROM STUDENTS
        )
        GROUP BY ORACLE_USERNAME
        HAVING COUNT(*) > 1
    );
    assert_equals('Cross-table username duplicates', v_actual, 0);

    SELECT COUNT(*)
    INTO v_actual
    FROM COURSE_PLANS
    WHERE EXTRACT(YEAR FROM START_DATE) <> ACADEMIC_YEAR
       OR EXTRACT(DAY FROM START_DATE) <> 1
       OR (
           SEMESTER = 1
           AND EXTRACT(MONTH FROM START_DATE) <> 1
       )
       OR (
           SEMESTER = 2
           AND EXTRACT(MONTH FROM START_DATE) <> 5
       )
       OR (
           SEMESTER = 3
           AND EXTRACT(MONTH FROM START_DATE) <> 9
       );
    assert_equals('Course-plan semester start dates', v_actual, 0);

    SELECT COUNT(*)
    INTO v_actual
    FROM USER_TABLES
    WHERE TABLE_NAME IN ('STAFF', 'STUDENTS')
      AND LAST_ANALYZED IS NOT NULL;
    assert_equals('Bulk tables have optimizer statistics', v_actual, 2);

    -- Only the 15 reference identities require real Oracle users. Synthetic
    -- load-test rows intentionally do not create database accounts.
    SELECT COUNT(*)
    INTO v_actual
    FROM ALL_USERS
    WHERE USERNAME IN (
        'DEAN01',
        'HEAD_IS01',
        'HEAD_SE01',
        'HEAD_CS01',
        'HEAD_IT01',
        'HEAD_CV01',
        'HEAD_NET01',
        'BASIC01',
        'BASIC02',
        'LECTURER01',
        'LECTURER02',
        'AFFAIRS01',
        'AFFAIRS02',
        'STUDENT01',
        'STUDENT02'
    );
    assert_equals('Oracle demo users', v_actual, 15);

    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');

    IF v_failures > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20020,
            'Phase 1 verification failed: ' || v_failures || ' check(s).'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE('[PASS] All mandatory Phase 1 checks completed.');
END;
/

PROMPT
PROMPT ============================================================
PROMPT Baseline query timings
PROMPT ============================================================

SET TIMING ON

PROMPT Query 1: Resolve one student by Oracle username
SELECT COUNT(*) AS MATCHED_STUDENTS
FROM STUDENTS
WHERE ORACLE_USERNAME = 'STUDENT4000';

PROMPT Query 2: Filter students by program, major, and campus
SELECT COUNT(*) AS FILTERED_STUDENTS
FROM STUDENTS
WHERE PROGRAM_ID = 'REGULAR'
  AND MAJOR_ID = 'IS'
  AND CAMPUS_ID = 'CAMPUS_1';

PROMPT Query 3: Find course plans for a program and term
SELECT COUNT(*) AS MATCHED_COURSE_PLANS
FROM COURSE_PLANS
WHERE PROGRAM_ID = 'REGULAR'
  AND ACADEMIC_YEAR = 2026
  AND SEMESTER = 2;

PROMPT Query 4: Find assignments for one lecturer and term
SELECT COUNT(*) AS MATCHED_ASSIGNMENTS
FROM TEACHING_ASSIGNMENTS
WHERE LECTURER_ID = 'S0010'
  AND ACADEMIC_YEAR = 2026
  AND SEMESTER = 2;

PROMPT Query 5: Find enrollments for one assigned class
SELECT COUNT(*) AS MATCHED_ENROLLMENTS
FROM ENROLLMENTS
WHERE LECTURER_ID = 'S0010'
  AND COURSE_ID = 'IS101'
  AND SEMESTER = 2
  AND ACADEMIC_YEAR = 2026
  AND PROGRAM_ID = 'REGULAR';

SET TIMING OFF

PROMPT
PROMPT Custom index definitions:

COLUMN INDEX_NAME FORMAT A38
COLUMN COLUMN_NAME FORMAT A28

SELECT
    index_name,
    column_position,
    column_name,
    descend
FROM USER_IND_COLUMNS
WHERE INDEX_NAME LIKE 'IX\_%' ESCAPE '\'
ORDER BY index_name, column_position;

PROMPT Phase 1 - Step 6 completed successfully.
