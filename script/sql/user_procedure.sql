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


--DELETE A USER
CREATE OR REPLACE PROCEDURE USER_DELETE (
    p_username IN VARCHAR2
)
AS
    v_username VARCHAR2(128);
    v_count    NUMBER;
BEGIN
    v_username := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(TRIM(p_username)));

    SELECT COUNT(*)
    INTO v_count
    FROM dba_users
    WHERE username = v_username;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'User does not exist');
    END IF;

    EXECUTE IMMEDIATE
        'DROP USER ' || v_username;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Failed to drop user: ' || SQLERRM);
END;
/

-- revoke a user's privilege
CREATE OR REPLACE PROCEDURE USER_REVOKE_PRIVILEGE (
    p_username   IN VARCHAR2,
    p_privileges IN VARCHAR2,
    p_table_name IN VARCHAR2 DEFAULT NULL
)
AS
    v_username        VARCHAR2(128);
    v_table_name      VARCHAR2(128);
    v_privilege       VARCHAR2(50);
    v_privilege_list  VARCHAR2(4000);
    v_sql             VARCHAR2(4000);
BEGIN
    v_username := DBMS_ASSERT.SIMPLE_SQL_NAME(
        UPPER(TRIM(p_username))
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
            ' FROM ' || v_username;
    ELSE
        v_sql :=
            'REVOKE ' || v_privilege_list ||
            ' FROM ' || v_username;
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
