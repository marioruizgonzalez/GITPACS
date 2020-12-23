CREATE OR REPLACE PACKAGE GG_ADMIN.DDLReplication AS

    /*
    Note about naming convention for constants:
    MD (metadata) constants
    MK (marker) constants
    NOTE: constant strings can be of any length up to 9(for example 'A1' or 'B2')
    NOTE: constant string cannot start with a digit
    NOTE: constant string cannot contain comma
    they are shortened to one byte or two bytes to produce less bulky output and save space in history tables
    */

    -- metadata columns
    -- IMPORTANT: when adding new ones, add them to tracing reporting routines
    MD_TAB_USERID CONSTANT VARCHAR2 (3) := 'A1';
    MD_COL_NAME CONSTANT VARCHAR2 (3) := 'A2';
    MD_COL_NUM CONSTANT VARCHAR2 (3) := 'A3';
    MD_COL_SEGCOL CONSTANT VARCHAR2 (3) := 'A4';
    MD_COL_TYPE CONSTANT VARCHAR2 (3) := 'A5';
    MD_COL_LEN CONSTANT VARCHAR2 (3) := 'A6';
    MD_COL_ISNULL CONSTANT VARCHAR2 (3) := 'A7';
    MD_COL_PREC CONSTANT VARCHAR2 (3) := 'A8';
    MD_COL_SCALE CONSTANT VARCHAR2 (3) := 'A9';
    MD_COL_CHARSETID CONSTANT VARCHAR2 (3) := 'B1';
    MD_COL_CHARSETFORM CONSTANT VARCHAR2 (3) := 'A';
    MD_COL_ALT_NAME CONSTANT VARCHAR2 (3) := 'C';
    MD_COL_ALT_TYPE CONSTANT VARCHAR2 (3) := 'D';
    MD_COL_ALT_PREC CONSTANT VARCHAR2 (3) := 'E';
    MD_COL_ALT_CHAR_USED CONSTANT VARCHAR2 (3) := 'F';
    MD_COL_ALT_XML_TYPE CONSTANT VARCHAR2 (3) := 'G';
    MD_TAB_COLCOUNT CONSTANT VARCHAR2 (3) := 'H';
    MD_TAB_DATAOBJECTID CONSTANT VARCHAR2 (3) := 'I';
    MD_TAB_CLUCOLS CONSTANT VARCHAR2 (3) := 'J';
    MD_TAB_TOTAL_COL_NUM CONSTANT VARCHAR2 (3) := 'K';
    MD_TAB_LOG_GROUP_EXISTS CONSTANT VARCHAR2 (3) := 'L';
    MD_COL_ALT_LOG_GROUP_COL CONSTANT VARCHAR2 (3) := 'M';
    MD_TAB_VALID CONSTANT VARCHAR2 (3) := 'N';
    MD_TAB_SUBPARTITION CONSTANT VARCHAR2 (3) := 'O';
    MD_TAB_PARTITION CONSTANT VARCHAR2 (3) := 'P';
    MD_TAB_PARTITION_IDS CONSTANT VARCHAR2 (3) := 'Q';
    MD_TAB_BLOCKSIZE CONSTANT VARCHAR2 (3) := 'R';
    MD_TAB_OBJECTID CONSTANT VARCHAR2 (3) := 'S';
    MD_TAB_PRIMARYKEY CONSTANT VARCHAR2 (3) := 'T';
    MD_TAB_PRIMARYKEYNAME CONSTANT VARCHAR2 (3) := 'V';
    MD_TAB_PARTITION_TYPE CONSTANT VARCHAR2 (3) := 'U';
    MD_TAB_OWNER CONSTANT VARCHAR2 (3) := 'W';
    MD_TAB_NAME CONSTANT VARCHAR2 (3) := 'X';
    MD_TAB_OBJTYPE CONSTANT VARCHAR2 (3) := 'Y';
    MD_TAB_OPTYPE CONSTANT VARCHAR2 (3) := 'Z';
    MD_TAB_SCN CONSTANT VARCHAR2 (3) := 'C2';
    MD_TAB_MASTEROWNER CONSTANT VARCHAR2 (3) := 'C3';
    MD_TAB_MASTERNAME CONSTANT VARCHAR2 (3) := 'C4';
    MD_TAB_MARKERSEQNO CONSTANT VARCHAR2 (3) := 'C5';
    MD_TAB_MARKERTABLENAME CONSTANT VARCHAR2 (3) := 'C6';
    MD_TAB_DDLSTATEMENT CONSTANT VARCHAR2 (3) := 'G1';
    MD_TAB_BIGFILE CONSTANT VARCHAR2 (3) := 'G2';
    MD_TAB_ISINDEXUNIQUE CONSTANT VARCHAR2 (3) := 'G3';
    MD_TAB_SEQUENCEROWID CONSTANT VARCHAR2 (3) := 'G4';
    MD_TAB_SEQCACHE CONSTANT VARCHAR2 (3) := 'G5';
    MD_TAB_SEQINCREMENTBY CONSTANT VARCHAR2 (3) := 'G6';
    MD_TAB_IOT CONSTANT VARCHAR2 (3) := 'G7';
    MD_TAB_IOT_OVERFLOW CONSTANT VARCHAR2 (3) := 'G8';
    MD_COL_ALT_BINARYXML_TYPE CONSTANT VARCHAR2 (3) := 'G9';
    MD_COL_ALT_LENGTH CONSTANT VARCHAR2 (3) := 'G10';
    MD_TAB_CLUSTER CONSTANT VARCHAR2 (3) := 'G11';
    MD_TAB_CLUSTER_COLNAME CONSTANT VARCHAR2 (3) := 'G12';
    MD_COL_ALT_TYPE_OWNER CONSTANT VARCHAR2 (3) := 'G13';
    MD_TAB_SESSION_OWNER CONSTANT VARCHAR2 (3) := 'G14'; -- not used in trigger, used in extract only
    MD_TAB_ENC_MKEYID CONSTANT VARCHAR2 (3) := 'G15';
    MD_TAB_ENC_ENCALG CONSTANT VARCHAR2 (3) := 'G16';
    MD_TAB_ENC_INTALG CONSTANT VARCHAR2 (3) := 'G17';
    MD_TAB_ENC_COLKLC CONSTANT VARCHAR2 (3) := 'G18';
    MD_TAB_ENC_KLCLEN CONSTANT VARCHAR2 (3) := 'G19';
    MD_COL_ENC_ISENC CONSTANT VARCHAR2 (3) := 'G20';
    MD_COL_ENC_NOSALT CONSTANT VARCHAR2 (3) := 'G21';
    MD_COL_ENC_ISLOB CONSTANT VARCHAR2 (3) := 'G22';
    MD_COL_LOB_ENCRYPT CONSTANT VARCHAR2 (3) := 'G23';
    MD_COL_LOB_COMPRESS CONSTANT VARCHAR2 (3) := 'G24';
    MD_COL_LOB_DEDUP CONSTANT VARCHAR2 (3) := 'G25';
    MD_COL_ALT_OBJECTXML_TYPE CONSTANT VARCHAR2 (3) := 'G26';
    MD_COL_HASNOTNULLDEFAULT CONSTANT VARCHAR2 (3) := 'G27';
    MD_TAB_XMLTYPETABLE CONSTANT VARCHAR2 (3) := 'G28';
    -- gap from 30 to 40 is because we added more properties in extract
    MD_TAB_TYPETABLE CONSTANT VARCHAR2 (3) := 'G38';
    MD_COL_OPQFLAGS CONSTANT VARCHAR2 (3) := 'G40';
    MD_COL_INTCOL CONSTANT VARCHAR2 (3) := 'G41';
    MD_COL_PROPERTY CONSTANT VARCHAR2 (3) := 'G42';
    MD_TAB_PROPERTY CONSTANT VARCHAR2 (3) := 'G48';
    MD_TAB_ORA_PFLAGS3 CONSTANT VARCHAR2 (3) := 'G54';
    --
    -- from now on, use G28 and on for hist
    --

    -- marker  constants
    MK_OBJECTID CONSTANT VARCHAR2 (3) := 'B2';
    MK_OBJECTOWNER CONSTANT VARCHAR2 (3) := 'B3';
    MK_OBJECTNAME CONSTANT VARCHAR2 (3) := 'B4';
    MK_OBJECTTYPE CONSTANT VARCHAR2 (3) := 'B5';
    MK_DDLTYPE CONSTANT VARCHAR2 (3) := 'B6';
    MK_DDLSEQ CONSTANT VARCHAR2 (3) := 'B7';
    MK_DDLHIST CONSTANT VARCHAR2 (3) := 'B8';
    MK_LOGINUSER CONSTANT VARCHAR2 (3) := 'B9';
    MK_DDLSTATEMENT CONSTANT VARCHAR2 (3) := 'C1';
    MK_TAB_VERSIONINFO CONSTANT VARCHAR2 (3) := 'C7';
    MK_TAB_VERSIONINFOCOMPAT CONSTANT VARCHAR2 (3) := 'C8';
    MK_TAB_VALID CONSTANT VARCHAR2 (3) := 'C9';
    MK_INSTANCENUMBER CONSTANT VARCHAR2 (3) := 'C10';
    MK_INSTANCENAME CONSTANT VARCHAR2 (3) := 'C11';
    MK_MASTEROWNER CONSTANT VARCHAR2 (3) := 'C12';
    MK_MASTERNAME CONSTANT VARCHAR2 (3) := 'C13';
    MK_TAB_OBJECTTABLE CONSTANT VARCHAR2 (3) := 'C14';
    MK_TAB_TOIGNORE CONSTANT VARCHAR2 (3) := 'C15';
    MK_TAB_NLS_PARAM CONSTANT VARCHAR2 (3) := 'C17';
    MK_TAB_NLS_VAL CONSTANT VARCHAR2 (3) := 'C18';
    MK_TAB_NLS_CNT CONSTANT VARCHAR2 (3) := 'C19';
    MK_TAB_XMLTYPETABLE CONSTANT VARCHAR2 (3) := 'C20';

    --
    -- IMPORTANT: when adding new constants (marker/history), add them to tracing reporting routines (trace_header_name())
    --


    -- fragment data constants
    GENERIC_MARKER CONSTANT INTEGER := 0;
    DDL_HISTORY CONSTANT INTEGER := 1;
    BEGIN_FRAGMENT CONSTANT INTEGER := 0;
    ADD_FRAGMENT CONSTANT INTEGER := 1;
    END_FRAGMENT CONSTANT INTEGER := 2;
    SOLE_FRAGMENT CONSTANT INTEGER := 3;
    ADD_FRAGMENT_AND_FLUSH CONSTANT INTEGER := 4;

    -- itemheader constants used to store data in marker larger than 32K
    ITEM_WHOLE CONSTANT INTEGER := 0;
    ITEM_HEAD CONSTANT INTEGER := 1;
    ITEM_TAIL CONSTANT INTEGER := 2;
    ITEM_DATA CONSTANT INTEGER := 3;

    MAX_NUMCHAR_PER_CHUNK CONSTANT INTEGER := 1333;

    escapeChars VARCHAR2(100) := '\'',=()';     -- special chars for metadata string
    escapeCharsLen CONSTANT INTEGER :=  6; -- if changing escapeChars, change this too!!

    -- variables for fragmenting
    current_fragment INTEGER;
    current_fragment_raw    RAW(32767);

    -- DDL trigger constants
    triggerErrorMessage VARCHAR2(32767) := 'Oracle GoldenGate DDL Replication Error: Code ';

    -- sequences (marker, history)
    currentMarkerSeq NUMBER;
    currentDDLSeq NUMBER;

    -- current object id (of the object being processed for DDL, if any, otherwise NULL)
    currentObjectId NUMBER;
    currentRowid VARCHAR2(32767);
    currentDataObjectId NUMBER;
    currentObjectName VARCHAR2(4000);
    currentDDLType VARCHAR2(130);
    currentObjectOwner VARCHAR2(400);
    currentObjectType VARCHAR2(130);
    currentMasterOwner VARCHAR2(400);
    currentMasterName VARCHAR2(400);

    errorMessage VARCHAR2(32767);

    -- Start SCN
    SCNB NUMBER;
    SCNW NUMBER;

    -- COL$ constants, this is referring to property bit
    COL_ISHIDDEN CONSTANT NUMBER := 32;                          -- 0x20
    COL_ISLOB CONSTANT NUMBER := 128;                            -- 0x80
    COL_ISENC CONSTANT NUMBER := 67108864;                 -- 0x04000000
    COL_ISNOSALT CONSTANT NUMBER := 536870912;             -- 0x20000000
    COL_HASNOTNULLDEFAULT CONSTANT NUMBER := 1073741824;   -- 0x40000000
    COL_ISINVISIBLE CONSTANT NUMBER := 17179869184;       -- 0x400000000

    -- OBJTABLE constants, this is referring to property bit
    OBJTAB CONSTANT NUMBER := 1;

    -- XMLTYPE constants, this is referring to opqtype$.flags bit
    XMLOBJECT CONSTANT NUMBER := 1;
    XMLLOB CONSTANT NUMBER := 4;
    XMLBINARY CONSTANT NUMBER := 64;
    XMLTAB CONSTANT NUMBER := 1024;

    -- IOT constants
    IOT CONSTANT NUMBER := 64;
    IOT_WITH_OVERFLOW CONSTANT NUMBER := 128;
    IOT_OVERFLOW_TABLE CONSTANT NUMBER := 512;

    -- cluster constants
    CLUSTER_TABLE CONSTANT NUMBER := 1024;

    deadlockDetected EXCEPTION;
    PRAGMA EXCEPTION_INIT (deadlockDetected, -60);

    -- location of trace directory
    dumpDir VARCHAR2(400) := '';

    -- query from v$DATABAE
    dbQueried boolean := FALSE;


    inumber NUMBER := NULL;
    iname VARCHAR2(400):= NULL;


    -- version info
    lv_version VARCHAR2(100) := '';
    lv_compat VARCHAR2(100) := '';
    lv_ora_db_block_size NUMBER := 0;

    -- tracing variables
    readTrace boolean := FALSE;
    trace_level NUMBER := 0; -- by default no tracing, can be 1 or 2 for more details
    sql_trace NUMBER := 0; -- by default no sql tracing, can be 0 or 1, this is for SQL TRACE (oracle's)
    useAllKeys NUMBER := 0; -- by default UKs are computed based on virtual/null, old method used all cols
    allowNonValidatedKeys NUMBER := 0; -- by default, keys need to be validated
    stay_metadata NUMBER := 0; -- by default query db and get metadata, 1 is useful for imports

    -- large DDL , max total DDL size is 2048K-someOdd bytes (2047K)
    useLargeDDL NUMBER := 1;

    -- simulate out of space if binary length is over 32K
    -- (for example number of characters can be less but number of bytes can be more)
    stringErrorSimulate EXCEPTION;
    PRAGMA EXCEPTION_INIT (stringErrorSimulate, -6502);

    -- raisable errors
    -- errors which should be raised up out of the DDL trigger
    -- e.g. raisable_errors VARCHAR2(18) := '-12751-01476-12545';
    raisable_errors VARCHAR2(6) := '-12751';

    -- optimization variables
    ddlObjNum  NUMBER := -1;
    ddlObjType  NUMBER := -1;
    ddlBaseObjNum NUMBER := -1;
    ddlObjUserId  NUMBER := -1;
    ddlBaseObjUserId NUMBER := -1;
    ddlBaseObjProperty NUMBER := -1;

    checkSchemaTabf NUMBER := -1;

    -- cursors to obtain metadata

    CURSOR nls_settings IS
		SELECT parameter, value
		FROM nls_session_parameters;


    -- get binary XML info
    CURSOR is_binary (tabObjNum IN NUMBER, tableName IN VARCHAR2, tableOwner IN VARCHAR2, colId IN NUMBER) IS
        SELECT TYPE# FROM
            (SELECT c.type#, c.segcol#
            FROM sys.col$ c, sys.obj$ o, sys.user$ u
            WHERE o.owner#=u.user# AND c.obj#=o.obj# AND o.obj# = tabObjNum
            AND col# = colId )
        WHERE segcol# > 0;


    --  primary key
    CURSOR pk_curs (ptabid IN NUMBER, powner IN VARCHAR2, ptable IN VARCHAR2) IS
        SELECT c.constraint_name,
                    c.column_name
               FROM dba_cons_columns c
              WHERE c.owner = powner
                AND c.table_name = ptable
                AND c.constraint_name =
                    (SELECT c1.name
                       FROM sys.user$ u1,
                            sys.user$ u2,
                            sys.cdef$ d,
                            sys.con$ c1,
                            sys.con$ c2,
                            sys.obj$ o1,
                            sys.obj$ o2
                      WHERE o1.obj# = ptabid
                        AND d.type# = 2
                        AND decode(d.type#, 5, 'ENABLED', decode(d.enabled, NULL, 'DISABLED', 'ENABLED')) = 'ENABLED'
                        AND c2.owner# = u2.user#(+)
                        AND d.robj# = o2.obj#(+)
                        AND d.rcon# = c2.con#(+)
                        AND o1.owner# = u1.user#
                        AND d.con# = c1.con#
                        AND d.obj# = o1.obj#)
                AND EXISTS
                    (SELECT 'Y'
                       FROM sys.user$ u3, sys.obj$ o3, sys.col$ c3
                      WHERE o3.obj# = ptabid
                        AND u3.name = powner
                        AND c3.name = c.column_name
                        AND o3.owner# = u3.user#
                        AND o3.obj# = c3.obj#
                        AND (bitand (c3.property, COL_ISHIDDEN) != COL_ISHIDDEN
                    ))
             ORDER BY c.position;




    -- get column defs
    CURSOR getCols (ptabid IN NUMBER) IS
        SELECT
            c.name column_name, c.col# col_num, c.segcol# segcol_num, c.intcol# intcol_num,
            c.type# type_num, c.length, 1 - c.null$ isnull,
            c.precision# precision_num, c.scale, c.charsetid, c.charsetform, c.property,
            tc.data_type, tc.data_type_owner, tc.data_precision, tc.data_length, tc.char_used,
            opq.flags opq_flags,
            (SELECT max(segcol#) FROM sys.col$ sc
             WHERE sc.obj# = c.obj# and sc.col# = c.col# and c.segcol# = 0) storage_segcol
        FROM sys.user$ u, sys.obj$ o, sys.col$ c, dba_tab_cols tc, sys.opqtype$ opq
        WHERE u.user# = o.owner# AND u.name = tc.owner
          AND o.obj# = c.obj# AND o.name = tc.table_name AND o.obj# = ptabid
          AND c.intcol# = tc.internal_column_id
          AND c.obj# = opq.obj# (+)
          AND c.intcol# = opq.intcol# (+)
          AND 1 = opq.type (+)
          AND o.type# in (2, 3, 4)      -- table, cluster, view
        ORDER BY c.intcol#;

    -- get table info
    CURSOR getTable IS
        SELECT o.dataobj# data_object_id, t.clucols clucols
        FROM sys.obj$ o, sys.tab$ t
        WHERE o.obj# = DDLReplication.currentObjectId AND t.obj# = DDLReplication.currentObjectId;

    -- get alternative object id
    CURSOR alt_objects (objName IN VARCHAR2, objOwner IN VARCHAR2, objType IN VARCHAR2) IS
        SELECT object_id
        FROM dba_objects
        WHERE object_name = objName AND
        owner = objOwner AND
        object_type = objType;

    -- get columns from supplemental log group
    CURSOR loggroup_suplog (s_log_group_name IN VARCHAR2, powner IN VARCHAR2, ptable IN VARCHAR2 ) IS
        SELECT column_name
        FROM dba_log_group_columns
        WHERE log_group_name = s_log_group_name AND
            owner = powner AND
            table_name = ptable;

    -- get IOT alternative IDs
    CURSOR iotAltId (objId IN NUMBER, objOwner IN VARCHAR2, objName IN VARCHAR2) IS
        SELECT i.obj# object_id  FROM sys.ind$ i, sys.obj$ o where i.bo# = objId
              and o.obj# = i.obj#;

    CURSOR iotOverflowAltId (objOwner IN VARCHAR2, objName IN VARCHAR2) IS
        SELECT object_id
            FROM dba_objects
            WHERE object_name =
                (SELECT table_name
                FROM dba_tables
                WHERE
                iot_name = objName and owner = objOwner and iot_type='IOT_OVERFLOW' and rownum=1) AND
                owner = objOwner;

    /*
    Prototypes for package implementation

    */
    PROCEDURE setCtxInfo(objNum  IN NUMBER, baseObjNum IN NUMBER,
                         objUserId IN NUMBER, baseObjUserId IN NUMBER,
                         baseObjProperty IN NUMBER);

    PROCEDURE getObjTypeName(obj_type IN NUMBER, objtype OUT VARCHAR2) ;
    PROCEDURE getObjType(objtype IN VARCHAR2, obj_type OUT NUMBER) ;
    PROCEDURE getDDLObjInfo(objtype IN VARCHAR2, ddlevent IN VARCHAR2,
                            powner IN VARCHAR2, pobj IN VARCHAR2);

    PROCEDURE getDDLBaseObjInfo(ddlevent IN VARCHAR2,
                            pbaseowner IN VARCHAR2, pbaseobj IN VARCHAR2) ;


    PROCEDURE getKeyCols (pobjid IN NUMBER,
                          powner IN VARCHAR2,
                          ptable IN VARCHAR2);


    PROCEDURE getKeyColsUseAllKeys (pobjid IN NUMBER,
                          powner IN VARCHAR2,
                          ptable IN VARCHAR2);

    PROCEDURE saveSeqInfo (
                           powner IN VARCHAR2,
                           pname IN VARCHAR2,
                           optype IN VARCHAR2,
                           userid IN VARCHAR2,
                           seqCache IN NUMBER,
                           seqIncrementBy IN NUMBER,
                           toIgnore IN VARCHAR2);

    PROCEDURE getColDefs (pobjid IN NUMBER,
                          powner IN VARCHAR2,
                          ptable IN VARCHAR2);

    PROCEDURE getTableInfo (objId IN NUMBER,
                            objName IN VARCHAR2,
                            objOwner IN VARCHAR2,
                            objType IN VARCHAR2,
                            opType IN VARCHAR2,
                            userId IN VARCHAR2,
                            mowner IN VARCHAR2,
                            mname IN VARCHAR2,
			    ddlStatement IN VARCHAR2,
			    toIgnore IN VARCHAR2,
			    isTypeTable IN VARCHAR2);

    PROCEDURE insertToMarker (
                              target IN INTEGER,
                              inType IN VARCHAR2,
                              inSubType IN VARCHAR2,
                              inString IN VARCHAR2,
                              markerOpType IN INTEGER
                              );

    FUNCTION itemHeader (
                         headerType IN VARCHAR2,
                         idKey IN VARCHAR2,
                         nameKey IN VARCHAR2,
                         val IN VARCHAR2,
                         itemMode NUMBER)
    RETURN VARCHAR2;

    FUNCTION getDDLText(stmt OUT VARCHAR2) RETURN NUMBER;

    FUNCTION isRecycle(stmt IN VARCHAR2) RETURN NUMBER;

    PROCEDURE getVersion;

    PROCEDURE beginHistory;
    PROCEDURE endHistory;
    PROCEDURE setTracing;

    FUNCTION replace_string ( item       VARCHAR2,
                              searchStr  VARCHAR2,
                              replaceStr VARCHAR2 )
    RETURN VARCHAR2;

    FUNCTION escape_string (
                            item VARCHAR2,
                            itemMode NUMBER)
    RETURN VARCHAR2;

    PROCEDURE saveMarkerDDL (
                             objid VARCHAR2,
                             powner VARCHAR2,
                             pname VARCHAR2,
                             ptype VARCHAR2,
                             dtype VARCHAR2,
                             seq VARCHAR2,
                             histname VARCHAR2,
                             ouser VARCHAR2,
                             objstatus VARCHAR2,
                             indexUnique VARCHAR2,
                             mowner VARCHAR2,
                             mname VARCHAR2,
                             stmt VARCHAR2,
                             toIgnore VARCHAR2);

    FUNCTION trace_header_name (
                                headerType VARCHAR2)
    RETURN VARCHAR2;

    FUNCTION removeSQLcomments (
                                stmt IN VARCHAR2)
    RETURN VARCHAR2;

    PROCEDURE getTableFromIndex (
                                 stmt IN VARCHAR2,
                                 ora_owner IN VARCHAR2,
                                 ora_name IN VARCHAR2,
                                 table_owner OUT NOCOPY VARCHAR2,
                                 table_name OUT NOCOPY VARCHAR2,
                                 otype OUT NOCOPY VARCHAR2);

    PROCEDURE getObjectTableType (
                                 stmt IN VARCHAR2,
                                 ora_owner IN VARCHAR2,
                                 ora_name IN VARCHAR2,
                                 type_owner OUT NOCOPY VARCHAR2,
                                 type_name OUT NOCOPY VARCHAR2,
                                 is_object OUT VARCHAR2,
                                 is_xml OUT VARCHAR2);

    PROCEDURE DDLtooLarge (stmt IN VARCHAR2,
                            ora_owner IN VARCHAR2,
                            ora_name IN VARCHAR2,
                            ora_type IN VARCHAR2,
                            sSize IN NUMBER);

    FUNCTION convertToUpper (
                             stmt IN VARCHAR2)
    RETURN VARCHAR2;


END DDLReplication;
/

