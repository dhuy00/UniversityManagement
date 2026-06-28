-- Phase 1 - Step 4B: Oracle demo users
-- Target database: Oracle Database 21c / XEPDB1
--
-- Run as a security administrator with CREATE USER, ALTER USER, and
-- GRANT CREATE SESSION privileges. Do not run this script in CDB$ROOT.
--
-- All demo users receive one randomly generated password for local testing.
-- The password is printed once at the end of the script. These accounts receive
-- only CREATE SESSION here; application roles are granted in a later phase.

SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

DECLARE
    v_container_name  VARCHAR2(128);
    v_password        VARCHAR2(64);
    v_user_count      PLS_INTEGER;

    PROCEDURE ensure_demo_user(p_username IN VARCHAR2)
    IS
        v_username VARCHAR2(128);
    BEGIN
        v_username := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(p_username));

        SELECT COUNT(*)
        INTO v_user_count
        FROM DBA_USERS
        WHERE USERNAME = v_username;

        IF v_user_count = 0 THEN
            EXECUTE IMMEDIATE
                'CREATE USER ' || v_username ||
                ' IDENTIFIED BY "' || v_password || '"' ||
                ' DEFAULT TABLESPACE USERS' ||
                ' TEMPORARY TABLESPACE TEMP' ||
                ' QUOTA 0 ON USERS';
        ELSE
            EXECUTE IMMEDIATE
                'ALTER USER ' || v_username ||
                ' IDENTIFIED BY "' || v_password || '"' ||
                ' ACCOUNT UNLOCK';
        END IF;

        EXECUTE IMMEDIATE
            'GRANT CREATE SESSION TO ' || v_username;
    END ensure_demo_user;
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
    INTO v_container_name
    FROM DUAL;

    IF v_container_name = 'CDB$ROOT' THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Connect to XEPDB1 before creating local demo users.'
        );
    END IF;

    v_password :=
        'Demo#' ||
        DBMS_RANDOM.STRING('X', 16) ||
        'a1';

    ensure_demo_user('DEAN01');

    ensure_demo_user('HEAD_IS01');
    ensure_demo_user('HEAD_SE01');
    ensure_demo_user('HEAD_CS01');
    ensure_demo_user('HEAD_IT01');
    ensure_demo_user('HEAD_CV01');
    ensure_demo_user('HEAD_NET01');

    ensure_demo_user('BASIC01');
    ensure_demo_user('BASIC02');

    ensure_demo_user('LECTURER01');
    ensure_demo_user('LECTURER02');

    ensure_demo_user('AFFAIRS01');
    ensure_demo_user('AFFAIRS02');

    ensure_demo_user('STUDENT01');
    ensure_demo_user('STUDENT02');

    DBMS_OUTPUT.PUT_LINE('Created or updated 15 demo users in ' || v_container_name || '.');
    DBMS_OUTPUT.PUT_LINE('Temporary demo password: ' || v_password);
    DBMS_OUTPUT.PUT_LINE('Store it securely; rerunning this script rotates it.');
END;
/

PROMPT Phase 1 - Step 4B completed: Oracle demo users can create sessions.
