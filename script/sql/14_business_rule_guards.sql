-- Phase 2 - Step 2.5: Conditional business-rule enforcement
-- Target database: Oracle Database 21c / XEPDB1
--
-- Run as UNIVERSITY_APP after 13_vpd_policies_cs1_cs5.sql.
--
-- Enforced rules:
--   1. Academic-affairs staff (and later students in CS#6) may insert/delete
--      enrollments only from semester START_DATE through START_DATE + 14 days.
--   2. An assigned lecturer must be LECTURER, UNIT_HEAD, or DEAN.
--   3. ENROLLMENTS.PROGRAM_ID must match the student's PROGRAM_ID.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'UNIVERSITY_APP' THEN
        RAISE_APPLICATION_ERROR(
            -20500,
            'Run this script as UNIVERSITY_APP.'
        );
    END IF;
END;
/

CREATE OR REPLACE PACKAGE BUSINESS_RULE_PKG
AUTHID DEFINER
AS
    FUNCTION IS_REGISTRATION_OPEN(
        p_course_id     IN VARCHAR2,
        p_semester      IN NUMBER,
        p_academic_year IN NUMBER,
        p_program_id    IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION ENROLLMENT_MAINTAIN_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;
END BUSINESS_RULE_PKG;
/

CREATE OR REPLACE PACKAGE BODY BUSINESS_RULE_PKG
AS
    FUNCTION IS_REGISTRATION_OPEN(
        p_course_id     IN VARCHAR2,
        p_semester      IN NUMBER,
        p_academic_year IN NUMBER,
        p_program_id    IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM COURSE_PLANS
        WHERE COURSE_ID = p_course_id
          AND SEMESTER = p_semester
          AND ACADEMIC_YEAR = p_academic_year
          AND PROGRAM_ID = p_program_id
          AND TRUNC(SYSDATE)
              BETWEEN TRUNC(START_DATE) AND TRUNC(START_DATE) + 14;

        IF v_count = 1 THEN
            RETURN 1;
        END IF;

        RETURN 0;
    END IS_REGISTRATION_OPEN;

    FUNCTION ENROLLMENT_MAINTAIN_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_role_code   VARCHAR2(30);
        v_student_id  VARCHAR2(20);
        v_window_predicate VARCHAR2(4000);
    BEGIN
        IF UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'))
           IN ('UNIVERSITY_APP', 'SYS') THEN
            RETURN '1=1';
        END IF;

        v_role_code :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'ROLE_CODE');
        v_student_id :=
            SYS_CONTEXT('UNIVERSITY_CTX', 'STUDENT_ID');

        v_window_predicate :=
            '(COURSE_ID, SEMESTER, ACADEMIC_YEAR, PROGRAM_ID) IN (' ||
            'SELECT cp.COURSE_ID, cp.SEMESTER, cp.ACADEMIC_YEAR, ' ||
            'cp.PROGRAM_ID FROM UNIVERSITY_APP.COURSE_PLANS cp ' ||
            'WHERE TRUNC(SYSDATE) BETWEEN TRUNC(cp.START_DATE) ' ||
            'AND TRUNC(cp.START_DATE) + 14)';

        IF v_role_code = 'ACADEMIC_AFFAIRS' THEN
            RETURN v_window_predicate;
        ELSIF v_role_code = 'STUDENT'
              AND v_student_id IS NOT NULL THEN
            RETURN
                'STUDENT_ID = ' ||
                DBMS_ASSERT.ENQUOTE_LITERAL(v_student_id) ||
                ' AND ' || v_window_predicate;
        END IF;

        RETURN '1=0';
    END ENROLLMENT_MAINTAIN_PREDICATE;
END BUSINESS_RULE_PKG;
/

SHOW ERRORS PACKAGE BUSINESS_RULE_PKG
SHOW ERRORS PACKAGE BODY BUSINESS_RULE_PKG

CREATE OR REPLACE TRIGGER TRG_VALIDATE_ASSIGNMENT_LECTURER
BEFORE INSERT OR UPDATE OF LECTURER_ID
ON TEACHING_ASSIGNMENTS
FOR EACH ROW
DECLARE
    v_role_code SECURITY_IDENTITIES.ROLE_CODE%TYPE;
BEGIN
    BEGIN
        SELECT ROLE_CODE
        INTO v_role_code
        FROM SECURITY_IDENTITIES
        WHERE IDENTITY_TYPE = 'STAFF'
          AND STAFF_ID = :NEW.LECTURER_ID;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20501,
                'Assigned lecturer has no staff security identity.'
            );
    END;

    IF v_role_code NOT IN ('LECTURER', 'UNIT_HEAD', 'DEAN') THEN
        RAISE_APPLICATION_ERROR(
            -20502,
            'Assigned staff member does not have a teaching role.'
        );
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_VALIDATE_ENROLLMENT_PROGRAM
BEFORE INSERT OR UPDATE OF STUDENT_ID, PROGRAM_ID
ON ENROLLMENTS
FOR EACH ROW
DECLARE
    v_program_id SECURITY_IDENTITIES.PROGRAM_ID%TYPE;
BEGIN
    BEGIN
        SELECT PROGRAM_ID
        INTO v_program_id
        FROM SECURITY_IDENTITIES
        WHERE IDENTITY_TYPE = 'STUDENT'
          AND STUDENT_ID = :NEW.STUDENT_ID;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20503,
                'Enrollment student has no student security identity.'
            );
    END;

    IF v_program_id <> :NEW.PROGRAM_ID THEN
        RAISE_APPLICATION_ERROR(
            -20504,
            'Enrollment program does not match the student program.'
        );
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_ENROLLMENT_WINDOW
BEFORE INSERT OR DELETE
ON ENROLLMENTS
FOR EACH ROW
DECLARE
    v_role_code      VARCHAR2(30);
    v_is_open        NUMBER;
    v_course_id      ENROLLMENTS.COURSE_ID%TYPE;
    v_semester       ENROLLMENTS.SEMESTER%TYPE;
    v_academic_year  ENROLLMENTS.ACADEMIC_YEAR%TYPE;
    v_program_id     ENROLLMENTS.PROGRAM_ID%TYPE;
BEGIN
    IF UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'))
       IN ('UNIVERSITY_APP', 'SYS') THEN
        RETURN;
    END IF;

    v_role_code :=
        SYS_CONTEXT('UNIVERSITY_CTX', 'ROLE_CODE');

    IF v_role_code NOT IN ('ACADEMIC_AFFAIRS', 'STUDENT') THEN
        RAISE_APPLICATION_ERROR(
            -20505,
            'Current role cannot add or remove enrollments.'
        );
    END IF;

    IF INSERTING THEN
        v_course_id := :NEW.COURSE_ID;
        v_semester := :NEW.SEMESTER;
        v_academic_year := :NEW.ACADEMIC_YEAR;
        v_program_id := :NEW.PROGRAM_ID;
    ELSE
        v_course_id := :OLD.COURSE_ID;
        v_semester := :OLD.SEMESTER;
        v_academic_year := :OLD.ACADEMIC_YEAR;
        v_program_id := :OLD.PROGRAM_ID;
    END IF;

    v_is_open :=
        BUSINESS_RULE_PKG.IS_REGISTRATION_OPEN(
            p_course_id     => v_course_id,
            p_semester      => v_semester,
            p_academic_year => v_academic_year,
            p_program_id    => v_program_id
        );

    IF v_is_open = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20506,
            'Enrollment adjustment period is closed.'
        );
    END IF;
END;
/

SHOW ERRORS TRIGGER TRG_VALIDATE_ASSIGNMENT_LECTURER
SHOW ERRORS TRIGGER TRG_VALIDATE_ENROLLMENT_PROGRAM
SHOW ERRORS TRIGGER TRG_ENROLLMENT_WINDOW

-- Add VPD checks for both existing rows (DELETE) and proposed rows (INSERT).
BEGIN
    FOR policy_record IN (
        SELECT OBJECT_NAME, POLICY_NAME
        FROM USER_POLICIES
        WHERE OBJECT_NAME = 'ENROLLMENTS'
          AND POLICY_NAME IN (
              'P2_ENROLLMENT_INSERT',
              'P2_ENROLLMENT_DELETE'
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
        object_name     => 'ENROLLMENTS',
        policy_name     => 'P2_ENROLLMENT_INSERT',
        function_schema => USER,
        policy_function =>
            'BUSINESS_RULE_PKG.ENROLLMENT_MAINTAIN_PREDICATE',
        statement_types => 'INSERT',
        update_check    => TRUE,
        policy_type     => DBMS_RLS.DYNAMIC
    );

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'ENROLLMENTS',
        policy_name     => 'P2_ENROLLMENT_DELETE',
        function_schema => USER,
        policy_function =>
            'BUSINESS_RULE_PKG.ENROLLMENT_MAINTAIN_PREDICATE',
        statement_types => 'DELETE',
        policy_type     => DBMS_RLS.DYNAMIC
    );
END;
/

DECLARE
    v_error_count   PLS_INTEGER;
    v_policy_count  PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_error_count
    FROM USER_ERRORS
    WHERE NAME IN (
        'BUSINESS_RULE_PKG',
        'TRG_VALIDATE_ASSIGNMENT_LECTURER',
        'TRG_VALIDATE_ENROLLMENT_PROGRAM',
        'TRG_ENROLLMENT_WINDOW'
    );

    SELECT COUNT(*)
    INTO v_policy_count
    FROM USER_POLICIES
    WHERE OBJECT_NAME = 'ENROLLMENTS'
      AND POLICY_NAME IN (
          'P2_ENROLLMENT_INSERT',
          'P2_ENROLLMENT_DELETE'
      )
      AND ENABLE = 'YES';

    IF v_error_count <> 0 THEN
        RAISE_APPLICATION_ERROR(
            -20507,
            'Business-rule package or triggers compiled with errors.'
        );
    END IF;

    IF v_policy_count <> 2 THEN
        RAISE_APPLICATION_ERROR(
            -20508,
            'Expected 2 enrollment-maintenance VPD policies, found ' ||
            v_policy_count || '.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Verified business-rule package, 3 triggers, and 2 VPD policies.'
    );
    DBMS_OUTPUT.PUT_LINE(
        'Registration window uses database date ' ||
        TO_CHAR(SYSDATE, 'YYYY-MM-DD') || '.'
    );
END;
/

PROMPT Phase 2 - Step 2.5 completed successfully.
