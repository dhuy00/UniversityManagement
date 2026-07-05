-- Phase 2 - Step 2.4: VPD row filtering for CS#1-CS#5
-- Target database: Oracle Database 21c / XEPDB1
--
-- Run as UNIVERSITY_APP after completing Step 2.3.
-- Reconnect demo users (or run 12c) before testing these policies.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'UNIVERSITY_APP' THEN
        RAISE_APPLICATION_ERROR(
            -20400,
            'Run this script as UNIVERSITY_APP.'
        );
    END IF;
END;
/

CREATE OR REPLACE PACKAGE ACCESS_POLICY_PKG
AUTHID DEFINER
AS
    FUNCTION STAFF_SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION STAFF_UPDATE_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION STAFF_ADMIN_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION ASSIGNMENT_SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION ASSIGNMENT_WRITE_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION ENROLLMENT_SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION ENROLLMENT_UPDATE_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;
END ACCESS_POLICY_PKG;
/

CREATE OR REPLACE PACKAGE BODY ACCESS_POLICY_PKG
AS
    FUNCTION CONTEXT_VALUE(p_attribute IN VARCHAR2)
    RETURN VARCHAR2
    IS
    BEGIN
        RETURN SYS_CONTEXT('UNIVERSITY_CTX', p_attribute);
    END CONTEXT_VALUE;

    FUNCTION QUOTED_VALUE(p_value IN VARCHAR2)
    RETURN VARCHAR2
    IS
    BEGIN
        RETURN DBMS_ASSERT.ENQUOTE_LITERAL(p_value);
    END QUOTED_VALUE;

    FUNCTION OWNER_BYPASS
    RETURN BOOLEAN
    IS
        v_session_user VARCHAR2(128);
    BEGIN
        v_session_user :=
            UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'));

        RETURN v_session_user IN ('UNIVERSITY_APP', 'SYS');
    END OWNER_BYPASS;

    FUNCTION STAFF_IDS_IN_UNIT(
        p_column_name IN VARCHAR2,
        p_unit_id     IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_predicate  VARCHAR2(32767);
        v_separator  VARCHAR2(1) := '';
    BEGIN
        IF p_unit_id IS NULL THEN
            RETURN '1=0';
        END IF;

        v_predicate :=
            DBMS_ASSERT.SIMPLE_SQL_NAME(p_column_name) || ' IN (';

        FOR identity_record IN (
            SELECT STAFF_ID
            FROM SECURITY_IDENTITIES
            WHERE IDENTITY_TYPE = 'STAFF'
              AND UNIT_ID = p_unit_id
              AND STAFF_ID IS NOT NULL
            ORDER BY STAFF_ID
        )
        LOOP
            v_predicate :=
                v_predicate ||
                v_separator ||
                QUOTED_VALUE(identity_record.STAFF_ID);
            v_separator := ',';
        END LOOP;

        IF v_separator IS NULL THEN
            RETURN '1=0';
        END IF;

        RETURN v_predicate || ')';
    END STAFF_IDS_IN_UNIT;

    FUNCTION COURSE_IDS_IN_UNIT(
        p_column_name IN VARCHAR2,
        p_unit_id     IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_predicate  VARCHAR2(32767);
        v_separator  VARCHAR2(1) := '';
    BEGIN
        IF p_unit_id IS NULL THEN
            RETURN '1=0';
        END IF;

        v_predicate :=
            DBMS_ASSERT.SIMPLE_SQL_NAME(p_column_name) || ' IN (';

        FOR course_record IN (
            SELECT COURSE_ID
            FROM COURSES
            WHERE UNIT_ID = p_unit_id
            ORDER BY COURSE_ID
        )
        LOOP
            v_predicate :=
                v_predicate ||
                v_separator ||
                QUOTED_VALUE(course_record.COURSE_ID);
            v_separator := ',';
        END LOOP;

        IF v_separator IS NULL THEN
            RETURN '1=0';
        END IF;

        RETURN v_predicate || ')';
    END COURSE_IDS_IN_UNIT;

    FUNCTION STAFF_SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_role_code VARCHAR2(30);
        v_staff_id  VARCHAR2(20);
    BEGIN
        IF OWNER_BYPASS THEN
            RETURN '1=1';
        END IF;

        v_role_code := CONTEXT_VALUE('ROLE_CODE');
        v_staff_id := CONTEXT_VALUE('STAFF_ID');

        IF v_role_code = 'DEAN' THEN
            RETURN '1=1';
        ELSIF v_role_code IN (
            'BASIC_STAFF',
            'LECTURER',
            'ACADEMIC_AFFAIRS',
            'UNIT_HEAD'
        ) AND v_staff_id IS NOT NULL THEN
            RETURN 'STAFF_ID = ' || QUOTED_VALUE(v_staff_id);
        END IF;

        RETURN '1=0';
    END STAFF_SELECT_PREDICATE;

    FUNCTION STAFF_UPDATE_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_role_code VARCHAR2(30);
        v_staff_id  VARCHAR2(20);
    BEGIN
        IF OWNER_BYPASS THEN
            RETURN '1=1';
        END IF;

        v_role_code := CONTEXT_VALUE('ROLE_CODE');
        v_staff_id := CONTEXT_VALUE('STAFF_ID');

        IF v_role_code = 'DEAN' THEN
            RETURN '1=1';
        ELSIF v_role_code IN (
            'BASIC_STAFF',
            'LECTURER',
            'ACADEMIC_AFFAIRS',
            'UNIT_HEAD'
        ) AND v_staff_id IS NOT NULL THEN
            RETURN 'STAFF_ID = ' || QUOTED_VALUE(v_staff_id);
        END IF;

        RETURN '1=0';
    END STAFF_UPDATE_PREDICATE;

    FUNCTION STAFF_ADMIN_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
    BEGIN
        IF OWNER_BYPASS OR CONTEXT_VALUE('ROLE_CODE') = 'DEAN' THEN
            RETURN '1=1';
        END IF;

        RETURN '1=0';
    END STAFF_ADMIN_PREDICATE;

    FUNCTION ASSIGNMENT_SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_role_code VARCHAR2(30);
        v_staff_id  VARCHAR2(20);
        v_unit_id   VARCHAR2(20);
        v_program_id VARCHAR2(20);
    BEGIN
        IF OWNER_BYPASS THEN
            RETURN '1=1';
        END IF;

        v_role_code := CONTEXT_VALUE('ROLE_CODE');
        v_staff_id := CONTEXT_VALUE('STAFF_ID');
        v_unit_id := CONTEXT_VALUE('UNIT_ID');
        v_program_id := CONTEXT_VALUE('PROGRAM_ID');

        IF v_role_code IN ('ACADEMIC_AFFAIRS', 'DEAN') THEN
            RETURN '1=1';
        ELSIF v_role_code = 'UNIT_HEAD' THEN
            RETURN
                '(' ||
                STAFF_IDS_IN_UNIT('LECTURER_ID', v_unit_id) ||
                ' OR ' ||
                COURSE_IDS_IN_UNIT('COURSE_ID', v_unit_id) ||
                ')';
        ELSIF v_role_code = 'LECTURER' AND v_staff_id IS NOT NULL THEN
            RETURN 'LECTURER_ID = ' || QUOTED_VALUE(v_staff_id);
        ELSIF v_role_code = 'STUDENT' AND v_program_id IS NOT NULL THEN
            RETURN 'PROGRAM_ID = ' || QUOTED_VALUE(v_program_id);
        END IF;

        RETURN '1=0';
    END ASSIGNMENT_SELECT_PREDICATE;

    FUNCTION ASSIGNMENT_WRITE_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_role_code VARCHAR2(30);
        v_unit_id   VARCHAR2(20);
    BEGIN
        IF OWNER_BYPASS THEN
            RETURN '1=1';
        END IF;

        v_role_code := CONTEXT_VALUE('ROLE_CODE');
        v_unit_id := CONTEXT_VALUE('UNIT_ID');

        IF v_role_code IN ('ACADEMIC_AFFAIRS', 'DEAN') THEN
            RETURN COURSE_IDS_IN_UNIT('COURSE_ID', 'OFFICE');
        ELSIF v_role_code = 'UNIT_HEAD' THEN
            RETURN COURSE_IDS_IN_UNIT('COURSE_ID', v_unit_id);
        END IF;

        RETURN '1=0';
    END ASSIGNMENT_WRITE_PREDICATE;

    FUNCTION ENROLLMENT_SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_role_code  VARCHAR2(30);
        v_staff_id   VARCHAR2(20);
        v_student_id VARCHAR2(20);
    BEGIN
        IF OWNER_BYPASS THEN
            RETURN '1=1';
        END IF;

        v_role_code := CONTEXT_VALUE('ROLE_CODE');
        v_staff_id := CONTEXT_VALUE('STAFF_ID');
        v_student_id := CONTEXT_VALUE('STUDENT_ID');

        IF v_role_code = 'DEAN' THEN
            RETURN '1=1';
        ELSIF v_role_code IN ('LECTURER', 'UNIT_HEAD')
              AND v_staff_id IS NOT NULL THEN
            RETURN 'LECTURER_ID = ' || QUOTED_VALUE(v_staff_id);
        ELSIF v_role_code = 'STUDENT'
              AND v_student_id IS NOT NULL THEN
            RETURN 'STUDENT_ID = ' || QUOTED_VALUE(v_student_id);
        END IF;

        RETURN '1=0';
    END ENROLLMENT_SELECT_PREDICATE;

    FUNCTION ENROLLMENT_UPDATE_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_role_code VARCHAR2(30);
        v_staff_id  VARCHAR2(20);
    BEGIN
        IF OWNER_BYPASS THEN
            RETURN '1=1';
        END IF;

        v_role_code := CONTEXT_VALUE('ROLE_CODE');
        v_staff_id := CONTEXT_VALUE('STAFF_ID');

        IF v_role_code IN ('LECTURER', 'UNIT_HEAD', 'DEAN')
           AND v_staff_id IS NOT NULL THEN
            RETURN 'LECTURER_ID = ' || QUOTED_VALUE(v_staff_id);
        END IF;

        RETURN '1=0';
    END ENROLLMENT_UPDATE_PREDICATE;
END ACCESS_POLICY_PKG;
/

SHOW ERRORS PACKAGE ACCESS_POLICY_PKG
SHOW ERRORS PACKAGE BODY ACCESS_POLICY_PKG

-- Remove only policies owned by this project so the script is rerunnable.
BEGIN
    FOR policy_record IN (
        SELECT OBJECT_NAME, POLICY_NAME
        FROM USER_POLICIES
        WHERE OBJECT_NAME IN (
            'STAFF',
            'TEACHING_ASSIGNMENTS',
            'ENROLLMENTS'
        )
          AND POLICY_NAME LIKE 'P2\_%' ESCAPE '\'
    )
    LOOP
        DBMS_RLS.DROP_POLICY(
            object_schema => USER,
            object_name   => policy_record.OBJECT_NAME,
            policy_name   => policy_record.POLICY_NAME
        );
    END LOOP;
END;
/

BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'STAFF',
        policy_name     => 'P2_STAFF_SELECT',
        function_schema => USER,
        policy_function => 'ACCESS_POLICY_PKG.STAFF_SELECT_PREDICATE',
        statement_types => 'SELECT',
        policy_type     => DBMS_RLS.DYNAMIC
    );

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'STAFF',
        policy_name     => 'P2_STAFF_UPDATE',
        function_schema => USER,
        policy_function => 'ACCESS_POLICY_PKG.STAFF_UPDATE_PREDICATE',
        statement_types => 'UPDATE',
        update_check    => TRUE,
        policy_type     => DBMS_RLS.DYNAMIC
    );

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'STAFF',
        policy_name     => 'P2_STAFF_INSERT',
        function_schema => USER,
        policy_function => 'ACCESS_POLICY_PKG.STAFF_ADMIN_PREDICATE',
        statement_types => 'INSERT',
        update_check    => TRUE,
        policy_type     => DBMS_RLS.DYNAMIC
    );

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'STAFF',
        policy_name     => 'P2_STAFF_DELETE',
        function_schema => USER,
        policy_function => 'ACCESS_POLICY_PKG.STAFF_ADMIN_PREDICATE',
        statement_types => 'DELETE',
        policy_type     => DBMS_RLS.DYNAMIC
    );

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'TEACHING_ASSIGNMENTS',
        policy_name     => 'P2_ASSIGNMENT_SELECT',
        function_schema => USER,
        policy_function => 'ACCESS_POLICY_PKG.ASSIGNMENT_SELECT_PREDICATE',
        statement_types => 'SELECT',
        policy_type     => DBMS_RLS.DYNAMIC
    );

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'TEACHING_ASSIGNMENTS',
        policy_name     => 'P2_ASSIGNMENT_WRITE',
        function_schema => USER,
        policy_function => 'ACCESS_POLICY_PKG.ASSIGNMENT_WRITE_PREDICATE',
        statement_types => 'INSERT,UPDATE',
        update_check    => TRUE,
        policy_type     => DBMS_RLS.DYNAMIC
    );

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'TEACHING_ASSIGNMENTS',
        policy_name     => 'P2_ASSIGNMENT_DELETE',
        function_schema => USER,
        policy_function => 'ACCESS_POLICY_PKG.ASSIGNMENT_WRITE_PREDICATE',
        statement_types => 'DELETE',
        policy_type     => DBMS_RLS.DYNAMIC
    );

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'ENROLLMENTS',
        policy_name     => 'P2_ENROLLMENT_SELECT',
        function_schema => USER,
        policy_function => 'ACCESS_POLICY_PKG.ENROLLMENT_SELECT_PREDICATE',
        statement_types => 'SELECT',
        policy_type     => DBMS_RLS.DYNAMIC
    );

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'ENROLLMENTS',
        policy_name     => 'P2_ENROLLMENT_UPDATE',
        function_schema => USER,
        policy_function => 'ACCESS_POLICY_PKG.ENROLLMENT_UPDATE_PREDICATE',
        statement_types => 'UPDATE',
        update_check    => TRUE,
        policy_type     => DBMS_RLS.DYNAMIC
    );
END;
/

COLUMN OBJECT_NAME FORMAT A28
COLUMN POLICY_NAME FORMAT A28
COLUMN SEL FORMAT A3
COLUMN INS FORMAT A3
COLUMN UPD FORMAT A3
COLUMN DEL FORMAT A3
COLUMN ENABLE FORMAT A6

SELECT
    OBJECT_NAME,
    POLICY_NAME,
    SEL,
    INS,
    UPD,
    DEL,
    ENABLE
FROM USER_POLICIES
WHERE POLICY_NAME LIKE 'P2\_%' ESCAPE '\'
ORDER BY OBJECT_NAME, POLICY_NAME;

DECLARE
    v_error_count   PLS_INTEGER;
    v_policy_count  PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_error_count
    FROM USER_ERRORS
    WHERE NAME = 'ACCESS_POLICY_PKG';

    SELECT COUNT(*)
    INTO v_policy_count
    FROM USER_POLICIES
    WHERE POLICY_NAME LIKE 'P2\_%' ESCAPE '\'
      AND ENABLE = 'YES';

    IF v_error_count <> 0 THEN
        RAISE_APPLICATION_ERROR(
            -20401,
            'ACCESS_POLICY_PKG compiled with errors.'
        );
    END IF;

    IF v_policy_count <> 9 THEN
        RAISE_APPLICATION_ERROR(
            -20402,
            'Expected 9 enabled Phase 2 VPD policies, found ' ||
            v_policy_count || '.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Verified ACCESS_POLICY_PKG and 9 enabled VPD policies.'
    );
END;
/

PROMPT Phase 2 - Step 2.4 completed successfully.
