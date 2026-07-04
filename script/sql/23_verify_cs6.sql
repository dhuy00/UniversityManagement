-- Phase 3 - Step 3.4: Effective-access verification for CS#6
-- Target database: Oracle Database 21c / XEPDB1
--
-- Run this script separately after reconnecting as STUDENT01 and STUDENT02.
-- Every DML test uses SAVEPOINT/ROLLBACK and leaves data unchanged.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

BEGIN
    UNIVERSITY_APP.SECURITY_CONTEXT_PKG.INITIALIZE_SESSION;
END;
/

DECLARE
    v_session_user  VARCHAR2(128);
    v_role_code     VARCHAR2(30);
    v_student_id    VARCHAR2(20);
    v_program_id    VARCHAR2(20);
    v_other_id      VARCHAR2(20);
    v_failures      PLS_INTEGER := 0;

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

    FUNCTION quoted(p_value IN VARCHAR2)
    RETURN VARCHAR2
    IS
    BEGIN
        RETURN DBMS_ASSERT.ENQUOTE_LITERAL(p_value);
    END quoted;

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
                pass(p_label || ' (rows=' || v_actual || ')');
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
        v_actual      PLS_INTEGER;
        v_error_code  PLS_INTEGER := 0;
        v_error_text  VARCHAR2(4000);
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
        SAVEPOINT cs6_test_case;

        BEGIN
            EXECUTE IMMEDIATE p_sql;
            v_actual := SQL%ROWCOUNT;
        EXCEPTION
            WHEN OTHERS THEN
                v_error_code := SQLCODE;
                v_error_text := SQLERRM;
        END;

        ROLLBACK TO cs6_test_case;

        IF v_error_code <> 0 THEN
            fail(
                p_label,
                'unexpected ORA error ' || v_error_code ||
                ': ' || v_error_text
            );
        ELSIF v_actual = p_expected THEN
            pass(p_label || ' (affected=' || v_actual || ')');
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
        p_allowed_code_3 IN PLS_INTEGER DEFAULT NULL,
        p_allowed_code_4 IN PLS_INTEGER DEFAULT NULL
    )
    IS
        v_rows         PLS_INTEGER;
        v_error_code   PLS_INTEGER := 0;
        v_error_text   VARCHAR2(4000);
    BEGIN
        SAVEPOINT cs6_test_case;

        BEGIN
            EXECUTE IMMEDIATE p_sql;
            v_rows := SQL%ROWCOUNT;
        EXCEPTION
            WHEN OTHERS THEN
                v_error_code := SQLCODE;
                v_error_text := SQLERRM;
        END;

        ROLLBACK TO cs6_test_case;

        IF v_error_code = p_allowed_code_1
           OR v_error_code = p_allowed_code_2
           OR v_error_code = p_allowed_code_3
           OR v_error_code = p_allowed_code_4 THEN
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
BEGIN
    v_session_user :=
        UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER'));
    v_role_code :=
        SYS_CONTEXT('UNIVERSITY_CTX', 'ROLE_CODE');
    v_student_id :=
        SYS_CONTEXT('UNIVERSITY_CTX', 'STUDENT_ID');
    v_program_id :=
        SYS_CONTEXT('UNIVERSITY_CTX', 'PROGRAM_ID');

    IF v_student_id = 'ST0001' THEN
        v_other_id := 'ST0002';
    ELSE
        v_other_id := 'ST0001';
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        '============================================================'
    );
    DBMS_OUTPUT.PUT_LINE(
        'Testing user=' || v_session_user ||
        ', student_id=' || NVL(v_student_id, '<NULL>') ||
        ', program_id=' || NVL(v_program_id, '<NULL>')
    );
    DBMS_OUTPUT.PUT_LINE(
        '============================================================'
    );

    IF v_role_code <> 'STUDENT'
       OR v_student_id IS NULL
       OR v_program_id IS NULL THEN
        RAISE_APPLICATION_ERROR(
            -20990,
            'Run this script as a recognized demo student.'
        );
    END IF;

    -- Row-level visibility
    assert_query_count(
        'Student sees exactly one STUDENTS row',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.STUDENTS',
        1
    );
    assert_query_count(
        'Visible STUDENTS row belongs to current student',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.STUDENTS ' ||
        'WHERE STUDENT_ID = ' || quoted(v_student_id),
        1
    );
    assert_query_count(
        'Other student row is hidden',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.STUDENTS ' ||
        'WHERE STUDENT_ID = ' || quoted(v_other_id),
        0
    );

    assert_query_count(
        'Student can read all COURSES',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.COURSES',
        7
    );
    assert_query_count(
        'Student sees only own-program COURSE_PLANS',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.COURSE_PLANS ' ||
        'WHERE PROGRAM_ID <> ' || quoted(v_program_id),
        0
    );
    assert_query_count(
        'REGULAR demo student sees expected COURSE_PLANS',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.COURSE_PLANS',
        9
    );

    assert_query_count(
        'Student sees exactly own ENROLLMENTS',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.ENROLLMENTS',
        2
    );
    assert_query_count(
        'Other student ENROLLMENTS are hidden',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.ENROLLMENTS ' ||
        'WHERE STUDENT_ID = ' || quoted(v_other_id),
        0
    );
    assert_query_count(
        'Student can read score values on own rows',
        'SELECT COUNT(PRACTICE_SCORE) ' ||
        'FROM UNIVERSITY_APP.ENROLLMENTS',
        1
    );

    -- Unauthorized application objects
    assert_query_denied(
        'Student cannot read STAFF',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.STAFF'
    );
    assert_query_denied(
        'Student cannot read TEACHING_ASSIGNMENTS',
        'SELECT COUNT(*) FROM UNIVERSITY_APP.TEACHING_ASSIGNMENTS'
    );

    -- Allowed and denied profile updates
    assert_dml_rows(
        'Student can update own ADDRESS',
        'UPDATE UNIVERSITY_APP.STUDENTS SET ADDRESS = ADDRESS ' ||
        'WHERE STUDENT_ID = ' || quoted(v_student_id),
        1
    );
    assert_dml_rows(
        'Student can update own PHONE',
        'UPDATE UNIVERSITY_APP.STUDENTS SET PHONE = PHONE ' ||
        'WHERE STUDENT_ID = ' || quoted(v_student_id),
        1
    );
    assert_dml_rows(
        'Student cannot update another student row',
        'UPDATE UNIVERSITY_APP.STUDENTS SET PHONE = PHONE ' ||
        'WHERE STUDENT_ID = ' || quoted(v_other_id),
        0
    );
    assert_dml_denied(
        'Student cannot update CUMULATIVE_GPA',
        'UPDATE UNIVERSITY_APP.STUDENTS ' ||
        'SET CUMULATIVE_GPA = CUMULATIVE_GPA ' ||
        'WHERE STUDENT_ID = ' || quoted(v_student_id),
        -1031,
        -942
    );

    -- Enrollment mutation restrictions
    assert_dml_denied(
        'Student cannot update enrollment scores',
        'UPDATE UNIVERSITY_APP.ENROLLMENTS ' ||
        'SET PRACTICE_SCORE = PRACTICE_SCORE',
        -1031,
        -942
    );
    assert_dml_denied(
        'Student cannot insert score values',
        'INSERT INTO UNIVERSITY_APP.ENROLLMENTS (' ||
        'STUDENT_ID, LECTURER_ID, COURSE_ID, SEMESTER, ACADEMIC_YEAR, ' ||
        'PROGRAM_ID, PRACTICE_SCORE) VALUES (' ||
        quoted(v_student_id) ||
        ', ''S0010'', ''IS101'', 3, 2026, ''REGULAR'', 10)',
        -1031,
        -942,
        -28115,
        -20506
    );
    assert_dml_denied(
        'Student cannot register for another student',
        'INSERT INTO UNIVERSITY_APP.ENROLLMENTS (' ||
        'STUDENT_ID, LECTURER_ID, COURSE_ID, SEMESTER, ACADEMIC_YEAR, ' ||
        'PROGRAM_ID) VALUES (' ||
        quoted(v_other_id) ||
        ', ''S0010'', ''IS101'', 3, 2026, ''REGULAR'')',
        -28115,
        -20506
    );

    -- Semester 2 of 2026 started on 2026-05-01, so its adjustment window is
    -- closed for the current project test date.
    assert_dml_rows(
        'Closed window prevents deleting own enrollment',
        'DELETE FROM UNIVERSITY_APP.ENROLLMENTS ' ||
        'WHERE STUDENT_ID = ' || quoted(v_student_id) ||
        ' AND SEMESTER = 2 AND ACADEMIC_YEAR = 2026',
        0
    );
    assert_dml_rows(
        'Student cannot delete another student enrollment',
        'DELETE FROM UNIVERSITY_APP.ENROLLMENTS ' ||
        'WHERE STUDENT_ID = ' || quoted(v_other_id),
        0
    );

    ROLLBACK;

    DBMS_OUTPUT.PUT_LINE(
        '------------------------------------------------------------'
    );

    IF v_failures > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20991,
            'CS#6 verification failed for ' ||
            v_session_user || ': ' || v_failures || ' test(s).'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        '[PASS] All CS#6 checks completed for ' || v_session_user || '.'
    );
END;
/

PROMPT Phase 3 - Step 3.4 completed successfully for the current student.
