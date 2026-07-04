-- Phase 4 - Step 4.1B: Register and enable Oracle Label Security
-- Target database: Oracle Database 21c / XEPDB1
-- Run as SYS with SYSDBA while connected directly to XEPDB1.
--
-- WARNING:
--   LBACSYS.CONFIGURE_OLS commits pending transactions and cannot be rolled
--   back. After this script, close and reopen XEPDB1 from CDB$ROOT.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

DECLARE
    v_container_name    VARCHAR2(128);
    v_option_value      VARCHAR2(10);
    v_configure_status  VARCHAR2(10);
    v_enable_status     VARCHAR2(10);
    v_status_row_count  PLS_INTEGER;
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
    INTO v_container_name
    FROM DUAL;

    IF v_container_name = 'CDB$ROOT' THEN
        RAISE_APPLICATION_ERROR(
            -20960,
            'Connect directly to XEPDB1 before configuring OLS.'
        );
    END IF;

    SELECT VALUE
    INTO v_option_value
    FROM V$OPTION
    WHERE PARAMETER = 'Oracle Label Security';

    IF v_option_value <> 'TRUE' THEN
        RAISE_APPLICATION_ERROR(
            -20961,
            'Cannot configure OLS because V$OPTION reports OLS=FALSE.'
        );
    END IF;

    BEGIN
        EXECUTE IMMEDIATE q'[
            SELECT
                COUNT(*),
                MAX(CASE
                    WHEN NAME = 'OLS_CONFIGURE_STATUS' THEN STATUS
                END),
                MAX(CASE
                    WHEN NAME = 'OLS_ENABLE_STATUS' THEN STATUS
                END)
            FROM DBA_OLS_STATUS
        ]'
        INTO
            v_status_row_count,
            v_configure_status,
            v_enable_status;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -942 THEN
                RAISE_APPLICATION_ERROR(
                    -20962,
                    'DBA_OLS_STATUS is missing; this image cannot configure OLS.'
                );
            ELSE
                RAISE;
            END IF;
    END;

    IF v_status_row_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20963,
            'No OLS status rows are available in XEPDB1.'
        );
    END IF;

    IF NVL(v_configure_status, 'FALSE') <> 'TRUE' THEN
        DBMS_OUTPUT.PUT_LINE('Registering Oracle Label Security...');
        LBACSYS.CONFIGURE_OLS;
    ELSE
        DBMS_OUTPUT.PUT_LINE('OLS is already configured.');
    END IF;

    IF NVL(v_enable_status, 'FALSE') <> 'TRUE' THEN
        DBMS_OUTPUT.PUT_LINE('Enabling Oracle Label Security...');
        LBACSYS.OLS_ENFORCEMENT.ENABLE_OLS;
    ELSE
        DBMS_OUTPUT.PUT_LINE('OLS is already enabled.');
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'OLS configuration request completed in ' || v_container_name || '.'
    );
    DBMS_OUTPUT.PUT_LINE(
        'Next: connect to CDB$ROOT and close/open XEPDB1.'
    );
END;
/

PROMPT Run the following from CDB$ROOT as SYSDBA:
PROMPT ALTER PLUGGABLE DATABASE XEPDB1 CLOSE IMMEDIATE;
PROMPT ALTER PLUGGABLE DATABASE XEPDB1 OPEN;
PROMPT
PROMPT Then reconnect to XEPDB1 and run 30a_check_ols_status.sql again.
