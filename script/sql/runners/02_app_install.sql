-- Runner 2/3: Complete application schema and data-security installation
-- Connect as UNIVERSITY_APP to XEPDB1, then run with F5.
--
-- WARNING: 01_schema.sql drops and recreates all application tables.

SET ECHO ON
SET SERVEROUTPUT ON
SET DEFINE OFF
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT ============================================================
PROMPT RUNNER 2/3 - APPLICATION INSTALL
PROMPT Required connection: UNIVERSITY_APP @ XEPDB1
PROMPT ============================================================

PROMPT --- Phase 1: schema and data
@@../01_schema.sql
@@../02_constraints.sql
@@../03_indexes.sql
@@../04_seed_reference_data.sql
@@../05_generate_bulk_data.sql
@@../06_verify_phase1.sql

PROMPT --- Phase 2: RBAC and CS#1-CS#5
@@../11_grant_object_privileges.sql
@@../12a_security_context_package.sql
@@../13_vpd_policies_cs1_cs5.sql
@@../14_business_rule_guards.sql

PROMPT --- Phase 3: CS#6
@@../20_grant_student_privileges.sql
@@../21_vpd_students_course_plans.sql
@@../22_vpd_student_enrollments.sql

PROMPT ============================================================
PROMPT Application installation completed.
PROMPT Next: reconnect as SYS and run 03_sys_finalize.sql.
PROMPT ============================================================

EXIT SUCCESS
