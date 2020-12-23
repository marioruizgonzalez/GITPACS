CREATE OR REPLACE FUNCTION GG_ADMIN.file_separator
RETURN CHAR
IS
dump_dir VARCHAR2(400);
errorMessage VARCHAR2(32767);
fileSeparator CHAR := '/';
BEGIN

    SELECT VALUE INTO dump_dir
    FROM sys.v_$parameter
    WHERE name = 'user_dump_dest' ;

      IF instr(dump_dir,'/') > 0 THEN
        fileSeparator := '/';
      ELSIF instr(dump_dir,'\') > 0 THEN
        fileSeparator := '\';
      END IF;

      RETURN fileSeparator;
END file_separator;
/

