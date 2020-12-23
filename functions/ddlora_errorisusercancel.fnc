CREATE OR REPLACE FUNCTION GG_ADMIN.ddlora_errorIsUserCancel
RETURN BOOLEAN
IS
        tmess                 VARCHAR2(32767);
        error_is_user_cancel  BOOLEAN := FALSE;
        error_pos             INTEGER := 0;
BEGIN
        tmess := DBMS_UTILITY.format_error_stack;
        error_pos := Instr(tmess, 'ORA-01013: ', 1, 1);
        IF error_pos > 0 THEN
	    error_is_user_cancel := TRUE;
        END IF;
        RETURN error_is_user_cancel;
END;
/

