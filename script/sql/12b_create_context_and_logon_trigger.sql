-- Phase 2 - Step 2.3B: Secure context and automatic initialization
-- Target database: Oracle Database 21c / XEPDB1
--
-- Run as SYS or a security administrator after
-- 12a_security_context_package.sql has compiled successfully.
--
-- Required privileges:
--   - CREATE ANY CONTEXT
--   - ADMINISTER DATABASE TRIGGER
--   - access to DBA_CONTEXT and DBA_TRIGGERS
--
-- This script also grants UNIVERSITY_APP permission to manage VPD policies on
-- its own application objects through SYS.DBMS_RLS.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

DECLARE
    v_container_name  VARCHAR2(128);
    v_context_count   PLS_INTEGER;
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
    INTO v_container_name
    FROM DUAL;

    IF v_container_name = 'CDB$ROOT' THEN
        RAISE_APPLICATION_ERROR(
            -20310,
            'Connect to XEPDB1 before creating UNIVERSITY_CTX.'
        );
    END IF;

    SELECT COUNT(*)
    INTO v_context_count
    FROM DBA_CONTEXT
    WHERE NAMESPACE = 'UNIVERSITY_CTX';

    IF v_context_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP CONTEXT UNIVERSITY_CTX';
    END IF;

    EXECUTE IMMEDIATE
        'CREATE CONTEXT UNIVERSITY_CTX' ||
        ' USING UNIVERSITY_APP.SECURITY_CONTEXT_PKG';

    SELECT COUNT(*)
    INTO v_context_count
    FROM DBA_CONTEXT
    WHERE NAMESPACE = 'UNIVERSITY_UNIT_WORKFLOW_CTX';

    IF v_context_count > 0 THEN
        EXECUTE IMMEDIATE
            'DROP CONTEXT UNIVERSITY_UNIT_WORKFLOW_CTX';
    END IF;

    EXECUTE IMMEDIATE
        'CREATE CONTEXT UNIVERSITY_UNIT_WORKFLOW_CTX' ||
        ' USING UNIVERSITY_APP.UNIT_WORKFLOW_PKG';
END;
/

GRANT EXECUTE ON SYS.DBMS_RLS TO UNIVERSITY_APP;

CREATE OR REPLACE TRIGGER TRG_UNIVERSITY_INIT_CTX
AFTER LOGON ON DATABASE
BEGIN
    UNIVERSITY_APP.SECURITY_CONTEXT_PKG.INITIALIZE_SESSION;
EXCEPTION
    WHEN OTHERS THEN
        -- A context-initialization failure must not lock administrators out of
        -- the database. VPD remains deny-by-default when context is absent.
        NULL;
END;
/

SHOW ERRORS TRIGGER TRG_UNIVERSITY_INIT_CTX

DECLARE
    v_context_count  PLS_INTEGER;
    v_trigger_count  PLS_INTEGER;
    v_error_count    PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_context_count
    FROM DBA_CONTEXT
    WHERE NAMESPACE IN (
        'UNIVERSITY_CTX',
        'UNIVERSITY_UNIT_WORKFLOW_CTX'
    );

    SELECT COUNT(*)
    INTO v_trigger_count
    FROM DBA_TRIGGERS t
    JOIN DBA_OBJECTS o
      ON o.OWNER = t.OWNER
     AND o.OBJECT_NAME = t.TRIGGER_NAME
     AND o.OBJECT_TYPE = 'TRIGGER'
    WHERE t.OWNER = 'SYS'
      AND t.TRIGGER_NAME = 'TRG_UNIVERSITY_INIT_CTX'
      AND t.STATUS = 'ENABLED'
      AND o.STATUS = 'VALID';

    SELECT COUNT(*)
    INTO v_error_count
    FROM DBA_ERRORS
    WHERE OWNER = 'SYS'
      AND NAME = 'TRG_UNIVERSITY_INIT_CTX'
      AND TYPE = 'TRIGGER';

    IF v_context_count <> 2 THEN
        RAISE_APPLICATION_ERROR(
            -20311,
            'Application contexts were not created correctly.'
        );
    END IF;

    IF v_error_count <> 0 THEN
        RAISE_APPLICATION_ERROR(
            -20313,
            'TRG_UNIVERSITY_INIT_CTX compiled with ' ||
            v_error_count || ' error(s). Review DBA_ERRORS.'
        );
    END IF;

    IF v_trigger_count <> 1 THEN
        RAISE_APPLICATION_ERROR(
            -20312,
            'TRG_UNIVERSITY_INIT_CTX is missing, disabled, or invalid.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Verified UNIVERSITY_CTX and enabled logon trigger.'
    );
    DBMS_OUTPUT.PUT_LINE(
        'Reconnect demo users before running context verification.'
    );
END;
/

PROMPT Phase 2 - Step 2.3B completed successfully.
