-- Runner 3/3: Finalize secure context initialization
-- Connect as SYS with SYSDBA directly to XEPDB1, then run with F5.
--
-- Runner 2 must complete first because the trusted context package must exist
-- before the database logon trigger is compiled.

SET ECHO ON
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT ============================================================
PROMPT RUNNER 3/3 - SYS FINALIZE
PROMPT Required connection: SYS AS SYSDBA @ XEPDB1
PROMPT ============================================================

@@../12b_create_context_and_logon_trigger.sql

PROMPT ============================================================
PROMPT Installation completed.
PROMPT Reconnect demo users before running verification scripts.
PROMPT ============================================================

EXIT SUCCESS
