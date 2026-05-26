CREATE OR REPLACE PROCEDURE Sp_Grant_Permission_To_User_Or_Role (
    permission_type IN VARCHAR2,
    tablename IN VARCHAR2,
    target_name IN VARCHAR2,
    is_grant_option IN NUMBER,
    column_name_select IN VARCHAR2,--CHUOI CAC COLUMN DUOC NGAN CACH BOI DAU PHAY
    column_name_update IN VARCHAR2
)
AS
    STRSQL VARCHAR(2000);
    STRSQL2 VARCHAR(2000);
BEGIN
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
