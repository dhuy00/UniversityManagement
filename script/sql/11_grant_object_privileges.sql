-- Phase 2 - Step 2.2: Coarse-grained object and column privileges
-- Target database: Oracle Database 21c / XEPDB1
--
-- Run as UNIVERSITY_APP after 10_create_security_roles.sql.
--
-- Important:
--   - These grants define which operations each role may attempt.
--   - Row-level restrictions are added in Steps 2.3-2.5.
--   - RL_STUDENT remains without application-table privileges until CS#6 VPD.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'UNIVERSITY_APP' THEN
        RAISE_APPLICATION_ERROR(
            -20200,
            'Run this script as UNIVERSITY_APP.'
        );
    END IF;
END;
/

-- Normalize direct grants made by UNIVERSITY_APP so rerunning this script
-- cannot leave stale privileges from an older policy version.
BEGIN
    FOR grant_record IN (
        SELECT DISTINCT GRANTEE, TABLE_NAME
        FROM (
            SELECT GRANTEE, TABLE_NAME
            FROM USER_TAB_PRIVS_MADE
            WHERE GRANTEE IN (
                'RL_BASIC_STAFF',
                'RL_LECTURER',
                'RL_ACADEMIC_AFFAIRS',
                'RL_UNIT_HEAD',
                'RL_DEAN',
                'RL_STUDENT'
            )
              AND TABLE_NAME IN (
                  'UNITS',
                  'STAFF',
                  'STUDENTS',
                  'COURSES',
                  'COURSE_PLANS',
                  'TEACHING_ASSIGNMENTS',
                  'ENROLLMENTS',
                  'NOTIFICATIONS'
              )
            UNION
            SELECT GRANTEE, TABLE_NAME
            FROM USER_COL_PRIVS_MADE
            WHERE GRANTEE IN (
                'RL_BASIC_STAFF',
                'RL_LECTURER',
                'RL_ACADEMIC_AFFAIRS',
                'RL_UNIT_HEAD',
                'RL_DEAN',
                'RL_STUDENT'
            )
              AND TABLE_NAME IN (
                  'UNITS',
                  'STAFF',
                  'STUDENTS',
                  'COURSES',
                  'COURSE_PLANS',
                  'TEACHING_ASSIGNMENTS',
                  'ENROLLMENTS',
                  'NOTIFICATIONS'
              )
        )
    )
    LOOP
        EXECUTE IMMEDIATE
            'REVOKE ALL ON ' ||
            DBMS_ASSERT.SIMPLE_SQL_NAME(grant_record.TABLE_NAME) ||
            ' FROM ' ||
            DBMS_ASSERT.SIMPLE_SQL_NAME(grant_record.GRANTEE);
    END LOOP;
END;
/

-- CS#1: basic staff
GRANT SELECT ON STAFF TO RL_BASIC_STAFF;
GRANT UPDATE (PHONE) ON STAFF TO RL_BASIC_STAFF;

GRANT SELECT ON STUDENTS TO RL_BASIC_STAFF;
GRANT SELECT ON UNITS TO RL_BASIC_STAFF;
GRANT SELECT ON COURSES TO RL_BASIC_STAFF;
GRANT SELECT ON COURSE_PLANS TO RL_BASIC_STAFF;

-- CS#2: lecturers inherit CS#1
GRANT SELECT ON TEACHING_ASSIGNMENTS TO RL_LECTURER;
GRANT SELECT ON ENROLLMENTS TO RL_LECTURER;
GRANT UPDATE (
    PRACTICE_SCORE,
    PROCESS_SCORE,
    FINAL_EXAM_SCORE,
    FINAL_SCORE
) ON ENROLLMENTS TO RL_LECTURER;

-- CS#3: academic-affairs staff inherit CS#1
GRANT INSERT, UPDATE ON STUDENTS TO RL_ACADEMIC_AFFAIRS;
GRANT INSERT, UPDATE ON UNITS TO RL_ACADEMIC_AFFAIRS;
GRANT INSERT, UPDATE ON COURSES TO RL_ACADEMIC_AFFAIRS;
GRANT INSERT, UPDATE ON COURSE_PLANS TO RL_ACADEMIC_AFFAIRS;

GRANT SELECT, UPDATE ON TEACHING_ASSIGNMENTS TO RL_ACADEMIC_AFFAIRS;
GRANT INSERT, DELETE ON ENROLLMENTS TO RL_ACADEMIC_AFFAIRS;

-- CS#4: unit heads inherit CS#2
GRANT INSERT, UPDATE, DELETE
ON TEACHING_ASSIGNMENTS
TO RL_UNIT_HEAD;

-- CS#5: the dean inherits CS#2 and can read the whole application schema
GRANT SELECT ON UNITS TO RL_DEAN;
GRANT SELECT ON STAFF TO RL_DEAN;
GRANT SELECT ON STUDENTS TO RL_DEAN;
GRANT SELECT ON COURSES TO RL_DEAN;
GRANT SELECT ON COURSE_PLANS TO RL_DEAN;
GRANT SELECT ON TEACHING_ASSIGNMENTS TO RL_DEAN;
GRANT SELECT ON ENROLLMENTS TO RL_DEAN;
GRANT SELECT ON NOTIFICATIONS TO RL_DEAN;

GRANT INSERT, UPDATE, DELETE ON STAFF TO RL_DEAN;
GRANT INSERT, UPDATE, DELETE
ON TEACHING_ASSIGNMENTS
TO RL_DEAN;

PROMPT
PROMPT Direct table-level grants:

COLUMN GRANTEE FORMAT A24
COLUMN TABLE_NAME FORMAT A28
COLUMN PRIVILEGE FORMAT A12

SELECT
    GRANTEE,
    TABLE_NAME,
    PRIVILEGE
FROM USER_TAB_PRIVS_MADE
WHERE GRANTEE IN (
    'RL_BASIC_STAFF',
    'RL_LECTURER',
    'RL_ACADEMIC_AFFAIRS',
    'RL_UNIT_HEAD',
    'RL_DEAN',
    'RL_STUDENT'
)
  AND TABLE_NAME IN (
      'UNITS',
      'STAFF',
      'STUDENTS',
      'COURSES',
      'COURSE_PLANS',
      'TEACHING_ASSIGNMENTS',
      'ENROLLMENTS',
      'NOTIFICATIONS'
  )
ORDER BY GRANTEE, TABLE_NAME, PRIVILEGE;

PROMPT
PROMPT Direct column-level grants:

COLUMN COLUMN_NAME FORMAT A24

SELECT
    GRANTEE,
    TABLE_NAME,
    COLUMN_NAME,
    PRIVILEGE
FROM USER_COL_PRIVS_MADE
WHERE GRANTEE IN (
    'RL_BASIC_STAFF',
    'RL_LECTURER',
    'RL_ACADEMIC_AFFAIRS',
    'RL_UNIT_HEAD',
    'RL_DEAN',
    'RL_STUDENT'
)
ORDER BY GRANTEE, TABLE_NAME, COLUMN_NAME, PRIVILEGE;

DECLARE
    v_actual  PLS_INTEGER;

    PROCEDURE assert_direct_grants(
        p_role_name          IN VARCHAR2,
        p_expected_tables    IN PLS_INTEGER,
        p_expected_columns   IN PLS_INTEGER
    )
    IS
        v_table_grants   PLS_INTEGER;
        v_column_grants  PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
        INTO v_table_grants
        FROM USER_TAB_PRIVS_MADE
        WHERE GRANTEE = p_role_name
          AND TABLE_NAME IN (
              'UNITS',
              'STAFF',
              'STUDENTS',
              'COURSES',
              'COURSE_PLANS',
              'TEACHING_ASSIGNMENTS',
              'ENROLLMENTS',
              'NOTIFICATIONS'
          );

        SELECT COUNT(*)
        INTO v_column_grants
        FROM USER_COL_PRIVS_MADE
        WHERE GRANTEE = p_role_name
          AND TABLE_NAME IN (
              'UNITS',
              'STAFF',
              'STUDENTS',
              'COURSES',
              'COURSE_PLANS',
              'TEACHING_ASSIGNMENTS',
              'ENROLLMENTS',
              'NOTIFICATIONS'
          );

        IF v_table_grants <> p_expected_tables
           OR v_column_grants <> p_expected_columns THEN
            RAISE_APPLICATION_ERROR(
                -20201,
                p_role_name ||
                ': expected table/column grants ' ||
                p_expected_tables || '/' || p_expected_columns ||
                ', found ' ||
                v_table_grants || '/' || v_column_grants || '.'
            );
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_role_name, 24) ||
            ' table grants=' || v_table_grants ||
            ', column grants=' || v_column_grants
        );
    END assert_direct_grants;
BEGIN
    assert_direct_grants('RL_BASIC_STAFF', 5, 1);
    assert_direct_grants('RL_LECTURER', 2, 4);
    assert_direct_grants('RL_ACADEMIC_AFFAIRS', 12, 0);
    assert_direct_grants('RL_UNIT_HEAD', 3, 0);
    assert_direct_grants('RL_DEAN', 14, 0);
    assert_direct_grants('RL_STUDENT', 0, 0);

    SELECT COUNT(*)
    INTO v_actual
    FROM USER_TAB_PRIVS_MADE
    WHERE GRANTEE IN (
        'RL_BASIC_STAFF',
        'RL_LECTURER',
        'RL_ACADEMIC_AFFAIRS',
        'RL_UNIT_HEAD',
        'RL_DEAN',
        'RL_STUDENT'
    )
      AND GRANTABLE = 'YES';

    IF v_actual <> 0 THEN
        RAISE_APPLICATION_ERROR(
            -20202,
            'Application roles must not receive WITH GRANT OPTION.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Verified direct grants and confirmed no WITH GRANT OPTION.'
    );
END;
/

PROMPT Phase 2 - Step 2.2 completed successfully.
