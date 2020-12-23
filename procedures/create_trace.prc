CREATE OR REPLACE PROCEDURE GG_ADMIN.create_trace IS
dump_dir VARCHAR2(400);
errorMessage VARCHAR2(32767);
BEGIN

    SELECT VALUE INTO dump_dir
    FROM sys.v_$parameter
    WHERE name = 'user_dump_dest' ;

    EXECUTE IMMEDIATE 'create or replace directory GGS_DDL_TRACE as ''' || dump_dir || '''';

EXCEPTION
    WHEN OTHERS THEN
        errorMessage := 'create_trace: ' || ':' || SQLERRM;
        dbms_output.put_line (errorMessage);
        RAISE;
END create_trace;
/

