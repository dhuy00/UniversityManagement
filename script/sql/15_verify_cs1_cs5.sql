-- Phase 2 - Step 2.6: Effective-access verification for CS#1-CS#5
-- Target database: Oracle Database 21c / XEPDB1
--
-- Run this script separately after reconnecting as:
--   BASIC01, LECTURER01, AFFAIRS01, HEAD_IS01, and DEAN01.
--
-- Every DML test uses SAVEPOINT/ROLLBACK and leaves application data unchanged.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    UNIVERSITY_APP.SECURITY_CONTEXT_PKG.INITIALIZE_SESSION;
END;
/

DECLARE
    v_role_code    VARCHAR2(30);
    v_staff_id     VARCHAR2(20);
    v_session_user VARCHAR2(128);
    v_failures     PLS_INTEGER := 0;

    PROCEDURE pass(p_label IN VARCHAR2)
    IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('[PASS] ' || p_label);
    END pass;

    PROCEDURE fail(
        p_label   IN VARCHAR2,
        p_detail  IN VARCHAR2
    )
    IS
    BEGIN
        v_failures := v_failures + 1;
        DBMS_OUTPUT.PUT_LINE(
            '[FAIL] ' || p_label || ' - ' || p_detail
        );
    END fail;

    PROCEDURE assert_query_count(
        p_label     IN VARCHAR2,
        p_sql       IN VARCHAR2,
        p_expected  IN PLS_INTEGER
    )
    IS
        v_actual PLS_INTEGER;
    BEGIN
        BEGIN
            EXECUTE IMMEDIATE p_sql INTO v_actual;

            IF v_actual = p_expected THEN
                pass(
                    p_label || ' (rows=' || v_actual || ')'
                );
            ELSE
                fail(
                    p_label,
                    'expected rows=' || p_expected ||
                    ', actual rows=' || v_actual
                );
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                fail(
                    p_label,
                    'unexpected ORA error ' || SQLCODE || ': ' || SQLERRM
                );
        END;
    END assert_query_count;

    PROCEDURE assert_query_denied(
        p_label  IN VARCHAR2,
        p_sql    IN VARCHAR2
    )
    IS
        v_actual       PLS_INTEGER;
        v_error_code   PLS_INTEGER := 0;
        v_error_text   VARCHAR2(4000);
    BEGIN
        BEGIN
            EXECUTE IMMEDIATE p_sql INTO v_actual;
        EXCEPTION
            WHEN OTHERS THEN
                v_error_code := SQLCODE;
                v_error_text := SQLERRM;
        END;

        IF v_error_code IN (-942, -1031) THEN
            pass(
                p_label || ' (denied with ORA' || v_error_code || ')'
            );
        ELSIF v_error_code = 0 THEN
            fail(
                p_label,
                'query unexpectedly succeeded with rows=' || v_actual
            );
        ELSE
            fail(
                p_label,
                'unexpected ORA error ' || v_error_code ||
                ': ' || v_error_text
            );
        END IF;
    END assert_query_denied;

    PROCEDURE assert_dml_rows(
        p_label     IN VARCHAR2,
        p_sql       IN VARCHAR2,
        p_expected  IN PLS_INTEGER
    )
    IS
        v_actual      PLS_INTEGER;
        v_error_code  PLS_INTEGER := 0;
        v_error_text  VARCHAR2(4000);
    BEGIN
        SAVEPOINT phase2_test_case;

        BEGIN
            EXECUTE IMMEDIATE p_sql;
            v_actual := SQL%ROWCOUNT;
        EXCEPTION
            WHEN OTHERS THEN
                v_error_code := SQLCODE;
                v_error_text := SQLERRM;
        END;

        ROLLBACK TO phase2_test_case;

        IF v_error_code <> 0 THEN
            fail(
                p_label,
                'unexpected ORA error ' || v_error_code ||
                ': ' || v_error_text
            );
        ELSIF v_actual = p_expected THEN
            pass(
                p_label || ' (affected=' || v_actual || ')'
            );
        ELSE
            fail(
                p_label,
                'expected affected=' || p_expected ||
                ', actual affected=' || v_actual
            );
        END IF;
    END assert_dml_rows;

    PROCEDURE assert_dml_denied(
        p_label          IN VARCHAR2,
        p_sql            IN VARCHAR2,
        p_allowed_code_1 IN PLS_INTEGER,
        p_allowed_code_2 IN PLS_INTEGER DEFAULT NULL,
        p_allowed_code_3 IN PLS_INTEGER DEFAULT NULL
    )
    IS
        v_rows         PLS_INTEGER;
        v_error_code   PLS_INTEGER := 0;
        v_error_text   VARCHAR2(4000);
    BEGIN
        SAVEPOINT phase2_test_case;

        BEGIN
            EXECUTE IMMEDIATE p_sql;
            v_rows := SQL%ROWCOUNT;
        EXCEPTION
            WHEN OTHERS THEN
                v_error_code := SQLCODE;
                v_error_text := SQLERRM;
        END;

        ROLLBACK TO phase2_test_case;

        IF v_error_code = p_allowed_code_1
           OR v_error_code = p_allowed_code_2
           OR v_error_code = p_allowed_code_3 THEN
            pass(
                p_label || ' (denied with ORA' || v_error_code || ')'
            );
        ELSIF v_error_code = 0 THEN
            fail(
                p_label,
                'statement unexpectedly succeeded; affected=' || v_rows
            );
        ELSE
            fail(
                p_label,
                'unexpected ORA error ' || v_error_code ||
                ': ' || v_error_text
            );
        END IF;
    END assert_dml_denied;

    FUNCTION quoted(p_value IN VARCHAR2)
    RETURN VARCHAR2
    IS
    BEGIN
        RETURN DBMS_ASSERT.ENQUOTE_LITERAL(p_value);
    END quoted;
BEGIN
    v_session_user :=
        UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'));
    v_role_code :=
        SYS_CONTEXT('UNIVERSITY_CTX', 'ROLE_CODE');
    v_staff_id :=
        SYS_CONTEXT('UNIVERSITY_CTX', 'STAFF_ID');

    DBMS_OUTPUT.PUT_LINE(
        '============================================================'
    );
    DBMS_OUTPUT.PUT_LINE(
        'Testing user=' || v_session_user ||
        ', role=' || NVL(v_role_code, '<NULL>') ||
        ', staff_id=' || NVL(v_staff_id, '<NULL>')
    );
    DBMS_OUTPUT.PUT_LINE(
        '============================================================'
    );

    IF v_role_code NOT IN (
        'BASIC_STAFF',
        'LECTURER',
        'ACADEMIC_AFFAIRS',
        'UNIT_HEAD',
        'DEAN'
    ) THEN
        RAISE_APPLICATION_ERROR(
            -20600,
            'Run this script as a CS#1-CS#5 demo staff user.'
        );
    END IF;

    -- CS#1 checks inherited by every staff role.
    IF v_role_code = 'DEAN' THEN
        assert_query_count(
            'Dean can read all STAFF rows',
            'SELECT COUNT(*) FROM UNIVERSITY_APP.STAFF',
            107
        );
    ELSE
        assert_query_count(
            'Staff user sees only own STAFF row',
            'SELECT COUNT(*) FROM UNIVERSITY_APP.STAFF',
            1
        );
    END IF;

    assert_query_count(
        'Staff role can read all STUDENTS',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.STUDENTS',
        4000
    );
    assert_query_count(
        'Staff role can read all UNITS',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.UNITS',
        7
    );
    assert_query_count(
        'Staff role can read all COURSES',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.COURSES',
        7
    );
    assert_query_count(
        'Staff role can read all COURSE_PLANS',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.COURSE_PLANS',
        10
    );

    assert_dml_rows(
        'Staff role can update own PHONE',
        'UPDATE UNIVERSITY_APP.STAFF SET PHONE = PHONE ' ||
        'WHERE STAFF_ID = ' || quoted(v_staff_id),
        1
    );

    IF v_role_code = 'DEAN' THEN
        assert_dml_rows(
            'Dean can update another staff PHONE',
            'UPDATE UNIVERSITY_APP.STAFF SET PHONE = PHONE ' ||
            'WHERE STAFF_ID = ''S0008''',
            1
        );
        assert_dml_rows(
            'Dean can update staff ALLOWANCE',
            'UPDATE UNIVERSITY_APP.STAFF SET ALLOWANCE = ALLOWANCE ' ||
            'WHERE STAFF_ID = ''S0008''',
            1
        );
    ELSE
        assert_dml_rows(
            'Non-dean cannot update another staff row',
            'UPDATE UNIVERSITY_APP.STAFF SET PHONE = PHONE ' ||
            'WHERE STAFF_ID = ' ||
            CASE
                WHEN v_staff_id = 'S0008' THEN '''S0009'''
                ELSE '''S0008'''
            END,
            0
        );
        assert_dml_denied(
            'Non-dean cannot update ALLOWANCE',
            'UPDATE UNIVERSITY_APP.STAFF SET ALLOWANCE = ALLOWANCE ' ||
            'WHERE STAFF_ID = ' || quoted(v_staff_id),
            -1031,
            -942
        );
    END IF;

    CASE v_role_code
        WHEN 'BASIC_STAFF' THEN
            assert_query_denied(
                'Basic staff cannot read assignments',
                'SELECT COUNT(*) FROM UNIVERSITY_APP.TEACHING_ASSIGNMENTS'
            );
            assert_query_denied(
                'Basic staff cannot read enrollments',
                'SELECT COUNT(*) FROM UNIVERSITY_APP.ENROLLMENTS'
            );

        WHEN 'LECTURER' THEN
            assert_query_count(
                'Lecturer sees only own assignments',
                'SELECT COUNT(*) ' ||
                'FROM UNIVERSITY_APP.TEACHING_ASSIGNMENTS',
                2
            );
            assert_query_count(
                'Lecturer sees only own class enrollments',
                'SELECT COUNT(*) FROM UNIVERSITY_APP.ENROLLMENTS',
                2
            );
            assert_dml_rows(
                'Lecturer can update scores in own classes',
                'UPDATE UNIVERSITY_APP.ENROLLMENTS ' ||
                'SET PRACTICE_SCORE = PRACTICE_SCORE ' ||
                'WHERE LECTURER_ID = ' || quoted(v_staff_id),
                2
            );
            assert_dml_rows(
                'Lecturer cannot update another lecturer class',
                'UPDATE UNIVERSITY_APP.ENROLLMENTS ' ||
                'SET PRACTICE_SCORE = PRACTICE_SCORE ' ||
                'WHERE LECTURER_ID <> ' || quoted(v_staff_id),
                0
            );
            assert_dml_denied(
                'Lecturer cannot update enrollment keys',
                'UPDATE UNIVERSITY_APP.ENROLLMENTS ' ||
                'SET COURSE_ID = COURSE_ID ' ||
                'WHERE LECTURER_ID = ' || quoted(v_staff_id),
                -1031,
                -942
            );

        WHEN 'ACADEMIC_AFFAIRS' THEN
            assert_query_count(
                'Academic affairs can read all assignments',
                'SELECT COUNT(*) ' ||
                'FROM UNIVERSITY_APP.TEACHING_ASSIGNMENTS',
                10
            );
            assert_query_denied(
                'Academic affairs has no enrollment SELECT grant',
                'SELECT COUNT(*) FROM UNIVERSITY_APP.ENROLLMENTS'
            );
            assert_dml_rows(
                'Academic affairs can update office assignments',
                'UPDATE UNIVERSITY_APP.TEACHING_ASSIGNMENTS ' ||
                'SET LECTURER_ID = LECTURER_ID ' ||
                'WHERE COURSE_ID = ''GEN101''',
                1
            );
            assert_dml_rows(
                'Academic affairs cannot update non-office assignments',
                'UPDATE UNIVERSITY_APP.TEACHING_ASSIGNMENTS ' ||
                'SET LECTURER_ID = LECTURER_ID ' ||
                'WHERE COURSE_ID = ''IS101''',
                0
            );
            assert_dml_rows(
                'Academic affairs can update STUDENTS',
                'UPDATE UNIVERSITY_APP.STUDENTS SET PHONE = PHONE ' ||
                'WHERE STUDENT_ID = ''ST0001''',
                1
            );
            assert_dml_denied(
                'Academic affairs cannot delete STUDENTS',
                'DELETE FROM UNIVERSITY_APP.STUDENTS ' ||
                'WHERE STUDENT_ID = ''ST4000''',
                -1031,
                -942
            );
            assert_dml_denied(
                'Closed registration window rejects enrollment insert',
                'INSERT INTO UNIVERSITY_APP.ENROLLMENTS (' ||
                'STUDENT_ID, LECTURER_ID, COURSE_ID, SEMESTER, ' ||
                'ACADEMIC_YEAR, PROGRAM_ID) VALUES (' ||
                '''ST0005'', ''S0010'', ''IS101'', 3, 2026, ''REGULAR'')',
                -20506,
                -28115
            );

        WHEN 'UNIT_HEAD' THEN
            assert_query_count(
                'IS head sees assignments of IS staff',
                'SELECT COUNT(*) ' ||
                'FROM UNIVERSITY_APP.TEACHING_ASSIGNMENTS',
                3
            );
            assert_query_count(
                'IS head sees own class enrollments only',
                'SELECT COUNT(*) FROM UNIVERSITY_APP.ENROLLMENTS',
                0
            );
            assert_dml_rows(
                'IS head can update IS course assignments',
                'UPDATE UNIVERSITY_APP.TEACHING_ASSIGNMENTS ' ||
                'SET LECTURER_ID = LECTURER_ID ' ||
                'WHERE COURSE_ID = ''IS101''',
                3
            );
            assert_dml_rows(
                'IS head cannot update another unit assignments',
                'UPDATE UNIVERSITY_APP.TEACHING_ASSIGNMENTS ' ||
                'SET LECTURER_ID = LECTURER_ID ' ||
                'WHERE COURSE_ID = ''CS101''',
                0
            );

        WHEN 'DEAN' THEN
            assert_query_count(
                'Dean can read all assignments',
                'SELECT COUNT(*) ' ||
                'FROM UNIVERSITY_APP.TEACHING_ASSIGNMENTS',
                10
            );
            assert_query_count(
                'Dean can read all enrollments',
                'SELECT COUNT(*) FROM UNIVERSITY_APP.ENROLLMENTS',
                4
            );
            assert_dml_rows(
                'Dean can update office assignments',
                'UPDATE UNIVERSITY_APP.TEACHING_ASSIGNMENTS ' ||
                'SET LECTURER_ID = LECTURER_ID ' ||
                'WHERE COURSE_ID = ''GEN101''',
                1
            );
            assert_dml_rows(
                'Dean cannot update non-office assignments',
                'UPDATE UNIVERSITY_APP.TEACHING_ASSIGNMENTS ' ||
                'SET LECTURER_ID = LECTURER_ID ' ||
                'WHERE COURSE_ID = ''CS101''',
                0
            );
    END CASE;

    ROLLBACK;

    DBMS_OUTPUT.PUT_LINE(
        '------------------------------------------------------------'
    );

    IF v_failures > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20601,
            'CS#1-CS#5 verification failed for ' ||
            v_session_user || ': ' || v_failures || ' test(s).'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        '[PASS] All checks completed for ' ||
        v_session_user || ' (' || v_role_code || ').'
    );
END;
/

PROMPT Phase 2 - Step 2.6 completed successfully for the current user.
