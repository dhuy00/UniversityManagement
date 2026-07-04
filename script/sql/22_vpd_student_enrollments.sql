-- Phase 3 - Step 3.3: CS#6 VPD for ENROLLMENTS
-- Target database: Oracle Database 21c / XEPDB1
--
-- Run as UNIVERSITY_APP after:
--   - 14_business_rule_guards.sql
--   - 21_vpd_students_course_plans.sql
--
-- This script replaces only the enrollment SELECT policy. Existing UPDATE,
-- INSERT, DELETE, and 14-day registration-window policies remain enabled.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'UNIVERSITY_APP' THEN
        RAISE_APPLICATION_ERROR(
            -20900,
            'Run this script as UNIVERSITY_APP.'
        );
    END IF;
END;
/

CREATE OR REPLACE PACKAGE ENROLLMENT_POLICY_PKG
AUTHID DEFINER
AS
    FUNCTION SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;
END ENROLLMENT_POLICY_PKG;
/

CREATE OR REPLACE PACKAGE BODY ENROLLMENT_POLICY_PKG
AS
    FUNCTION SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_role_code   VARCHAR2(30);
        v_staff_id    VARCHAR2(20);
        v_student_id  VARCHAR2(20);
    BEGIN
        IF UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'))
           IN ('UNIVERSITY_APP', 'SYS') THEN
            RETURN '1=1';
        END IF;

        v_role_code :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'ROLE_CODE');
        v_staff_id :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'STAFF_ID');
        v_student_id :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'STUDENT_ID');

        IF v_role_code = 'DEAN' THEN
            RETURN '1=1';
        ELSIF v_role_code IN ('LECTURER', 'UNIT_HEAD')
              AND v_staff_id IS NOT NULL THEN
            RETURN
                'LECTURER_ID = ' ||
                DBMS_ASSERT.ENQUOTE_LITERAL(v_staff_id);
        ELSIF v_role_code = 'STUDENT'
              AND v_student_id IS NOT NULL THEN
            RETURN
                'STUDENT_ID = ' ||
                DBMS_ASSERT.ENQUOTE_LITERAL(v_student_id);
        END IF;

        RETURN '1=0';
    END SELECT_PREDICATE;
END ENROLLMENT_POLICY_PKG;
/

SHOW ERRORS PACKAGE ENROLLMENT_POLICY_PKG
SHOW ERRORS PACKAGE BODY ENROLLMENT_POLICY_PKG

BEGIN
    FOR policy_record IN (
        SELECT OBJECT_NAME, POLICY_NAME
        FROM USER_POLICIES
        WHERE OBJECT_NAME = 'ENROLLMENTS'
          AND POLICY_NAME = 'P2_ENROLLMENT_SELECT'
    )
    LOOP
        DBMS_RLS.DROP_POLICY(
            object_schema => USER,
            object_name   => policy_record.OBJECT_NAME,
            policy_name   => policy_record.POLICY_NAME
        );
    END LOOP;

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'ENROLLMENTS',
        policy_name     => 'P2_ENROLLMENT_SELECT',
        function_schema => USER,
        policy_function =>
            'ENROLLMENT_POLICY_PKG.SELECT_PREDICATE',
        statement_types => 'SELECT',
        policy_type     => DBMS_RLS.DYNAMIC
    );
END;
/

COLUMN POLICY_NAME FORMAT A28
COLUMN PACKAGE FORMAT A28
COLUMN FUNCTION FORMAT A28
COLUMN SEL FORMAT A3
COLUMN INS FORMAT A3
COLUMN UPD FORMAT A3
COLUMN DEL FORMAT A3
COLUMN ENABLE FORMAT A6

SELECT
    POLICY_NAME,
    PACKAGE,
    FUNCTION,
    SEL,
    INS,
    UPD,
    DEL,
    ENABLE
FROM USER_POLICIES
WHERE OBJECT_NAME = 'ENROLLMENTS'
  AND POLICY_NAME IN (
      'P2_ENROLLMENT_SELECT',
      'P2_ENROLLMENT_UPDATE',
      'P2_ENROLLMENT_INSERT',
      'P2_ENROLLMENT_DELETE'
  )
ORDER BY POLICY_NAME;

DECLARE
    v_error_count         PLS_INTEGER;
    v_select_policy_count PLS_INTEGER;
    v_window_policy_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_error_count
    FROM USER_ERRORS
    WHERE NAME = 'ENROLLMENT_POLICY_PKG';

    SELECT COUNT(*)
    INTO v_select_policy_count
    FROM USER_POLICIES
    WHERE OBJECT_NAME = 'ENROLLMENTS'
      AND POLICY_NAME = 'P2_ENROLLMENT_SELECT'
      AND PACKAGE = 'ENROLLMENT_POLICY_PKG'
      AND FUNCTION = 'SELECT_PREDICATE'
      AND SEL = 'YES'
      AND ENABLE = 'YES';

    SELECT COUNT(*)
    INTO v_window_policy_count
    FROM USER_POLICIES
    WHERE OBJECT_NAME = 'ENROLLMENTS'
      AND POLICY_NAME IN (
          'P2_ENROLLMENT_INSERT',
          'P2_ENROLLMENT_DELETE'
      )
      AND ENABLE = 'YES';

    IF v_error_count <> 0 THEN
        RAISE_APPLICATION_ERROR(
            -20901,
            'ENROLLMENT_POLICY_PKG compiled with errors.'
        );
    END IF;

    IF v_select_policy_count <> 1 THEN
        RAISE_APPLICATION_ERROR(
            -20902,
            'Unified enrollment SELECT policy is missing or invalid.'
        );
    END IF;

    IF v_window_policy_count <> 2 THEN
        RAISE_APPLICATION_ERROR(
            -20903,
            'Enrollment INSERT/DELETE window policies are not both enabled.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Verified unified enrollment SELECT policy and retained both ' ||
        'registration-window policies.'
    );
END;
/

PROMPT Phase 3 - Step 3.3 completed successfully.
