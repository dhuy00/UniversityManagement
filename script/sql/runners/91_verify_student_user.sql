-- Verification runner for the currently connected CS#6 demo user.
-- Supported connections:
--   STUDENT01, STUDENT02

SET ECHO ON
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

@@../12c_verify_security_context.sql
@@../23_verify_cs6.sql

EXIT SUCCESS
