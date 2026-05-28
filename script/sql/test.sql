VAR rc REFCURSOR;

EXEC USER_GET_ALL(:rc);

PRINT rc;

SELECT * FROM DBA_TAB_PRIVS;

select * from DBA_ROLES;

VAR rc REFCURSOR;

EXEC ROLE_GET_ALL(:rc);

PRINT rc;

SELECT * from DBA_TAB_PRIVS WHERE GrANTEE = 'USER_TEST_AGAIN';

BEGIN
    PERMISSION_GRANT(
        p_permission_type    => 'SELECT',
        p_tablename          => 'DUAL',
        p_target_name        => 'USER_TEST_AGAIN',
        p_is_grant_option    => 0,
        p_column_name_select => NULL,
        p_column_name_update => NULL
    );
END;
/