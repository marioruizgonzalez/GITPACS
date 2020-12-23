CREATE OR REPLACE PROCEDURE GG_ADMIN.clear_trace
IS
output_file utl_file.file_type;
errorMessage VARCHAR2(32767);
BEGIN

    utl_file.fremove ('GGS_DDL_TRACE', 'ggs_ddl_trace.log');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE <>  - 29283 THEN -- avoid 'file not found'
            errorMessage := 'trace_put_line: ' || ':' || SQLERRM;
            RAISE;
        END IF;
END clear_trace;
/

