-- Runner 3/3: Finalize secure context initialization
-- Connect as SYS with SYSDBA directly to XEPDB1, then run with F5.
--
-- Runner 2 must complete first because the data-user rows and trusted context
-- package must exist before accounts are provisioned and the logon trigger is
-- compiled.

SET ECHO ON
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT ============================================================
PROMPT RUNNER 3/3 - SYS FINALIZE
PROMPT Required connection: SYS AS SYSDBA @ XEPDB1
PROMPT ============================================================

PROMPT --- Provision all STAFF and STUDENTS Oracle accounts
@@../12d_provision_all_data_users.sql

PROMPT --- Enable secure application-context initialization
@@../12b_create_context_and_logon_trigger.sql

PROMPT ============================================================
PROMPT Installation completed.
PROMPT All data-user accounts use password 123 for this local demo.
PROMPT Reconnect data users before running verification scripts.
PROMPT ============================================================

EXIT SUCCESS
