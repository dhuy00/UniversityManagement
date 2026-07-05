-- Phase 3 - Step 3.1: Minimum coarse-grained privileges for CS#6
-- Target database: Oracle Database 21c / XEPDB1
--
-- Run as UNIVERSITY_APP after Phase 2 is complete.
--
-- Important: Do not use student accounts for application queries until the
-- VPD policies in Steps 3.2 and 3.3 have been installed.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'UNIVERSITY_APP' THEN
        RAISE_APPLICATION_ERROR(
            -20700,
            'Run this script as UNIVERSITY_APP.'
        );
    END IF;
END;
/

-- Normalize only RL_STUDENT grants on CS#6 objects. Grants for CS#1-CS#5 are
-- not changed by this script.
BEGIN
    FOR grant_record IN (
        SELECT DISTINCT TABLE_NAME
        FROM (
            SELECT TABLE_NAME
            FROM USER_TAB_PRIVS_MADE
            WHERE GRANTEE = 'RL_STUDENT'
              AND TABLE_NAME IN (
                  'STUDENTS',
                  'COURSES',
                  'COURSE_PLANS',
                  'ENROLLMENTS'
              )
            UNION
            SELECT TABLE_NAME
            FROM USER_COL_PRIVS_MADE
            WHERE GRANTEE = 'RL_STUDENT'
              AND TABLE_NAME IN (
                  'STUDENTS',
                  'COURSES',
                  'COURSE_PLANS',
                  'ENROLLMENTS'
              )
        )
    )
    LOOP
        EXECUTE IMMEDIATE
            'REVOKE ALL ON ' ||
            DBMS_ASSERT.SIMPLE_SQL_NAME(grant_record.TABLE_NAME) ||
            ' FROM RL_STUDENT';
    END LOOP;
END;
/

-- A student may read only their own row after the Step 3.2 VPD policy.
GRANT SELECT ON STUDENTS TO RL_STUDENT;
GRANT UPDATE (ADDRESS, PHONE) ON STUDENTS TO RL_STUDENT;

-- All courses are visible. Course plans are restricted by PROGRAM_ID in VPD.
GRANT SELECT ON COURSES TO RL_STUDENT;
GRANT SELECT ON COURSE_PLANS TO RL_STUDENT;
GRANT SELECT ON TEACHING_ASSIGNMENTS TO RL_STUDENT;

-- Enrollment rows are restricted to the current student in Step 3.3.
GRANT SELECT ON ENROLLMENTS TO RL_STUDENT;

-- Excluding score columns from the INSERT grant prevents students from
-- supplying PRACTICE_SCORE, PROCESS_SCORE, FINAL_EXAM_SCORE, or FINAL_SCORE.
GRANT INSERT (
    STUDENT_ID,
    LECTURER_ID,
    COURSE_ID,
    SEMESTER,
    ACADEMIC_YEAR,
    PROGRAM_ID
) ON ENROLLMENTS TO RL_STUDENT;

GRANT DELETE ON ENROLLMENTS TO RL_STUDENT;

PROMPT
PROMPT Direct table-level RL_STUDENT grants:

COLUMN TABLE_NAME FORMAT A28
COLUMN PRIVILEGE FORMAT A12
COLUMN GRANTABLE FORMAT A10

SELECT
    TABLE_NAME,
    PRIVILEGE,
    GRANTABLE
FROM USER_TAB_PRIVS_MADE
WHERE GRANTEE = 'RL_STUDENT'
  AND TABLE_NAME IN (
      'STUDENTS',
      'COURSES',
      'COURSE_PLANS',
      'ENROLLMENTS'
  )
ORDER BY TABLE_NAME, PRIVILEGE;

PROMPT
PROMPT Direct column-level RL_STUDENT grants:

COLUMN COLUMN_NAME FORMAT A28

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    PRIVILEGE,
    GRANTABLE
FROM USER_COL_PRIVS_MADE
WHERE GRANTEE = 'RL_STUDENT'
  AND TABLE_NAME IN (
      'STUDENTS',
      'COURSES',
      'COURSE_PLANS',
      'ENROLLMENTS'
  )
ORDER BY TABLE_NAME, PRIVILEGE, COLUMN_NAME;

DECLARE
    v_table_grants       PLS_INTEGER;
    v_column_grants      PLS_INTEGER;
    v_score_grants       PLS_INTEGER;
    v_update_enrollment  PLS_INTEGER;
    v_grantable_count    PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_table_grants
    FROM USER_TAB_PRIVS_MADE
    WHERE GRANTEE = 'RL_STUDENT'
      AND TABLE_NAME IN (
          'STUDENTS',
          'COURSES',
          'COURSE_PLANS',
          'ENROLLMENTS'
      );

    SELECT COUNT(*)
    INTO v_column_grants
    FROM USER_COL_PRIVS_MADE
    WHERE GRANTEE = 'RL_STUDENT'
      AND TABLE_NAME IN ('STUDENTS', 'ENROLLMENTS');

    SELECT COUNT(*)
    INTO v_score_grants
    FROM USER_COL_PRIVS_MADE
    WHERE GRANTEE = 'RL_STUDENT'
      AND TABLE_NAME = 'ENROLLMENTS'
      AND COLUMN_NAME IN (
          'PRACTICE_SCORE',
          'PROCESS_SCORE',
          'FINAL_EXAM_SCORE',
          'FINAL_SCORE'
      );

    SELECT COUNT(*)
    INTO v_update_enrollment
    FROM (
        SELECT PRIVILEGE
        FROM USER_TAB_PRIVS_MADE
        WHERE GRANTEE = 'RL_STUDENT'
          AND TABLE_NAME = 'ENROLLMENTS'
          AND PRIVILEGE = 'UPDATE'
        UNION ALL
        SELECT PRIVILEGE
        FROM USER_COL_PRIVS_MADE
        WHERE GRANTEE = 'RL_STUDENT'
          AND TABLE_NAME = 'ENROLLMENTS'
          AND PRIVILEGE = 'UPDATE'
    );

    SELECT COUNT(*)
    INTO v_grantable_count
    FROM (
        SELECT GRANTABLE
        FROM USER_TAB_PRIVS_MADE
        WHERE GRANTEE = 'RL_STUDENT'
        UNION ALL
        SELECT GRANTABLE
        FROM USER_COL_PRIVS_MADE
        WHERE GRANTEE = 'RL_STUDENT'
    )
    WHERE GRANTABLE = 'YES';

    IF v_table_grants <> 5 THEN
        RAISE_APPLICATION_ERROR(
            -20701,
            'Expected 5 direct table grants, found ' ||
            v_table_grants || '.'
        );
    END IF;

    IF v_column_grants <> 8 THEN
        RAISE_APPLICATION_ERROR(
            -20702,
            'Expected 8 direct column grants, found ' ||
            v_column_grants || '.'
        );
    END IF;

    IF v_score_grants <> 0 OR v_update_enrollment <> 0 THEN
        RAISE_APPLICATION_ERROR(
            -20703,
            'RL_STUDENT must not insert or update score columns.'
        );
    END IF;

    IF v_grantable_count <> 0 THEN
        RAISE_APPLICATION_ERROR(
            -20704,
            'RL_STUDENT must not receive WITH GRANT OPTION.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Verified 5 table grants, 8 column grants, no score UPDATE, ' ||
        'and no WITH GRANT OPTION.'
    );
END;
/

PROMPT Phase 3 - Step 3.1 completed successfully.
