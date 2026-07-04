-- Phase 4 - Step 4.1C: Create a dedicated OLS administrator
-- Target database: Oracle Database 21c / XEPDB1
-- Run as SYS with SYSDBA after OLS is enabled and XEPDB1 has been reopened.
--
-- Rerunning this script rotates the UNIVERSITY_OLS_ADMIN password.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

DECLARE
    v_container_name    VARCHAR2(128);
    v_configure_status  VARCHAR2(10);
    v_enable_status     VARCHAR2(10);
    v_user_count        PLS_INTEGER;
    v_password          VARCHAR2(64);
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
    INTO v_container_name
    FROM DUAL;

    IF v_container_name = 'CDB$ROOT' THEN
        RAISE_APPLICATION_ERROR(
            -20970,
            'Connect directly to XEPDB1 before creating the OLS admin.'
        );
    END IF;

    EXECUTE IMMEDIATE q'[
        SELECT
            MAX(CASE
                WHEN NAME = 'OLS_CONFIGURE_STATUS' THEN STATUS
            END),
            MAX(CASE
                WHEN NAME = 'OLS_ENABLE_STATUS' THEN STATUS
            END)
        FROM DBA_OLS_STATUS
    ]'
    INTO v_configure_status, v_enable_status;

    IF v_configure_status <> 'TRUE'
       OR v_enable_status <> 'TRUE' THEN
        RAISE_APPLICATION_ERROR(
            -20971,
            'OLS must be configured and enabled before creating its admin.'
        );
    END IF;

    v_password :=
        'Ols#' ||
        DBMS_RANDOM.STRING('X', 20) ||
        'a1';

    SELECT COUNT(*)
    INTO v_user_count
    FROM DBA_USERS
    WHERE USERNAME = 'UNIVERSITY_OLS_ADMIN';

    IF v_user_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE USER UNIVERSITY_OLS_ADMIN' ||
            ' IDENTIFIED BY "' || v_password || '"' ||
            ' DEFAULT TABLESPACE USERS' ||
            ' TEMPORARY TABLESPACE TEMP' ||
            ' QUOTA 50M ON USERS';
    ELSE
        EXECUTE IMMEDIATE
            'ALTER USER UNIVERSITY_OLS_ADMIN' ||
            ' IDENTIFIED BY "' || v_password || '"' ||
            ' ACCOUNT UNLOCK';
    END IF;

    EXECUTE IMMEDIATE
        'GRANT CREATE SESSION TO UNIVERSITY_OLS_ADMIN';
    EXECUTE IMMEDIATE
        'GRANT LBAC_DBA TO UNIVERSITY_OLS_ADMIN';

    DBMS_OUTPUT.PUT_LINE(
        'OLS administrator created or updated in ' || v_container_name || '.'
    );
    DBMS_OUTPUT.PUT_LINE('Username: UNIVERSITY_OLS_ADMIN');
    DBMS_OUTPUT.PUT_LINE('Temporary password: ' || v_password);
    DBMS_OUTPUT.PUT_LINE('Store it securely; rerunning rotates it.');
END;
/

DECLARE
    v_role_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_role_count
    FROM DBA_ROLE_PRIVS
    WHERE GRANTEE = 'UNIVERSITY_OLS_ADMIN'
      AND GRANTED_ROLE = 'LBAC_DBA';

    IF v_role_count <> 1 THEN
        RAISE_APPLICATION_ERROR(
            -20972,
            'UNIVERSITY_OLS_ADMIN did not receive LBAC_DBA.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        '[PASS] UNIVERSITY_OLS_ADMIN has CREATE SESSION and LBAC_DBA.'
    );
END;
/

PROMPT Phase 4 - Step 4.1C completed successfully.
