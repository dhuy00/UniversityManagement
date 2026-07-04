-- Phase 4 - Step 4.1A: Check Oracle Label Security prerequisites
-- Target database: Oracle Database 21c / XEPDB1
-- Run as SYS with SYSDBA while connected directly to XEPDB1.
--
-- This script is read-only.

SET DEFINE OFF
SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

DECLARE
    v_container_name    VARCHAR2(128);
    v_option_value      VARCHAR2(10);
    v_registry_status   VARCHAR2(30);
    v_configure_status  VARCHAR2(10);
    v_enable_status     VARCHAR2(10);
    v_status_row_count  PLS_INTEGER;
BEGIN
    SELECT SYS_CONTEXT('USERENV', 'CON_NAME')
    INTO v_container_name
    FROM DUAL;

    IF v_container_name = 'CDB$ROOT' THEN
        RAISE_APPLICATION_ERROR(
            -20950,
            'Connect directly to XEPDB1 before checking OLS.'
        );
    END IF;

    BEGIN
        SELECT VALUE
        INTO v_option_value
        FROM V$OPTION
        WHERE PARAMETER = 'Oracle Label Security';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_option_value := 'FALSE';
    END;

    SELECT MAX(STATUS)
    INTO v_registry_status
    FROM DBA_REGISTRY
    WHERE COMP_ID = 'OLS';

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
                v_status_row_count := 0;
                v_configure_status := 'FALSE';
                v_enable_status := 'FALSE';
            ELSE
                RAISE;
            END IF;
    END;

    DBMS_OUTPUT.PUT_LINE('Container             : ' || v_container_name);
    DBMS_OUTPUT.PUT_LINE(
        'V$OPTION OLS           : ' || NVL(v_option_value, '<NULL>')
    );
    DBMS_OUTPUT.PUT_LINE(
        'DBA_REGISTRY OLS       : ' || NVL(v_registry_status, '<MISSING>')
    );
    DBMS_OUTPUT.PUT_LINE(
        'OLS configured         : ' || NVL(v_configure_status, 'FALSE')
    );
    DBMS_OUTPUT.PUT_LINE(
        'OLS enabled            : ' || NVL(v_enable_status, 'FALSE')
    );

    IF v_option_value <> 'TRUE'
       OR v_status_row_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20951,
            'V$OPTION reports OLS=FALSE; native OLS is not installed in this image.'
        );
    END IF;

    IF v_configure_status <> 'TRUE'
       OR v_enable_status <> 'TRUE' THEN
        RAISE_APPLICATION_ERROR(
            -20952,
            'OLS is installed but not ready. Run 30b_configure_ols.sql.'
        );
    END IF;

    IF v_registry_status <> 'VALID' THEN
        RAISE_APPLICATION_ERROR(
            -20953,
            'OLS is enabled but its DBA_REGISTRY status is not VALID.'
        );
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        '[PASS] Oracle Label Security is installed, configured, and enabled.'
    );
END;
/

PROMPT Phase 4 - Step 4.1A completed successfully.
