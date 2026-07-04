-- Phase 3 - Step 3.2: CS#6 VPD for STUDENTS and COURSE_PLANS
-- Target database: Oracle Database 21c / XEPDB1
--
-- Run as UNIVERSITY_APP after 20_grant_student_privileges.sql.
-- Reconnect student sessions after this script, or manually refresh context
-- with UNIVERSITY_APP.SECURITY_CONTEXT_PKG.INITIALIZE_SESSION.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'UNIVERSITY_APP' THEN
        RAISE_APPLICATION_ERROR(
            -20800,
            'Run this script as UNIVERSITY_APP.'
        );
    END IF;
END;
/

CREATE OR REPLACE PACKAGE STUDENT_POLICY_PKG
AUTHID DEFINER
AS
    FUNCTION STUDENTS_SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION STUDENTS_UPDATE_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION COURSE_PLANS_SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;
END STUDENT_POLICY_PKG;
/

CREATE OR REPLACE PACKAGE BODY STUDENT_POLICY_PKG
AS
    FUNCTION OWNER_BYPASS
    RETURN BOOLEAN
    IS
    BEGIN
        RETURN UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'))
               IN ('UNIVERSITY_APP', 'SYS');
    END OWNER_BYPASS;

    FUNCTION QUOTED_VALUE(p_value IN VARCHAR2)
    RETURN VARCHAR2
    IS
    BEGIN
        RETURN DBMS_ASSERT.ENQUOTE_LITERAL(p_value);
    END QUOTED_VALUE;

    FUNCTION STUDENTS_SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_identity_type VARCHAR2(30);
        v_role_code     VARCHAR2(30);
        v_student_id    VARCHAR2(20);
    BEGIN
        IF OWNER_BYPASS THEN
            RETURN '1=1';
        END IF;

        v_identity_type :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'IDENTITY_TYPE');
        v_role_code :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'ROLE_CODE');
        v_student_id :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'STUDENT_ID');

        IF v_identity_type = 'STAFF'
           AND v_role_code IN (
               'BASIC_STAFF',
               'LECTURER',
               'ACADEMIC_AFFAIRS',
               'UNIT_HEAD',
               'DEAN'
           ) THEN
            RETURN '1=1';
        ELSIF v_identity_type = 'STUDENT'
              AND v_role_code = 'STUDENT'
              AND v_student_id IS NOT NULL THEN
            RETURN
                'STUDENT_ID = ' || QUOTED_VALUE(v_student_id);
        END IF;

        RETURN '1=0';
    END STUDENTS_SELECT_PREDICATE;

    FUNCTION STUDENTS_UPDATE_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_identity_type VARCHAR2(30);
        v_role_code     VARCHAR2(30);
        v_student_id    VARCHAR2(20);
    BEGIN
        IF OWNER_BYPASS THEN
            RETURN '1=1';
        END IF;

        v_identity_type :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'IDENTITY_TYPE');
        v_role_code :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'ROLE_CODE');
        v_student_id :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'STUDENT_ID');

        IF v_identity_type = 'STAFF'
           AND v_role_code = 'ACADEMIC_AFFAIRS' THEN
            RETURN '1=1';
        ELSIF v_identity_type = 'STUDENT'
              AND v_role_code = 'STUDENT'
              AND v_student_id IS NOT NULL THEN
            RETURN
                'STUDENT_ID = ' || QUOTED_VALUE(v_student_id);
        END IF;

        RETURN '1=0';
    END STUDENTS_UPDATE_PREDICATE;

    FUNCTION COURSE_PLANS_SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_identity_type VARCHAR2(30);
        v_role_code     VARCHAR2(30);
        v_program_id    VARCHAR2(20);
    BEGIN
        IF OWNER_BYPASS THEN
            RETURN '1=1';
        END IF;

        v_identity_type :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'IDENTITY_TYPE');
        v_role_code :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'ROLE_CODE');
        v_program_id :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'PROGRAM_ID');

        IF v_identity_type = 'STAFF'
           AND v_role_code IN (
               'BASIC_STAFF',
               'LECTURER',
               'ACADEMIC_AFFAIRS',
               'UNIT_HEAD',
               'DEAN'
           ) THEN
            RETURN '1=1';
        ELSIF v_identity_type = 'STUDENT'
              AND v_role_code = 'STUDENT'
              AND v_program_id IS NOT NULL THEN
            RETURN
                'PROGRAM_ID = ' || QUOTED_VALUE(v_program_id);
        END IF;

        RETURN '1=0';
    END COURSE_PLANS_SELECT_PREDICATE;
END STUDENT_POLICY_PKG;
/

SHOW ERRORS PACKAGE STUDENT_POLICY_PKG
SHOW ERRORS PACKAGE BODY STUDENT_POLICY_PKG

-- Remove only the three CS#6 policies managed by this script.
BEGIN
    FOR policy_record IN (
        SELECT OBJECT_NAME, POLICY_NAME
        FROM USER_POLICIES
        WHERE POLICY_NAME IN (
            'P3_STUDENTS_SELECT',
            'P3_STUDENTS_UPDATE',
            'P3_COURSE_PLANS_SELECT'
        )
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
        object_name     => 'STUDENTS',
        policy_name     => 'P3_STUDENTS_SELECT',
        function_schema => USER,
        policy_function =>
            'STUDENT_POLICY_PKG.STUDENTS_SELECT_PREDICATE',
        statement_types => 'SELECT',
        policy_type     => DBMS_RLS.DYNAMIC
    );

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'STUDENTS',
        policy_name     => 'P3_STUDENTS_UPDATE',
        function_schema => USER,
        policy_function =>
            'STUDENT_POLICY_PKG.STUDENTS_UPDATE_PREDICATE',
        statement_types => 'UPDATE',
        update_check    => TRUE,
        policy_type     => DBMS_RLS.DYNAMIC
    );

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'COURSE_PLANS',
        policy_name     => 'P3_COURSE_PLANS_SELECT',
        function_schema => USER,
        policy_function =>
            'STUDENT_POLICY_PKG.COURSE_PLANS_SELECT_PREDICATE',
        statement_types => 'SELECT',
        policy_type     => DBMS_RLS.DYNAMIC
    );
END;
/

COLUMN OBJECT_NAME FORMAT A24
COLUMN POLICY_NAME FORMAT A28
COLUMN SEL FORMAT A3
COLUMN UPD FORMAT A3
COLUMN ENABLE FORMAT A6

SELECT
    OBJECT_NAME,
    POLICY_NAME,
    SEL,
    UPD,
    ENABLE
FROM USER_POLICIES
WHERE POLICY_NAME IN (
    'P3_STUDENTS_SELECT',
    'P3_STUDENTS_UPDATE',
    'P3_COURSE_PLANS_SELECT'
)
ORDER BY OBJECT_NAME, POLICY_NAME;

DECLARE
    v_error_count   PLS_INTEGER;
    v_policy_count  PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_error_count
    FROM USER_ERRORS
    WHERE NAME = 'STUDENT_POLICY_PKG';

    SELECT COUNT(*)
    INTO v_policy_count
    FROM USER_POLICIES
    WHERE POLICY_NAME IN (
        'P3_STUDENTS_SELECT',
        'P3_STUDENTS_UPDATE',
        'P3_COURSE_PLANS_SELECT'
    )
      AND ENABLE = 'YES';

    IF v_error_count <> 0 THEN
        RAISE_APPLICATION_ERROR(
            -20801,
            'STUDENT_POLICY_PKG compiled with errors.'
        );
    END IF;

    IF v_policy_count <> 3 THEN
        RAISE_APPLICATION_ERROR(
            -20802,
            'Expected 3 enabled CS#6 policies, found ' ||
            v_policy_count || '.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Verified STUDENT_POLICY_PKG and 3 enabled CS#6 VPD policies.'
    );
END;
/

PROMPT Phase 3 - Step 3.2 completed successfully.
