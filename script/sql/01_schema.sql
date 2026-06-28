-- Phase 1 - Step 1: Core application tables
-- Target database: Oracle Database 21c
-- Run this script while connected to the application owner schema.
--
-- This step intentionally defines only:
--   - tables and columns
--   - data types
--   - primary keys
--
-- Foreign keys, unique constraints, check constraints, and indexes are added
-- in later scripts after the core data model has been reviewed.

SET DEFINE OFF
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

-- Remove downstream security packages before rebuilding their source tables.
-- The SYS-owned context/logon trigger is intentionally preserved and safely
-- ignores initialization errors until Phase 2 recreates the trusted package.
BEGIN
    FOR target IN (
        SELECT 'BUSINESS_RULE_PKG' AS PACKAGE_NAME FROM DUAL
        UNION ALL
        SELECT 'ACCESS_POLICY_PKG' FROM DUAL
        UNION ALL
        SELECT 'SECURITY_CONTEXT_PKG' FROM DUAL
    )
    LOOP
        BEGIN
            EXECUTE IMMEDIATE
                'DROP PACKAGE ' || target.PACKAGE_NAME;
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE != -4043 THEN
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/

-- Oracle 21c does not support DROP TABLE IF EXISTS. This block provides the
-- equivalent behavior so the schema script can be rerun safely.
--
-- WARNING: Rerunning this file permanently removes all data from these tables.
BEGIN
    FOR target IN (
        SELECT 1 AS DROP_ORDER, 'SECURITY_IDENTITIES' AS TABLE_NAME FROM DUAL
        UNION ALL
        SELECT 2, 'ENROLLMENTS' FROM DUAL
        UNION ALL
        SELECT 3, 'TEACHING_ASSIGNMENTS' FROM DUAL
        UNION ALL
        SELECT 4, 'COURSE_PLANS' FROM DUAL
        UNION ALL
        SELECT 5, 'COURSES' FROM DUAL
        UNION ALL
        SELECT 6, 'NOTIFICATIONS' FROM DUAL
        UNION ALL
        SELECT 7, 'STUDENTS' FROM DUAL
        UNION ALL
        SELECT 8, 'UNITS' FROM DUAL
        UNION ALL
        SELECT 9, 'STAFF' FROM DUAL
        ORDER BY 1
    )
    LOOP
        BEGIN
            EXECUTE IMMEDIATE
                'DROP TABLE ' || target.TABLE_NAME ||
                ' CASCADE CONSTRAINTS PURGE';
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE != -942 THEN
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/

CREATE TABLE UNITS (
    UNIT_ID         VARCHAR2(20 CHAR)  NOT NULL,
    UNIT_NAME       VARCHAR2(150 CHAR) NOT NULL,
    HEAD_STAFF_ID   VARCHAR2(20 CHAR),

    CONSTRAINT PK_UNITS PRIMARY KEY (UNIT_ID)
);

CREATE TABLE STAFF (
    STAFF_ID          VARCHAR2(20 CHAR)  NOT NULL,
    FULL_NAME         VARCHAR2(150 CHAR) NOT NULL,
    GENDER            VARCHAR2(10 CHAR)  NOT NULL,
    DATE_OF_BIRTH     DATE               NOT NULL,
    ALLOWANCE         NUMBER(12, 2)      DEFAULT 0 NOT NULL,
    PHONE             VARCHAR2(20 CHAR),
    ROLE_CODE         VARCHAR2(30 CHAR)  NOT NULL,
    UNIT_ID           VARCHAR2(20 CHAR)  NOT NULL,
    ORACLE_USERNAME   VARCHAR2(128 CHAR) NOT NULL,
    CAMPUS_ID         VARCHAR2(20 CHAR)  NOT NULL,

    CONSTRAINT PK_STAFF PRIMARY KEY (STAFF_ID)
);

CREATE TABLE STUDENTS (
    STUDENT_ID           VARCHAR2(20 CHAR)  NOT NULL,
    FULL_NAME            VARCHAR2(150 CHAR) NOT NULL,
    GENDER               VARCHAR2(10 CHAR)  NOT NULL,
    DATE_OF_BIRTH        DATE               NOT NULL,
    ADDRESS              VARCHAR2(500 CHAR),
    PHONE                VARCHAR2(20 CHAR),
    PROGRAM_ID           VARCHAR2(20 CHAR)  NOT NULL,
    MAJOR_ID             VARCHAR2(20 CHAR)  NOT NULL,
    ACCUMULATED_CREDITS  NUMBER(4)          DEFAULT 0 NOT NULL,
    CUMULATIVE_GPA       NUMBER(4, 2)       DEFAULT 0 NOT NULL,
    ORACLE_USERNAME      VARCHAR2(128 CHAR) NOT NULL,
    CAMPUS_ID            VARCHAR2(20 CHAR)  NOT NULL,

    CONSTRAINT PK_STUDENTS PRIMARY KEY (STUDENT_ID)
);

CREATE TABLE COURSES (
    COURSE_ID          VARCHAR2(20 CHAR)  NOT NULL,
    COURSE_NAME        VARCHAR2(200 CHAR) NOT NULL,
    CREDITS            NUMBER(2)          NOT NULL,
    THEORY_PERIODS     NUMBER(3)          DEFAULT 0 NOT NULL,
    PRACTICE_PERIODS   NUMBER(3)          DEFAULT 0 NOT NULL,
    MAX_STUDENTS       NUMBER(4)          NOT NULL,
    UNIT_ID            VARCHAR2(20 CHAR)  NOT NULL,

    CONSTRAINT PK_COURSES PRIMARY KEY (COURSE_ID)
);

CREATE TABLE COURSE_PLANS (
    COURSE_ID       VARCHAR2(20 CHAR) NOT NULL,
    SEMESTER        NUMBER(1)         NOT NULL,
    ACADEMIC_YEAR   NUMBER(4)         NOT NULL,
    PROGRAM_ID      VARCHAR2(20 CHAR) NOT NULL,
    START_DATE      DATE              NOT NULL,

    CONSTRAINT PK_COURSE_PLANS PRIMARY KEY (
        COURSE_ID,
        SEMESTER,
        ACADEMIC_YEAR,
        PROGRAM_ID
    )
);

CREATE TABLE TEACHING_ASSIGNMENTS (
    LECTURER_ID     VARCHAR2(20 CHAR) NOT NULL,
    COURSE_ID       VARCHAR2(20 CHAR) NOT NULL,
    SEMESTER        NUMBER(1)         NOT NULL,
    ACADEMIC_YEAR   NUMBER(4)         NOT NULL,
    PROGRAM_ID      VARCHAR2(20 CHAR) NOT NULL,

    CONSTRAINT PK_TEACHING_ASSIGNMENTS PRIMARY KEY (
        LECTURER_ID,
        COURSE_ID,
        SEMESTER,
        ACADEMIC_YEAR,
        PROGRAM_ID
    )
);

CREATE TABLE ENROLLMENTS (
    STUDENT_ID        VARCHAR2(20 CHAR) NOT NULL,
    LECTURER_ID       VARCHAR2(20 CHAR) NOT NULL,
    COURSE_ID         VARCHAR2(20 CHAR) NOT NULL,
    SEMESTER          NUMBER(1)         NOT NULL,
    ACADEMIC_YEAR     NUMBER(4)         NOT NULL,
    PROGRAM_ID        VARCHAR2(20 CHAR) NOT NULL,
    PRACTICE_SCORE    NUMBER(4, 2),
    PROCESS_SCORE     NUMBER(4, 2),
    FINAL_EXAM_SCORE  NUMBER(4, 2),
    FINAL_SCORE       NUMBER(4, 2),

    CONSTRAINT PK_ENROLLMENTS PRIMARY KEY (
        STUDENT_ID,
        LECTURER_ID,
        COURSE_ID,
        SEMESTER,
        ACADEMIC_YEAR,
        PROGRAM_ID
    )
);

CREATE TABLE NOTIFICATIONS (
    NOTIFICATION_ID   NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY,
    CONTENT           CLOB               NOT NULL,
    CREATED_AT        TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,
    CREATED_BY        VARCHAR2(128 CHAR)  NOT NULL,

    CONSTRAINT PK_NOTIFICATIONS PRIMARY KEY (NOTIFICATION_ID)
);

PROMPT Phase 1 - Step 1 completed: core tables and primary keys created.
