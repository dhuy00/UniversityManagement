-- Verification runner for the currently connected CS#1-CS#5 demo user.
-- Supported connections:
--   BASIC01, LECTURER01, AFFAIRS01, HEAD_IS01, DEAN01

SET ECHO ON
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

@@../12c_verify_security_context.sql
@@../15_verify_cs1_cs5.sql

EXIT SUCCESS
