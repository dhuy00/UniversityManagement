-- Legacy scratch tests for the original admin-console procedures.
VAR rc REFCURSOR;

EXEC USER_GET_ALL(:rc);

PRINT rc;

SELECT * FROM DBA_TAB_PRIVS;

select * from DBA_ROLES;

select * from dba_users;

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

    SELECT COUNT(*)
    FROM DBA_USERS
    WHERE USERNAME = 'USER_TEST_AGAIN';

select *
from DBA_USERS;


SELECT COUNT(*) FROM UNIVERSITY_APP.STUDENTS;      -- 1
SELECT COUNT(*) FROM UNIVERSITY_APP.COURSE_PLANS; -- 9 với STUDENT01

SELECT COUNT(*) FROM UNIVERSITY_APP.ENROLLMENTS;
