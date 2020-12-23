CREATE OR REPLACE FUNCTION GG_ADMIN.ddlora_verifyDDL
RETURN VARCHAR2
IS
someErr NUMBER;
trigStat VARCHAR2(100);
BEGIN
    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'GG_ADMIN' AND name = 'DDLORA_GETERRORSTACK' AND TYPE = 'FUNCTION';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (1.1)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'GG_ADMIN' AND name = 'CREATE_TRACE' AND TYPE = 'PROCEDURE';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (2)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'GG_ADMIN' AND name = 'TRACE_PUT_LINE' AND TYPE = 'PROCEDURE';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (3)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'GG_ADMIN' AND name = 'FILE_SEPARATOR' AND TYPE = 'FUNCTION';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (3.1)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'GG_ADMIN' AND name = 'INITIAL_SETUP' AND TYPE = 'PROCEDURE';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (4)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'GG_ADMIN' AND name = 'DDLORA_GETLOBS' AND TYPE = 'PROCEDURE';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (4.1)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'GG_ADMIN' AND name = 'DDLORA_GETALLCOLSLOGGING' AND TYPE = 'PROCEDURE';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (4.2)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'GG_ADMIN' AND name = 'DDLREPLICATION' AND TYPE = 'PACKAGE';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (5)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'GG_ADMIN' AND name = 'DDLVERSIONSPECIFIC' AND TYPE = 'PACKAGE';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (5.1)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'GG_ADMIN' AND name = 'DDLREPLICATION' AND TYPE ='PACKAGE BODY';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (6)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = 'GG_ADMIN' AND table_name = 'GGS_DDL_RULES';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (6.1)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = 'GG_ADMIN' AND table_name = 'GGS_DDL_RULES_LOG';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (6.2)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'GG_ADMIN' AND name = 'DDLAUX' AND TYPE = 'PACKAGE';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (6.3)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'GG_ADMIN' AND name = 'DDLAUX' AND TYPE = 'PACKAGE BODY';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (6.4)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'SYS' AND name = 'DDLCTXINFO' AND TYPE = 'PACKAGE';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' 6.5)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors WHERE owner = 'SYS' AND name = 'DDLCTXINFO' AND TYPE = 'PACKAGE BODY';
    IF 0 <> someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (6.6)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = 'GG_ADMIN' AND table_name = 'GGS_DDL_HIST';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (7)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = 'SYS' AND table_name = 'ENC$';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (7.0)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = 'GG_ADMIN' AND table_name = 'GGS_DDL_HIST' || '_ALT';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (7.1)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = 'GG_ADMIN' AND table_name = 'GGS_DDL_OBJECTS';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (8)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = 'GG_ADMIN' AND table_name = 'GGS_DDL_COLUMNS';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (9)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = 'GG_ADMIN' AND table_name = 'GGS_DDL_LOG_GROUPS';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (A)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = 'GG_ADMIN' AND table_name = 'GGS_DDL_PARTITIONS';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (B)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = 'GG_ADMIN' AND table_name = 'GGS_DDL_PRIMARY_KEYS';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (C)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = 'GG_ADMIN' AND table_name = 'GGS_TEMP_COLS';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (C1)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_tables WHERE owner = 'GG_ADMIN' AND table_name = 'GGS_TEMP_UK';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (C2)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_sequences WHERE sequence_owner = 'GG_ADMIN' AND sequence_name = 'GGS_DDL_SEQ';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (D)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_errors a, dual WHERE owner = 'SYS' AND name = 'GGS_DDL_TRIGGER_BEFORE' AND TYPE = 'TRIGGER' ;
    IF someErr <> 0 THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (E)';
    END IF;

    SELECT COUNT(*) INTO someErr
    FROM dba_triggers WHERE owner = 'SYS' AND trigger_name = 'GGS_DDL_TRIGGER_BEFORE';
    IF 0 = someErr THEN
        RETURN 'ERRORS detected in installation of DDL Replication software components' || ' (F)';
    END IF;

    SELECT status INTO  trigStat
    FROM dba_triggers WHERE owner = 'SYS' AND trigger_name = 'GGS_DDL_TRIGGER_BEFORE';

    IF trigStat <> 'ENABLED' THEN
        RETURN 'WARNING: DDL Trigger is NOT enabled. ' || 'SUCCESSFUL installation of DDL Replication software components';
    ELSE
        RETURN 'SUCCESSFUL installation of DDL Replication software components';
    END IF;


END;
/

