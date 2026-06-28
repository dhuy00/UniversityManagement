-- Phase 2 - Step 2.3A: Secure identity-context package
-- Target database: Oracle Database 21c / XEPDB1
--
-- Run as UNIVERSITY_APP after 11_grant_object_privileges.sql.
-- Then run 12b_create_context_and_logon_trigger.sql as a security admin.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'UNIVERSITY_APP' THEN
        RAISE_APPLICATION_ERROR(
            -20300,
            'Run this script as UNIVERSITY_APP.'
        );
    END IF;
END;
/

DECLARE
    v_table_count  PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_table_count
    FROM USER_TABLES
    WHERE TABLE_NAME = 'SECURITY_IDENTITIES';

    IF v_table_count = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE SECURITY_IDENTITIES (
                DB_USERNAME    VARCHAR2(128 CHAR) NOT NULL,
                IDENTITY_TYPE  VARCHAR2(10 CHAR)  NOT NULL,
                STAFF_ID       VARCHAR2(20 CHAR),
                STUDENT_ID     VARCHAR2(20 CHAR),
                ROLE_CODE      VARCHAR2(30 CHAR)  NOT NULL,
                UNIT_ID        VARCHAR2(20 CHAR),
                PROGRAM_ID     VARCHAR2(20 CHAR),
                MAJOR_ID       VARCHAR2(20 CHAR),
                CAMPUS_ID      VARCHAR2(20 CHAR),

                CONSTRAINT PK_SECURITY_IDENTITIES
                    PRIMARY KEY (DB_USERNAME),
                CONSTRAINT CK_SECURITY_IDENTITY_TYPE
                    CHECK (IDENTITY_TYPE IN ('STAFF', 'STUDENT')),
                CONSTRAINT CK_SECURITY_IDENTITY_OWNER
                    CHECK (
                        (IDENTITY_TYPE = 'STAFF'
                         AND STAFF_ID IS NOT NULL
                         AND STUDENT_ID IS NULL)
                        OR
                        (IDENTITY_TYPE = 'STUDENT'
                         AND STUDENT_ID IS NOT NULL
                         AND STAFF_ID IS NULL)
                    )
            )
        ]';

        EXECUTE IMMEDIATE q'[
            CREATE INDEX IX_SECURITY_IDENTITIES_UNIT
            ON SECURITY_IDENTITIES (UNIT_ID, ROLE_CODE, STAFF_ID)
        ]';
    END IF;
END;
/

-- Remove identities whose source row no longer exists, then upsert the current
-- STAFF/STUDENTS mapping. No application role receives access to this table.
DELETE FROM SECURITY_IDENTITIES si
WHERE NOT EXISTS (
    SELECT 1
    FROM STAFF s
    WHERE s.ORACLE_USERNAME = si.DB_USERNAME
)
  AND NOT EXISTS (
    SELECT 1
    FROM STUDENTS s
    WHERE s.ORACLE_USERNAME = si.DB_USERNAME
);

MERGE INTO SECURITY_IDENTITIES target
USING (
    SELECT
        ORACLE_USERNAME AS DB_USERNAME,
        'STAFF' AS IDENTITY_TYPE,
        STAFF_ID,
        CAST(NULL AS VARCHAR2(20)) AS STUDENT_ID,
        ROLE_CODE,
        UNIT_ID,
        CAST(NULL AS VARCHAR2(20)) AS PROGRAM_ID,
        CAST(NULL AS VARCHAR2(20)) AS MAJOR_ID,
        CAMPUS_ID
    FROM STAFF
    UNION ALL
    SELECT
        ORACLE_USERNAME AS DB_USERNAME,
        'STUDENT' AS IDENTITY_TYPE,
        CAST(NULL AS VARCHAR2(20)) AS STAFF_ID,
        STUDENT_ID,
        'STUDENT' AS ROLE_CODE,
        CAST(NULL AS VARCHAR2(20)) AS UNIT_ID,
        PROGRAM_ID,
        MAJOR_ID,
        CAMPUS_ID
    FROM STUDENTS
) source
ON (target.DB_USERNAME = source.DB_USERNAME)
WHEN MATCHED THEN
    UPDATE SET
        target.IDENTITY_TYPE = source.IDENTITY_TYPE,
        target.STAFF_ID = source.STAFF_ID,
        target.STUDENT_ID = source.STUDENT_ID,
        target.ROLE_CODE = source.ROLE_CODE,
        target.UNIT_ID = source.UNIT_ID,
        target.PROGRAM_ID = source.PROGRAM_ID,
        target.MAJOR_ID = source.MAJOR_ID,
        target.CAMPUS_ID = source.CAMPUS_ID
WHEN NOT MATCHED THEN
    INSERT (
        DB_USERNAME,
        IDENTITY_TYPE,
        STAFF_ID,
        STUDENT_ID,
        ROLE_CODE,
        UNIT_ID,
        PROGRAM_ID,
        MAJOR_ID,
        CAMPUS_ID
    )
    VALUES (
        source.DB_USERNAME,
        source.IDENTITY_TYPE,
        source.STAFF_ID,
        source.STUDENT_ID,
        source.ROLE_CODE,
        source.UNIT_ID,
        source.PROGRAM_ID,
        source.MAJOR_ID,
        source.CAMPUS_ID
    );

COMMIT;

CREATE OR REPLACE PACKAGE SECURITY_CONTEXT_PKG
AUTHID DEFINER
AS
    PROCEDURE INITIALIZE_SESSION;
END SECURITY_CONTEXT_PKG;
/

CREATE OR REPLACE PACKAGE BODY SECURITY_CONTEXT_PKG
AS
    PROCEDURE SET_ATTRIBUTE(
        p_name   IN VARCHAR2,
        p_value  IN VARCHAR2
    )
    IS
    BEGIN
        DBMS_SESSION.SET_CONTEXT(
            namespace => 'UNIVERSITY_CTX',
            attribute => p_name,
            value     => p_value
        );
    END SET_ATTRIBUTE;

    PROCEDURE INITIALIZE_SESSION
    IS
        v_database_username  VARCHAR2(128);
        v_identity_type      SECURITY_IDENTITIES.IDENTITY_TYPE%TYPE;
        v_staff_id           SECURITY_IDENTITIES.STAFF_ID%TYPE;
        v_student_id         SECURITY_IDENTITIES.STUDENT_ID%TYPE;
        v_role_code          SECURITY_IDENTITIES.ROLE_CODE%TYPE;
        v_unit_id            SECURITY_IDENTITIES.UNIT_ID%TYPE;
        v_program_id         SECURITY_IDENTITIES.PROGRAM_ID%TYPE;
        v_major_id           SECURITY_IDENTITIES.MAJOR_ID%TYPE;
        v_campus_id          SECURITY_IDENTITIES.CAMPUS_ID%TYPE;
    BEGIN
        v_database_username :=
            UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'));

        DBMS_SESSION.CLEAR_ALL_CONTEXT('UNIVERSITY_CTX');
        SET_ATTRIBUTE('DB_USERNAME', v_database_username);

        IF v_database_username = 'UNIVERSITY_APP' THEN
            SET_ATTRIBUTE('IDENTITY_TYPE', 'OWNER');
            SET_ATTRIBUTE('ROLE_CODE', 'OWNER');
            RETURN;
        END IF;

        BEGIN
            SELECT
                IDENTITY_TYPE,
                STAFF_ID,
                STUDENT_ID,
                ROLE_CODE,
                UNIT_ID,
                PROGRAM_ID,
                MAJOR_ID,
                CAMPUS_ID
            INTO
                v_identity_type,
                v_staff_id,
                v_student_id,
                v_role_code,
                v_unit_id,
                v_program_id,
                v_major_id,
                v_campus_id
            FROM SECURITY_IDENTITIES
            WHERE DB_USERNAME = v_database_username;

            SET_ATTRIBUTE('IDENTITY_TYPE', v_identity_type);
            SET_ATTRIBUTE('STAFF_ID', v_staff_id);
            SET_ATTRIBUTE('STUDENT_ID', v_student_id);
            SET_ATTRIBUTE('ROLE_CODE', v_role_code);
            SET_ATTRIBUTE('UNIT_ID', v_unit_id);
            SET_ATTRIBUTE('PROGRAM_ID', v_program_id);
            SET_ATTRIBUTE('MAJOR_ID', v_major_id);
            SET_ATTRIBUTE('CAMPUS_ID', v_campus_id);
            RETURN;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;

        -- Unknown database users receive no application identity. Future VPD
        -- policies treat IDENTITY_TYPE=UNKNOWN as deny-by-default.
        SET_ATTRIBUTE('IDENTITY_TYPE', 'UNKNOWN');
        SET_ATTRIBUTE('ROLE_CODE', 'NONE');
    END INITIALIZE_SESSION;
END SECURITY_CONTEXT_PKG;
/

CREATE OR REPLACE TRIGGER TRG_SYNC_STAFF_IDENTITY
AFTER INSERT OR UPDATE OR DELETE ON STAFF
FOR EACH ROW
BEGIN
    IF DELETING OR (
        UPDATING
        AND :OLD.ORACLE_USERNAME <> :NEW.ORACLE_USERNAME
    ) THEN
        DELETE FROM SECURITY_IDENTITIES
        WHERE DB_USERNAME = :OLD.ORACLE_USERNAME;
    END IF;

    IF INSERTING OR UPDATING THEN
        MERGE INTO SECURITY_IDENTITIES target
        USING (
            SELECT
                :NEW.ORACLE_USERNAME AS DB_USERNAME,
                :NEW.STAFF_ID AS STAFF_ID,
                :NEW.ROLE_CODE AS ROLE_CODE,
                :NEW.UNIT_ID AS UNIT_ID,
                :NEW.CAMPUS_ID AS CAMPUS_ID
            FROM DUAL
        ) source
        ON (target.DB_USERNAME = source.DB_USERNAME)
        WHEN MATCHED THEN
            UPDATE SET
                target.IDENTITY_TYPE = 'STAFF',
                target.STAFF_ID = source.STAFF_ID,
                target.STUDENT_ID = NULL,
                target.ROLE_CODE = source.ROLE_CODE,
                target.UNIT_ID = source.UNIT_ID,
                target.PROGRAM_ID = NULL,
                target.MAJOR_ID = NULL,
                target.CAMPUS_ID = source.CAMPUS_ID
        WHEN NOT MATCHED THEN
            INSERT (
                DB_USERNAME,
                IDENTITY_TYPE,
                STAFF_ID,
                STUDENT_ID,
                ROLE_CODE,
                UNIT_ID,
                PROGRAM_ID,
                MAJOR_ID,
                CAMPUS_ID
            )
            VALUES (
                source.DB_USERNAME,
                'STAFF',
                source.STAFF_ID,
                NULL,
                source.ROLE_CODE,
                source.UNIT_ID,
                NULL,
                NULL,
                source.CAMPUS_ID
            );
    END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_SYNC_STUDENT_IDENTITY
AFTER INSERT OR UPDATE OR DELETE ON STUDENTS
FOR EACH ROW
BEGIN
    IF DELETING OR (
        UPDATING
        AND :OLD.ORACLE_USERNAME <> :NEW.ORACLE_USERNAME
    ) THEN
        DELETE FROM SECURITY_IDENTITIES
        WHERE DB_USERNAME = :OLD.ORACLE_USERNAME;
    END IF;

    IF INSERTING OR UPDATING THEN
        MERGE INTO SECURITY_IDENTITIES target
        USING (
            SELECT
                :NEW.ORACLE_USERNAME AS DB_USERNAME,
                :NEW.STUDENT_ID AS STUDENT_ID,
                :NEW.PROGRAM_ID AS PROGRAM_ID,
                :NEW.MAJOR_ID AS MAJOR_ID,
                :NEW.CAMPUS_ID AS CAMPUS_ID
            FROM DUAL
        ) source
        ON (target.DB_USERNAME = source.DB_USERNAME)
        WHEN MATCHED THEN
            UPDATE SET
                target.IDENTITY_TYPE = 'STUDENT',
                target.STAFF_ID = NULL,
                target.STUDENT_ID = source.STUDENT_ID,
                target.ROLE_CODE = 'STUDENT',
                target.UNIT_ID = NULL,
                target.PROGRAM_ID = source.PROGRAM_ID,
                target.MAJOR_ID = source.MAJOR_ID,
                target.CAMPUS_ID = source.CAMPUS_ID
        WHEN NOT MATCHED THEN
            INSERT (
                DB_USERNAME,
                IDENTITY_TYPE,
                STAFF_ID,
                STUDENT_ID,
                ROLE_CODE,
                UNIT_ID,
                PROGRAM_ID,
                MAJOR_ID,
                CAMPUS_ID
            )
            VALUES (
                source.DB_USERNAME,
                'STUDENT',
                NULL,
                source.STUDENT_ID,
                'STUDENT',
                NULL,
                source.PROGRAM_ID,
                source.MAJOR_ID,
                source.CAMPUS_ID
            );
    END IF;
END;
/

SHOW ERRORS PACKAGE SECURITY_CONTEXT_PKG
SHOW ERRORS PACKAGE BODY SECURITY_CONTEXT_PKG
SHOW ERRORS TRIGGER TRG_SYNC_STAFF_IDENTITY
SHOW ERRORS TRIGGER TRG_SYNC_STUDENT_IDENTITY

GRANT EXECUTE ON SECURITY_CONTEXT_PKG TO RL_BASIC_STAFF;
GRANT EXECUTE ON SECURITY_CONTEXT_PKG TO RL_STUDENT;

DECLARE
    v_error_count  PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_error_count
    FROM USER_ERRORS
    WHERE NAME IN (
        'SECURITY_CONTEXT_PKG',
        'TRG_SYNC_STAFF_IDENTITY',
        'TRG_SYNC_STUDENT_IDENTITY'
    );

    IF v_error_count <> 0 THEN
        RAISE_APPLICATION_ERROR(
            -20301,
            'SECURITY_CONTEXT_PKG compiled with ' ||
            v_error_count || ' error(s).'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Security identity map, package, and sync triggers are valid.'
    );
END;
/

PROMPT Phase 2 - Step 2.3A completed successfully.
