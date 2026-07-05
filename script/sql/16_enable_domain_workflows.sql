-- Incremental domain-workflow migration for existing installations.
-- Run as UNIVERSITY_APP after the RBAC/VPD scripts.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') <> 'UNIVERSITY_APP' THEN
        RAISE_APPLICATION_ERROR(
            -20600,
            'Run this script as UNIVERSITY_APP.'
        );
    END IF;
END;
/

-- Replace the original fixed-month start-date rule. Academic Affairs controls
-- the real start date, while the year must still match ACADEMIC_YEAR.
DECLARE
    v_constraint_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_constraint_count
    FROM USER_CONSTRAINTS
    WHERE TABLE_NAME = 'COURSE_PLANS'
      AND CONSTRAINT_NAME = 'CK_COURSE_PLANS_START_DATE';

    IF v_constraint_count = 1 THEN
        EXECUTE IMMEDIATE
            'ALTER TABLE COURSE_PLANS ' ||
            'DROP CONSTRAINT CK_COURSE_PLANS_START_DATE';
    END IF;

    EXECUTE IMMEDIATE q'[
        ALTER TABLE COURSE_PLANS
        ADD CONSTRAINT CK_COURSE_PLANS_START_DATE
        CHECK (EXTRACT(YEAR FROM START_DATE) = ACADEMIC_YEAR)
    ]';
END;
/

-- A unit is created first, then the dean can add/reassign staff into it, and
-- Academic Affairs can finally select a head from that same unit.
DECLARE
    v_nullable USER_TAB_COLUMNS.NULLABLE%TYPE;
BEGIN
    SELECT NULLABLE
    INTO v_nullable
    FROM USER_TAB_COLUMNS
    WHERE TABLE_NAME = 'UNITS'
      AND COLUMN_NAME = 'HEAD_STAFF_ID';

    IF v_nullable = 'N' THEN
        EXECUTE IMMEDIATE
            'ALTER TABLE UNITS MODIFY (HEAD_STAFF_ID NULL)';
    ELSE
        DBMS_OUTPUT.PUT_LINE(
            'UNITS.HEAD_STAFF_ID is already nullable; skipping ALTER.'
        );
    END IF;
END;
/

-- Students need the assignment key to create an enrollment. VPD below exposes
-- only assignments for the student's own program.
GRANT SELECT ON TEACHING_ASSIGNMENTS TO RL_STUDENT;

CREATE OR REPLACE PACKAGE ASSIGNMENT_SELECT_POLICY_PKG
AUTHID DEFINER
AS
    FUNCTION SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2;
END ASSIGNMENT_SELECT_POLICY_PKG;
/

CREATE OR REPLACE PACKAGE BODY ASSIGNMENT_SELECT_POLICY_PKG
AS
    FUNCTION QUOTED_VALUE(p_value IN VARCHAR2)
    RETURN VARCHAR2
    IS
    BEGIN
        RETURN DBMS_ASSERT.ENQUOTE_LITERAL(p_value);
    END QUOTED_VALUE;

    FUNCTION STAFF_IDS_IN_UNIT(p_unit_id IN VARCHAR2)
    RETURN VARCHAR2
    IS
        v_predicate VARCHAR2(32767) := 'LECTURER_ID IN (';
        v_separator VARCHAR2(1) := '';
    BEGIN
        IF p_unit_id IS NULL THEN
            RETURN '1=0';
        END IF;

        FOR identity_record IN (
            SELECT STAFF_ID
            FROM SECURITY_IDENTITIES
            WHERE IDENTITY_TYPE = 'STAFF'
              AND UNIT_ID = p_unit_id
              AND STAFF_ID IS NOT NULL
            ORDER BY STAFF_ID
        )
        LOOP
            v_predicate :=
                v_predicate ||
                v_separator ||
                QUOTED_VALUE(identity_record.STAFF_ID);
            v_separator := ',';
        END LOOP;

        IF v_separator IS NULL THEN
            RETURN '1=0';
        END IF;

        RETURN v_predicate || ')';
    END STAFF_IDS_IN_UNIT;

    FUNCTION COURSE_IDS_IN_UNIT(p_unit_id IN VARCHAR2)
    RETURN VARCHAR2
    IS
        v_predicate VARCHAR2(32767) := 'COURSE_ID IN (';
        v_separator VARCHAR2(1) := '';
    BEGIN
        IF p_unit_id IS NULL THEN
            RETURN '1=0';
        END IF;

        FOR course_record IN (
            SELECT COURSE_ID
            FROM COURSES
            WHERE UNIT_ID = p_unit_id
            ORDER BY COURSE_ID
        )
        LOOP
            v_predicate :=
                v_predicate ||
                v_separator ||
                QUOTED_VALUE(course_record.COURSE_ID);
            v_separator := ',';
        END LOOP;

        IF v_separator IS NULL THEN
            RETURN '1=0';
        END IF;

        RETURN v_predicate || ')';
    END COURSE_IDS_IN_UNIT;

    FUNCTION SELECT_PREDICATE(
        p_object_schema IN VARCHAR2,
        p_object_name   IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_role_code  VARCHAR2(30);
        v_staff_id   VARCHAR2(20);
        v_unit_id    VARCHAR2(20);
        v_program_id VARCHAR2(20);
    BEGIN
        IF UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'))
           IN ('UNIVERSITY_APP', 'SYS') THEN
            RETURN '1=1';
        END IF;

        v_role_code := SYS_CONTEXT('UNIVERSITY_CTX', 'ROLE_CODE');
        v_staff_id := SYS_CONTEXT('UNIVERSITY_CTX', 'STAFF_ID');
        v_unit_id := SYS_CONTEXT('UNIVERSITY_CTX', 'UNIT_ID');
        v_program_id := SYS_CONTEXT('UNIVERSITY_CTX', 'PROGRAM_ID');

        IF v_role_code IN ('ACADEMIC_AFFAIRS', 'DEAN') THEN
            RETURN '1=1';
        ELSIF v_role_code = 'UNIT_HEAD' THEN
            RETURN
                '(' ||
                STAFF_IDS_IN_UNIT(v_unit_id) ||
                ' OR ' ||
                COURSE_IDS_IN_UNIT(v_unit_id) ||
                ')';
        ELSIF v_role_code = 'LECTURER' AND v_staff_id IS NOT NULL THEN
            RETURN 'LECTURER_ID = ' || QUOTED_VALUE(v_staff_id);
        ELSIF v_role_code = 'STUDENT' AND v_program_id IS NOT NULL THEN
            RETURN 'PROGRAM_ID = ' || QUOTED_VALUE(v_program_id);
        END IF;

        RETURN '1=0';
    END SELECT_PREDICATE;
END ASSIGNMENT_SELECT_POLICY_PKG;
/

SHOW ERRORS PACKAGE ASSIGNMENT_SELECT_POLICY_PKG
SHOW ERRORS PACKAGE BODY ASSIGNMENT_SELECT_POLICY_PKG

BEGIN
    FOR policy_record IN (
        SELECT POLICY_NAME
        FROM USER_POLICIES
        WHERE OBJECT_NAME = 'TEACHING_ASSIGNMENTS'
          AND POLICY_NAME = 'P2_ASSIGNMENT_SELECT'
    )
    LOOP
        DBMS_RLS.DROP_POLICY(
            object_schema => USER,
            object_name   => 'TEACHING_ASSIGNMENTS',
            policy_name   => policy_record.POLICY_NAME
        );
    END LOOP;

    DBMS_RLS.ADD_POLICY(
        object_schema   => USER,
        object_name     => 'TEACHING_ASSIGNMENTS',
        policy_name     => 'P2_ASSIGNMENT_SELECT',
        function_schema => USER,
        policy_function =>
            'ASSIGNMENT_SELECT_POLICY_PKG.SELECT_PREDICATE',
        statement_types => 'SELECT',
        policy_type     => DBMS_RLS.DYNAMIC
    );
END;
/

DECLARE
    v_error_count  PLS_INTEGER;
    v_policy_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_error_count
    FROM USER_ERRORS
    WHERE NAME = 'ASSIGNMENT_SELECT_POLICY_PKG';

    SELECT COUNT(*)
    INTO v_policy_count
    FROM USER_POLICIES
    WHERE OBJECT_NAME = 'TEACHING_ASSIGNMENTS'
      AND POLICY_NAME = 'P2_ASSIGNMENT_SELECT'
      AND ENABLE = 'YES';

    IF v_error_count <> 0 OR v_policy_count <> 1 THEN
        RAISE_APPLICATION_ERROR(
            -20601,
            'Domain workflow migration verification failed.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Verified nullable unit heads and student assignment visibility.'
    );
END;
/

COMMIT;

PROMPT Domain workflow migration completed successfully.
