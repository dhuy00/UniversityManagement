--Select All Role--
CREATE OR REPLACE PROCEDURE ROLE_GET_ALL(
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR 
      SELECT ROLE, AUTHENTICATION_TYPE, COMMON, ORACLE_MAINTAINED
      FROM DBA_ROLES;
END;
/

-- Get role's privilege
CREATE OR REPLACE PROCEDURE ROLE_GET_PRIVILEGE (
    p_rolename IN VARCHAR2,
    p_cursor  OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT
            'TABLE' AS PRIVILEGE_TYPE,
            p.GRANTEE AS ROLE,
            p.OWNER,
            p.TABLE_NAME,
            NULL AS COLUMN_NAME,
            p.PRIVILEGE,
            p.GRANTABLE
        FROM SYS.DBA_TAB_PRIVS p
        WHERE p.GRANTEE = UPPER(p_rolename)
          AND NOT (
              p.PRIVILEGE = 'SELECT'
              AND EXISTS (
                  SELECT 1
                  FROM SYS.DBA_TABLES t
                  WHERE p.TABLE_NAME =
                      'VW_SEL_' || t.OWNER || '_' || t.TABLE_NAME || '_' || p.GRANTEE
              )
          )
        UNION ALL
        SELECT
            'COLUMN' AS PRIVILEGE_TYPE,
            p.GRANTEE AS ROLE,
            p.OWNER,
            p.TABLE_NAME,
            p.COLUMN_NAME,
            p.PRIVILEGE,
            p.GRANTABLE
        FROM SYS.DBA_COL_PRIVS p
        WHERE p.GRANTEE = UPPER(p_rolename)
        UNION ALL
        SELECT
            'COLUMN' AS PRIVILEGE_TYPE,
            p.GRANTEE AS ROLE,
            t.OWNER,
            t.TABLE_NAME,
            c.COLUMN_NAME,
            'SELECT' AS PRIVILEGE,
            p.GRANTABLE
        FROM SYS.DBA_TAB_PRIVS p
        JOIN SYS.DBA_TABLES t
          ON p.TABLE_NAME =
             'VW_SEL_' || t.OWNER || '_' || t.TABLE_NAME || '_' || p.GRANTEE
        JOIN SYS.DBA_TAB_COLUMNS c
          ON c.OWNER = p.OWNER
         AND c.TABLE_NAME = p.TABLE_NAME
        WHERE p.GRANTEE = UPPER(p_rolename)
          AND p.PRIVILEGE = 'SELECT'
        UNION ALL
        SELECT
            'SYSTEM' AS PRIVILEGE_TYPE,
            p.GRANTEE AS ROLE,
            NULL AS OWNER,
            NULL AS TABLE_NAME,
            NULL AS COLUMN_NAME,
            p.PRIVILEGE,
            p.ADMIN_OPTION AS GRANTABLE
        FROM SYS.DBA_SYS_PRIVS p
        WHERE p.GRANTEE = UPPER(p_rolename);
END;
/

-- Create a new role
CREATE OR REPLACE PROCEDURE ROLE_CREATE (
    p_rolename IN VARCHAR2,
    p_password IN VARCHAR2 DEFAULT NULL
)
IS
    role_name VARCHAR2(128);
    li_count NUMBER := 0;
    lv_stmt VARCHAR2(1000);
BEGIN
    -- Validate role name
    role_name := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM(p_rolename)));

    -- Check existing role
    SELECT COUNT(1)
    INTO li_count
    FROM DBA_ROLES
    WHERE ROLE = role_name;

    IF li_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Role already exists'
        );
    END IF;

    -- Create role
    IF p_password IS NULL THEN
        lv_stmt := 'CREATE ROLE ' || role_name;
    ELSE
        lv_stmt := 'CREATE ROLE ' || role_name ||
                   ' IDENTIFIED BY "' ||
                   REPLACE(p_password, '"', '""') || '"';
    END IF;

    EXECUTE IMMEDIATE lv_stmt;

    -- Grant login privilege
    lv_stmt := 'GRANT CREATE SESSION TO ' || role_name;
    EXECUTE IMMEDIATE lv_stmt;

    DBMS_OUTPUT.PUT_LINE('Role created successfully');
END;
/

-- Update role password
CREATE OR REPLACE PROCEDURE ROLE_UPDATE_PASSWORD (
    p_rolename IN VARCHAR2,
    p_password IN VARCHAR2
)
AS
    v_rolename VARCHAR2(128);
    v_count    NUMBER;
BEGIN
    v_rolename := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM(p_rolename)));

    IF p_password IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Password is required');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM SYS.DBA_ROLES
    WHERE ROLE = v_rolename;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Role does not exist');
    END IF;

    EXECUTE IMMEDIATE
        'ALTER ROLE ' || v_rolename ||
        ' IDENTIFIED BY "' || REPLACE(p_password, '"', '""') || '"';
END;
/

-- GRANT ROLE TO USER
CREATE OR REPLACE PROCEDURE ROLE_GRANT_TO_USER (
    p_username IN VARCHAR2,
    p_rolename IN VARCHAR2
)
AS
    v_username VARCHAR2(128);
    v_rolename VARCHAR2(128);

    v_count NUMBER;
BEGIN
    v_username := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM(p_username)));
    v_rolename := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM(p_rolename)));

    SELECT COUNT(*)
    INTO v_count
    FROM DBA_USERS
    WHERE USERNAME = v_username;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'User does not exists');
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM DBA_ROLES
    WHERE ROLE = v_rolename;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Role does not exists');
    END IF;
    
    EXECUTE IMMEDIATE 'GRANT ' || v_rolename || ' TO ' || v_username;
END;
/

-- REVOKE ROLE FROM USER
CREATE OR REPLACE PROCEDURE ROLE_REVOKE_FROM_USER (
    p_username IN VARCHAR2,
    p_rolename IN VARCHAR2
)
AS
    v_username VARCHAR2(128);
    v_rolename VARCHAR2(128);
    v_count    NUMBER;
BEGIN
    v_username := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM(p_username)));
    v_rolename := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM(p_rolename)));

    SELECT COUNT(*)
    INTO v_count
    FROM DBA_ROLE_PRIVS
    WHERE GRANTEE = v_username
      AND GRANTED_ROLE = v_rolename;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Role is not granted to user');
    END IF;

    EXECUTE IMMEDIATE 'REVOKE ' || v_rolename || ' FROM ' || v_username;
END;
/

--DELETE A ROLE
CREATE OR REPLACE PROCEDURE ROLE_DELETE (
    p_rolename IN VARCHAR2
)
AS
    v_rolename VARCHAR2(128);
    v_count    NUMBER;
BEGIN
    v_rolename := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM(p_rolename)));

    SELECT COUNT(*)
    INTO v_count
    FROM dba_roles
    WHERE role = v_rolename;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Role does not exist');
    END IF;

    EXECUTE IMMEDIATE
        'DROP ROLE ' || v_rolename;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Failed to drop role: ' || SQLERRM);
END;
/


-- revoke a role's privilege
CREATE OR REPLACE PROCEDURE ROLE_REVOKE_PRIVILEGE (
    p_rolename   IN VARCHAR2,
    p_privileges IN VARCHAR2,
    p_table_name IN VARCHAR2 DEFAULT NULL
)
AS
    v_rolename        VARCHAR2(128);
    v_table_name      VARCHAR2(128);
    v_privilege       VARCHAR2(50);
    v_privilege_list  VARCHAR2(4000);
    v_sql             VARCHAR2(4000);
    v_view_name       VARCHAR2(128);
    v_count           NUMBER;
BEGIN
    v_rolename := DBMS_ASSERT.SIMPLE_SQL_NAME(
        UPPER(TRIM(p_rolename))
    );

    IF p_table_name IS NOT NULL THEN
        v_table_name := DBMS_ASSERT.SQL_OBJECT_NAME(
            UPPER(TRIM(p_table_name))
        );
    END IF;

    -- Validate privileges and build list
    FOR rec IN (
        SELECT TRIM(
                   REGEXP_SUBSTR(
                       UPPER(p_privileges),
                       '[^,]+',
                       1,
                       LEVEL
                   )
               ) privilege
        FROM dual
        CONNECT BY REGEXP_SUBSTR(
                       UPPER(p_privileges),
                       '[^,]+',
                       1,
                       LEVEL
                   ) IS NOT NULL
    )
    LOOP
        v_privilege := rec.privilege;

        IF p_table_name IS NOT NULL THEN
            IF v_privilege NOT IN (
                'SELECT',
                'INSERT',
                'UPDATE',
                'DELETE',
                'EXECUTE',
                'REFERENCES',
                'ALTER',
                'INDEX'
            ) THEN
                RAISE_APPLICATION_ERROR(
                    -20001,
                    'Invalid object privilege: ' || v_privilege
                );
            END IF;
        ELSE
            SELECT COUNT(*)
            INTO v_count
            FROM SYS.SYSTEM_PRIVILEGE_MAP
            WHERE NAME = v_privilege;

            IF v_count = 0 THEN
                RAISE_APPLICATION_ERROR(
                    -20001,
                    'Invalid system privilege: ' || v_privilege
                );
            END IF;
        END IF;

        IF v_privilege_list IS NULL THEN
            v_privilege_list := v_privilege;
        ELSE
            v_privilege_list := v_privilege_list || ', ' || v_privilege;
        END IF;
    END LOOP;

    IF v_privilege_list IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'No privileges specified'
        );
    END IF;

    IF v_table_name IS NOT NULL AND v_privilege_list = 'SELECT' THEN
        v_view_name := DBMS_ASSERT.SIMPLE_SQL_NAME(
            'VW_SEL_' ||
            REPLACE(v_table_name, '.', '_') ||
            '_' ||
            v_rolename
        );

        SELECT COUNT(*)
        INTO v_count
        FROM SYS.DBA_TAB_PRIVS
        WHERE GRANTEE = v_rolename
          AND TABLE_NAME = v_view_name
          AND PRIVILEGE = 'SELECT';

        IF v_count > 0 THEN
            EXECUTE IMMEDIATE
                'REVOKE SELECT ON ' || v_view_name ||
                ' FROM ' || v_rolename;
            EXECUTE IMMEDIATE 'DROP VIEW ' || v_view_name;
            RETURN;
        END IF;
    END IF;

    IF v_table_name IS NOT NULL THEN
        v_sql :=
            'REVOKE ' || v_privilege_list ||
            ' ON ' || v_table_name ||
            ' FROM ' || v_rolename;
    ELSE
        v_sql :=
            'REVOKE ' || v_privilege_list ||
            ' FROM ' || v_rolename;
    END IF;

    EXECUTE IMMEDIATE v_sql;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Failed to revoke privilege(s): ' || SQLERRM
        );
END;
/
