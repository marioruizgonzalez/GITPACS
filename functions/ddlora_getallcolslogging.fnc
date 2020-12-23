CREATE OR REPLACE FUNCTION GG_ADMIN.ddlora_getAllColsLogging (
                                                             pobjid NUMBER)
RETURN NUMBER
IS
    all_log_group_exists NUMBER;
BEGIN
    BEGIN
        SELECT COUNT(*)
		INTO all_log_group_exists
		FROM sys.obj$ o,sys.cdef$ c
		WHERE
			o.obj#=pobjid
			AND o.obj#=c.obj#
			AND c.type#=17
			AND rownum=1;

		EXCEPTION
	        WHEN OTHERS THEN
				all_log_group_exists := 0;
	END;
    RETURN all_log_group_exists;
END;
/

