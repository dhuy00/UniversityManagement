-- Non-persistent verification for 02_security_context.sql.

BEGIN;
SET search_path TO university, public;

DO $$
DECLARE
    staff_user_id   bigint;
    student_user_id bigint;
    inactive_id     bigint;
BEGIN
    INSERT INTO units (unit_id, unit_name)
    VALUES ('VERIFY_UNIT', 'Security context verification unit');

    INSERT INTO app_users (username, password_hash)
    VALUES ('VERIFY_LECTURER', 'test-only')
    RETURNING user_id INTO staff_user_id;

    INSERT INTO staff (
        staff_id, user_id, full_name, gender, date_of_birth, allowance,
        phone, unit_id, campus_id
    ) VALUES (
        'VERIFY_STAFF', staff_user_id, 'Verify Lecturer', 'OTHER',
        DATE '1990-01-01', 0, NULL, 'VERIFY_UNIT', 'CAMPUS_1'
    );
    INSERT INTO app_user_roles (user_id, role_code)
    VALUES (staff_user_id, 'LECTURER');

    PERFORM set_security_context(staff_user_id);
    ASSERT current_app_user_id() = staff_user_id,
        'Staff application user ID was not initialized';
    ASSERT current_app_username() = 'VERIFY_LECTURER',
        'Staff username was not resolved';
    ASSERT current_staff_id() = 'VERIFY_STAFF',
        'Staff ID was not resolved';
    ASSERT current_unit_id() = 'VERIFY_UNIT',
        'Staff unit was not resolved';
    ASSERT current_campus_id() = 'CAMPUS_1',
        'Staff campus was not resolved';
    ASSERT current_student_id() IS NULL,
        'Staff unexpectedly resolved a student ID';
    ASSERT has_role('LECTURER'), 'Lecturer role was not resolved';
    ASSERT has_permission('GRADE_UPDATE_ASSIGNED'),
        'Lecturer permission was not resolved';
    ASSERT NOT has_permission('STAFF_MANAGE_ALL'),
        'Lecturer unexpectedly received dean permission';

    INSERT INTO app_users (username, password_hash)
    VALUES ('VERIFY_STUDENT', 'test-only')
    RETURNING user_id INTO student_user_id;

    INSERT INTO students (
        student_id, user_id, full_name, gender, date_of_birth, address,
        phone, program_id, major_id, campus_id
    ) VALUES (
        'VERIFY_STUDENT', student_user_id, 'Verify Student', 'OTHER',
        DATE '2000-01-01', NULL, NULL, 'REGULAR', 'IS', 'CAMPUS_2'
    );
    INSERT INTO app_user_roles (user_id, role_code)
    VALUES (student_user_id, 'STUDENT');

    PERFORM set_security_context(student_user_id);
    ASSERT current_student_id() = 'VERIFY_STUDENT',
        'Student ID was not resolved';
    ASSERT current_program_id() = 'REGULAR',
        'Student program was not resolved';
    ASSERT current_major_id() = 'IS',
        'Student major was not resolved';
    ASSERT current_campus_id() = 'CAMPUS_2',
        'Student campus was not resolved';
    ASSERT current_staff_id() IS NULL,
        'Student unexpectedly resolved a staff ID';
    ASSERT has_role('STUDENT'), 'Student role was not resolved';
    ASSERT has_permission('ENROLLMENT_CREATE_DELETE_SELF'),
        'Student permission was not resolved';
    ASSERT NOT has_permission('GRADE_UPDATE_ASSIGNED'),
        'Student unexpectedly received grade-update permission';

    PERFORM clear_security_context();
    ASSERT current_app_user_id() IS NULL,
        'Security context was not cleared';
    ASSERT NOT has_role('STUDENT'),
        'Cleared context unexpectedly retained a role';

    INSERT INTO app_users (username, password_hash, is_active)
    VALUES ('VERIFY_INACTIVE', 'test-only', false)
    RETURNING user_id INTO inactive_id;

    BEGIN
        PERFORM set_security_context(inactive_id);
        RAISE EXCEPTION 'Inactive user was accepted by set_security_context';
    EXCEPTION
        WHEN invalid_authorization_specification THEN NULL;
    END;
END;
$$;

SELECT 'security context verification passed' AS result;
ROLLBACK;
