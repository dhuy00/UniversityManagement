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