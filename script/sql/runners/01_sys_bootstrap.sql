-- Runner 1/3: SYS bootstrap
-- Connect as SYS with SYSDBA directly to XEPDB1, then run with F5.
--
-- Outputs:
--   - a generated UNIVERSITY_APP password
--   - the fixed local-demo password shared by the 15 bootstrap users
--
-- Save the generated UNIVERSITY_APP password from Script Output.

SET ECHO ON
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT ============================================================
PROMPT RUNNER 1/3 - SYS BOOTSTRAP
PROMPT Required connection: SYS AS SYSDBA @ XEPDB1
PROMPT ============================================================

DECLARE
    v_container_name  VARCHAR2(128);
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
    INTO v_container_name
    FROM DUAL;

    IF v_container_name <> 'XEPDB1' THEN
        RAISE_APPLICATION_ERROR(
            -20390,
            'Runner 1 must run in XEPDB1; current container is ' ||
            v_container_name || '.'
        );
    END IF;
END;
/

-- A previous installation may already have the database logon trigger. The
-- application installer below drops and recreates objects referenced by that
-- trigger, which would invalidate it and can prevent the SYS reconnect needed
-- for Runner 3. Remove it before rebuilding the application schema; Runner 3
-- recreates it after SECURITY_CONTEXT_PKG is valid again.
DECLARE
    v_trigger_count  PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_trigger_count
    FROM DBA_TRIGGERS
    WHERE OWNER = 'SYS'
      AND TRIGGER_NAME = 'TRG_UNIVERSITY_INIT_CTX';

    IF v_trigger_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP TRIGGER SYS.TRG_UNIVERSITY_INIT_CTX';
        DBMS_OUTPUT.PUT_LINE(
            'Removed the previous logon trigger before schema rebuild.'
        );
    END IF;
END;
/

@@../00_create_app_owner.sql
@@../04_test_users.sql
@@../10_create_security_roles.sql

-- Needed by UNIVERSITY_APP when Runner 2 installs VPD policies.
GRANT EXECUTE ON SYS.DBMS_RLS TO UNIVERSITY_APP;

PROMPT ============================================================
PROMPT SYS bootstrap completed.
PROMPT Save the generated UNIVERSITY_APP password.
PROMPT Bootstrap demo-user password: 123
PROMPT Next: reconnect as UNIVERSITY_APP and run 02_app_install.sql.
PROMPT ============================================================

EXIT SUCCESS
