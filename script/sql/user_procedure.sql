-- Get all users
CREATE OR REPLACE PROCEDURE USER_GET_ALL (
    p_cursor OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR 
        SELECT USERNAME, ACCOUNT_STATUS
        FROM SYS.DBA_USERS;
END;
/

-- Get user's privilege
CREATE OR REPLACE PROCEDURE USER_GET_PRIVILEGE (
    p_username IN VARCHAR2,
    p_cursor  OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_cursor FOR
        SELECT 
            GRANTEE,
            OWNER,
            TABLE_NAME,
            PRIVILEGE,
            GRANTABLE
        FROM SYS.DBA_TAB_PRIVS
        WHERE GRANTEE = UPPER(p_username);
END;
/

-- Create a new user
CREATE OR REPLACE PROCEDURE USER_CREATE (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2
)
IS
    v_user   VARCHAR2(128);
    v_sql    VARCHAR2(1000);
    v_exists NUMBER;
BEGIN
    -- Normalize username
    v_user := UPPER(TRIM(p_username));

    -- Check user existence (more reliable than COUNT)
    SELECT COUNT(*)
    INTO v_exists
    FROM all_users
    WHERE username = v_user;

    -- If exists → drop first
    IF v_exists > 0 THEN
        v_sql := 'DROP USER ' || DBMS_ASSERT.SIMPLE_SQL_NAME(v_user) || ' CASCADE';
        EXECUTE IMMEDIATE v_sql;
    END IF;

    -- Create user 
    v_sql :=
        'CREATE USER ' || DBMS_ASSERT.SIMPLE_SQL_NAME(v_user) ||
        ' IDENTIFIED BY "' || REPLACE(p_password, '"', '""') || '"' ||
        ' DEFAULT TABLESPACE USERS';

    EXECUTE IMMEDIATE v_sql;

    -- Grants
    EXECUTE IMMEDIATE
        'GRANT CREATE SESSION TO ' || DBMS_ASSERT.SIMPLE_SQL_NAME(v_user);

    EXECUTE IMMEDIATE
        'GRANT RESOURCE TO ' || DBMS_ASSERT.SIMPLE_SQL_NAME(v_user);

    DBMS_OUTPUT.PUT_LINE('User ' || v_user || ' created successfully');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END;
/