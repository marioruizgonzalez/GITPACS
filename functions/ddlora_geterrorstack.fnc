CREATE OR REPLACE FUNCTION GG_ADMIN.ddlora_getErrorStack
RETURN VARCHAR2
IS
	tmess VARCHAR2(32767);
BEGIN
	tmess := DBMS_UTILITY.format_error_backtrace;
	IF length (tmess) > 32767 - 5000 THEN
		tmess := SUBSTR (tmess, 5000); -- just trailing portion
	END IF;
	RETURN tmess;
END;
/

