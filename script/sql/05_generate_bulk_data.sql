-- Phase 1 - Step 5: Bulk staff and student data
-- Target database: Oracle Database 21c
-- Run as the application owner after 04_seed_reference_data.sql.
--
-- Target totals from the project requirements:
--   BASIC_STAFF        10
--   LECTURER           80
--   ACADEMIC_AFFAIRS   10
--   UNIT_HEAD           6
--   DEAN                1
--   STUDENTS         4000
--
-- MERGE makes this script safe to rerun. Synthetic rows have application
-- usernames but do not require matching Oracle database accounts. The 15 demo
-- accounts from 04_test_users.sql are sufficient for access-control testing.

SET DEFINE OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('SYS', 'SYSTEM') THEN
        RAISE_APPLICATION_ERROR(
            -20000,
            'Run application scripts as UNIVERSITY_APP, not SYS or SYSTEM.'
        );
    END IF;
END;
/

-- Add 8 synthetic basic staff to the 2 reference rows.
MERGE INTO STAFF target
USING (
    SELECT
        'S' || LPAD(sequence_number + 13, 4, '0') AS STAFF_ID,
        'Basic Staff ' || LPAD(sequence_number + 2, 2, '0') AS FULL_NAME,
        CASE
            WHEN MOD(sequence_number, 2) = 0 THEN 'FEMALE'
            ELSE 'MALE'
        END AS GENDER,
        ADD_MONTHS(DATE '1985-01-01', MOD(sequence_number * 11, 120))
            AS DATE_OF_BIRTH,
        1000000 AS ALLOWANCE,
        '0902' || LPAD(sequence_number + 13, 6, '0') AS PHONE,
        'BASIC_STAFF' AS ROLE_CODE,
        CASE MOD(sequence_number - 1, 7)
            WHEN 0 THEN 'OFFICE'
            WHEN 1 THEN 'IS'
            WHEN 2 THEN 'SE'
            WHEN 3 THEN 'CS'
            WHEN 4 THEN 'IT'
            WHEN 5 THEN 'CV'
            ELSE 'NET'
        END AS UNIT_ID,
        'BASIC' || LPAD(sequence_number + 2, 2, '0') AS ORACLE_USERNAME,
        CASE
            WHEN MOD(sequence_number, 2) = 0 THEN 'CAMPUS_2'
            ELSE 'CAMPUS_1'
        END AS CAMPUS_ID
    FROM (
        SELECT LEVEL AS sequence_number
        FROM DUAL
        CONNECT BY LEVEL <= 8
    )
) source
ON (target.STAFF_ID = source.STAFF_ID)
WHEN NOT MATCHED THEN
    INSERT (
        STAFF_ID,
        FULL_NAME,
        GENDER,
        DATE_OF_BIRTH,
        ALLOWANCE,
        PHONE,
        ROLE_CODE,
        UNIT_ID,
        ORACLE_USERNAME,
        CAMPUS_ID
    )
    VALUES (
        source.STAFF_ID,
        source.FULL_NAME,
        source.GENDER,
        source.DATE_OF_BIRTH,
        source.ALLOWANCE,
        source.PHONE,
        source.ROLE_CODE,
        source.UNIT_ID,
        source.ORACLE_USERNAME,
        source.CAMPUS_ID
    );

-- Add 78 synthetic lecturers to the 2 reference rows.
MERGE INTO STAFF target
USING (
    SELECT
        'S' || LPAD(sequence_number + 21, 4, '0') AS STAFF_ID,
        'Lecturer ' || LPAD(sequence_number + 2, 2, '0') AS FULL_NAME,
        CASE
            WHEN MOD(sequence_number, 2) = 0 THEN 'FEMALE'
            ELSE 'MALE'
        END AS GENDER,
        ADD_MONTHS(DATE '1978-01-01', MOD(sequence_number * 7, 180))
            AS DATE_OF_BIRTH,
        2000000 + MOD(sequence_number, 5) * 100000 AS ALLOWANCE,
        '0903' || LPAD(sequence_number + 21, 6, '0') AS PHONE,
        'LECTURER' AS ROLE_CODE,
        CASE MOD(sequence_number - 1, 6)
            WHEN 0 THEN 'IS'
            WHEN 1 THEN 'SE'
            WHEN 2 THEN 'CS'
            WHEN 3 THEN 'IT'
            WHEN 4 THEN 'CV'
            ELSE 'NET'
        END AS UNIT_ID,
        'LECTURER' || LPAD(sequence_number + 2, 2, '0')
            AS ORACLE_USERNAME,
        CASE
            WHEN MOD(sequence_number, 2) = 0 THEN 'CAMPUS_2'
            ELSE 'CAMPUS_1'
        END AS CAMPUS_ID
    FROM (
        SELECT LEVEL AS sequence_number
        FROM DUAL
        CONNECT BY LEVEL <= 78
    )
) source
ON (target.STAFF_ID = source.STAFF_ID)
WHEN NOT MATCHED THEN
    INSERT (
        STAFF_ID,
        FULL_NAME,
        GENDER,
        DATE_OF_BIRTH,
        ALLOWANCE,
        PHONE,
        ROLE_CODE,
        UNIT_ID,
        ORACLE_USERNAME,
        CAMPUS_ID
    )
    VALUES (
        source.STAFF_ID,
        source.FULL_NAME,
        source.GENDER,
        source.DATE_OF_BIRTH,
        source.ALLOWANCE,
        source.PHONE,
        source.ROLE_CODE,
        source.UNIT_ID,
        source.ORACLE_USERNAME,
        source.CAMPUS_ID
    );

-- Add 8 synthetic academic-affairs staff to the 2 reference rows.
MERGE INTO STAFF target
USING (
    SELECT
        'S' || LPAD(sequence_number + 99, 4, '0') AS STAFF_ID,
        'Academic Affairs ' || LPAD(sequence_number + 2, 2, '0')
            AS FULL_NAME,
        CASE
            WHEN MOD(sequence_number, 2) = 0 THEN 'MALE'
            ELSE 'FEMALE'
        END AS GENDER,
        ADD_MONTHS(DATE '1988-01-01', MOD(sequence_number * 13, 96))
            AS DATE_OF_BIRTH,
        1500000 AS ALLOWANCE,
        '0904' || LPAD(sequence_number + 99, 6, '0') AS PHONE,
        'ACADEMIC_AFFAIRS' AS ROLE_CODE,
        'OFFICE' AS UNIT_ID,
        'AFFAIRS' || LPAD(sequence_number + 2, 2, '0')
            AS ORACLE_USERNAME,
        CASE
            WHEN MOD(sequence_number, 2) = 0 THEN 'CAMPUS_2'
            ELSE 'CAMPUS_1'
        END AS CAMPUS_ID
    FROM (
        SELECT LEVEL AS sequence_number
        FROM DUAL
        CONNECT BY LEVEL <= 8
    )
) source
ON (target.STAFF_ID = source.STAFF_ID)
WHEN NOT MATCHED THEN
    INSERT (
        STAFF_ID,
        FULL_NAME,
        GENDER,
        DATE_OF_BIRTH,
        ALLOWANCE,
        PHONE,
        ROLE_CODE,
        UNIT_ID,
        ORACLE_USERNAME,
        CAMPUS_ID
    )
    VALUES (
        source.STAFF_ID,
        source.FULL_NAME,
        source.GENDER,
        source.DATE_OF_BIRTH,
        source.ALLOWANCE,
        source.PHONE,
        source.ROLE_CODE,
        source.UNIT_ID,
        source.ORACLE_USERNAME,
        source.CAMPUS_ID
    );

-- Add students ST0003 through ST4000 to the 2 reference rows.
MERGE INTO STUDENTS target
USING (
    SELECT
        'ST' || LPAD(student_number, 4, '0') AS STUDENT_ID,
        'Student ' || LPAD(student_number, 4, '0') AS FULL_NAME,
        CASE
            WHEN MOD(student_number, 2) = 0 THEN 'FEMALE'
            ELSE 'MALE'
        END AS GENDER,
        DATE '2002-01-01' + MOD(student_number * 17, 1460)
            AS DATE_OF_BIRTH,
        'Address ' || student_number || ', Ho Chi Minh City' AS ADDRESS,
        '092' || LPAD(student_number, 7, '0') AS PHONE,
        CASE MOD(student_number - 1, 4)
            WHEN 0 THEN 'REGULAR'
            WHEN 1 THEN 'HIGH_QUALITY'
            WHEN 2 THEN 'ADVANCED'
            ELSE 'VIETNAM_FRANCE'
        END AS PROGRAM_ID,
        CASE MOD(student_number - 1, 6)
            WHEN 0 THEN 'IS'
            WHEN 1 THEN 'SE'
            WHEN 2 THEN 'CS'
            WHEN 3 THEN 'IT'
            WHEN 4 THEN 'CV'
            ELSE 'NET'
        END AS MAJOR_ID,
        MOD(student_number * 3, 121) AS ACCUMULATED_CREDITS,
        ROUND(5 + MOD(student_number * 37, 501) / 100, 2)
            AS CUMULATIVE_GPA,
        'STUDENT' || LPAD(student_number, 4, '0') AS ORACLE_USERNAME,
        CASE
            WHEN MOD(student_number, 2) = 0 THEN 'CAMPUS_2'
            ELSE 'CAMPUS_1'
        END AS CAMPUS_ID
    FROM (
        SELECT LEVEL + 2 AS student_number
        FROM DUAL
        CONNECT BY LEVEL <= 3998
    )
) source
ON (target.STUDENT_ID = source.STUDENT_ID)
WHEN NOT MATCHED THEN
    INSERT (
        STUDENT_ID,
        FULL_NAME,
        GENDER,
        DATE_OF_BIRTH,
        ADDRESS,
        PHONE,
        PROGRAM_ID,
        MAJOR_ID,
        ACCUMULATED_CREDITS,
        CUMULATIVE_GPA,
        ORACLE_USERNAME,
        CAMPUS_ID
    )
    VALUES (
        source.STUDENT_ID,
        source.FULL_NAME,
        source.GENDER,
        source.DATE_OF_BIRTH,
        source.ADDRESS,
        source.PHONE,
        source.PROGRAM_ID,
        source.MAJOR_ID,
        source.ACCUMULATED_CREDITS,
        source.CUMULATIVE_GPA,
        source.ORACLE_USERNAME,
        source.CAMPUS_ID
    );

-- Validate before COMMIT so SQL*Plus can roll back the bulk load on failure.
DECLARE
    v_basic_staff_count       PLS_INTEGER;
    v_lecturer_count          PLS_INTEGER;
    v_academic_affairs_count  PLS_INTEGER;
    v_unit_head_count         PLS_INTEGER;
    v_dean_count              PLS_INTEGER;
    v_student_count           PLS_INTEGER;

    PROCEDURE assert_count(
        p_label     IN VARCHAR2,
        p_actual    IN PLS_INTEGER,
        p_expected  IN PLS_INTEGER
    )
    IS
    BEGIN
        IF p_actual != p_expected THEN
            RAISE_APPLICATION_ERROR(
                -20010,
                p_label || ': expected ' || p_expected || ', found ' || p_actual
            );
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            RPAD(p_label, 20) || ' = ' || TO_CHAR(p_actual)
        );
    END assert_count;
BEGIN
    SELECT
        COUNT(CASE WHEN ROLE_CODE = 'BASIC_STAFF' THEN 1 END),
        COUNT(CASE WHEN ROLE_CODE = 'LECTURER' THEN 1 END),
        COUNT(CASE WHEN ROLE_CODE = 'ACADEMIC_AFFAIRS' THEN 1 END),
        COUNT(CASE WHEN ROLE_CODE = 'UNIT_HEAD' THEN 1 END),
        COUNT(CASE WHEN ROLE_CODE = 'DEAN' THEN 1 END)
    INTO
        v_basic_staff_count,
        v_lecturer_count,
        v_academic_affairs_count,
        v_unit_head_count,
        v_dean_count
    FROM STAFF;

    SELECT COUNT(*)
    INTO v_student_count
    FROM STUDENTS;

    assert_count('BASIC_STAFF', v_basic_staff_count, 10);
    assert_count('LECTURER', v_lecturer_count, 80);
    assert_count('ACADEMIC_AFFAIRS', v_academic_affairs_count, 10);
    assert_count('UNIT_HEAD', v_unit_head_count, 6);
    assert_count('DEAN', v_dean_count, 1);
    assert_count('STUDENTS', v_student_count, 4000);
END;
/

COMMIT;

-- Refresh optimizer statistics after the validated bulk load.
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => USER,
        tabname => 'STAFF',
        cascade => TRUE
    );

    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => USER,
        tabname => 'STUDENTS',
        cascade => TRUE
    );
END;
/

PROMPT Phase 1 - Step 5 completed: bulk staff and student data generated.
