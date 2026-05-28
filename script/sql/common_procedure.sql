CREATE OR REPLACE PROCEDURE PERMISSION_GRANT (
    p_permission_type     IN VARCHAR2,
    p_tablename           IN VARCHAR2,
    p_target_name         IN VARCHAR2,
    p_is_grant_option     IN NUMBER,
    p_column_name_select  IN VARCHAR2,
    p_column_name_update  IN VARCHAR2
)
AS
    v_sql               VARCHAR2(4000);
    v_view_name         VARCHAR2(128);

    v_table_name        VARCHAR2(128);
    v_target_name       VARCHAR2(128);
    v_permission_type   VARCHAR2(20);

    v_column            VARCHAR2(128);
    v_column_list       VARCHAR2(4000);

    -- VALIDATE COLUMN LIST
    FUNCTION Validate_Column_List(
        p_column_list IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_result VARCHAR2(4000) := '';
        v_col    VARCHAR2(128);
    BEGIN
        IF p_column_list IS NULL THEN
            RETURN NULL;
        END IF;

        FOR i IN 1 .. REGEXP_COUNT(p_column_list, '[^,]+')
        LOOP
            v_col := TRIM(
                        REGEXP_SUBSTR(
                            p_column_list,
                            '[^,]+',
                            1,
                            i
                        )
                     );

            -- VALIDATE COLUMN NAME
            v_col := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(v_col));

            IF i > 1 THEN
                v_result := v_result || ', ';
            END IF;

            v_result := v_result || v_col;
        END LOOP;

        RETURN v_result;
    END;
BEGIN
    -- VALIDATE INPUTS

    v_permission_type := UPPER(TRIM(p_permission_type));

    IF v_permission_type NOT IN (
        'SELECT',
        'UPDATE',
        'INSERT',
        'DELETE'
    ) THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'INVALID PERMISSION TYPE'
        );
    END IF;

    IF p_is_grant_option NOT IN (0, 1) THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'p_is_grant_option MUST BE 0 OR 1'
        );
    END IF;

    -- VALIDATE TABLE NAME
    v_table_name :=
        DBMS_ASSERT.SQL_OBJECT_NAME(
            UPPER(TRIM(p_tablename))
        );

    -- VALIDATE USER/ROLE NAME
    v_target_name :=
        DBMS_ASSERT.SIMPLE_SQL_NAME(
            UPPER(TRIM(p_target_name))
        );

    -- SELECT PRIVILEGE
    IF v_permission_type = 'SELECT' THEN

        -- COLUMN LEVEL SELECT
        IF p_column_name_select IS NOT NULL THEN

            -- VALIDATE COLUMN LIST
            v_column_list :=
                Validate_Column_List(
                    p_column_name_select
                );

            -- SAFE VIEW NAME
            v_view_name :=
                DBMS_ASSERT.SIMPLE_SQL_NAME(
                    'VW_SEL_' ||
                    REPLACE(v_table_name, '.', '_') ||
                    '_' ||
                    v_target_name
                );

            -- DROP VIEW IF EXISTS
            BEGIN
                EXECUTE IMMEDIATE
                    'DROP VIEW ' || v_view_name;
            EXCEPTION
                WHEN OTHERS THEN
                    -- ORA-00942: table or view does not exist
                    IF SQLCODE != -942 THEN
                        RAISE;
                    END IF;
            END;

            -- CREATE VIEW
            v_sql :=
                'CREATE VIEW ' || v_view_name ||
                ' AS SELECT ' || v_column_list ||
                ' FROM ' || v_table_name;

            EXECUTE IMMEDIATE v_sql;

            -- GRANT SELECT ON VIEW
            v_sql :=
                'GRANT SELECT ON ' || v_view_name ||
                ' TO ' || v_target_name;

        ELSE

            -- FULL TABLE SELECT
            v_sql :=
                'GRANT SELECT ON ' || v_table_name ||
                ' TO ' || v_target_name;

        END IF;

        IF p_is_grant_option = 1 THEN
            v_sql := v_sql || ' WITH GRANT OPTION';
        END IF;

        EXECUTE IMMEDIATE v_sql;

    -- UPDATE PRIVILEGE
    ELSIF v_permission_type = 'UPDATE' THEN
        -- COLUMN LEVEL UPDATE
        IF p_column_name_update IS NOT NULL THEN

            v_column_list :=
                Validate_Column_List(
                    p_column_name_update
                );

            v_sql :=
                'GRANT UPDATE (' || v_column_list || ')' ||
                ' ON ' || v_table_name ||
                ' TO ' || v_target_name;

        ELSE
            v_sql :=
                'GRANT UPDATE ON ' || v_table_name ||
                ' TO ' || v_target_name;

        END IF;

        IF p_is_grant_option = 1 THEN
            v_sql := v_sql || ' WITH GRANT OPTION';
        END IF;

        EXECUTE IMMEDIATE v_sql;

    -- INSERT PRIVILEGE
    ELSIF v_permission_type = 'INSERT' THEN

        v_sql :=
            'GRANT INSERT ON ' || v_table_name ||
            ' TO ' || v_target_name;

        IF p_is_grant_option = 1 THEN
            v_sql := v_sql || ' WITH GRANT OPTION';
        END IF;

        EXECUTE IMMEDIATE v_sql;

    -- DELETE PRIVILEGE
    ELSIF v_permission_type = 'DELETE' THEN

        v_sql :=
            'GRANT DELETE ON ' || v_table_name ||
            ' TO ' || v_target_name;

        IF p_is_grant_option = 1 THEN
            v_sql := v_sql || ' WITH GRANT OPTION';
        END IF;

        EXECUTE IMMEDIATE v_sql;

    END IF;

EXCEPTION
    -- HANDLE ERRORS
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(
            -20999,
            'ERROR IN PERMISSION_GRANT: ' ||
            SQLERRM
        );
END;
/