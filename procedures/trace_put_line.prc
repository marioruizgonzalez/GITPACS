CREATE OR REPLACE PROCEDURE GG_ADMIN.trace_put_line (
                                                        oper VARCHAR2,
                                                        message VARCHAR2)
IS
output_file utl_file.file_type;
errorMessage VARCHAR2(32767);
total_fragments NUMBER;
line_size NUMBER;
prepLine VARCHAR2(32767);
i NUMBER;
BEGIN

    output_file := utl_file.fopen ('GGS_DDL_TRACE', 'ggs_ddl_trace.log', 'A', max_linesize => 32767);
    prepLine := 'SESS ' || USERENV('SESSIONID') || '-' ||
    TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') || ' : ' || oper || ' : ';
    utl_file.put (output_file, prepLine);
    line_size := 900 - lengthb (prepLine) - 1;
    total_fragments := lengthb (message) / line_size + 1;
    IF total_fragments * line_size = lengthb (message) THEN
        total_fragments := total_fragments - 1;
    END IF;

    -- line cannot be bigger than approx 1000 bytes so split it up other
    FOR i IN 1..total_fragments LOOP
        utl_file.put_line (output_file, substrb (message, (i - 1) * line_size + 1, line_size));
    END LOOP;

    utl_file.fCLOSE (output_file);
EXCEPTION
    WHEN OTHERS THEN
        --
        -- If tracing fails, trigger *will not* fail:
        --
        -- closing file can cause an error too, so it's all in vain if we don't check
        BEGIN
            utl_file.fCLOSE (output_file);
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        errorMessage := 'trace_put_line: ' || ':' || SQLERRM;
        -- we will not raise error here, probably out of space
        -- we will sacrifice tracing capability for trigger continuing to work
        -- othewise we would do:
        -- RAISE;
        NULL;
END trace_put_line;
/

