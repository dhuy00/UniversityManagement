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