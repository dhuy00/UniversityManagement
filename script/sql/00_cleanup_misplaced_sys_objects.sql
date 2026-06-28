-- One-time cleanup for application tables accidentally created in SYS.
-- Run only as SYS in XEPDB1, then stop using SYS for application scripts.
--
-- WARNING: This permanently removes data from the eight exact table names
-- listed below in the SYS schema.

SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'SYS' THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'This cleanup must be run as SYS.'
        );
    END IF;

    FOR target IN (
        SELECT 1 AS DROP_ORDER, 'ENROLLMENTS' AS TABLE_NAME FROM DUAL
        UNION ALL
        SELECT 2, 'TEACHING_ASSIGNMENTS' FROM DUAL
        UNION ALL
        SELECT 3, 'COURSE_PLANS' FROM DUAL
        UNION ALL
        SELECT 4, 'COURSES' FROM DUAL
        UNION ALL
        SELECT 5, 'NOTIFICATIONS' FROM DUAL
        UNION ALL
        SELECT 6, 'STUDENTS' FROM DUAL
        UNION ALL
        SELECT 7, 'UNITS' FROM DUAL
        UNION ALL
        SELECT 8, 'STAFF' FROM DUAL
        ORDER BY 1
    )
    LOOP
        BEGIN
            EXECUTE IMMEDIATE
                'DROP TABLE SYS.' || target.TABLE_NAME ||
                ' CASCADE CONSTRAINTS PURGE';

            DBMS_OUTPUT.PUT_LINE(
                'Dropped SYS.' || target.TABLE_NAME || '.'
            );
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -942 THEN
                    DBMS_OUTPUT.PUT_LINE(
                        'Skipped SYS.' || target.TABLE_NAME ||
                        ' because it does not exist.'
                    );
                ELSE
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/

PROMPT One-time SYS cleanup completed.
