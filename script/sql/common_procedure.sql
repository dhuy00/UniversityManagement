CREATE OR REPLACE PROCEDURE Sp_Grant_Permission_To_User_Or_Role (
    p_permission_type IN VARCHAR2,
    p_tablename IN VARCHAR2,
    p_target_name IN VARCHAR2,
    p_is_grant_option IN NUMBER,
    p_column_name_select IN VARCHAR2,
    p_column_name_update IN VARCHAR2
)
AS
    v_sql VARCHAR2;
    v_view_name VARCHAR2;

    v_table_name VARCHAR2;
    v_target_name VARCHAR2;
BEGIN
    -- validate table name and target name
    v_table_name := DBMS_ASSERT.SQL_OBJECT_NAME(UPPER(p_tablename));
    v_target_name := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(p_target_name));

    IF (INSTR(UPPER(p_permission_type)), 'SELECT') > 0 THEN
        IF p_column_name_select IS NOT NULL THEN
            v_view_name := 'VIEW_SELECT_' || p_tablename || '_' || v_target_name;

            -- drop view if exists, try to delet, if  get error, ignore it
            BEGIN
                EXECUTE IMMEDIATE 'DROP VIEW ' || v_view_name;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;

            -- create view
            v_sql := 'CREATE OR REPLACE VIEW' || v_view_name || ' AS SELECT ' || p_column_name_select
            || ' FROM ' || v_table_name;

            --grant select on view
            v_sql := 'GRANT SELECT ON ' || v_view_name || ' TO ' || v_target_name;
        ELSE
            v_sql := 'GRANT SELECT ON ' || v_table_name || ' TO ' || v_target_name; 
        END IF;

        IF p_is_grant_option = 1 THEN
            v_sql := v_sql || ' WITH GRANT OPTION';
        END IF;

        EXECUTE IMMEDIATE v_sql;
    END IF;

    --NEU CHO PHEP SELECT TREN CAC COT CU THE
    IF column_name_select IS NOT NULL AND permission_type LIKE '%SELECT%' THEN
        STRSQL2 := '
        CREATE OR REPLACE VIEW VIEW_SELECT_COLUMN_' || tablename || '_' || target_name ||
        ' AS
        SELECT ' || column_name_select || ' 
        FROM ' || tablename || '
        WITH CHECK OPTION ';
        EXECUTE IMMEDIATE(STRSQL2);
        STRSQL := 'GRANT SELECT ON VIEW_SELECT_COLUMN_' || tablename || '_' || target_name || ' TO ' || target_name;
        IF is_grant_option = 1 THEN
            STRSQL := STRSQL || ' WITH GRANT OPTION ';   
        END IF;
        EXECUTE IMMEDIATE(STRSQL);
    --NEU CHO PHEP SELECT TREN TAT CA CAC COT
    ELSIF permission_type LIKE '%SELECT%' THEN
        STRSQL := 'GRANT SELECT ' || ' ON ' || tablename || ' TO ' || target_name;
        IF is_grant_option = 1 THEN
            STRSQL := STRSQL || ' WITH GRANT OPTION ';
        END IF;
        EXECUTE IMMEDIATE(STRSQL);
    END IF;
    --NEU CHO PHEP UPDATE TREN CAC COT CHI DINH
    IF column_name_update IS NOT NULL AND permission_type LIKE '%UPDATE%' THEN
        STRSQL := 'GRANT UPDATE (' || column_name_update || ') ON ' || tablename || ' TO ' || target_name;
        IF is_grant_option = 1 THEN
            STRSQL := STRSQL || ' WITH GRANT OPTION ';
        END IF;
        EXECUTE IMMEDIATE(STRSQL);
    --NEU CHO PHEP UPDATE TREN TAT CA CAC COT
    ELSIF permission_type LIKE '%UPDATE%' THEN
        STRSQL := 'GRANT UPDATE ' || ' ON ' || tablename || ' TO ' || target_name;
        IF is_grant_option = 1 THEN
            STRSQL := STRSQL || ' WITH GRANT OPTION ';
        END IF;
        EXECUTE IMMEDIATE(STRSQL);
    END IF;
    --NEU CHO PHEP INSERT
    IF  permission_type LIKE '%INSERT%' THEN
        STRSQL := 'GRANT INSERT' || ' ON ' || tablename || ' TO ' || target_name;
        IF is_grant_option = 1 THEN
            STRSQL := STRSQL || ' WITH GRANT OPTION ';
        END IF;
        EXECUTE IMMEDIATE(STRSQL);
    END IF;
    --NEU CHO PHEP DELETE
    IF permission_type LIKE '%DELETE%' THEN
        STRSQL := 'GRANT DELETE' || ' ON ' || tablename || ' TO ' || target_name;
        IF is_grant_option = 1 THEN
            STRSQL := STRSQL || ' WITH GRANT OPTION ';
        END IF;
        EXECUTE IMMEDIATE(STRSQL);
    END IF;
END;
/
