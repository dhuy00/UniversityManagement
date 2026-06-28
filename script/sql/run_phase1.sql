-- Phase 1 master runner
-- Run this file as UNIVERSITY_APP while connected to XEPDB1.
--
-- SQL*Plus / SQLcl:
--   @run_phase1.sql
--
-- Oracle SQL Developer:
--   Open this file and use Run Script (F5), not Run Statement (Ctrl+Enter).
--
-- Prerequisite:
--   1. Run 00_create_app_owner.sql as a security administrator.
--   2. Run 04_test_users.sql as a security administrator.
--   3. Reconnect as UNIVERSITY_APP.

SET ECHO ON
SET SERVEROUTPUT ON
SET DEFINE OFF
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

PROMPT ============================================================
PROMPT Running Phase 1 as UNIVERSITY_APP
PROMPT ============================================================

@@01_schema.sql
@@02_constraints.sql
@@03_indexes.sql
@@04_seed_reference_data.sql
@@05_generate_bulk_data.sql
@@06_verify_phase1.sql

PROMPT ============================================================
PROMPT Phase 1 completed successfully.
PROMPT ============================================================

EXIT SUCCESS
