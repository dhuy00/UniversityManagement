-- Runner 1/3: SYS bootstrap
-- Connect as SYS with SYSDBA directly to XEPDB1, then run with F5.
--
-- Outputs:
--   - a generated UNIVERSITY_APP password
--   - the fixed local-demo password shared by the 15 bootstrap users
--
-- Save the generated UNIVERSITY_APP password from Script Output.

SET ECHO ON
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT ============================================================
PROMPT RUNNER 1/3 - SYS BOOTSTRAP
PROMPT Required connection: SYS AS SYSDBA @ XEPDB1
PROMPT ============================================================

@@../00_create_app_owner.sql
@@../04_test_users.sql
@@../10_create_security_roles.sql

-- Needed by UNIVERSITY_APP when Runner 2 installs VPD policies.
GRANT EXECUTE ON SYS.DBMS_RLS TO UNIVERSITY_APP;

PROMPT ============================================================
PROMPT SYS bootstrap completed.
PROMPT Save the generated UNIVERSITY_APP password.
PROMPT Bootstrap demo-user password: 123
PROMPT Next: reconnect as UNIVERSITY_APP and run 02_app_install.sql.
PROMPT ============================================================

EXIT SUCCESS
