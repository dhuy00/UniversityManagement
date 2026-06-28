-- Phase 2 - Step 2.3C: Verify the current session identity
-- Run this script after reconnecting as any demo application user.
--
-- Recommended checks:
--   BASIC01, LECTURER01, AFFAIRS01, HEAD_IS01, DEAN01, STUDENT01

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

-- Manual refresh makes this verification deterministic even when the current
-- connection was opened before the database logon trigger was created.
BEGIN
    UNIVERSITY_APP.SECURITY_CONTEXT_PKG.INITIALIZE_SESSION;
END;
/

COLUMN DB_USERNAME FORMAT A20
COLUMN IDENTITY_TYPE FORMAT A16
COLUMN ROLE_CODE FORMAT A20
COLUMN STAFF_ID FORMAT A12
COLUMN STUDENT_ID FORMAT A12
COLUMN UNIT_ID FORMAT A12
COLUMN PROGRAM_ID FORMAT A18
COLUMN MAJOR_ID FORMAT A10
COLUMN CAMPUS_ID FORMAT A12

SELECT
    SYS_CONTEXT('UNIVERSITY_CTX', 'DB_USERNAME') AS DB_USERNAME,
    SYS_CONTEXT('UNIVERSITY_CTX', 'IDENTITY_TYPE') AS IDENTITY_TYPE,
    SYS_CONTEXT('UNIVERSITY_CTX', 'ROLE_CODE') AS ROLE_CODE,
    SYS_CONTEXT('UNIVERSITY_CTX', 'STAFF_ID') AS STAFF_ID,
    SYS_CONTEXT('UNIVERSITY_CTX', 'STUDENT_ID') AS STUDENT_ID,
    SYS_CONTEXT('UNIVERSITY_CTX', 'UNIT_ID') AS UNIT_ID,
    SYS_CONTEXT('UNIVERSITY_CTX', 'PROGRAM_ID') AS PROGRAM_ID,
    SYS_CONTEXT('UNIVERSITY_CTX', 'MAJOR_ID') AS MAJOR_ID,
    SYS_CONTEXT('UNIVERSITY_CTX', 'CAMPUS_ID') AS CAMPUS_ID
FROM DUAL;

DECLARE
    v_session_user   VARCHAR2(128);
    v_context_user   VARCHAR2(128);
    v_identity_type  VARCHAR2(30);
    v_role_code      VARCHAR2(30);
BEGIN
    v_session_user :=
        UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'));
    v_context_user :=
        SYS_CONTEXT('UNIVERSITY_CTX', 'DB_USERNAME');
    v_identity_type :=
        SYS_CONTEXT('UNIVERSITY_CTX', 'IDENTITY_TYPE');
    v_role_code :=
        SYS_CONTEXT('UNIVERSITY_CTX', 'ROLE_CODE');

    IF v_context_user <> v_session_user THEN
        RAISE_APPLICATION_ERROR(
            -20320,
            'Context username does not match SESSION_USER.'
        );
    END IF;

    IF v_identity_type NOT IN ('STAFF', 'STUDENT', 'OWNER') THEN
        RAISE_APPLICATION_ERROR(
            -20321,
            'Current user has no recognized application identity.'
        );
    END IF;

    IF v_role_code IS NULL OR v_role_code = 'NONE' THEN
        RAISE_APPLICATION_ERROR(
            -20322,
            'Current user has no application role in context.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Verified context for ' || v_session_user ||
        ': identity=' || v_identity_type ||
        ', role=' || v_role_code || '.'
    );
END;
/

PROMPT Phase 2 - Step 2.3C completed successfully.
