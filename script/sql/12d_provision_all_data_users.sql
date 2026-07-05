-- Provision an Oracle login for every STAFF and STUDENTS row.
-- Run as SYS in XEPDB1 after the application schema and seed data exist.
--
-- Every account receives the fixed password 123. This intentionally weak
-- password is suitable only for the local demo environment.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

DECLARE
    v_container_name   VARCHAR2(128);
    v_user_count       PLS_INTEGER;
    v_expected_count   PLS_INTEGER;
    v_distinct_count   PLS_INTEGER;
    v_processed_count  PLS_INTEGER := 0;
    v_assignment_count PLS_INTEGER;
    v_password         CONSTANT VARCHAR2(64) := '123';

    PROCEDURE ensure_data_user(
        p_username  IN VARCHAR2,
        p_role_name IN VARCHAR2
    )
    IS
        v_username  VARCHAR2(128);
        v_role_name VARCHAR2(128);
    BEGIN
        v_username :=
            DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM(p_username)));
        v_role_name :=
            DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM(p_role_name)));

        IF v_role_name NOT IN (
            'RL_BASIC_STAFF',
            'RL_LECTURER',
            'RL_ACADEMIC_AFFAIRS',
            'RL_UNIT_HEAD',
            'RL_DEAN',
            'RL_STUDENT'
        ) THEN
            RAISE_APPLICATION_ERROR(
                -20120,
                'Unsupported application role: ' || v_role_name
            );
        END IF;

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

        FOR stale_role IN (
            SELECT GRANTED_ROLE
            FROM DBA_ROLE_PRIVS
            WHERE GRANTEE = v_username
              AND GRANTED_ROLE IN (
                  'RL_BASIC_STAFF',
                  'RL_LECTURER',
                  'RL_ACADEMIC_AFFAIRS',
                  'RL_UNIT_HEAD',
                  'RL_DEAN',
                  'RL_STUDENT'
              )
              AND GRANTED_ROLE <> v_role_name
        )
        LOOP
            EXECUTE IMMEDIATE
                'REVOKE ' ||
                DBMS_ASSERT.SIMPLE_SQL_NAME(stale_role.GRANTED_ROLE) ||
                ' FROM ' || v_username;
        END LOOP;

        EXECUTE IMMEDIATE
            'GRANT ' || v_role_name || ' TO ' || v_username;

        v_processed_count := v_processed_count + 1;
    END ensure_data_user;
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
    INTO v_container_name
    FROM DUAL;

    IF v_container_name = 'CDB$ROOT' THEN
        RAISE_APPLICATION_ERROR(
            -20121,
            'Connect to XEPDB1 before provisioning local users.'
        );
    END IF;

    SELECT COUNT(*), COUNT(DISTINCT ORACLE_USERNAME)
    INTO v_expected_count, v_distinct_count
    FROM (
        SELECT ORACLE_USERNAME
        FROM UNIVERSITY_APP.STAFF
        UNION ALL
        SELECT ORACLE_USERNAME
        FROM UNIVERSITY_APP.STUDENTS
    );

    IF v_expected_count <> v_distinct_count THEN
        RAISE_APPLICATION_ERROR(
            -20122,
            'ORACLE_USERNAME values must be unique across STAFF and STUDENTS.'
        );
    END IF;

    FOR identity_record IN (
        SELECT
            ORACLE_USERNAME,
            CASE ROLE_CODE
                WHEN 'BASIC_STAFF' THEN 'RL_BASIC_STAFF'
                WHEN 'LECTURER' THEN 'RL_LECTURER'
                WHEN 'ACADEMIC_AFFAIRS' THEN 'RL_ACADEMIC_AFFAIRS'
                WHEN 'UNIT_HEAD' THEN 'RL_UNIT_HEAD'
                WHEN 'DEAN' THEN 'RL_DEAN'
            END AS ROLE_NAME
        FROM UNIVERSITY_APP.STAFF
        UNION ALL
        SELECT
            ORACLE_USERNAME,
            'RL_STUDENT' AS ROLE_NAME
        FROM UNIVERSITY_APP.STUDENTS
        ORDER BY ORACLE_USERNAME
    )
    LOOP
        IF identity_record.ORACLE_USERNAME IS NULL
           OR identity_record.ROLE_NAME IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20123,
                'Every identity must have a username and supported role.'
            );
        END IF;

        ensure_data_user(
            identity_record.ORACLE_USERNAME,
            identity_record.ROLE_NAME
        );
    END LOOP;

    SELECT COUNT(*)
    INTO v_assignment_count
    FROM (
        SELECT
            ORACLE_USERNAME,
            CASE ROLE_CODE
                WHEN 'BASIC_STAFF' THEN 'RL_BASIC_STAFF'
                WHEN 'LECTURER' THEN 'RL_LECTURER'
                WHEN 'ACADEMIC_AFFAIRS' THEN 'RL_ACADEMIC_AFFAIRS'
                WHEN 'UNIT_HEAD' THEN 'RL_UNIT_HEAD'
                WHEN 'DEAN' THEN 'RL_DEAN'
            END AS ROLE_NAME
        FROM UNIVERSITY_APP.STAFF
        UNION ALL
        SELECT ORACLE_USERNAME, 'RL_STUDENT'
        FROM UNIVERSITY_APP.STUDENTS
    ) expected_assignment
    JOIN DBA_ROLE_PRIVS actual_assignment
      ON actual_assignment.GRANTEE =
         UPPER(expected_assignment.ORACLE_USERNAME)
     AND actual_assignment.GRANTED_ROLE =
         expected_assignment.ROLE_NAME;

    IF v_processed_count <> v_expected_count
       OR v_assignment_count <> v_expected_count THEN
        RAISE_APPLICATION_ERROR(
            -20124,
            'User provisioning verification failed. Expected ' ||
            v_expected_count || ', processed ' || v_processed_count ||
            ', assigned ' || v_assignment_count || '.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Provisioned ' || v_processed_count ||
        ' Oracle data users in ' || v_container_name || '.'
    );
    DBMS_OUTPUT.PUT_LINE(
        'Demo password: ' || v_password
    );
    DBMS_OUTPUT.PUT_LINE(
        'WARNING: Use this password only in the local demo environment.'
    );
END;
/

PROMPT All STAFF and STUDENTS Oracle accounts were provisioned successfully.
