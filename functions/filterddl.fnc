CREATE OR REPLACE FUNCTION GG_ADMIN.filterDDL (
    stmt IN VARCHAR2,
	ora_owner IN VARCHAR2,
	ora_name IN VARCHAR2,
	ora_objtype IN VARCHAR2,
	ora_optype IN VARCHAR2
)
RETURN VARCHAR2
IS
retVal VARCHAR2(400);
errorMessage VARCHAR2(32767);
BEGIN

    retVal := 'INCLUDE';

	--
	--
	--  DO NOT CUSTOMIZE BEFORE THIS COMMENT
	--
	--


	-- CUSTOMIZE HERE: compute retVal here. It must be either 'INCLUDE' or 'EXCLUDE'.
    -- if it is 'EXCLUDE', DDL will be excluded from DDL trigger processing
    -- and vice versa. Use input parameters to this function to perform this
    -- computation.
    --
    --

    --
    --
    -- DO NOT CUSTOMIZE AFTER THIS COMMENT
    --
    --

    -- intentionally commented out, as it may cause 6508. Use only if needed.
	-- IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            -- intentionally commented out, as it may cause 6508. Use only if needed.
            -- "GG_ADMIN" .trace_put_line ('DDL', 'Returning ' || retVal || ' from filterDDL');
    -- END IF;
	RETURN retVal;

	EXCEPTION
    WHEN OTHERS THEN
        errorMessage := 'filterDDL:' || SQLERRM;
        dbms_output.put_line (errorMessage);
        RAISE;
END;
/

