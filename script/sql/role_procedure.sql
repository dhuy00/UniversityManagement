--Select All Role--
CREATE OR REPLACE PROCEDURE ROLE_GET_ALL(
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR 
      SELECT ROLE, AUTHENTICATION_TYPE, COMMON
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
            ROLE,
            OWNER,
            TABLE_NAME,
            PRIVILEGE,
            GRANTABLE
        FROM ROLE_TAB_PRIVS
        WHERE ROLE = UPPER(p_rolename);
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
    lv_stmt := 'ALTER SESSION SET "_ORACLE_SCRIPT" = TRUE';
    EXECUTE IMMEDIATE lv_stmt;
    
    -- Validate role name
    role_name := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(p_rolename));

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
                   ' IDENTIFIED BY "' || p_password || '"';
    END IF;

    EXECUTE IMMEDIATE lv_stmt;

    -- Grant login privilege
    lv_stmt := 'GRANT CREATE SESSION TO ' || role_name;
    EXECUTE IMMEDIATE lv_stmt;

    DBMS_OUTPUT.PUT_LINE('Role created successfully');
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
BEGIN
    v_rolename := DBMS_ASSERT.SIMPLE_SQL_NAME(
        UPPER(TRIM(p_rolename))
    );

    IF p_table_name IS NOT NULL THEN
        v_table_name := DBMS_ASSERT.SIMPLE_SQL_NAME(
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

        IF v_privilege NOT IN (
            'SELECT',
            'INSERT',
            'UPDATE',
            'DELETE',
            'EXECUTE',
            'REFERENCES',
            'ALTER',
            'INDEX',
            'CREATE SESSION',
            'CREATE TABLE',
            'CREATE VIEW',
            'CREATE PROCEDURE'
        ) THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'Invalid privilege: ' || v_privilege
            );
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