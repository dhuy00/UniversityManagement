-- Bootstrap: create the application-owner schema.
-- Target database: Oracle Database 21c / XEPDB1
-- Run as SYS or another security administrator in XEPDB1.
--
-- The generated password is printed once. Rerunning this script rotates the
-- UNIVERSITY_APP password.

SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

DECLARE
    v_container_name  VARCHAR2(128);
    v_password        VARCHAR2(64);
    v_user_count      PLS_INTEGER;
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
    INTO v_container_name
    FROM DUAL;

    IF v_container_name = 'CDB$ROOT' THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Connect to XEPDB1 before creating UNIVERSITY_APP.'
        );
    END IF;

    v_password :=
        'App#' ||
        DBMS_RANDOM.STRING('X', 20) ||
        'a1';

    SELECT COUNT(*)
    INTO v_user_count
    FROM DBA_USERS
    WHERE USERNAME = 'UNIVERSITY_APP';

    IF v_user_count = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE USER UNIVERSITY_APP' ||
            ' IDENTIFIED BY "' || v_password || '"' ||
            ' DEFAULT TABLESPACE USERS' ||
            ' TEMPORARY TABLESPACE TEMP' ||
            ' QUOTA 500M ON USERS';
    ELSE
        EXECUTE IMMEDIATE
            'ALTER USER UNIVERSITY_APP' ||
            ' IDENTIFIED BY "' || v_password || '"' ||
            ' ACCOUNT UNLOCK';

        EXECUTE IMMEDIATE
            'ALTER USER UNIVERSITY_APP QUOTA 500M ON USERS';
    END IF;

    EXECUTE IMMEDIATE
        'GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW,' ||
        ' CREATE PROCEDURE, CREATE SEQUENCE, CREATE TRIGGER' ||
        ' TO UNIVERSITY_APP';

    DBMS_OUTPUT.PUT_LINE(
        'Application owner created or updated in ' || v_container_name || '.'
    );
    DBMS_OUTPUT.PUT_LINE('Username: UNIVERSITY_APP');
    DBMS_OUTPUT.PUT_LINE('Temporary password: ' || v_password);
    DBMS_OUTPUT.PUT_LINE('Store it securely; rerunning this script rotates it.');
END;
/

PROMPT Bootstrap completed: connect as UNIVERSITY_APP before running scripts 01-06.
