-- Phase 2 - Step 2.1: Security roles and demo-user assignments
-- Target database: Oracle Database 21c / XEPDB1
--
-- Run as SYS or a security administrator with:
--   - CREATE ROLE
--   - GRANT ANY ROLE
--   - access to DBA_ROLES and DBA_ROLE_PRIVS
--
-- This script creates only roles, role inheritance, and direct role-to-user
-- assignments. Object privileges are granted in Step 2.2.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

DECLARE
    v_container_name  VARCHAR2(128);
    v_role_count      PLS_INTEGER;
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
    INTO v_container_name
    FROM DUAL;

    IF v_container_name = 'CDB$ROOT' THEN
        RAISE_APPLICATION_ERROR(
            -20100,
            'Connect to XEPDB1 before creating local application roles.'
        );
    END IF;

    FOR role_record IN (
        SELECT 'RL_BASIC_STAFF' AS ROLE_NAME FROM DUAL
        UNION ALL
        SELECT 'RL_LECTURER' FROM DUAL
        UNION ALL
        SELECT 'RL_ACADEMIC_AFFAIRS' FROM DUAL
        UNION ALL
        SELECT 'RL_UNIT_HEAD' FROM DUAL
        UNION ALL
        SELECT 'RL_DEAN' FROM DUAL
        UNION ALL
        SELECT 'RL_STUDENT' FROM DUAL
    )
    LOOP
        SELECT COUNT(*)
        INTO v_role_count
        FROM DBA_ROLES
        WHERE ROLE = role_record.ROLE_NAME;

        IF v_role_count = 0 THEN
            EXECUTE IMMEDIATE
                'CREATE ROLE ' ||
                DBMS_ASSERT.SIMPLE_SQL_NAME(role_record.ROLE_NAME);

            DBMS_OUTPUT.PUT_LINE(
                'Created role ' || role_record.ROLE_NAME || '.'
            );
        ELSE
            DBMS_OUTPUT.PUT_LINE(
                'Role ' || role_record.ROLE_NAME || ' already exists.'
            );
        END IF;
    END LOOP;
END;
/

-- Role inheritance mirrors the policy inheritance in CS#1-CS#5.
GRANT RL_BASIC_STAFF TO RL_LECTURER;
GRANT RL_BASIC_STAFF TO RL_ACADEMIC_AFFAIRS;
GRANT RL_LECTURER TO RL_UNIT_HEAD;
GRANT RL_LECTURER TO RL_DEAN;

DECLARE
    v_user_count  PLS_INTEGER;

    PROCEDURE normalize_and_grant_role(
        p_username   IN VARCHAR2,
        p_role_name  IN VARCHAR2
    )
    IS
        v_username   VARCHAR2(128);
        v_role_name  VARCHAR2(128);
    BEGIN
        v_username :=
            DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(p_username));
        v_role_name :=
            DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(p_role_name));

        SELECT COUNT(*)
        INTO v_user_count
        FROM DBA_USERS
        WHERE USERNAME = v_username;

        IF v_user_count = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20101,
                'Required demo user does not exist: ' || v_username
            );
        END IF;

        -- Remove stale direct assignments from this application's role set.
        -- Inherited roles are not listed as direct grants and are unaffected.
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

        DBMS_OUTPUT.PUT_LINE(
            'Granted ' || v_role_name || ' to ' || v_username || '.'
        );
    END normalize_and_grant_role;
BEGIN
    normalize_and_grant_role('DEAN01', 'RL_DEAN');

    normalize_and_grant_role('HEAD_IS01', 'RL_UNIT_HEAD');
    normalize_and_grant_role('HEAD_SE01', 'RL_UNIT_HEAD');
    normalize_and_grant_role('HEAD_CS01', 'RL_UNIT_HEAD');
    normalize_and_grant_role('HEAD_IT01', 'RL_UNIT_HEAD');
    normalize_and_grant_role('HEAD_CV01', 'RL_UNIT_HEAD');
    normalize_and_grant_role('HEAD_NET01', 'RL_UNIT_HEAD');

    normalize_and_grant_role('BASIC01', 'RL_BASIC_STAFF');
    normalize_and_grant_role('BASIC02', 'RL_BASIC_STAFF');

    normalize_and_grant_role('LECTURER01', 'RL_LECTURER');
    normalize_and_grant_role('LECTURER02', 'RL_LECTURER');

    normalize_and_grant_role('AFFAIRS01', 'RL_ACADEMIC_AFFAIRS');
    normalize_and_grant_role('AFFAIRS02', 'RL_ACADEMIC_AFFAIRS');

    normalize_and_grant_role('STUDENT01', 'RL_STUDENT');
    normalize_and_grant_role('STUDENT02', 'RL_STUDENT');
END;
/

PROMPT
PROMPT Role hierarchy:

COLUMN GRANTEE FORMAT A24
COLUMN GRANTED_ROLE FORMAT A24

SELECT
    GRANTEE,
    GRANTED_ROLE
FROM DBA_ROLE_PRIVS
WHERE GRANTEE IN (
    'RL_LECTURER',
    'RL_ACADEMIC_AFFAIRS',
    'RL_UNIT_HEAD',
    'RL_DEAN'
)
  AND GRANTED_ROLE IN (
      'RL_BASIC_STAFF',
      'RL_LECTURER'
  )
ORDER BY GRANTEE, GRANTED_ROLE;

PROMPT
PROMPT Direct demo-user role assignments:

SELECT
    GRANTEE,
    GRANTED_ROLE
FROM DBA_ROLE_PRIVS
WHERE GRANTEE IN (
    'DEAN01',
    'HEAD_IS01',
    'HEAD_SE01',
    'HEAD_CS01',
    'HEAD_IT01',
    'HEAD_CV01',
    'HEAD_NET01',
    'BASIC01',
    'BASIC02',
    'LECTURER01',
    'LECTURER02',
    'AFFAIRS01',
    'AFFAIRS02',
    'STUDENT01',
    'STUDENT02'
)
  AND GRANTED_ROLE IN (
      'RL_BASIC_STAFF',
      'RL_LECTURER',
      'RL_ACADEMIC_AFFAIRS',
      'RL_UNIT_HEAD',
      'RL_DEAN',
      'RL_STUDENT'
  )
ORDER BY GRANTEE, GRANTED_ROLE;

DECLARE
    v_role_count       PLS_INTEGER;
    v_hierarchy_count  PLS_INTEGER;
    v_assignment_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_role_count
    FROM DBA_ROLES
    WHERE ROLE IN (
        'RL_BASIC_STAFF',
        'RL_LECTURER',
        'RL_ACADEMIC_AFFAIRS',
        'RL_UNIT_HEAD',
        'RL_DEAN',
        'RL_STUDENT'
    );

    SELECT COUNT(*)
    INTO v_hierarchy_count
    FROM DBA_ROLE_PRIVS
    WHERE (
        GRANTEE = 'RL_LECTURER'
        AND GRANTED_ROLE = 'RL_BASIC_STAFF'
    )
       OR (
        GRANTEE = 'RL_ACADEMIC_AFFAIRS'
        AND GRANTED_ROLE = 'RL_BASIC_STAFF'
    )
       OR (
        GRANTEE = 'RL_UNIT_HEAD'
        AND GRANTED_ROLE = 'RL_LECTURER'
    )
       OR (
        GRANTEE = 'RL_DEAN'
        AND GRANTED_ROLE = 'RL_LECTURER'
    );

    SELECT COUNT(*)
    INTO v_assignment_count
    FROM DBA_ROLE_PRIVS
    WHERE GRANTEE IN (
        'DEAN01',
        'HEAD_IS01',
        'HEAD_SE01',
        'HEAD_CS01',
        'HEAD_IT01',
        'HEAD_CV01',
        'HEAD_NET01',
        'BASIC01',
        'BASIC02',
        'LECTURER01',
        'LECTURER02',
        'AFFAIRS01',
        'AFFAIRS02',
        'STUDENT01',
        'STUDENT02'
    )
      AND GRANTED_ROLE IN (
          'RL_BASIC_STAFF',
          'RL_LECTURER',
          'RL_ACADEMIC_AFFAIRS',
          'RL_UNIT_HEAD',
          'RL_DEAN',
          'RL_STUDENT'
      );

    IF v_role_count <> 6 THEN
        RAISE_APPLICATION_ERROR(
            -20102,
            'Expected 6 application roles, found ' || v_role_count || '.'
        );
    END IF;

    IF v_hierarchy_count <> 4 THEN
        RAISE_APPLICATION_ERROR(
            -20103,
            'Expected 4 role-hierarchy grants, found ' ||
            v_hierarchy_count || '.'
        );
    END IF;

    IF v_assignment_count <> 15 THEN
        RAISE_APPLICATION_ERROR(
            -20104,
            'Expected 15 direct demo-user role grants, found ' ||
            v_assignment_count || '.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Verified 6 roles, 4 hierarchy grants, and 15 user assignments.'
    );
END;
/

PROMPT Phase 2 - Step 2.1 completed successfully.
