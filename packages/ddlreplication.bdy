CREATE OR REPLACE PACKAGE BODY GG_ADMIN.DDLReplication AS

    /*
    FUNCTION REMOVESQLCOMMENTS RETURNS VARCHAR2
    Remove all SQL comments in DDL (or any SQL). Takes care of dash-dash and slash-star comments.
    Also 'knows' about double and single quoted strings and doesn't remove parts of string if they
    take comment form
    param[in] STMT                           VARCHAR2                SQL to decoment

    return de-commented SQL
    note Statement passed into this function MUST be lesser than 32767 The returned
    statement is NOT correct if SQL is of greater length than that size.
    */
    FUNCTION removeSQLcomments (
                                stmt IN VARCHAR2)
    RETURN VARCHAR2
    IS
    retval VARCHAR2 (32767);
    -- the following (xxxStart) remember if string or comment started (0 not, 1 yes)
    identStart NUMBER := 0;
    stringStart NUMBER := 0;
    slashStart NUMBER := 0;
    dashStart NUMBER := 0;
    beg NUMBER := 0;
    curr NUMBER := 0;
    tryExitLoop NUMBER := 0;
    -- 11833474: We are by default in byte semantics so have
    -- space to accomodate multibyte chars.
    currChar VARCHAR2(5);
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering removeSQLcomments()');
        END IF;

        -- Early out
        IF stmt IS NULL THEN
           return stmt;
        END IF;

        retval := '';
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
			"GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Length of input ' || to_char (length(stmt)));
		END IF;
        LOOP
            -- look for beginning of comment (slash or dash)
            -- make sure strings can contain them (those are not comments)
            -- make sure comments can contain each other
            tryExitLoop := 1;
            beg := beg + 1;
            currChar := substr (stmt, beg, 1);
            IF '''' = currChar AND identStart = 0 AND slashStart = 0 AND dashStart = 0 THEN
                stringStart := 1 - stringStart;
            ELSIF '"' = currChar  AND stringStart = 0 AND slashStart = 0 AND dashStart = 0 THEN
                identStart := 1 - identStart;
            ELSIF '/' = currChar  AND '*' = substr (stmt, beg + 1, 1) AND identStart = 0 AND stringStart = 0 AND dashStart = 0 THEN
                slashStart := 1;
                tryExitLoop := 0;
            ELSIF '*' = currChar  AND '/' = substr (stmt, beg + 1, 1) THEN
                IF slashStart <> 0 THEN
                    beg := beg + 1;
                    slashStart := 0;
                    tryExitLoop := 0;
                END IF;
            ELSIF '-' = currChar  AND '-' = substr (stmt, beg + 1, 1) AND identStart = 0 AND stringStart = 0 AND slashStart = 0 THEN
                dashStart := 1;
                tryExitLoop := 0;
            ELSIF CHR (10) = currChar  OR beg >= length (stmt) THEN
                IF dashStart = 0 THEN
                    retval := retval || currChar ;
                END IF;
                dashStart := 0;
                IF beg < length (stmt) THEN
					tryExitLoop := 0;
				ELSE
				    tryExitLoop := 1;
				    dashStart := 0;
				    slashStart := 0;
				    identStart := 0;
				    stringStart := 0;
				    IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
						"GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Found end of DDL ');
					END IF;
                END IF;
            END IF;

            IF tryExitLoop = 1 THEN
                IF slashStart = 0 AND dashStart = 0 THEN
                    -- if this is not a comment, append to resulting de-commented SQL
                    retval := retval || currChar ;
                    IF beg >= length (stmt) THEN
                        EXIT;
                    END IF;
                END IF;
            END IF;
        END LOOP;

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
			"GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Returning from removecomment ' || retval);
		END IF;
        RETURN retval;

        EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'removeSQLComments' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END removeSQLComments;

/*
   FUNCTION GETDDLTEXT
   Get text of DDL, the first 4K
   param[out] STMT VARCHAR2 DDL statement text
   return 0 if there was an error in getting the text (no text), or 1 if ok

   remarks This only gets the first 4K, which for many purposes is enough
           Can raise stringErrorSimulate, caller must handle.
*/

    FUNCTION getDDLText(stmt OUT VARCHAR2) RETURN NUMBER
    IS
        -- construct the entire text of SQL statement
        -- NOTE: last SQL statement obtained for a given transaction
        -- has the clear text of it
        sql_text ora_name_list_t;
        n INTEGER;
        sSize NUMBER;
        rawDDL   RAW(4000);
        pieceRaw RAW(4000);
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering getDDLText()');
        END IF;

        rawDDL := '';
        n := ora_sql_txt(sql_text );
        -- Early out
        IF n IS NULL THEN
           IF "GG_ADMIN" .DDLReplication.trace_level >= 0 THEN
              "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Got NULL ddl text');
           END IF;
          RETURN 0;
        END IF;

        BEGIN
        -- get first 4K of statement (such as create table, index etc)
            IF "GG_ADMIN" .DDLReplication.trace_level >= 2 THEN
                "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'Got ' || to_char(n) || ' block DDL fragments.');
            END IF;
            FOR i IN 1..n LOOP
                -- retrieve a piece as raw data.
                pieceRaw := utl_raw.cast_to_raw(sql_text(i));
                IF "GG_ADMIN" .DDLReplication.trace_level >= 2 THEN
                    "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'Got DDL fragment ' || to_char(n) ||
                                                ', length = ' || to_char(utl_raw.length(pieceRaw)));
                END IF;
                -- if more than 4K, stop concatenation.
                if (utl_raw.length(pieceRaw) + utl_raw.length(rawDDL)) > ((4000 / 4) * 3) THEN
                    IF "GG_ADMIN" .DDLReplication.trace_level >= 2 THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'DDL size reached to max. length = ' ||
                                                     to_char(utl_raw.length(rawDDL)));
                    END IF;
                    EXIT;
                END IF;
                -- concatenate a piece.
                rawDDL := utl_raw.concat(rawDDL, pieceRaw);
                IF "GG_ADMIN" .DDLReplication.trace_level >= 2 THEN
                    "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'DDL concatenated. length = ' ||
                                                 to_char(utl_raw.length(rawDDL)));
                END IF;
            END LOOP;
        EXCEPTION
            WHEN OTHERS THEN
                IF instr (raisable_errors, to_char (SQLCODE, 'S00000')) > 0 THEN
                    RAISE;
                END IF;
                -- we should not reach here, because we no longer concatenate more than 32K.
                -- this is ok, because first 32K is used for these only:
                -- 1. reporting, which always shows only first part
                -- 2. extraction (through parsing) of owner, name etc which is always in the head of DDL
                -- 3. ignoring BIN$ objects as those DDLs are not long (rena mes)
                -- so we don't care about the rest. The rest is stored in ma rker table for extract
                -- anyway (for actual replication)
            NULL;
        END;
        -- convert to VARCHAR2 type from RAW.
        stmt := utl_raw.cast_to_varchar2(rawDDL);
        IF "GG_ADMIN" .DDLReplication.trace_level >= 2 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'Raw DDL converted to VARCHAR2. length = ' ||
                                        to_char(lengthb(stmt)) || ' , stmt = ' || stmt);
        END IF;

        -- check if multi byte DDL.
        if length(stmt) <> lengthb(stmt) THEN
            -- extract only valid character, so that we don't truncate by middle of character.
            stmt := substr(stmt, 1, length(stmt));
            IF "GG_ADMIN" .DDLReplication.trace_level >= 2 THEN
                "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'Multi byte DDL validated. length = ' ||
                                            to_char(lengthb(stmt)) || ' , stmt = ' || stmt);
            END IF;
        END IF;

        stmt := rtrim (stmt, ' ');
        -- nulls are in it from oracle!
        stmt := REPLACE (stmt, chr(0), ' ');
        RETURN 1;
    EXCEPTION
        -- this would happen if oracle error (internal ddl error, server error, 3113 etc)
        WHEN OTHERS THEN
            IF instr (raisable_errors, to_char (SQLCODE, 'S00000')) > 0 THEN
                RAISE;
            END IF;
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Cannot obtain DDL statemen t from Oracle (2), ignoring, objtype [' || ora_dict_obj_type ||
                '] name [' || ora_dict_obj_owner || '.' || ora_dict_obj_name || '], error [' || to_char( SQLCODE) || ']');
            IF "GG_ADMIN" .DDLReplication.sql_trace = 1 THEN
                dbms_session.set_sql_trace(false);
            END IF;
        RETURN 0;
    END;

    /*
    FUNCTION ISRECYCLE
    Determine if DDL is recycle bin
    param[in] STMT                           VARCHAR2                DDL statement text

    remarks Recyclebin DDLs are short (renames). This will look for BIN$ within string in
    this DDL. If found, it's recyclebin and will be ignored.
    */
    FUNCTION isRecycle(stmt IN VARCHAR2) RETURN NUMBER
    IS
        cStmt VARCHAR2(32767);
        binP NUMBER;
        binE NUMBER;
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering isRecycle()');
        END IF;

        -- strip comments, so we don't find BIN$ in comments
        cStmt := removeSQLComments (substr (stmt, 1, 32767 - 100));

        -- look for BIN$
        binP := instr(cStmt, '"BIN$', 1);
        IF binP = 0 THEN
            RETURN 0;
        END IF;
        cStmt := substr (cStmt, binP);

        -- look for closing double quote
        binE := instr(cStmt, '"', 2);
        IF binE = 0 THEN
            RETURN 0;
        END IF;

        -- found BIN$ object. We don't support user-created objects that start with
        -- BIN$
        cStmt := substr(cStmt, 2, binE-2);
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'BIN$ = [' || cStmt || ']');
        END IF;

        -- recycle bin name is BIN$<24 char id>$<ver num>, so 29th is always $
        -- and there has to be at least 30 chars.
        IF length(cStmt) < 30 THEN
            RETURN 0;
        END IF;
        IF substr(cStmt, 29, 1) = '$' THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END;

    PROCEDURE getDDLBaseObjInfo(ddlevent IN VARCHAR2,
                            pbaseowner IN VARCHAR2, pbaseobj IN VARCHAR2) IS

     tobjNum NUMBER;
    BEGIN
       IF pbaseobj IS NOT NULL AND pbaseowner IS NOT NULL AND
          ddlevent <> 'CREATE'
       THEN
         select o.object_id , u.user# into ddlBaseObjNum , ddlBaseObjUserId
         from  dba_objects o, sys.user$ u where
         o.object_name = pbaseobj and u.name = pbaseowner  and o.owner = u.name
         and o.object_type = 'TABLE';
         select t.property into ddlBaseObjProperty from sys.tab$ t where
         obj# = ddlBaseObjNum;
       END IF;

    END getDDLBaseObjInfo;

    PROCEDURE setCtxInfo(objNum  IN NUMBER, baseObjNum IN NUMBER,
                         objUserId IN NUMBER, baseObjUserId IN NUMBER,
                         baseObjProperty IN NUMBER) IS
    BEGIN
    ddlObjNum  := objNum;
    ddlBaseObjNum := baseObjNum ;
    ddlObjUserId  := objUserId;
    ddlBaseObjUserId := baseObjUserId;
    ddlBaseObjProperty := baseObjProperty;
    END;

    PROCEDURE getObjType(objtype IN VARCHAR2, obj_type OUT NUMBER) IS
    BEGIN
      select   decode(objtype, 'NEXT OBJECT', 0,
                     'INDEX', 1, 'TABLE', 2, 'CLUSTER',
                      3, 'VIEW', 4, 'SYNONYM', 5, 'SEQUENCE',
                      6, 'PROCEDURE', 7, 'FUNCTION', 8, 'PACKAGE',
                      9, 'PACKAGE BODY', 11, 'TRIGGER',
                      12, 'TYPE', 13, 'TYPE BODY',
                      14, 'TABLE PARTITION', 19, 'INDEX PARTITION', 20, 'LOB',
                      21, 'LIBRARY', 22, 'DIRECTORY', 23, 'QUEUE',
                      24, 'JAVA SOURCE', 28, 'JAVA CLASS', 29, 'JAVA RESOURCE',
                      30, 'INDEXTYPE', 32, 'OPERATOR',
                      33, 'TABLE SUBPARTITION', 34, 'INDEX SUBPARTITION',
                      35, 'LOB PARTITION', 40, 'LOB SUBPARTITION',
                      42, 'DIMENSION',
                      43, 'CONTEXT', 44, 'RULE SET', 46, 'RESOURCE PLAN',
                      47, 'CONSUMER GROUP',
                      48, 'SUBSCRIPTION', 51, 'LOCATION',
                      52, 'XML SCHEMA', 55, 'JAVA DATA',
                      56, 'EDITION', 57, 'RULE',
                      59, 'CAPTURE', 60, 'APPLY',
                      61, 'EVALUATION CONTEXT',
                      62, 'JOB', 66, 'PROGRAM', 67, 'JOB CLASS', 68, 'WINDOW',
                      69, 'SCHEDULER GROUP', 72, 'SCHEDULE', 74, 'CHAIN',
                      79, 'FILE GROUP', 81, 'MINING MODEL', 82, 'ASSEMBLY',
                      87, 'CREDENTIAL', 90, 'CUBE DIMENSION', 92, 'CUBE',
                      93, 'MEASURE FOLDER', 94, 'CUBE BUILD PROCESS',
                      95, 'FILE WATCHER', 100, 'DESTINATION',
                      101, 'SQL TRANSLATION PROFILE',104,
                     '-1')  into obj_type from dual;

    END;

    PROCEDURE getObjTypeName(obj_type IN NUMBER, objtype OUT VARCHAR2) IS
    BEGIN
      select
      decode(obj_type, 0, 'NEXT OBJECT', 1, 'INDEX', 2, 'TABLE', 3, 'CLUSTER',
                      4, 'VIEW', 5, 'SYNONYM', 6, 'SEQUENCE',
                      7, 'PROCEDURE', 8, 'FUNCTION', 9, 'PACKAGE',
                      11, 'PACKAGE BODY', 12, 'TRIGGER',
                      13, 'TYPE', 14, 'TYPE BODY',
                      19, 'TABLE PARTITION', 20, 'INDEX PARTITION', 21, 'LOB',
                      22, 'LIBRARY', 23, 'DIRECTORY', 24, 'QUEUE',
                      28, 'JAVA SOURCE', 29, 'JAVA CLASS', 30, 'JAVA RESOURCE',
                      32, 'INDEXTYPE', 33, 'OPERATOR',
                      34, 'TABLE SUBPARTITION', 35, 'INDEX SUBPARTITION',
                      40, 'LOB PARTITION', 41, 'LOB SUBPARTITION',
                      43, 'DIMENSION',
                      44, 'CONTEXT', 46, 'RULE SET', 47, 'RESOURCE PLAN',
                      48, 'CONSUMER GROUP',
                      51, 'SUBSCRIPTION', 52, 'LOCATION',
                      55, 'XML SCHEMA', 56, 'JAVA DATA',
                      57, 'EDITION', 59, 'RULE',
                      60, 'CAPTURE', 61, 'APPLY',
                      62, 'EVALUATION CONTEXT',
                      66, 'JOB', 67, 'PROGRAM', 68, 'JOB CLASS', 69, 'WINDOW',
                      72, 'SCHEDULER GROUP', 74, 'SCHEDULE', 79, 'CHAIN',
                      81, 'FILE GROUP', 82, 'MINING MODEL', 87, 'ASSEMBLY',
                      90, 'CREDENTIAL', 92, 'CUBE DIMENSION', 93, 'CUBE',
                      94, 'MEASURE FOLDER', 95, 'CUBE BUILD PROCESS',
                      100, 'FILE WATCHER', 101, 'DESTINATION',
                      114, 'SQL TRANSLATION PROFILE',
                     'UNDEFINED')  into objtype from dual;

    END;


    PROCEDURE getDDLObjInfo(objtype IN VARCHAR2, ddlevent IN VARCHAR2,
                            powner IN VARCHAR2, pobj IN VARCHAR2) IS

     tobjNum NUMBER;
    BEGIN
     BEGIN
       /* If we dont know the objno already (from ctx) then query */
       if ddlObjNum = -1 THEN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getDDLObjInfo: objname '||pobj||' user '||powner||
                ' objtype '||ddlobjType);
        END IF;
         getObjType(objtype,ddlObjType);
         /* Check if owner# is known and query accordingly */
         IF ddlObjUserId = -1 THEN
            IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
                "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getDDLObjInfo: ddlObjUserId is -1');
            END IF;
           select o.obj#, u.user# into ddlObjNum , ddlObjUserId
           from sys.obj$ o, sys.user$ u where
           o.name = pobj and u.name = powner and o.owner# = u.user# and
           o.type# = ddlObjType and o.subname is NULL and o.remoteowner is null and o.linkname is null; -- subname is NULL means only the most recent type
         ELSE
            IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
                "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getDDLObjInfo: ddlObjUserId is '||ddlObjUserId);
            END IF;
           select o.obj#, u.user# into ddlObjNum , ddlObjUserId
           from sys.obj$ o, sys.user$ u where
           o.name = pobj and o.owner# = u.user# and u.user# = ddlObjUserId and
           o.type# = ddlObjType and o.subname is NULL  and o.remoteowner is null and o.linkname is null;
         END IF;
        /* If obj# is known but owner is not known then populate it */
       ELSIF ddlObjUserId = -1 THEN
          IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
              "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getDDLObjInfo: ddlObjUserId is  -1 and ddlObjNum is -1' );
          END IF;
          select o.owner# into ddlObjUserId from sys.obj$ o
          where o.obj# = ddlObjNum  and o.subname is NULL  and o.remoteowner is null and o.linkname is null;
       END IF;

       IF objtype = 'TABLE' THEN
         tobjNum := ddlObjNum;
         ddlBaseObjNum := ddlObjNum;
         ddlBaseObjUserId := ddlObjUserId;

         IF ddlBaseObjProperty = -1 THEN
           IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
              "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getDDLObjInfo: ddlBaseObjproper is -1, obj# is '||tobjNum);
           END IF;
           select t.property into ddlBaseObjProperty from sys.tab$ t where
           obj# = tobjNum;
         END IF;
       END IF;
     EXCEPTION WHEN NO_DATA_FOUND THEN
       ddlObjNum := -1;
       ddlObjUserId := -1;
       ddlBaseObjUserId := -1;
       ddlBaseObjNum := -1;
       ddlBaseObjProperty := -1;
     WHEN OTHERS THEN
       --dbms_output.put_line('getDDLObjInfo:'||SQLERRM);
      RAISE;
     END;

    END getDDLObjInfo;

    /*
    PROCEDURE GETTABLEFROMINDEX
    Get table owner/name referenced in CREATE INDEX
    param[in] STMT                           VARCHAR2                DDL statement test
    param[in] ORA_OWNER                      VARCHAR2                Owner of index
    param[in] ORA_NAME                       VARCHAR2                Name of index
    param[out] TABLE_OWNER                    VARCHAR2               Table owner referenced in index
    param[out] TABLE_NAME                     VARCHAR2               Table name referenced in index
    param[out] OTYPE                         VARCHAR2                TABLE or CLUSTER

    remarks Reason for this pedestrian function (parsing of SQL) is that we must use Before DDL trigger
    which implies CREATEd object doesn't exist yet and can't be queried against DB. Also, name of
    base object cannot wait for extract resolution.
    */
    PROCEDURE getTableFromIndex (
                                 stmt IN VARCHAR2,
                                 ora_owner IN VARCHAR2,
                                 ora_name IN VARCHAR2,
                                 table_owner OUT NOCOPY VARCHAR2,
                                 table_name OUT NOCOPY VARCHAR2,
                                 otype OUT NOCOPY VARCHAR2)
    IS

    cStmt VARCHAR2(32767);
    sObj VARCHAR2(400);
    quoNum NUMBER;
    posOn NUMBER;
    counter NUMBER;
    unquotedStmt VARCHAR2(32767);
    unquotedStmtPos NUMBER;
    unquotedStmtLen NUMBER;
    nextDoubleQuotePos NUMBER;
    tName VARCHAR2(32767);
    word1 VARCHAR2(32767) := '';
    word2 VARCHAR2(32767) := '';
    posStart NUMBER;
    posEnd NUMBER;
    posDot NUMBER;

    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering getTableFromIndex()');
        END IF;

        cStmt := removeSQLComments (substr (stmt, 1, 32767 - 100));

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Remove comments, new = [' || cStmt || ']');
        END IF;
        -- normalize text
        cStmt := REPLACE (cStmt, chr(10), ' ');
        cStmt := REPLACE (cStmt, chr(13), ' ');
        cStmt := REPLACE (cStmt, chr(9), ' ');

        -- Convert the stmt into upper case and leave the quoted
        -- identifiers intact since they are case sensitive.
        cStmt := convertToUpper (cStmt);

        -- look for index keyword first, it must be here
        sObj := 'INDEX';
        posOn := instr (cStmt, sObj, 1);

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Found keyword index, position = [' || posOn || ']');
        END IF;

        -- look for table name after ON keyword
        -- look for the first unquoted ON keyword
        -- Considering the special case like:
        --     create index "ON"."ON"ON"ON"."ON" (col_1);

        -- Count the occurrence of double quote.
        --  The count of the double quotes equals to the difference between
        --  the orignial statment and the statment without double quotes.
        quoNum := length(stmt)-length(replace(stmt, '"'));
        sObj := ' ON ';
        posOn := 0;
        unquotedStmtPos := 1;


        -- The basic idea to find the ON keyword is first to look for the
        -- unquoted segments and to ignore the quoted identifiers in the SQL
        -- statement. Then, to look for the ON keyword in the unqutoed text.
        -- The ON keyword should be surrounded by delimiters,
        -- which should either be space or double quote.

        IF quoNum = 0 THEN
            -- If there is no double quotes in the statement,
            -- The first occurence of ' ON ' is the location of the ON keyword.
            posOn := instr (cStmt, sObj, 1);
        ELSE
            WHILE posOn = 0
            LOOP
                -- Look for the next double quote
                -- The text between the current double quote and the next
                -- double quote is case-insensitive.
                -- nextDoubleQuotePos keeps the track of the end position
                -- of the current unquoted text.
                nextDoubleQuotePos := instr(cStmt, '"', unquotedStmtPos+1, 1);

                -- Calculate the length of the unquoted sql statement
                -- unquotedStmtLen keeps the track of the length of the
                -- unquoted statment.
                IF nextDoubleQuotePos = 0 THEN
                    -- If there is no more double quote in the sql statement
                    -- Then the rest of the statement is case-insensitive
                    unquotedStmtLen := length(cStmt) - unquotedStmtPos + 1;
                ELSE
                    unquotedStmtLen := nextDoubleQuotePos - unquotedStmtPos + 1;
                END IF;

                -- Extract the current unquoted sql statement
                unquotedStmt := substr(cStmt, unquotedStmtPos, unquotedStmtLen);

                -- Double quote could also be used as delimiter
                unquotedStmt := replace(unquotedStmt, '"', ' ');
                -- posOn keeps track the position of the ON keyword
                posOn := instr (unquotedStmt, sObj, 1);

                -- If the ON keyword is found, then posOn should be
                -- a Non-zero value.
                IF posOn <> 0 THEN
                    -- Add the offset of the current segment
                    posOn := posOn + unquotedStmtPos - 1;
                END IF;

                -- Look for the position of the starting position of
                -- the next unquoted segment, which is the position of
                -- the first double quote after the next double quote.
                -- The text between the next double quote and
                -- the double quote after that is a case-sensitive identifier.

                unquotedStmtPos := instr (cStmt, '"',
                                          nextDoubleQuotePos + 1,
                                          1);

                -- If there is no more double quote, exit the loop.
                EXIT WHEN unquotedStmtPos = 0;

            END LOOP;
        END IF;

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'position of ON = [' || posOn || ']');
        END IF;

        IF posOn <> 0 THEN
            tName := substr (cStmt, posOn + length (sObj) - 1);
        END IF;


        tName := trim (both ' ' FROM tName);

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Found position of Table name = [' || tname || ']');
        END IF;

        -- look out for clusters (indexing clusters)
        IF substr (upper (tName), 1, 7) = 'CLUSTER' THEN
            tName := substr (tName, 8);
            tName := trim (both ' ' FROM tName);
            otype := 'CLUSTER';
        ELSE
            otype := 'TABLE';
        END IF;

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'CREATE INDEX, interim (1) = [' || tName || '], ' || ascii (substr (tName, 12, 1)));
        END IF;

        -- parse table name by figuring out
        -- what kind of notation is used,
        -- get owner name as well or use the same as index's

	-- parse index owner and index name
	-- if owner is missing, do not assume index owner is ora_owner.

	posStart := instr(tName, '"', 1, 1);
	posEnd := instr(tName, '"', 1, 2);

	IF posStart = 1 AND posEnd > 0 THEN
	  -- first word begins with quote
	  -- do not remove spaces from a quoted name
	  word1 := substr(tName, 2, posEnd-2);

	  IF length(tName) = posEnd THEN
	     posEnd := 0;
      ELSE
         posEnd := posEnd + 1;
      END IF;
    ELSE
	  posEnd := instr(tName, ' ', 1);
	  posDot := instr(tName, '.', 1);

	  IF posEnd = 0 AND posDot = 0 THEN
	    -- no second word
	    word1 := substr(tName, 1);
	  ELSE
	    IF (posDot > 0 AND (posDot < posEnd OR posEnd = 0)) THEN
	        posEnd := posDot;
        END IF;
	    word1 := substr(tName, 1, posEnd-1);
      END IF;
    END IF;

	IF posEnd > 0 THEN
	  -- there are more words
	  tName := trim(both ' ' FROM substr(tName, posEnd));
	  posDot := instr(tName, '.', 1);

	  -- to find second word, second word must begin with dot
	  IF posDot = 1 THEN
	    tName := trim(both ' ' FROM substr(tName, 2));

	    posStart := instr(tName, '"', 1, 1);
	    posEnd := instr(tName, '"', 1, 2);

	    IF posStart = 1 AND posEnd > 0 THEN
	      -- after trimming, second word begins with quote
	      word2 := substr(tName, 2, posEnd-2);
            ELSE
	      posEnd := instr(tName, ' ', 1);
	      IF posEnd = 0 THEN
		word2 := substr(tName, 1);
                ELSE
		word2 := substr(tName, 1, posEnd-1);
	      END IF;
                END IF;
            END IF;
        END IF;

	IF word2 IS NULL THEN
	  table_owner := upper(ora_owner);
	  table_name := word1;
	ELSE
	  table_owner := word1;
	  table_name := word2;
        END IF;

	-- index on table has '(' following the table name
	posEnd := instr(table_name, '(', 1);
	IF posEnd > 0 THEN
	  table_name := trim(both ' ' FROM substr(table_name, 1, posEnd-1));
        END IF;

        EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'getTableFromIndex' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END;


    /*
    PROCEDURE GETOBJECTTABLETYPE
    Get type owner/name referenced in CREATE TABLE .. OF .. (object table)
    param[in] STMT                           VARCHAR2                DDL statement test
    param[in] ORA_OWNER                      VARCHAR2                Owner of table
    param[in] ORA_NAME                       VARCHAR2                Name of table
    param[out] TYPE_OWNER                    VARCHAR2                Type owner, in upper case
    param[out] TYPE_NAME                     VARCHAR2                Type name, in upper case
    param[out] IS_OBJECT                     VARCHAR2                1 if this is object type, 0 otherwise

    remarks Reason for this pedestrian function (parsing of SQL) is that we must use Before DDL trigger
    which implies CREATEd object doesn't exist yet and can't be queried against DB. If type_name is empty,
    this is NOT object table.
    */
    PROCEDURE getObjectTableType (
                                 stmt IN VARCHAR2,
                                 ora_owner IN VARCHAR2,
                                 ora_name IN VARCHAR2,
                                 type_owner OUT NOCOPY VARCHAR2,
                                 type_name OUT NOCOPY VARCHAR2,
                                 is_object OUT VARCHAR2,
                                 is_xml OUT VARCHAR2)
    IS

    cStmt VARCHAR2(32767);
    sObj VARCHAR2(400);
    lenPos1 NUMBER;
    objPos1 NUMBER;
    lenPos2 NUMBER;
    objPos2 NUMBER;
    lenPos3 NUMBER;
    objPos3 NUMBER;
    lenPos4 NUMBER;
    objPos4 NUMBER;
    lenPos NUMBER;
    objPos NUMBER;
    restP VARCHAR2(32767);
    posOn NUMBER;
    tName VARCHAR2(32767);
    word1 VARCHAR2(32767) := '';
    word2 VARCHAR2(32767) := '';
    posStart NUMBER;
    posEnd NUMBER;
    posDot NUMBER;

    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering getObjectTableType()');
        END IF;

        is_object := 'NO';
        is_xml := 'NO';

        cStmt := removeSQLComments (substr (stmt, 1, 32767 - 100));

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Get object type, new = [' || cStmt || ']');
        END IF;

        -- normalize text
        cStmt := REPLACE (cStmt, chr(10), ' ');
        cStmt := REPLACE (cStmt, chr(13), ' ');
        cStmt := REPLACE (cStmt, chr(9), ' ');

        cStmt := upper (cStmt);

        -- look for table keyword first, it must be here
        sObj := 'TABLE';
        posOn := instr (cStmt, sObj, 1);

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Found keyword table, position = [' || posOn || ']');
        END IF;

        -- find table name and get passed it
        -- try al different object name combinations that are valid
        sObj := upper(ora_name);
        objPos1 := instr (cStmt, sObj , posOn);
        lenPos1 := length (sObj);

        sObj := '"' || upper(ora_name) || '"';
        objPos2 := instr (cStmt, sObj, posOn);
        lenPos2 := length (sObj);

        sObj := upper(ora_owner) || '.' || '"' || upper(ora_name) || '"';
        objPos3 := instr (cStmt, sObj, posOn);
        lenPos3 := length (sObj);

        sObj := '"' || upper(ora_owner) || '"' || '.' || '"' || upper(ora_name) || '"';
        objPos4 := instr (cStmt, sObj, posOn);
        lenPos4 := length (sObj);

        objPos := length (cStmt);

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'objPos1 = [' || objPos1 || ']');
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'objPos2 = [' || objPos2 || ']');
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'objPos3 = [' || objPos3 || ']');
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'objPos4 = [' || objPos4 || ']');
        END IF;

        -- find valid name that comes up first
        IF objPos1 <> 0 AND objPos1 < objPos THEN
            objPos := objPos1;
            lenPos := lenPos1;
        END IF;
        IF objPos2 <> 0 AND objPos2 < objPos THEN
            objPos := objPos2;
            lenPos := lenPos2;
        END IF;
        IF objPos3 <> 0 AND objPos3 < objPos THEN
            objPos := objPos3;
            lenPos := lenPos3;
        END IF;
        IF objPos4 <> 0 AND objPos4 < objPos THEN
            objPos := objPos4;
            lenPos := lenPos4;
        END IF;

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'objPos = [' || objPos || ']');
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'lenPos = [' || lenPos || ']');
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'stmt = [' || cStmt || ']');
        END IF;
        -- now we have obj pos
        restP := substr (cStmt, objPos + lenPos);
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'object = [' || restP || ']');
        END IF;

        -- look for type name after OF keyword (if there is OF keyword)
        sObj := 'OF ';
        restP := trim (both ' ' FROM restP);
        posOn := instr (restP, sObj, 1);

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'position of OF = [' || posOn || ']');
        END IF;

        IF posOn = 1 THEN
            tName := substr (restP, posOn + length (sObj));
        ELSE
            RETURN; -- this is not object table
        END IF;


        tName := trim (both ' ' FROM tName);

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Found position of Type name = [' || tName || ']');
        END IF;


	-- parse type owner and type name.
	-- if type owner is missing, do not assume type owner
	-- is ora_owner because type can be PUBLIC

	posStart := instr(tName, '"', 1, 1);
	posEnd := instr(tName, '"', 1, 2);

	IF posStart = 1 AND posEnd > 0 THEN
	  -- first word begins with quote
	  word1 := replace(substr(tName, 2, posEnd-2), ' ');
	  IF length(tName) = posEnd THEN
	    posEnd := 0;
	  ELSE
	    posEnd := posEnd + 1;
	  END IF;
	ELSE
	  posEnd := instr(tName, ' ', 1);
	  posDot := instr(tName, '.', 1);

	  IF posEnd = 0 AND posDot = 0 THEN
	    -- no second word
	    word1 := substr(tName, 1);
	  ELSE
	    IF (posDot > 0 AND (posDot < posEnd OR posEnd = 0)) THEN
	      posEnd := posDot;
	    END IF;
	    word1 := substr(tName, 1, posEnd-1);
	  END IF;
	END IF;

	IF posEnd > 0 THEN
	  -- there are more words
	  tName := trim(both ' ' FROM substr(tName, posEnd));
	  posDot := instr(tName, '.', 1);

	  -- to find second word, second word must begin with dot
	  IF posDot = 1 THEN
	    tName := trim(both ' ' FROM substr(tName, 2));

	    posStart := instr(tName, '"', 1, 1);
	    posEnd := instr(tName, '"', 1, 2);

	    IF posStart = 1 AND posEnd > 0 THEN
	      -- after trimming, second word begins with quote
	      word2 := replace(substr(tName, 2, posEnd-2), ' ');
	    ELSE
	      posEnd := instr(tName, ' ', 1);
	      IF posEnd = 0 THEN
		word2 := substr(tName, 1);
	      ELSE
		word2 := substr(tName, 1, posEnd-1);
	      END IF;
	    END IF;
	  END IF;
	END IF;

	IF word2 IS NULL THEN
	  type_owner := '';
	  type_name := word1;
	ELSE
	  type_owner := word1;
	  type_name := word2;
	END IF;

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Type owner.name = [' || type_owner || '.' || type_name || ']');
        END IF;

        is_object := 'YES';

        IF type_name = 'XMLTYPE' AND (type_owner IS NULL OR type_owner = 'SYS') THEN
            is_xml := 'YES';
        END IF;

        EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'getObjectTableType' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END;



    /*
    PROCEDURE DDLTOOLARGE
    React to DDL that is too large (either 32K or 2Mb depending on what is current limit). This
    means inform extract that this DDL is too large.
    param[in] STMT                           VARCHAR2                DDL statement test (first 32K)
    param[in] ORA_OWNER                      VARCHAR2                Owner of object
    param[in] ORA_NAME                       VARCHAR2                Name of object
    param[in] ORA_TYPE                       VARCHAR2                type of object
    param[in] sSize                          NUMBER                  actual size of DDL

    remarks This will put IGNORESIZE: message in marker, which extract knows how to process
    Also, if there was any data in marker, it will be deleted. Note that we always make sure
    to have less than 2Mb of data in marker rows for same marker sequence, because if more, we
    won't be able to process the delete in extract.
    */
    PROCEDURE DDLtooLarge (stmt IN VARCHAR2,
                            ora_owner IN VARCHAR2,
                            ora_name IN VARCHAR2,
                            ora_type IN VARCHAR2,
                            sSize IN NUMBER)
    IS
        outMessage VARCHAR2(32767);
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering DDLtooLarge()');
        END IF;


        -- get marker seqno, or deleting whatever was there currently
        IF "GG_ADMIN" .DDLReplication.currentMarkerSeq IS NULL THEN  -- only if marker seqno not set
            SELECT "GG_ADMIN" ."GGS_MARKER_SEQ" .NEXTVAL INTO "GG_ADMIN" .DDLReplication.currentMarkerSeq FROM dual;
        ELSE
            DELETE FROM "GG_ADMIN" ."GGS_MARKER" WHERE seqNo = "GG_ADMIN" .DDLReplication.currentMarkerSeq;
            "GG_ADMIN" .trace_put_line ('DDL', 'Deleted ' || to_char(SQL%ROWCOUNT) || ' from marker table');
        END IF;

        "GG_ADMIN" .trace_put_line ('DDL', 'Statement too large (marker seq ' || to_char("GG_ADMIN" .DDLReplication.currentMarkerSeq) ||
        ' size ' || to_char (sSize) || '), ignored  [' || substr (stmt, 1, 1000) || ']' );

        -- this message would be caught by extract and extract would print it out as warning (at this time)
        outMessage := 'IGNORESIZE: ' || ora_owner || '.' || ora_name || '(' || ora_type || ') ' ||
            'size (' || to_char (sSize) || ') DDL sequence [' || to_char ("GG_ADMIN" .DDLReplication.currentDDLSeq) ||
            '], marker sequence [' || to_char ("GG_ADMIN" .DDLReplication.currentMarkerSeq) ||
            '], DDL trace log file [' || "GG_ADMIN" .DDLReplication.dumpDir || "GG_ADMIN" .file_separator || 'ggs_ddl_trace.log]';
        INSERT INTO "GG_ADMIN" ."GGS_MARKER" (
            seqNo,
            fragmentNo,
            optime,
            TYPE,
            SUBTYPE,
            marker_text
        )
        VALUES (
            "GG_ADMIN" .DDLReplication.currentMarkerSeq,
            0,
            TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS'),
            'DDL',
            'DDLINFO',
            outMessage
        );
    END;

    /*
    PROCEDURE SAVEMARKERDDL
    Write marker record to marker file. This record is periodically purged
    since extract uses log based extraction for DDL. Record is generally
    split in 4K blocks connected by sequence number.

    param[in] OBJID                          VARCHAR2                object id
    param[in] POWNER                         VARCHAR2                object owner
    param[in] PNAME                          VARCHAR2                object name
    param[in] PTYPE                          VARCHAR2                object type (table, index..)
    param[in] DTYPE                          VARCHAR2                type of DDL (create, alter..)
    param[in] SEQ                            VARCHAR2                sequence number for marker to use
    param[in] HISTNAME                       VARCHAR2                ddl history table name (for extract)
    param[in] OUSER                          VARCHAR2                login user (who dunnit)
    param[in] OBJSTATUS                      VARCHAR2                object status (valid, invalid)
    param[in] INDEXUNIQUE                    VARCHAR2                INDEXUNIQUE or NO (for CREATE/DROP INDEX)
    param[in] mowner                          VARCHAR2                  master owner (base)
    param[in] mname                          VARCHAR2                  master name (base)
    param[in] STMT                           VARCHAR2                actual DDL statement
    param[in] TOIGNORE                       VARCHAR2                if YES, this DDL is written with IGNORE flag (for extract)

    see insertToMarker() - all data is essentially (name, value) pairs packed in strings split up in 4K chunks
    */
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
                             toIgnore VARCHAR2)
    IS
    errorMessage VARCHAR2(32767);
    ddlNum NUMBER;
    ddlCur NUMBER;
    sql_text ora_name_list_t;
    pieceStmt VARCHAR2(4000);
    isObjTab VARCHAR2(130);
    isXMLTab VARCHAR2(130);
    tableTypeOwner VARCHAR2(130);
    tableTypeName VARCHAR2(130);
    rawDDL RAW(4000);
    pieceRaw RAW(4000);
    pieceLen NUMBER;
    charbitRaw RAW(4);
    prop NUMBER;
    nlsSeq NUMBER;
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering saveMarkerDDL()');
        END IF;

        IF iname is null or inumber is null THEN
          SELECT
          instance_number, instance_name
          INTO inumber, iname
          FROM sys.v_$instance;

          IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1:optim', 'Init:iname,inumber');
          END IF;
        END IF;


        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', '', BEGIN_FRAGMENT);
        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDL', 'Marker seqno is '|| to_char(currentMarkerSeq));
        END IF;

        ddlNum := ora_sql_txt(sql_text );

        rawDDL := '';
        ddlCur := 1;

        FOR i IN 1..ddlNum LOOP
            pieceRaw := utl_raw.cast_to_raw(sql_text(i));
            IF (utl_raw.length(rawDDL) + utl_raw.length(pieceRaw)) > ((4000 / 4) * 3) THEN
                -- convert rawDDL to WHOLE characters
                pieceStmt := substr(utl_raw.cast_to_varchar2(rawDDL), 1);
                -- get the length of WHOLE characters in bytes
                pieceLen := lengthb(pieceStmt);
                charbitRaw := '';
                -- if the 'whole character' length in bytes is less than the raw length there
                -- is a split character at the end
                IF (pieceLen < utl_raw.length(rawDDL)) THEN
                    IF trace_level >= 2 THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'Multi-byte split detected');
                    END IF;
                    -- keep hold of partial character
                    charbitRaw := utl_raw.substr(rawDDL, pieceLen+1);
                END IF;
                pieceStmt := replace_string(pieceStmt, chr(0), ' ');

                -- flash out current block.
                IF ddlCur = 1 THEN
                    -- first one less then 4K is used with old parsing
                    -- note that this is ADD_FRAGMENT, above one is ADD_FRAGMENT_AND_FLUSH to make it final
                    -- (this is first of many, while above is first of one, i.e. the only one, such as short DDL)
                    insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                                    itemHeader (MK_DDLSTATEMENT, '', '', pieceStmt, ITEM_HEAD),
                                    ADD_FRAGMENT);
                    IF trace_level >= 2 THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'Add piece of DDL (ADD_FRAGMENT - HEAD): ' || pieceStmt);
                    END IF;
                ELSE
                    -- for the rest, use fragments, starting with 2
                    insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                                    itemHeader (MK_DDLSTATEMENT, '', '', pieceStmt, ITEM_DATA),
                                    ADD_FRAGMENT);
                    IF trace_level >= 2 THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'Add piece of DDL (ADD_FRAGMENT - DATA): ' || pieceStmt);
                    END IF;
                END IF;

                ddlCur := ddlCur + 1;
                -- set rawDDL to partial character (if any)
                rawDDL := charbitRaw;
            END IF;
            rawDDL := utl_raw.concat(rawDDL, pieceRaw);
            IF trace_level >= 2 THEN
                "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'rawDDL bytes: ' || rawtohex(rawDDL));
            END IF;
        END LOOP;

        -- check if remainning exists.
        IF (utl_raw.length(rawDDL) > 0) THEN
            pieceStmt := replace_string(utl_raw.cast_to_varchar2(rawDDL), chr(0), ' ');

            IF ddlCur = 1 THEN
                -- this is only DDL block writtent to.
                insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                                itemHeader (MK_DDLSTATEMENT, '', '', pieceStmt, ITEM_WHOLE)
                                , ADD_FRAGMENT_AND_FLUSH);
                IF trace_level >= 2 THEN
                    "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'Add whole DDL (FRAGMENT_AND_FLUSH - WHOLE): ' || pieceStmt);
                END IF;
            ELSE
                -- every next one will be fetched based on fragment No (starting with 2)
                insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                                itemHeader (MK_DDLSTATEMENT, '', '', pieceStmt, ITEM_TAIL)
                                , ADD_FRAGMENT_AND_FLUSH);
                IF trace_level >= 2 THEN
                    "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'Add piece of DDL (FRAGMENT_AND_FLUSH - TAIL): ' || pieceStmt);
                END IF;
            END IF;
        END IF;

        -- this data must be smaller than DDL_EXTERNAL_OVERHEAD from ddl.h
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MD_TAB_MARKERSEQNO, '', '', to_char ("GG_ADMIN" .DDLReplication.currentMarkerSeq), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_OBJECTID, '', '', objid, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MD_TAB_SEQUENCEROWID, '', '', currentRowid, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_OBJECTOWNER, '', '', powner, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        IF ptype = 'COLUMN' AND dtype = 'COMMENT' THEN
            -- as per other comment on COMMENT on COLUMN we cannot support names that contain dots
            insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                            itemHeader (MK_OBJECTNAME, '', '', substr (pname, 1, instr (pname,'.') -1), ITEM_WHOLE)
                            , ADD_FRAGMENT);
        ELSE
            insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                            itemHeader (MK_OBJECTNAME, '', '', pname, ITEM_WHOLE)
                            , ADD_FRAGMENT);
        END IF;
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_MASTEROWNER, '', '', mowner, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_MASTERNAME, '', '', mname, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_OBJECTTYPE, '', '', ptype, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_DDLTYPE, '', '', dtype, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_DDLSEQ, '', '', seq, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_DDLHIST, '', '', histname, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_LOGINUSER, '', '', ouser, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_TAB_VERSIONINFO, '', '', lv_version, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_TAB_VERSIONINFOCOMPAT, '', '', lv_compat, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_TAB_VALID, '', '', objstatus, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_INSTANCENUMBER, '', '', to_char (inumber), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_INSTANCENAME, '', '', iname, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MD_TAB_ISINDEXUNIQUE, '', '', indexUnique, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        IF toIgnore = 'YES' THEN  -- do not make marker record bigger unnecessarily
            insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_TAB_TOIGNORE, '', '', toIgnore, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        END IF;

        isObjTab := 'NO';
        isXMLTab := 'NO';
        BEGIN
            -- object table query
            SELECT MOD(property, POWER(2, 64))
            INTO prop
            FROM sys.tab$
            WHERE obj# = objid;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                prop := 0;
        END;

        IF bitand (prop, OBJTAB) = OBJTAB THEN
            isObjTab := 'YES';

            BEGIN
                -- XMLType table query
                SELECT decode (max (bitand (flags, XMLTAB)), XMLTAB, 'YES', 'NO')
                INTO isXMLTab
                FROM sys.opqtype$
                WHERE obj# = objid and type = 1;
            EXCEPTION
                WHEN OTHERS THEN
                    IF instr (raisable_errors, to_char (SQLCODE, 'S00000')) > 0 THEN
                        RAISE;
                    END IF;
                    isXMLTab := 'NO';
            END;

            IF trace_level >= 1 THEN
                "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'isXMLTab = [' || isXMLTab || ']');
            END IF;

        END IF;

        IF ptype = 'TABLE' AND dtype = 'CREATE' THEN
            "GG_ADMIN" .DDLReplication.getObjectTableType (
                stmt,
                powner,
                pname,
                tableTypeOwner,
                tableTypeName,
                isObjTab,
                isXMLTab);
        END IF;

        -- object table processing may happen here in the future (when it's supported)
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_TAB_OBJECTTABLE, '', '', isObjTab, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_TAB_XMLTYPETABLE, '', '', isXMLTab, ITEM_WHOLE)
                        , ADD_FRAGMENT);

        nlsSeq := 0;
        FOR n IN nls_settings LOOP
			nlsSeq := nlsSeq + 1;
			insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_TAB_NLS_PARAM, to_char (nlsSeq), '', n.parameter, ITEM_WHOLE)
                        , ADD_FRAGMENT);
			insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_TAB_NLS_VAL, to_char (nlsSeq), '', n.value, ITEM_WHOLE)
                        , ADD_FRAGMENT);
			IF trace_level >= 1 THEN
				"GG_ADMIN" .trace_put_line ('DDLTRACE1', 'SaveMarkerDDL:NLS:' || n.parameter || '=' ||
					n.value);
			END IF;
        END LOOP;

        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                        itemHeader (MK_TAB_NLS_CNT, '', '', to_char (nlsSeq), ITEM_WHOLE)
                        , ADD_FRAGMENT);

        insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO', '', END_FRAGMENT);

        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'SaveMarkerDDL:');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'saveMarkerDDL: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;

    END saveMarkerDDL;

    /*
    FUNCTION REPLACE_STRING RETURNS VARCHAR2
    Find the search string in item string, and substitute all occurances with
    replace string.
    param[in] ITEM         VARCHAR2   String to be processed
    param[in] SEARCHSTR    VARCHAR2   String to be searched with
    param[in] REPLACESTR   VARCHAR2   String to be replaced with

    return replaced string
    */
    FUNCTION replace_string ( item       VARCHAR2,
                              searchStr  VARCHAR2,
                              replaceStr VARCHAR2 )
    RETURN VARCHAR2
    IS
    head VARCHAR2 (32767) := '';
    errorMessage VARCHAR2(32767);
    pos1 NUMBER := 1;
    pos2 NUMBER := 1;
    itemRaw RAW (32767) := utl_raw.cast_to_raw(item);
    itemLen NUMBER := LENGTHB(item);
    replaceStrRaw RAW (32767) := utl_raw.cast_to_raw(replaceStr);
    searchStrLen NUMBER := LENGTHB(searchStr);
    appendLen NUMBER := 0;
    BEGIN
       IF "GG_ADMIN" .DDLReplication.trace_level >= 2 THEN
          "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'Entering replace_string()');
       END IF;

       -- Early out, NULL passed in
       IF item IS NULL THEN
          RETURN item;
       END IF;

       -- Find the first occurance of search string
       pos1 := INSTRB( item, searchStr );

       -- Early out, search string not found
       IF pos1 = 0 THEN
          RETURN item;
       END IF;

       -- Save item from begining till first position, into head
       head := SUBSTRB(item, 1, pos1-1);

       -- Process loop
       LOOP

         IF (pos1 + searchStrLen) > itemLen THEN
            -- 1) Search string is at the end of item
            --    Append to head:
            --    a) The replace string
            head := utl_raw.cast_to_varchar2( utl_raw.cast_to_raw(head) ||
                                              replaceStrRaw );
            EXIT;
         ELSE
            -- Find second occurence of search string
            pos2 := INSTRB( item, searchStr, pos1 + searchStrLen );
         END IF;

         IF pos2 = 0 THEN
            -- 2) Second occurence of search string not found
            --    Append to head:
            --    a) The replace string
            --    b) The remaing item after first occurence of search string
            head := utl_raw.cast_to_varchar2( utl_raw.cast_to_raw(head) ||
                                              replaceStrRaw             ||
                                              utl_raw.SUBSTR
                                              ( itemRaw,
                                                pos1 + searchStrLen
                                              )
                                            );
            EXIT;
         ELSE

            -- Find the length of item that will be appended after replace str
            appendLen := pos2 - (pos1 + searchStrLen);

            IF appendLen = 0 THEN
              -- 3) Second occurence of search string found
              --    Append to head:
              --    a) The replace string
              head := utl_raw.cast_to_varchar2( utl_raw.cast_to_raw(head) ||
                                                replaceStrRaw );
            ELSE
              -- 4) Second occurence of search string found
              --    Append to head:
              --    a) The replace string
              --    b) The item between first and second occurence of search str
              head := utl_raw.cast_to_varchar2( utl_raw.cast_to_raw(head) ||
                                                replaceStrRaw             ||
                                                utl_raw.SUBSTR
                                                ( itemRaw,
                                                  pos1 + searchStrLen,
                                                  appendLen
                                                )
                                              );
            END IF;
            -- move forward
            pos1 := pos2;
         END IF;

       END LOOP;

       IF trace_level >= 2 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'replace_string: head = ['
                                        || head || ']');
       END IF;

       RETURN head;
    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'replace_string: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END replace_string;

    /*
    FUNCTION ESCAPE_STRING RETURNS VARCHAR2
    Escape all special chars in string. This way string's start and end can be safely
    figured out (in delimited string). This is because tables and column names can have
    any character (except double quote in oracle).
    param[in] ITEM                           VARCHAR2                string to escape
    param[in] ITEMMODE                       NUMBER                  ITEM_WHOLE, ITEM_HEAD, ITEM_DATA, ITEM_TAIL

    return escaped string

    remarks see ITEM_* description under itemHeader function
    */
    FUNCTION escape_string (
                            item VARCHAR2,
                            itemMode NUMBER)
    RETURN VARCHAR2
    IS
    retVal VARCHAR2 (32767);
    errorMessage VARCHAR2(32767);
    ec varchar2(2);
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 2 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'Entering escape_string()');
        END IF;

        retVal := item;
        -- the following replacements will work since UTF-8 (multibyte) and ASCII overlap in full
        -- in other words these characters cannot appear as part of multibytes
        -- the body formatting is always there regardless of head or tail
        FOR i IN 1..escapeCharsLen LOOP
            ec := SUBSTR (escapeChars, i, 1);
            retVal := replace_string (retVal, ec, '\' || ec);
        END LOOP;

        -- if we need head, include head formatting
        IF itemMode = ITEM_WHOLE OR itemMode = ITEM_HEAD THEN
            retVal := '''' || retVal;
        END IF;

        -- if we need tail, include tail formatting
        IF itemMode = ITEM_WHOLE OR itemMode = ITEM_TAIL THEN
            retVal := retVal || '''';
        END IF;

        IF trace_level >= 2 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'escape_string: retVal = [' || retVal || ']');
        END IF;

        RETURN retVal;
    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'escape_string: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END escape_string;

    /*
    PROCEDURE BEGINHISTORY
    Starts DDL history table record.
    Since record can span many rows, we have beginning fragment, fragments and ending fragment
    (this way insertToMarker knows when to stop the record)

    see insertToMarker
    */
    PROCEDURE beginHistory
    IS
    errorMessage VARCHAR2(32767);
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering beginHistory()');
        END IF;

        insertToMarker (DDL_HISTORY, '', '', '', BEGIN_FRAGMENT);

    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'beginHistory: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END beginHistory;

    /*
    PROCEDURE SETTRACING
    Set tracing level for code based on what's in setup table.
    Tracing level (and other parameters0 are kept in setup table in form of (name,value) pairs
    Tracing level is externally set by ddl_tracelevel, we only read it here and set the tracing
    variable so tracing in PL/SQL code knows when to trace

    see ddl_tracelevel.sql
    */
    PROCEDURE setTracing
    IS
    errorMessage VARCHAR2(32767);
    tl VARCHAR2(400);
    BEGIN

        SELECT VALUE
        INTO tl
        FROM "GG_ADMIN" ."GGS_SETUP"
        WHERE property = 'DDL_TRACE_LEVEL';

        if upper (tl) = 'NONE' THEN
            trace_level := -1;
        ELSE
            trace_level := to_number (tl);
        END IF;

        SELECT VALUE
        INTO tl
        FROM "GG_ADMIN" ."GGS_SETUP"
        WHERE property = 'DDL_STAYMETADATA';

        if tl = 'ON' THEN
            IF trace_level >= 0 THEN
                "GG_ADMIN" .trace_put_line ('DDL', 'Metadata is not queried (STAYMETADATA is ON)');
            END IF;
            stay_metadata := 1;
        ELSE
            stay_metadata := 0;
        END IF;

        SELECT VALUE
        INTO tl
        FROM "GG_ADMIN" ."GGS_SETUP"
        WHERE property = 'DDL_SQL_TRACING';

        sql_trace := to_number (tl);

        SELECT VALUE
        INTO tl
        FROM "GG_ADMIN" ."GGS_SETUP"
        WHERE property = '_USEALLKEYS';

        useAllKeys := to_number (tl);

        SELECT VALUE
        INTO tl
        FROM "GG_ADMIN" ."GGS_SETUP"
        WHERE property = 'ALLOWNONVALIDATEDKEYS';

        allowNonValidatedKeys := to_number (tl);

        SELECT VALUE
        INTO tl
        FROM "GG_ADMIN" ."GGS_SETUP"
        WHERE property = '_LIMIT32K';

        useLargeDDL := 1 - to_number (tl);


        -- get trace file directory location to include in error message
        SELECT VALUE INTO dumpDir
        FROM sys.v_$parameter
        WHERE name = 'user_dump_dest' ;

        -- we do not call set_sql_trace (false) any more, because this requires executor of
        -- DDL to have ALTER SESSION priv, which is not given
        -- we also post a note in ddl_trace_off.sql to exit that session for end of tracing
        -- to take place (otherwise was automatic until now)
        IF sql_trace = 1 THEN
            "GG_ADMIN" .trace_put_line ('DDL', 'Turning on Oracle SQL tracing');
            dbms_session.set_sql_trace(true);
        END IF;

        IF useAllKeys = 1 THEN
            "GG_ADMIN" .trace_put_line ('DDL', 'Using all keys method for UK');
        END IF;

        IF allowNonValidatedKeys = 1 THEN
            "GG_ADMIN" .trace_put_line ('DDL', 'Allow non-validated keys');
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            "GG_ADMIN" .trace_put_line ('DDL', 'Tracing set to zero (data not found)');
            trace_level := 0;
        WHEN OTHERS THEN
            errorMessage := 'setTracing: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END setTracing;


    /*
    PROCEDURE ENDHISTORY
    Ends DDL history table record - there must have been begin history and some
    fragments before it.

    remarks Extract reads these fragments as a transaction (since it's part of DDL) so no
    actual 'end marker' is required.

    see insertToMarker
    */
    PROCEDURE endHistory
    IS
    errorMessage VARCHAR2(32767);
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering endHistory()');
        END IF;

        insertToMarker (DDL_HISTORY, '', '', '', END_FRAGMENT);
    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'endHistory: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END endHistory;


    /*
    PROCEDURE GETVERSION
    Get version of Oracle (true and compatability versions)

    remarks this is passed to extract trail records for auditing
    */
    PROCEDURE getVersion
    IS
    errorMessage VARCHAR2(32767);
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering getVersion()');
        END IF;
        IF length(lv_version) > 0 AND length(lv_compat) > 0 THEN
            RETURN; -- we already have the values
        END IF;
		BEGIN
			SELECT value INTO lv_version
			FROM "GG_ADMIN" ."GGS_STICK"
			WHERE property = 'lv_version';
			SELECT value INTO lv_compat
			FROM "GG_ADMIN" ."GGS_STICK"
			WHERE property = 'lv_compat';
			IF trace_level >= 1 THEN
				"GG_ADMIN" .trace_put_line ('DDL', 'DB Version from cache:' || lv_version || 'DB Compatability Version: ' || lv_compat);
			END IF;
			RETURN;
		EXCEPTION
			WHEN OTHERS THEN
				IF instr (raisable_errors, to_char (SQLCODE, 'S00000')) > 0 THEN
					RAISE;
				END IF;
				NULL;  -- nothing, not in cache yet
		END;
        dbms_utility.db_version (lv_version, lv_compat);
        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDL', 'DB Version computed: ' || lv_version || 'DB Compatability Version: ' || lv_compat);
        END IF;
        BEGIN
			INSERT INTO "GG_ADMIN" ."GGS_STICK" (property, value)
			VALUES ('lv_version', lv_version);
			INSERT INTO "GG_ADMIN" ."GGS_STICK" (property, value)
			VALUES ('lv_compat', lv_compat);
		EXCEPTION
			WHEN OTHERS THEN
				IF instr (raisable_errors, to_char (SQLCODE, 'S00000')) > 0 THEN
					RAISE;
				END IF;
				NULL;
		END;
    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'getVersion: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END getVersion;


    /*
    FUNCTION TRACE_HEADER_NAME RETURNS VARCHAR2
    Under tracing level 2, whenever we record piece of information to DDL history table
    or marker table, we trace it. Each piece has a code: this function returns human
    readable code for abbreviated marker/history code.
    param[in] HEADERTYPE                     VARCHAR2         type of info recorded

    return actual human readable code for tracing purposes
    */
    FUNCTION trace_header_name (
                                headerType IN VARCHAR2)
    RETURN VARCHAR2
    IS
    BEGIN
        IF headerType = MD_TAB_USERID THEN RETURN 'MD_TAB_USERID'; END IF;
        IF headerType = MD_COL_NAME THEN RETURN 'MD_COL_NAME'; END IF;
        IF headerType = MD_COL_NUM THEN RETURN 'MD_COL_NUM'; END IF;
        IF headerType = MD_COL_SEGCOL THEN RETURN 'MD_COL_SEGCOL'; END IF;
        IF headerType = MD_COL_TYPE THEN RETURN 'MD_COL_TYPE'; END IF;
        IF headerType = MD_COL_LEN THEN RETURN 'MD_COL_LEN'; END IF;
        IF headerType = MD_COL_ISNULL THEN RETURN 'MD_COL_ISNULL'; END IF;
        IF headerType = MD_COL_PREC THEN RETURN 'MD_COL_PREC'; END IF;
        IF headerType = MD_COL_SCALE THEN RETURN 'MD_COL_SCALE'; END IF;
        IF headerType = MD_COL_CHARSETID THEN RETURN 'MD_COL_CHARSETID'; END IF;
        IF headerType = MD_COL_CHARSETFORM THEN RETURN 'MD_COL_CHARSETFORM'; END IF;
        IF headerType = MD_COL_ALT_NAME THEN RETURN 'MD_COL_ALT_NAME'; END IF;
        IF headerType = MD_COL_ALT_TYPE THEN RETURN 'MD_COL_ALT_TYPE'; END IF;
        IF headerType = MD_COL_ALT_PREC THEN RETURN 'MD_COL_ALT_PREC'; END IF;
        IF headerType = MD_COL_ALT_CHAR_USED THEN RETURN 'MD_COL_ALT_CHAR_USED'; END IF;
        IF headerType = MD_COL_ALT_XML_TYPE THEN RETURN 'MD_COL_ALT_XML_TYPE'; END IF;
        IF headerType = MD_TAB_COLCOUNT THEN RETURN 'MD_TAB_COLCOUNT'; END IF;
        IF headerType = MD_TAB_DATAOBJECTID THEN RETURN 'MD_TAB_DATAOBJECTID'; END IF;
        IF headerType = MD_TAB_CLUCOLS THEN RETURN 'MD_TAB_CLUCOLS'; END IF;
        IF headerType = MD_TAB_TOTAL_COL_NUM THEN RETURN 'MD_TAB_TOTAL_COL_NUM'; END IF;
        IF headerType = MD_TAB_LOG_GROUP_EXISTS THEN RETURN 'MD_TAB_LOG_GROUP_EXISTS'; END IF;
        IF headerType = MD_COL_ALT_LOG_GROUP_COL THEN RETURN 'MD_COL_ALT_LOG_GROUP_COL'; END IF;
        IF headerType = MD_TAB_VALID THEN RETURN 'MD_TAB_VALID'; END IF;
        IF headerType = MD_TAB_SUBPARTITION THEN RETURN 'MD_TAB_SUBPARTITION'; END IF;
        IF headerType = MD_TAB_PARTITION THEN RETURN 'MD_TAB_PARTITION'; END IF;
        IF headerType = MD_TAB_PARTITION_IDS THEN RETURN 'MD_TAB_PARTITION_IDS'; END IF;
        IF headerType = MD_TAB_BLOCKSIZE THEN RETURN 'MD_TAB_BLOCKSIZE'; END IF;
        IF headerType = MD_TAB_OBJECTID THEN RETURN 'MD_TAB_OBJECTID'; END IF;
        IF headerType = MD_TAB_PRIMARYKEY THEN RETURN 'MD_TAB_PRIMARYKEY'; END IF;
        IF headerType = MD_TAB_PRIMARYKEYNAME THEN RETURN 'MD_TAB_PRIMARYKEYNAME'; END IF;
        IF headerType = MD_TAB_PARTITION_TYPE THEN RETURN 'MD_TAB_PARTITION_TYPE'; END IF;
        IF headerType = MD_TAB_OWNER THEN RETURN 'MD_TAB_OWNER'; END IF;
        IF headerType = MD_TAB_NAME THEN RETURN 'MD_TAB_NAME'; END IF;
        IF headerType = MD_TAB_OBJTYPE THEN RETURN 'MD_TAB_OBJTYPE'; END IF;
        IF headerType = MD_TAB_OPTYPE THEN RETURN 'MD_TAB_OPTYPE'; END IF;
        IF headerType = MD_TAB_SCN THEN RETURN 'MD_TAB_SCN'; END IF;
        IF headerType = MK_OBJECTID THEN RETURN 'MK_OBJECTID'; END IF;
        IF headerType = MK_OBJECTOWNER THEN RETURN 'MK_OBJECTOWNER'; END IF;
        IF headerType = MK_OBJECTNAME THEN RETURN 'MK_OBJECTNAME'; END IF;
        IF headerType = MK_MASTEROWNER THEN RETURN 'MK_MASTEROWNER'; END IF;
        IF headerType = MK_MASTERNAME THEN RETURN 'MK_MASTERNAME'; END IF;
        IF headerType = MK_OBJECTTYPE THEN RETURN 'MK_OBJECTTYPE'; END IF;
        IF headerType = MK_DDLTYPE THEN RETURN 'MK_DDLTYPE'; END IF;
        IF headerType = MK_DDLSEQ THEN RETURN 'MK_DDLSEQ'; END IF;
        IF headerType = MK_DDLHIST THEN RETURN 'MK_DDLHIST'; END IF;
        IF headerType = MK_LOGINUSER THEN RETURN 'MK_LOGINUSER'; END IF;
        IF headerType = MK_DDLSTATEMENT THEN RETURN 'MK_DDLSTATEMENT'; END IF;
        IF headerType = MD_TAB_MASTEROWNER THEN RETURN 'MD_TAB_MASTEROWNER'; END IF;
        IF headerType = MD_TAB_MASTERNAME THEN RETURN 'MD_TAB_MASTERNAME'; END IF;
        IF headerType = MD_TAB_MARKERSEQNO THEN RETURN 'MD_TAB_MARKERSEQNO'; END IF;
        IF headerType = MD_TAB_MARKERTABLENAME THEN RETURN 'MD_TAB_MARKERTABLENAME'; END IF;
        IF headerType = MD_TAB_DDLSTATEMENT THEN RETURN 'MD_TAB_DDLSTATEMENT'; END IF;
        IF headerType = MD_TAB_BIGFILE THEN RETURN 'MD_TAB_BIGFILE'; END IF;
        IF headerType = MK_TAB_VERSIONINFO THEN RETURN 'MK_TAB_VERSIONINFO'; END IF;
        IF headerType = MK_TAB_VERSIONINFOCOMPAT THEN RETURN 'MK_TAB_VERSIONINFOCOMPAT'; END IF;
        IF headerType = MK_TAB_VALID THEN RETURN 'MK_TAB_VALID'; END IF;
        IF headerType = MK_INSTANCENUMBER THEN RETURN 'MK_INSTANCENUMBER'; END IF;
        IF headerType = MK_INSTANCENAME THEN RETURN 'MK_INSTANCENAME'; END IF;
        IF headerType = MD_TAB_SEQUENCEROWID THEN RETURN 'MD_TAB_SEQUENCEROWID'; END IF;
        IF headerType = MD_TAB_SEQCACHE THEN RETURN 'MD_TAB_SEQCACHE'; END IF;
        IF headerType = MD_TAB_SEQINCREMENTBY THEN RETURN 'MD_TAB_SEQINCREMENTBY'; END IF;
        IF headerType = MD_TAB_IOT THEN RETURN 'MD_TAB_IOT'; END IF;
        IF headerType = MD_TAB_IOT_OVERFLOW THEN RETURN 'MD_TAB_IOT_OVERFLOW'; END IF;
        IF headerType = MD_COL_ALT_BINARYXML_TYPE THEN RETURN 'MD_COL_ALT_BINARYXML_TYPE'; END IF;
	IF headerType = MD_COL_ALT_LENGTH THEN RETURN 'MD_COL_ALT_LENGTH'; END IF;
        IF headerType = MK_TAB_OBJECTTABLE THEN RETURN 'MK_TAB_OBJECTTABLE'; END IF;
        IF headerType = MK_TAB_TOIGNORE THEN RETURN 'MK_TAB_TOIGNORE'; END IF;
        IF headerType = MK_TAB_NLS_PARAM THEN RETURN 'MK_TAB_NLS_PARAM'; END IF;
        IF headerType = MK_TAB_NLS_VAL THEN RETURN 'MK_TAB_NLS_VAL'; END IF;
        IF headerType = MK_TAB_NLS_CNT THEN RETURN 'MK_TAB_NLS_CNT'; END IF;
        IF headerType = MK_TAB_XMLTYPETABLE THEN RETURN 'MK_TAB_XMLTYPETABLE'; END IF;
        IF headerType = MD_TAB_ENC_MKEYID THEN RETURN 'MD_TAB_ENC_MKEYID'; END IF;
        IF headerType = MD_TAB_ENC_ENCALG THEN RETURN 'MD_TAB_ENC_ENCALG'; END IF;
        IF headerType = MD_TAB_ENC_INTALG THEN RETURN 'MD_TAB_ENC_INTALG'; END IF;
        IF headerType = MD_TAB_ENC_COLKLC THEN RETURN 'MD_TAB_ENC_COLKLC'; END IF;
        IF headerType = MD_TAB_ENC_KLCLEN THEN RETURN 'MD_TAB_ENC_KLCLEN'; END IF;
        IF headerType = MD_COL_ENC_ISENC THEN RETURN 'MD_COL_ENC_ISENC'; END IF;
        IF headerType = MD_COL_HASNOTNULLDEFAULT THEN RETURN 'MD_COL_HASNULLDEFAULT'; END IF;
        IF headerType = MD_COL_ENC_NOSALT THEN RETURN 'MD_COL_ENC_NOSALT'; END IF;
        IF headerType = MD_COL_ENC_ISLOB THEN RETURN 'MD_COL_ENC_ISLOB'; END IF;
        IF headerType = MD_COL_LOB_ENCRYPT THEN RETURN 'MD_COL_LOB_ENCRYPT'; END IF;
        IF headerType = MD_COL_LOB_COMPRESS THEN RETURN 'MD_COL_LOB_COMPRESS'; END IF;
        IF headerType = MD_COL_LOB_DEDUP THEN RETURN 'MD_COL_LOB_DEDUP'; END IF;
        IF headerType = MD_COL_ALT_OBJECTXML_TYPE THEN RETURN 'MD_COL_ALT_OBJECTXML_TYPE'; END IF;
	IF headerType = MD_TAB_XMLTYPETABLE THEN RETURN 'MD_TAB_XMLTYPETABLE'; END IF;
	IF headerType = MD_TAB_TYPETABLE THEN RETURN 'MD_TAB_TYPETABLE'; END IF;
	IF headerType = MD_COL_OPQFLAGS THEN RETURN 'MD_COL_OPQFLAGS'; END IF;
	IF headerType = MD_COL_INTCOL THEN RETURN 'MD_COL_INTCOL'; END IF;
	IF headerType = MD_COL_PROPERTY THEN RETURN 'MD_COL_PROPERTY'; END IF;
	IF headerType = MD_TAB_PROPERTY THEN RETURN 'MD_TAB_PROPERTY'; END IF;

        IF headerType = MD_TAB_SESSION_OWNER THEN RETURN 'MD_TAB_SESSION_OWNER'; END IF;
        RETURN 'UNKNOWN';

    END trace_header_name;

    /*
    FUNCTION ITEMHEADER RETURNS VARCHAR2
    Create a name/value pair that can be simply appended to a string that will be saved to
    either marker or DDL tables.
    param[in] HEADERTYPE                     VARCHAR2                MD or MK constant
    param[in] IDKEY                          VARCHAR2                ID-based accesor key
    param[in] NAMEKEY                        VARCHAR2                NAME-based accessor key
    param[in] VAL                            VARCHAR2                actual value (up to 32K)
    param[in] ITEMMODE                       NUMBER                  ITEM_WHOLE, ITEM_HEAD, ITEM_TAIL, ITEM_DATA

    return a string value that contains all strings escaped and delimited so that simple
    concatenation of strings produced by this function is ready for persistent save
    MODE can be be ITEM_WHOLE (data with full header and footer), ITEM_HEAD (head+data),
    ITEM_TAIL (data+tail), ITEM_DATA (just data)
    */
    FUNCTION itemHeader (headerType IN VARCHAR2, idKey IN VARCHAR2, nameKey IN VARCHAR2, val IN VARCHAR2,
        itemMode IN NUMBER)
    RETURN VARCHAR2
    IS
    -- note: size of retVal is in most cases limited to frag_size (4K) because it is
    -- used with ADD_FRAGMENT, however for marker string building it must be up to
    -- max size (32K), so final limit is really 32K
    retVal VARCHAR2(32767);
    errorMessage VARCHAR2(32767);
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering itemHeader()');
        END IF;

        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'itemHeader: ' || trace_header_name (headerType) ||
                                        '(ID key = [' || idKey || '] NAME key = [' || nameKey || ']) = [' || val || '], ' ||
                                        'itemMode = [' || to_char(itemMode) || ']');
        END IF;


        retVal := '';

        -- when head is needed, include standard DDL head formatting
        IF itemMode = ITEM_WHOLE OR itemMode = ITEM_HEAD THEN
            IF idKey IS NOT NULL THEN
                retVal := ',' || headerType || '(' || escape_string (idKey, ITEM_WHOLE) || ')';
                IF nameKey IS NOT NULL THEN
                    -- the header of a NAME key must always end with suffix '_N' to avoid key collision with ID key
                    retVal := retVal || ',' || headerType || '_N(' || escape_string (nameKey, ITEM_WHOLE) || ')' || '=';
                ELSE
                    retVal := retVal || '=';
                END IF;
            ELSE
                retVal := ',' || headerType || '=';
            END IF;
        END IF;

        -- actual data is always there, regardless of head or tail
        retVal := utl_raw.cast_to_varchar2( utl_raw.cast_to_raw(retVal) ||
                                            utl_raw.cast_to_raw(escape_string (val, itemMode)) );

        -- when tail is needed, include standard DDL tail formatting
        IF itemMode = ITEM_WHOLE OR itemMode = ITEM_TAIL THEN
            retVal := utl_raw.cast_to_varchar2( utl_raw.cast_to_raw(retVal) ||
                                                utl_raw.cast_to_raw(',') );
        END IF;

        IF trace_level >= 2 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'itemHeader: retVal = [' || retVal || ']');
        END IF;
        RETURN retVal;
    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'itemHeader: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END itemHeader;


    /*
    PROCEDURE SAVESEQINFO
    Save owner, name, object id and row id (as of this SCN) of sequence
    to be used to resolve sequence in extract when needed

    param[in] POWNER                         VARCHAR2     owner of sequence
    param[in] PTABLE                         VARCHAR2     name of sequence
    param[in] OPTYPE                         VARCHAR2     type of DDL
    param[in] USERID                         VARCHAR2     id of user who owns the object
    param[in] SEQCACHE                       VARCHAR2     cache value for seq
    param[in] SEQINCREMENTBY                 VARCHAR2     incrementby value for seq
    param[in] TOIGNORE                       VARCHAR2     if DDL is to be ignored in extract

    */
    PROCEDURE saveSeqInfo (
                           powner IN VARCHAR2,
                           pname IN VARCHAR2,
                           optype IN VARCHAR2,
                           userid IN VARCHAR2,
                           seqCache IN NUMBER,
                           seqIncrementBy IN NUMBER,
                           toIgnore IN VARCHAR2)
    IS
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering saveSeqInfo()');
        END IF;

        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_SEQUENCEROWID, '', '', currentRowid, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_OBJECTID, '', '', to_char (currentObjectId), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_NAME, '', '', pname, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_OWNER, '', '', powner, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_OBJTYPE, '', '', 'SEQUENCE', ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_USERID, '', '', userid, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_OPTYPE, '', '', optype, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_SEQCACHE, '', '', to_char (seqCache), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_SEQINCREMENTBY, '', '', to_char (seqIncrementBy), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MK_TAB_TOIGNORE, '', '', toIgnore, ITEM_WHOLE)
                        , ADD_FRAGMENT);

        IF currentObjectId IS NOT NULL THEN
            -- object id can be NULL in CREATE statements
            -- we don't delete alt data because it can cause deadlock. So there is more records with
            -- the same information, but that's fine because in extract we select one only. And these
            -- records can be purged with PURGEDDLHISTORYALT in manager
            BEGIN
				-- populate alt table for resolution of partition DMLs or sequences
				-- it won't matter if there is a duplicate (altObjectId, objectId), it will be handled
				-- we will also record partitions that have been dropped (their ids won't be removed)
                -- but that's fine since those can't show up for DML any more
                INSERT INTO "GG_ADMIN" ."GGS_DDL_HIST_ALT" (
                    altObjectId,
                    objectId,
                    optime)
                VALUES (
                    currentObjectId,
                    currentObjectId,
                    TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')
                );
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert duplicate, handled (5)');
                NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                WHEN NO_DATA_FOUND THEN
                "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert no data found, handled (5)');
                NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                WHEN deadlockDetected THEN
                "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert - deadlock, ignored (5)');
                NULL; -- do nothing, this means somebody else is doing this exact work!
            END;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'saveSeqInfo' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;

    END saveSeqInfo;

    /*
    PROCEDURE GETKEYCOLSUSEALLKEYS
    Add key cols to DDL history. If PK is not present, UK is tried.

    param[in] POWNER                         VARCHAR2     owner of table
    param[in] PTABLE                         VARCHAR2     name of table

    remarks final decision what to use as PK rests with extract. This is USEALLKEYS (old) implementation
    */
    PROCEDURE getKeyColsUseAllKeys (pobjid IN NUMBER,
                          powner IN VARCHAR2,
                          ptable IN VARCHAR2)
    IS
    seq NUMBER;
    errorMessage VARCHAR2(32767);
    realColName VARCHAR2(400);
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering getKeyColsUseAllKeys()');
        END IF;

        seq := 0;
        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Looking for primary key for [(' || pobjid||')'||powner || '.' || ptable || ']');
        END IF;

        FOR pk IN DDLReplication.pk_curs (pobjid,powner, ptable) LOOP
            seq := seq + 1;
            IF seq = 1 THEN
                insertToMarker (DDL_HISTORY, '', '',
                                itemHeader (MD_TAB_PRIMARYKEYNAME, '', '', pk.constraint_name, ITEM_WHOLE)
                                , ADD_FRAGMENT);
            END IF;
            insertToMarker (DDL_HISTORY, '', '',
                            itemHeader (MD_TAB_PRIMARYKEY, to_char (seq), pk.column_name, pk.column_name, ITEM_WHOLE)
                            , ADD_FRAGMENT);
        END LOOP;

        IF seq = 0 THEN
            seq := 0;
            FOR uk IN "GG_ADMIN" .DDLVersionSpecific.uk_curs_all_keys (powner, ptable) LOOP
                seq := seq + 1;
                IF seq = 1 THEN
                    insertToMarker (DDL_HISTORY, '', '',
                                    itemHeader (MD_TAB_PRIMARYKEYNAME, '', '', uk.index_name, ITEM_WHOLE)
                                    , ADD_FRAGMENT);
                END IF;
                -- find real column name if DESC used in column in index definition (oracle generates system one)
                IF uk.descend = 'DESC' THEN
                    SELECT c.default$ INTO realColName
                    FROM sys.obj$  o, sys.col$ c
                    WHERE o.obj# = c.obj#
                        AND c.default$ is not NULL
                        AND o.obj# = pobjid and c.name = uk.column_name;
                ELSE
                    realColName := uk.column_name;
                END IF;
                insertToMarker (DDL_HISTORY, '', '',
                                itemHeader (MD_TAB_PRIMARYKEY, to_char (seq), realColName, realColName, ITEM_WHOLE)
                                , ADD_FRAGMENT);
            END LOOP;
        END IF;
        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Found [' || to_char (seq) || '] columns for primary or unique key');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'getKeyColsUseAllKeys: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END getKeyColsUseAllKeys;



    -- get the key - either a pk, uk or none of the above
    -- param[in] powner owner of table
    -- param[in] ptable table name
    -- stores result in DDL history

    /*
    PROCEDURE GETKEYCOLS
    Add key cols to DDL history. If PK is not present, UK is tried.

    param[in] POWNER                         VARCHAR2     owner of table
    param[in] PTABLE                         VARCHAR2     name of table

    remarks final decision what to use as PK rests with extract
    */
    PROCEDURE getKeyCols (pobjid IN NUMBER,
                          powner IN VARCHAR2,
                          ptable IN VARCHAR2)
    IS
    seqPK NUMBER;
    errorMessage VARCHAR2(32767);
    colNull NUMBER;
    colVirtual NUMBER;
    colUdt NUMBER;
    colSys NUMBER;
    bestKey VARCHAR2(400);
    realColName VARCHAR2(400);
    pkFound NUMBER;
    ukFound NUMBER;
    keyCount NUMBER;
    pkValid NUMBER;
    thereIsNotNullUK NUMBER;
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering getKeyCols()');
        END IF;


        pkFound := 0;
        ukFound := 0;


        seqPK := 1;
        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Looking for primary key for [(' || pobjid ||')'||powner || '.' || ptable || ']');
        END IF;

        FOR pk IN DDLReplication.pk_curs (pobjid, powner, ptable) LOOP
            pkFound := 1;
            IF seqPK = 1 THEN

                IF "GG_ADMIN" .DDLReplication.allowNonvalidatedKeys = 0 THEN
                    SELECT COUNT(*) INTO pkValid
                    FROM dba_constraints
                    WHERE owner = powner AND table_name= ptable AND constraint_name = pk.constraint_name
                    AND validated='VALIDATED'
                    AND status = 'ENABLED';

                    IF pkValid = 0 THEN -- go look for UK if PK not valid
                        pkFound := 0;
                        EXIT;
                    END IF;
                END IF;

                insertToMarker (DDL_HISTORY, '', '',
                                itemHeader (MD_TAB_PRIMARYKEYNAME, '', '', pk.constraint_name, ITEM_WHOLE)
                                , ADD_FRAGMENT);
            END IF;
            insertToMarker (DDL_HISTORY, '', '',
                            itemHeader (MD_TAB_PRIMARYKEY, to_char (seqPK), pk.column_name, pk.column_name, ITEM_WHOLE)
                            , ADD_FRAGMENT);
            seqPK := seqPK + 1;
        END LOOP;

        IF pkFound = 0 THEN
            -- unique key query is now oracle version specific, part of own package
            -- we record info for keys in global temp table, so we do query only once
            FOR uk IN "GG_ADMIN" .DDLVersionSpecific.uk_curs (powner, ptable) LOOP
                ukFound := 1;

                -- find real column name if DESC used in column in index definition (oracle generates system one)
                IF uk.descend = 'DESC' THEN
                    BEGIN
                        SELECT c.default$ INTO realColName
                        FROM sys.obj$ o, sys.col$ c
                        WHERE o.obj# = c.obj#
                            AND c.default$ is not NULL
                            AND o.obj# = pobjid and c.name = uk.column_name;
                    EXCEPTION
                        WHEN OTHERS THEN
                            IF instr (raisable_errors, to_char (SQLCODE, 'S00000')) > 0 THEN
                                RAISE;
                            END IF;
                            "GG_ADMIN" .trace_put_line ('DDLTRACE', 'Error processing query (realColName, getKeyCols) ' || SQLERRM);
                            realColName := uk.column_name;
                    END;
                ELSE
                    realColName := uk.column_name;
                END IF;

                -- find out if columns in key are either null or virtual or udt, no duplicates as queries primary key
                IF trace_level >= 1 THEN
                    "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Querying index  ' || uk.index_name || ' column ' || realColName ||
                        ' obtained name ' || uk.column_name);
                END IF;


                -- this column must be here
                -- if not, we should stop processing

                BEGIN
                    SELECT nullable, virtual, udt, isSys INTO colNull, colVirtual, colUdt, colSys
                    FROM "GG_ADMIN" ."GGS_TEMP_COLS"
                    WHERE seqno = "GG_ADMIN" .DDLReplication.currentMarkerSeq AND colName=uk.column_name;

                    IF trace_level >= 1 THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Index ' || uk.index_name || ' column ' || realColName ||
                            ' colNull ' || colNull || ' colVirtual ' || colVirtual || ' colUDT ' || colUdt || ' colSys ' || colSys);
                    END IF;

                    -- this insert should not fail as we have primary key
                    INSERT INTO "GG_ADMIN" ."GGS_TEMP_UK" (seqNo, keyName, colName, nullable, virtual, udt, isSys)
                    VALUES ("GG_ADMIN" .DDLReplication.currentMarkerSeq, uk.index_name, realColName, colNull, colVirtual, colUdt, colSys);

                EXCEPTION
                    WHEN OTHERS THEN
                        IF instr (raisable_errors, to_char (SQLCODE, 'S00000')) > 0 THEN
                            RAISE;
                        END IF;
                        -- this means that probably table has primary key but not columns
                        "GG_ADMIN" .trace_put_line ('DDLTRACE', 'Warning processing query (nvu, getKeyCols), column ' || uk.column_name || SQLERRM);
                        colNull := 0;
                        colVirtual := 0;
                        colUdt := 0;
                END;

            END LOOP;
            IF ukFound = 1 THEN
                BEGIN

                    -- keyCount is number of unique keys that have neither null nor udt nor virtual
                    -- use SUM() to make sure GROUP BY doesn't produce multiple results
                    SELECT SUM(COUNT(*)) INTO keyCount FROM "GG_ADMIN" ."GGS_TEMP_UK" uk1
                    WHERE seqNo = "GG_ADMIN" .DDLReplication.currentMarkerSeq
                    AND NOT EXISTS  (
                        SELECT uk2.nullable FROM "GG_ADMIN" ."GGS_TEMP_UK" uk2
                        WHERE uk2.seqNo = "GG_ADMIN" .DDLReplication.currentMarkerSeq
                        AND uk2.keyName = uk1.keyName
                        AND (uk2.virtual = 1 OR uk2.udt = 1 OR uk2.nullable = 1 OR uk2.isSys = 1)
                        )
                    GROUP BY keyName;
                    IF trace_level >= 1 THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Minimum number of good keys (1) ' || keyCount);
                    END IF;
                    IF keyCount = 0 OR keyCount IS NULL THEN
                        SELECT SUM(COUNT(*)) INTO keyCount FROM "GG_ADMIN" ."GGS_TEMP_UK" uk1
                        WHERE seqNo = "GG_ADMIN" .DDLReplication.currentMarkerSeq
                        AND NOT EXISTS  (
                            SELECT uk2.virtual FROM "GG_ADMIN" ."GGS_TEMP_UK" uk2
                            WHERE uk2.seqNo = "GG_ADMIN" .DDLReplication.currentMarkerSeq
                            AND uk2.keyName = uk1.keyName
                            AND (uk2.virtual = 1 OR uk2.udt = 1 OR uk2.isSys = 1)
                            )
                        GROUP BY keyName;
                        thereIsNotNullUK := 0;
                    ELSE
                        thereIsNotNullUK := 1;
                    END IF;

                    IF trace_level >= 1 THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Minimum number of good keys [' || keyCount || ']');
                    END IF;

                    IF keyCount IS NOT NULL AND keyCount > 0 THEN
                        -- find alphabetically first key which has minimum number of columns
                        -- because of previous query, this one must return result
                        IF thereIsNotNullUK = 1 THEN
                            SELECT MIN(keyName) INTO bestKey
                            FROM "GG_ADMIN" ."GGS_TEMP_UK"  uk1
                            WHERE seqNo = "GG_ADMIN" .DDLReplication.currentMarkerSeq
                            AND NOT EXISTS (SELECT uk2.nullable FROM "GG_ADMIN" ."GGS_TEMP_UK" uk2
                                WHERE seqNo = "GG_ADMIN" .DDLReplication.currentMarkerSeq
                                AND uk2.keyName = uk1.keyName
                                AND (uk2.virtual = 1 OR uk2.udt = 1 OR uk2.nullable = 1 OR uk2.isSys = 1))
                            ORDER BY keyName ASC;
                        ELSE
                            SELECT MIN(keyName) INTO bestKey
                            FROM "GG_ADMIN" ."GGS_TEMP_UK"  uk1
                            WHERE seqNo = "GG_ADMIN" .DDLReplication.currentMarkerSeq
                            AND NOT EXISTS (SELECT uk2.virtual FROM "GG_ADMIN" ."GGS_TEMP_UK" uk2
                                WHERE seqNo = "GG_ADMIN" .DDLReplication.currentMarkerSeq
                                AND uk2.keyName = uk1.keyName
                                AND (uk2.virtual = 1 OR uk2.udt = 1 OR uk2.isSys = 1))
                            ORDER BY keyName ASC;
                        END IF;

                        IF trace_level >= 1 THEN
                            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Best Index ' || bestKey);
                        END IF;

                        insertToMarker (DDL_HISTORY, '', '',
                                        itemHeader (MD_TAB_PRIMARYKEYNAME, '', '', bestKey, ITEM_WHOLE)
                                        , ADD_FRAGMENT);

                        -- find columns for this key
                        -- we already established that there is more than 0 columns in a key (maxKeys > 0)
                        FOR ukc IN (SELECT colName FROM "GG_ADMIN" ."GGS_TEMP_UK" WHERE
                            seqNo = "GG_ADMIN" .DDLReplication.currentMarkerSeq AND keyName = bestKey) LOOP
                            insertToMarker (DDL_HISTORY, '', '',
                                    itemHeader (MD_TAB_PRIMARYKEY, to_char (seqPK), ukc.colName, ukc.colName, ITEM_WHOLE)
                                    , ADD_FRAGMENT);
                            IF trace_level >= 1 THEN
                                "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Add column to best index ' || ukc.colName);
                            END IF;
                            seqPK := seqPK + 1;
                        END LOOP;
                    END IF;
                EXCEPTION WHEN NO_DATA_FOUND THEN
                    "GG_ADMIN" .trace_put_line ('DDLTRACE', 'No unique key found for for [' || powner || '.' || ptable || ']');
                END;
            END IF;
        END IF;
        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Found [' || to_char (seqPK - 1) || '] columns for primary or unique key');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'getKeyCols: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END getKeyCols;


    /*
    PROCEDURE GETCOLDEFS
    Stores column information to DDL history table. Most column info is here
    (such as name, number, type, length, precision etc.) is gathered here.
    param[in] POWNER                         VARCHAR2                owner of table
    param[in] PTABLE                         VARCHAR2                name of table
    */

    PROCEDURE getColDefs (pobjid IN NUMBER,
                          powner IN VARCHAR2,
                          ptable IN VARCHAR2)
    IS
    colCount NUMBER;
    errorMessage VARCHAR2(32767);
    segcol NUMBER;
    isUDT NUMBER;
    isVirtual NUMBER;
    isSys NUMBER;
    isEnc NUMBER;
    isXMLTab VARCHAR2(130);
    hasInvisible VARCHAR2(130);
    encMkeyid "SYS" ."ENC$".MKEYID%TYPE;
    encEncAlg "SYS" ."ENC$".ENCALG%TYPE;
    encIntAlg "SYS" ."ENC$".INTALG%TYPE;
    encColKey VARCHAR2(32767);
    encColKeyLen "SYS" ."ENC$".KLCLEN%TYPE;
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering getColDefs()');
        END IF;

        isEnc := 0; -- flag to track if there is TDE for table or not
        isXMLTab := 'NO';
        hasInvisible := 'NO';
	colCount := 0;

        FOR cd IN DDLReplication.getCols (pobjid) LOOP

            IF trace_level >= 1 THEN
	        "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Col ' || cd.column_name || ' col# ' || cd.col_num || ' intcol# ' || cd.intcol_num ||
		' original type ' || cd.type_num || ' type ' || cd.data_type || ' type owner ' || cd.data_type_owner);
            END IF;
	    segcol := cd.segcol_num;
	    isUDT := 0;
	    isVirtual := 0;
	    isSys := 0;

            IF bitand(cd.property, COL_ISENC) = COL_ISENC THEN
	        isEnc := 1; -- now we now we'll need other TDE info for this table
                IF trace_level >= 1 THEN
                    "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Col ' || cd.column_name || ' type ' || cd.data_type || ',encrypted property ' || cd.property);
                END IF;
            END IF;
            IF bitand(cd.property, COL_ISINVISIBLE) = COL_ISINVISIBLE THEN
                hasInvisible := 'YES';
            END IF;
            IF cd.type_num in (121, 122, 123) OR cd.opq_flags <> 0 THEN -- UDT or XML
	        isUDT := 1;
            END IF;
            IF bitand(cd.opq_flags, XMLTAB) = XMLTAB THEN
                isXMLTab := 'YES';
            END IF;
            IF cd.storage_segcol <> 0 THEN
                segcol := cd.storage_segcol;
            END IF;
	    IF segcol = 0 THEN
	        isVirtual := 1;
	    END IF;
	    IF bitand(cd.property, COL_ISHIDDEN + COL_ISINVISIBLE) = COL_ISHIDDEN THEN
	        isSys := 1;
	    ELSE
	        colCount := colCount + 1;
	    END IF;

            IF isSys = 0 AND (bitand(cd.property, COL_ISLOB) = COL_ISLOB OR bitand(cd.opq_flags, XMLLOB) = XMLLOB) THEN
                "GG_ADMIN" .ddlora_getLobs (powner, ptable, cd.column_name, cd.intcol_num);
            END IF;

	    insertToMarker (DDL_HISTORY, '', '',
                            itemHeader (MD_COL_NAME, to_char (cd.intcol_num), cd.column_name, cd.column_name, ITEM_WHOLE) ||
                            itemHeader (MD_COL_NUM, to_char (cd.intcol_num), cd.column_name , to_char (cd.col_num), ITEM_WHOLE) ||
                            itemHeader (MD_COL_SEGCOL, to_char (cd.intcol_num), cd.column_name, to_char (segcol), ITEM_WHOLE) ||
                            itemHeader (MD_COL_INTCOL, to_char (cd.intcol_num), cd.column_name, to_char (cd.intcol_num), ITEM_WHOLE) ||
                            itemHeader (MD_COL_TYPE, to_char (cd.intcol_num), cd.column_name, to_char (cd.type_num), ITEM_WHOLE) ||
                            itemHeader (MD_COL_LEN, to_char (cd.intcol_num), cd.column_name, to_char (cd.length), ITEM_WHOLE) ||
                            itemHeader (MD_COL_ISNULL, to_char (cd.intcol_num), cd.column_name, to_char (cd.isnull), ITEM_WHOLE) ||
                            itemHeader (MD_COL_PREC, to_char (cd.intcol_num), cd.column_name, to_char (cd.precision_num), ITEM_WHOLE) ||
                            itemHeader (MD_COL_SCALE, to_char (cd.intcol_num), cd.column_name, to_char (cd.scale), ITEM_WHOLE) ||
                            itemHeader (MD_COL_CHARSETID, to_char (cd.intcol_num), cd.column_name, to_char (cd.charsetid), ITEM_WHOLE) ||
                            itemHeader (MD_COL_CHARSETFORM, to_char (cd.intcol_num), cd.column_name, to_char (cd.charsetform), ITEM_WHOLE) ||
                            itemHeader (MD_COL_PROPERTY, to_char (cd.intcol_num), cd.column_name, cd.property, ITEM_WHOLE)
                            , ADD_FRAGMENT);

            insertToMarker (DDL_HISTORY, '', '',
                            itemHeader (MD_COL_ALT_TYPE, to_char (cd.intcol_num), cd.column_name, to_char (cd.data_type), ITEM_WHOLE) ||
                            itemHeader (MD_COL_ALT_TYPE_OWNER, to_char (cd.intcol_num), cd.column_name, to_char (cd.data_type_owner), ITEM_WHOLE) ||
                            itemHeader (MD_COL_ALT_PREC, to_char (cd.intcol_num), cd.column_name, to_char (cd.data_precision), ITEM_WHOLE) ||
                            itemHeader (MD_COL_ALT_CHAR_USED, to_char (cd.intcol_num), cd.column_name, cd.char_used, ITEM_WHOLE) ||
                            itemHeader (MD_COL_ALT_LENGTH, to_char (cd.intcol_num), cd.column_name, cd.data_length, ITEM_WHOLE) ||
                            itemHeader (MD_COL_OPQFLAGS, to_char (cd.intcol_num), cd.column_name, to_char (cd.opq_flags), ITEM_WHOLE)
                            , ADD_FRAGMENT);

            IF trace_level >= 1 THEN
	      "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Insert into TEMP COLS [' || cd.column_name || '], nullable ' || cd.isnull ||
                                          ', isvirtual ' || isVirtual || ', isUDT ' || isUDT || ', isSys ' || isSys);
            END IF;
            -- should always succeed, we're using pk
            INSERT INTO "GG_ADMIN" ."GGS_TEMP_COLS" (seqNo, colName, nullable, virtual, udt, isSys)
            VALUES ("GG_ADMIN" .DDLReplication.currentMarkerSeq, cd.column_name, cd.isnull, isVirtual, isUDT, isSys);

        END LOOP;

        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_COLCOUNT, '', '', to_char (colCount), ITEM_WHOLE)
                        , ADD_FRAGMENT);

        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_XMLTYPETABLE, '', '', isXMLTab, ITEM_WHOLE)
                        , ADD_FRAGMENT);

        IF isEnc = 1 THEN
            /* Get TDE related data for this object IF there are encrypted columns*/
            BEGIN
                SELECT MKEYID, ENCALG, INTALG, COLKLC, KLCLEN
                INTO encMkeyid, encEncAlg, encIntAlg, encColKey, encColKeyLen
                FROM "SYS" ."ENC$"
                WHERE OBJ#=DDLReplication.currentObjectId;

                -- 0 is sometimes found in keys
                encMkeyid := REPLACE (encMkeyid, chr(0), ' ');
                encColKey := REPLACE (encColKey, chr(0), ' ');

                IF trace_level >= 1 THEN
                    "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Table ' || powner || '.' || ptable || ' mkeyid ' || encMkeyid || ' encalg ' || encEncAlg || ' intalg ' || encIntAlg || ' encColKey ' || encColKey || ' encColKeyLen ' || encColKeyLen);
		END IF;

                insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_ENC_MKEYID, '', '', to_char (encMkeyid), ITEM_WHOLE)
                        , ADD_FRAGMENT);
                insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_ENC_ENCALG, '', '', to_char (encEncAlg), ITEM_WHOLE)
                        , ADD_FRAGMENT);
                insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_ENC_INTALG, '', '', to_char (encIntAlg), ITEM_WHOLE)
                        , ADD_FRAGMENT);
                insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_ENC_COLKLC, '', '', to_char (encColKey), ITEM_WHOLE)
                        , ADD_FRAGMENT);
                insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_ENC_KLCLEN, '', '', to_char (encColKeyLen), ITEM_WHOLE)
                        , ADD_FRAGMENT);
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
				errorMessage := 'getTDEinfo, error: found enc cols, but no TDE data: ' || ':' || SQLERRM;
				"GG_ADMIN" .trace_put_line ('DDL', errorMessage);
				NULL; -- do nothing, we may not need to decrypt anything!!
			WHEN OTHERS THEN
				IF instr (raisable_errors, to_char (SQLCODE, 'S00000')) > 0 THEN
					RAISE;
				END IF;
				errorMessage := 'getTDEinfo, error: found enc cols, but trouble getting TDE data: ' || ':' || SQLERRM;
				"GG_ADMIN" .trace_put_line ('DDL', errorMessage);
				NULL; -- do nothing, we may not need to decrypt anything!!
			END;
		END IF;
    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'getColDefs: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END getColDefs;

    -- get the table info
    -- param[in] powner owner of table
    -- param[in] ptable table name
    -- stores result in DDL history

    /*
    PROCEDURE GETTABLEINFO
    Store table information in DDL history table, such as number of columns, partitions etc.
    Also, general information about DDL is put in here.

    param[in] OBJNAME                        VARCHAR2                object name (can be index, trigger..)
    param[in] OBJOWNER                       VARCHAR2                object owner (can be index, trigger...)
    param[in] OBJTYPE                        VARCHAR2                TABLE, INDEX, TRIGGER...
    param[in] OPTYPE                         VARCHAR2                CREATE, ALTER...
    param[in] USERID                         VARCHAR2                user id of owner
    param[in] MOWNER                         VARCHAR2                base owner (of the table)
    param[in] MNAME                          VARCHAR2                base name (of the table)
    param[in] DDLSTATEMENT                   VARCHAR2                actual DDL statement text
    param[in] TOIGNORE                       VARCHAR2                if DDL is to be ignored in extract
    param[in] ISTYPETABLE                    VARCHAR2                if object is an object table

    remarks ADD_FRAGMENT_AND_FLUSH is used for DDL statement  because it can be bigger than 4K, such data
    is immediatelly flushed to DDL history table
    */
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
			    isTypeTable IN VARCHAR2)
    IS
    num_objects NUMBER;
    unusedCols NUMBER;
    ora_column_cnt NUMBER;
    log_group_exists NUMBER;
    all_log_group_exists NUMBER;
    s_log_group_name VARCHAR2(400);
    log_group_id NUMBER;
    part_id NUMBER;
    errorMessage VARCHAR2(32767);
    alt_obj_type VARCHAR2(130);
    is_subpart NUMBER;
    is_part NUMBER;
    isCompressed NUMBER;
    isIOT VARCHAR2(130);
    isIOTWithOverflow VARCHAR2(130);
    prop NUMBER;
    prop3 NUMBER;
    clusterType VARCHAR2(130);
    tabColsCounter NUMBER;
    check_schema_suplog NUMBER;
    check_schema_tabf NUMBER;
    schemaSuplog_cursor    INTEGER;
    ignore                 INTEGER;
    schemaSuplog_colName   VARCHAR2(400);
    min_altobjectid NUMBER;
    max_altobjectid NUMBER;
    partition_type NUMBER;
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering getTableInfo(), object id (objId)' || objId);
        END IF;

        -- !!!!! keep this record the very first one, because
        -- it can be larger than 4K - needs to flush immediately
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_DDLSTATEMENT, '', '', ddlStatement, ITEM_WHOLE)
                        , ADD_FRAGMENT_AND_FLUSH);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_MARKERTABLENAME, '', '', 'GG_ADMIN' || '.' || 'GGS_MARKER', ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_MARKERSEQNO, '', '', to_char ("GG_ADMIN" .DDLReplication.currentMarkerSeq), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_SCN, '', '', to_char ("GG_ADMIN" .DDLReplication.SCNB + "GG_ADMIN" .DDLReplication.SCNW * power (2, 32)), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_OBJECTID, '', '', to_char (currentObjectId), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_OWNER, '', '', objOwner, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_NAME, '', '', objName, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_OBJTYPE, '', '', objType, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_OPTYPE, '', '', opType, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_USERID, '', '', userId, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_USERID, '', '', userId, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_MASTEROWNER, '', '', mowner, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_MASTERNAME, '', '', mname, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MK_TAB_TOIGNORE, '', '', toIgnore, ITEM_WHOLE)
                        , ADD_FRAGMENT);
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_TYPETABLE, '', '', isTypeTable, ITEM_WHOLE)
                        , ADD_FRAGMENT);

        BEGIN
            IF lv_ora_db_block_size = 0 THEN
                IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
                   "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 16');
                END IF;
    			SELECT value INTO lv_ora_db_block_size
    			FROM "GG_ADMIN" ."GGS_STICK"
    			WHERE property = 'ora_db_block_size';
    			IF trace_level >= 1 THEN
    				"GG_ADMIN" .trace_put_line ('DDL', 'DB block size from cache ' || to_char (lv_ora_db_block_size));
                END IF;
			END IF;
		EXCEPTION
			WHEN OTHERS THEN
				IF instr (raisable_errors, to_char (SQLCODE, 'S00000')) > 0 THEN
					RAISE;
				END IF;
				BEGIN
                    IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
                       "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 15');
                    END IF;
					SELECT VALUE
						INTO lv_ora_db_block_size
						FROM v$parameter
						WHERE upper(name) = 'DB_BLOCK_SIZE' AND
							VALUE IS NOT NULL;
					INSERT INTO "GG_ADMIN" ."GGS_STICK" (property, value)
						VALUES ('ora_db_block_size', lv_ora_db_block_size);
					IF trace_level >= 1 THEN
                        "GG_ADMIN" .trace_put_line ('DDL', 'DB block size computed ' || to_char (lv_ora_db_block_size));
					END IF;
				EXCEPTION
					WHEN OTHERS THEN
						IF instr (raisable_errors, to_char (SQLCODE, 'S00000')) > 0 THEN
							RAISE;
						END IF;
						NULL;
				END;
		END;

        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_BLOCKSIZE, '', '', to_char(lv_ora_db_block_size), ITEM_WHOLE)
                        , ADD_FRAGMENT);

        FOR ti IN DDLReplication.getTable LOOP
            insertToMarker (DDL_HISTORY, '', '',
                            itemHeader (MD_TAB_DATAOBJECTID, '', '', to_char (ti.data_object_id), ITEM_WHOLE) ||
                            itemHeader (MD_TAB_CLUCOLS, '', '', to_char (ti.clucols), ITEM_WHOLE)
                            , ADD_FRAGMENT);
        END LOOP;

        /* total column count */
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 14');
        END IF;
        SELECT COUNT(*)
            INTO ora_column_cnt
            FROM sys.col$ c,
                sys.tab$ t,
                sys.obj$ o
            WHERE c.obj# = o.obj# AND
                t.obj# = o.obj# AND
                o.obj# = objId;
        insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_TOTAL_COL_NUM, '', '', to_char (ora_column_cnt), ITEM_WHOLE)
                        , ADD_FRAGMENT);
        BEGIN
            SELECT MOD(property, POWER(2, 64)), FLOOR(property/POWER(2, 64))
            INTO prop, prop3
            FROM sys.tab$
            WHERE obj# = objId;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
               prop := 0;
               prop3 := 0;
            END;
                                                                                                                                    IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'OBJTAB prop= [' || to_char(prop) || ']'
                                        || '  prop3= [' || to_char(prop3) || ']');
       END IF;
       insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                       itemHeader (MD_TAB_PROPERTY, '', '', to_char(prop), ITEM_WHOLE)
                       , ADD_FRAGMENT);
       insertToMarker (GENERIC_MARKER, 'DDL', 'DDLINFO',
                       itemHeader (MD_TAB_ORA_PFLAGS3, '', '', to_char(prop3), ITEM_WHOLE)
                       , ADD_FRAGMENT);


        -- get partition type, 0 if not partitioned
        BEGIN
            select parttype into partition_type from sys.partobj$ where obj# = objId;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            partition_type:=0; -- not a partitioned table
        END;
        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'PARTITION TYPE=' || to_char(partition_type));
        END IF;
        insertToMarker (DDL_HISTORY, '', '',
                       itemHeader (MD_TAB_PARTITION_TYPE, '', '', to_char(partition_type), ITEM_WHOLE)
                       , ADD_FRAGMENT);


        -- first check if ALL group exists, if it does

        log_group_exists := 0;
        all_log_group_exists := ddlora_getAllColsLogging (DDLReplication.currentObjectId);

        IF all_log_group_exists IS NOT NULL AND all_log_group_exists > 0 THEN
            insertToMarker (DDL_HISTORY, '', '',
                itemHeader (MD_TAB_LOG_GROUP_EXISTS, '', '', '2', ITEM_WHOLE)
                , ADD_FRAGMENT);
        ELSE
            -- check for schema level supplemental logging
            BEGIN
                check_schema_suplog := 0;
                check_schema_tabf := 0;
                if checkSchemaTabf = -1 THEN
                  IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
                     "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 13');
                  END IF;
                  SELECT count (1)
                      INTO checkSchemaTabf
                      FROM dba_objects o
                      WHERE o.object_name = 'LOGMNR$ALWAYS_SUPLOG_COLUMNS' AND
                            o.object_type = 'SYNONYM' AND
                            o.status = 'VALID';
                END IF;
                check_schema_tabf := checkSchemaTabf;


                IF check_schema_tabf = 1 THEN
                    IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
                       "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 12');
                    END IF;
                    EXECUTE IMMEDIATE 'SELECT count(1)
                                       FROM logmnr$schema_allkey_suplog
                                       WHERE allkey_suplog = ''YES'' and
                                             schema_name = :objOwner'
                                      INTO check_schema_suplog USING objOwner;

                    IF check_schema_suplog = 1 THEN
                        log_group_exists := 1;
                    END IF;
                END IF;
            END;

            IF log_group_exists = 0 THEN
                s_log_group_name := 'GGS_' || to_char (DDLReplication.currentObjectId);
                 IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
                    "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 11');
                 END IF;
                 select count(*) into log_group_exists
                 from sys.obj$ o, sys.cdef$ c, sys.con$ oc
                 where o.obj# = objId and o.obj# = c.obj# and
                 c.con# = oc.con# and oc.name = s_log_group_name and
                        ROWNUM = 1;
            END IF;

            insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_LOG_GROUP_EXISTS, '', '', to_char (log_group_exists), ITEM_WHOLE)
                        , ADD_FRAGMENT);

        END IF;

        -- at this time log_group_name is the correct one (it exists)
        IF log_group_exists > 0 THEN
              IF check_schema_suplog = 1 THEN
                schemaSuplog_cursor := dbms_sql.open_cursor;

                IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
                   "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 10');
                END IF;
                DBMS_SQL.PARSE(schemaSuplog_cursor,
                               'SELECT column_name
                                FROM table(LOGMNR$ALWAYS_SUPLOG_COLUMNS (
                                           :objOwner_bind , :objName_bind))',
                                DBMS_SQL.V7);

                DBMS_SQL.BIND_VARIABLE (schemaSuplog_cursor, ':objOwner_bind', objOwner);
                DBMS_SQL.BIND_VARIABLE (schemaSuplog_cursor, ':objName_bind', objName);
                DBMS_SQL.DEFINE_COLUMN(schemaSuplog_cursor, 1,
                                       schemaSuplog_colName, 128);

                ignore := DBMS_SQL.EXECUTE(schemaSuplog_cursor);

                log_group_id := 1;
                LOOP
                    IF DBMS_SQL.FETCH_ROWS(schemaSuplog_cursor) > 0 THEN
                        DBMS_SQL.COLUMN_VALUE(schemaSuplog_cursor, 1, schemaSuplog_colName);
                        insertToMarker (DDL_HISTORY, '', '',
                                        itemHeader (MD_COL_ALT_LOG_GROUP_COL,
                                                    to_char (log_group_id), '',
                                                    schemaSuplog_colName,
                                                    ITEM_WHOLE),
                                        ADD_FRAGMENT);
                        log_group_id := log_group_id + 1;
                    ELSE
                        -- No more rows to copy:
                        EXIT;
                    END IF;
                END LOOP;

                DBMS_SQL.CLOSE_CURSOR(schemaSuplog_cursor);
            ELSE
                log_group_id := 1;
                FOR lc IN loggroup_suplog (s_log_group_name, objOwner, objName) LOOP
                    insertToMarker (DDL_HISTORY, '', '',
                                    itemHeader (MD_COL_ALT_LOG_GROUP_COL, to_char (log_group_id), '', lc.column_name, ITEM_WHOLE)
                                    , ADD_FRAGMENT);
                    log_group_id := log_group_id + 1;
                END LOOP;
            END IF;
        END IF;

        /* based on unused columns, verify that table is valid */
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 9');
        END IF;
        SELECT COUNT(*) INTO unusedCols FROM sys.col$
        WHERE col# = 0 AND segcol# > 0
        AND obj# = DDLReplication.currentObjectId;

        /* check compression table or partitions */
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 8');
        END IF;
        SELECT   (SELECT COUNT(*) FROM sys.tab$ t, sys.seg$ s
                  WHERE t.obj# = DDLReplication.currentObjectId AND
                  t.file# = s.file# AND
                  t.block# = s.block# AND
                  t.ts# = s.ts# AND
                  decode(bitand(t.property, 32), 32, null,
                        decode(bitand(s.spare1, 2048), 2048,
                              'ENABLED', 'DISABLED')) = 'ENABLED' AND rownum=1)
                +
                 (SELECT COUNT(*) FROM dba_tab_partitions
                  WHERE table_owner = objOwner and table_name = objName
                  AND compression = 'ENABLED' AND rownum=1)
                +
                 (select count(*) from dba_indexes
                  WHERE table_owner = objOwner and table_name = objName
                        and index_type = 'IOT - TOP'
                        and compression = 'ENABLED' AND rownum=1)
        INTO isCompressed
        FROM DUAL;

        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 7');
        END IF;

        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Compression flag [' || to_char (isCompressed) || '] unused [' ||
                to_char (unusedCols) || ']');
        END IF;

        IF unusedCols > 0 OR isCompressed >0 THEN
            IF isCompressed > 0 THEN
                insertToMarker (DDL_HISTORY, '', '',
                            itemHeader (MD_TAB_VALID, '', '', 'INVALIDABEND', ITEM_WHOLE)
                            , ADD_FRAGMENT);
            ELSE
                insertToMarker (DDL_HISTORY, '', '',
                                itemHeader (MD_TAB_VALID, '', '', 'INVALID', ITEM_WHOLE)
                                , ADD_FRAGMENT);
            END IF;
        ELSE
            insertToMarker (DDL_HISTORY, '', '',
                            itemHeader (MD_TAB_VALID, '', '', 'VALID', ITEM_WHOLE)
                            , ADD_FRAGMENT);
        END IF;


        isIOT := 'NO';
        isIOTWithOverflow := 'NO';
        part_id := 1; -- IOT can add alternative ids now

        prop := 0;
        IF ddlBaseObjProperty <> -1 THEN
            prop := MOD(DDLReplication.ddlBaseObjProperty, POWER(2, 64));
        END IF;

        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'IOT,OBJTAB prop= [' || to_char(prop) || ']');
        END IF;
        IF bitand (prop, IOT) = IOT THEN
            isIOT := 'YES';
            IF bitand (prop, IOT_WITH_OVERFLOW) = IOT_WITH_OVERFLOW THEN
                isIOTWithOverflow := 'YES';
            END IF;

            insertToMarker (DDL_HISTORY, '', '',
                itemHeader (MD_TAB_SUBPARTITION, '', '', 'NO', ITEM_WHOLE)
                , ADD_FRAGMENT); -- to make parsing on extract side easier

            IF trace_level >= 1 THEN
                "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'IOT alt id query, objowner= [' || objOwner || '], name = ['
                || objName || ']');
            END IF;
            FOR iotId in DDLReplication.iotAltId (objId ,objOwner, objName) LOOP
                if part_id = 1 THEN
                     insertToMarker (DDL_HISTORY, '', '',
                            itemHeader (MD_TAB_PARTITION, '', '', 'YES', ITEM_WHOLE)
                            , ADD_FRAGMENT);
                END IF;
                 insertToMarker (DDL_HISTORY, '', '',
                    itemHeader (MD_TAB_PARTITION_IDS, to_char (part_id), '', to_char (iotId.object_id), ITEM_WHOLE)
                    , ADD_FRAGMENT);
                 -- populate alt table for resolution of partition DMLs
                -- we always first delete primary key data to avoid unique violations
                -- object id can be NULL in CREATE statements or for INDEXES
                IF currentObjectId IS NOT NULL AND iotId.object_id IS NOT NULL THEN
    			    BEGIN
                        INSERT INTO "GG_ADMIN" ."GGS_DDL_HIST_ALT" (
                            altObjectId,
                            objectId,
                            optime)
                        VALUES (
                            iotId.object_id,
                            currentObjectId,
                            TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')
                        );
                        EXCEPTION
                            WHEN DUP_VAL_ON_INDEX THEN
                            "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert duplicate, handled (2)');
                            NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                            WHEN NO_DATA_FOUND THEN
                            "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert no data found, handled (2)');
                            NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                            WHEN deadlockDetected THEN
                            "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert - deadlock, ignored (2)');
                            NULL; -- do nothing, this means somebody else is doing this exact work!
                    END;
                END IF;
                part_id := part_id + 1;
            END LOOP;

            IF bitand (prop, IOT_WITH_OVERFLOW) = IOT_WITH_OVERFLOW THEN
                if part_id = 1 THEN
                     insertToMarker (DDL_HISTORY, '', '',
                            itemHeader (MD_TAB_PARTITION, '', '', 'YES', ITEM_WHOLE)
                            , ADD_FRAGMENT);
                END IF;
                FOR iotId in DDLReplication.iotOverflowAltId (objOwner, objName) LOOP
                     insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_PARTITION_IDS, to_char (part_id), '', to_char (iotId.object_id), ITEM_WHOLE)
                        , ADD_FRAGMENT);
                    -- populate alt table for resolution of partition DMLs
                    -- we always first delete primary key data to avoid unique violations
                    -- object id can be NULL in CREATE statements or for INDEXES
                    IF currentObjectId IS NOT NULL AND iotId.object_id IS NOT NULL THEN
                        BEGIN
                            INSERT INTO "GG_ADMIN" ."GGS_DDL_HIST_ALT" (
                                altObjectId,
                                objectId,
                                optime)
                            VALUES (
                                iotId.object_id,
                                currentObjectId,
                                TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')
                            );
                            EXCEPTION
                                WHEN DUP_VAL_ON_INDEX THEN
                                "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert duplicate, handled (3)');
                                NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                                WHEN NO_DATA_FOUND THEN
                                "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert no data found, handled (3)');
                                NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                                WHEN deadlockDetected THEN
                                "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert - deadlock, ignored (3)');
                                NULL; -- do nothing, this means somebody else is doing this exact work!
                        END;
                    END IF;
                    part_id := part_id + 1;
                END LOOP;
            END IF;
        END IF;

        clusterType := 'FALSE';
        IF bitand (prop, CLUSTER_TABLE) = CLUSTER_TABLE THEN
            BEGIN
            IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
               "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 6');
            END IF;
                SELECT cluster_type
                INTO clusterType
                FROM dba_clusters ac,
                        dba_tables at
                WHERE at.owner = objOwner
                    AND at.table_name = objName
                    AND at.owner = ac.owner
                    AND at.cluster_name = ac.cluster_name;
            EXCEPTION
                WHEN OTHERS THEN
                    IF instr (raisable_errors, to_char (SQLCODE, 'S00000')) > 0 THEN
                        RAISE;
                    END IF;
                    clusterType := 'FALSE';
            END;

            IF clusterType <> 'INDEX' AND clusterType <> 'HASH' THEN
                clusterType := 'FALSE';
            END IF;
            insertToMarker (DDL_HISTORY, '', '',
                    itemHeader (MD_TAB_CLUSTER, '', '', to_char (clusterType), ITEM_WHOLE)
                    , ADD_FRAGMENT);

            IF clusterType <> 'FALSE' THEN
                tabColsCounter := 1;
                IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
                   "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 5');
                END IF;
                FOR tabCols IN (SELECT tab_column_name
                        FROM dba_clu_columns
                        WHERE owner = objOwner AND
                        table_name = objName) LOOP
                    insertToMarker (DDL_HISTORY, '', '',
                        itemHeader (MD_TAB_CLUSTER_COLNAME, to_char(tabColsCounter), '', to_char (tabCols.tab_column_name), ITEM_WHOLE)
                        , ADD_FRAGMENT);
                    tabColsCounter := tabColsCounter + 1;
                END LOOP;
            END IF;
        END IF;

        insertToMarker (DDL_HISTORY, '', '',
                itemHeader (MD_TAB_CLUSTER, '', '', to_char (clusterType), ITEM_WHOLE)
                , ADD_FRAGMENT);

        -- determine IOT status (if not, it will show up here too)
        insertToMarker (DDL_HISTORY, '', '',
            itemHeader (MD_TAB_IOT, '', '', isIOT, ITEM_WHOLE)
            , ADD_FRAGMENT); -- to make parsing on extract side easier

        insertToMarker (DDL_HISTORY, '', '',
            itemHeader (MD_TAB_IOT_OVERFLOW, '', '', isIOTWithOverflow, ITEM_WHOLE)
            , ADD_FRAGMENT); -- to make parsing on extract side easier


        IF isIOT <> 'YES' THEN

            is_subpart := 0;
            is_part := 0;
            /* number of alternative (if any) objects for subpartitions */
            /* TODO: This is expensive way to find if there are partitions
             * or sub partitions
             */
            alt_obj_type := 'TABLE SUBPARTITION';
            IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
               "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 3');
            END IF;
            SELECT COUNT(*)
            INTO num_objects
            FROM dba_objects
            WHERE
                object_name = objName AND
                owner = objOwner AND
                object_type = alt_obj_type;

            IF num_objects = 0 THEN
                insertToMarker (DDL_HISTORY, '', '',
                                itemHeader (MD_TAB_SUBPARTITION, '', '', 'NO', ITEM_WHOLE)
                                , ADD_FRAGMENT);
                /* number of alternative (if any) objects for partitions */
                alt_obj_type := 'TABLE PARTITION';
                IF objId <> -1 THEN
                  IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
                     "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 2');
                  END IF;
                  begin
                  select bitand(property,32) into num_objects
                  from sys.tab$ where obj# = objId;
                  EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                  num_objects:=0; -- could be a VIEW, not a table
                  END;
                ELSE
                IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
                   "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'getTableInfo() query 1');
                END IF;
                SELECT COUNT(*)
                INTO num_objects
                FROM dba_objects
                WHERE
                    object_name = objName AND
                    owner = objOwner AND
                    object_type = alt_obj_type;
                  END IF;
                IF num_objects = 0 THEN
                    insertToMarker (DDL_HISTORY, '', '',
                                    itemHeader (MD_TAB_PARTITION, '', '', 'NO', ITEM_WHOLE)
                                    , ADD_FRAGMENT);
                ELSE
                    insertToMarker (DDL_HISTORY, '', '',
                                    itemHeader (MD_TAB_PARTITION, '', '', 'YES', ITEM_WHOLE)
                                    , ADD_FRAGMENT);
                    is_part := 1;
                END IF;
            ELSE
                insertToMarker (DDL_HISTORY, '', '',
                                itemHeader (MD_TAB_SUBPARTITION, '', '', 'YES', ITEM_WHOLE)
                                , ADD_FRAGMENT);
                is_subpart := 1;
            END IF;

            IF currentObjectId IS NOT NULL THEN
                BEGIN
                -- object id can be NULL in CREATE statements or for INDEXES
                -- populate alt table for resolution of partition DMLs
                INSERT INTO "GG_ADMIN" ."GGS_DDL_HIST_ALT" (
                    altObjectId,
                    objectId,
                    optime)
                VALUES (
                    currentObjectId,
                    currentObjectId,
                    TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')
                );
                EXCEPTION
                    WHEN DUP_VAL_ON_INDEX THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert duplicate, handled (1)');
                        NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                    WHEN NO_DATA_FOUND THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert no data found, handled (1)');
                        NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                    WHEN deadlockDetected THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert - deadlock, ignored (1)');
                        NULL; -- do nothing, this means somebody else is doing this exact work!
                END;
            END IF;
            IF num_objects > 0 THEN
                part_id := 1;
                FOR ai IN DDLReplication.alt_objects (objName, objOwner, alt_obj_type) LOOP
                    insertToMarker (DDL_HISTORY, '', '',
                                    itemHeader (MD_TAB_PARTITION_IDS, to_char (part_id), '', to_char (ai.object_id), ITEM_WHOLE)
                                    , ADD_FRAGMENT);
                    IF part_id = 1 THEN
                        BEGIN
                        -- get min/max alternative object id already saved
                        SELECT min(altobjectid), max(altobjectid)
                        INTO   min_altobjectid, max_altobjectid
                        FROM   "GG_ADMIN" ."GGS_DDL_HIST_ALT"
                        WHERE  objectid = currentObjectId;
                        EXCEPTION
                            WHEN OTHERS THEN
                                min_altobjectid := NULL;
                                max_altobjectid := NULL;
                        END;
                        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
                            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'ALTOBJID min=' || min_altobjectid || ', max=' || + max_altobjectid);
                        END IF;

                    END IF;

                    -- populate alt table for resolution of partition DMLs
                    -- object id can be NULL in CREATE statements or for INDEXES
                    -- use min/max to prevent inserting values that are already present
                    IF ai.object_id IS NOT NULL AND currentObjectId IS NOT NULL AND (ai.object_id < NVL(min_altobjectid,ai.object_id+1) OR ai.object_id > NVL(max_altobjectid,0)) THEN
                        BEGIN
                            INSERT INTO "GG_ADMIN" ."GGS_DDL_HIST_ALT" (
                                altObjectId,
                                objectId,
                                optime)
                            VALUES (
                                ai.object_id,
                                currentObjectId,
                                TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')
                            );
                            EXCEPTION
                                WHEN DUP_VAL_ON_INDEX THEN
                                "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert duplicate, handled (4)');
                                NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                                WHEN NO_DATA_FOUND THEN
                                "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert no data found, handled (4)');
                                NULL; -- do nothing, because racing condition can cause duplicate INSERTs, it's ok
                                WHEN deadlockDetected THEN
                                "GG_ADMIN" .trace_put_line ('DDLTRACE', 'ALTOBJID insert - deadlock, ignored (4)');
                                NULL; -- do nothing, this means somebody else is doing this exact work!
                        END;
                    END IF;
                    part_id := part_id + 1;
                END LOOP;
            END IF;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'getTableInfo: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END getTableInfo;




    /*
    PROCEDURE INSERTTOMARKER

    Stores data previously prepared by itemheader() function to either marker or DDL history table.
    This function manages sizing issues (larger than 4K chunks).
    Depending on MARKEROPTYPE param, it can take everything in one (SOLE_FRAGMENT), or in series of
    fragments (BEGIN/ADD/END_FRAGMENT). ADD_FRAGMENT_AND_FLUSH is used for chunks greater than 4K (
    it causes flush to table, i.e. INSERT); otherwise function gathers as much data as possible before
    flushing 4K chunks; this is to save space and increase performance.

    param[in] TARGET                         NUMBER(38)              which table to write to? DDL history (DDL_HISTORY), or marker (GENERIC_MARKER)?
    param[in] INTYPE                         VARCHAR2                empty for DDL history, 'DDL' for marker type
    param[in] INSUBTYPE                      VARCHAR2                empty for DDL history, 'DDLINFO' for marker type
    param[in] INSTRING                       VARCHAR2                actual data prepared by itemheader()
    param[in] MARKEROPTYPE                   NUMBER(38)              BEGIN/ADD/END_FRAGMENT (pieces of string), SOLE_FRAGMENT (entire string in one call) mode of usage

    remarks Note that this same function is used for both MARKER and DDL history table. In fact,
    extract uses the same internal process for both.
    */

    PROCEDURE insertToMarker (
                              target IN INTEGER,
                              inType IN VARCHAR2,
                              inSubType IN VARCHAR2,
                              inString IN VARCHAR2,
                              markerOpType IN INTEGER
                              ) IS
    i INTEGER;
    fragment_raw_length INTEGER;
    string_chunk    VARCHAR2(4000);
    fragment "GG_ADMIN" ."GGS_MARKER" .marker_text%TYPE;
    runtimeMarkerOpType INTEGER;
    current_fragment_leftover RAW(4000) := '';
    current_fragment_leftover_pos INTEGER := 0;
    end_frag INTEGER := 0;
    BEGIN
        IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
           "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'Entering insertToMarker()');
        END IF;

        runtimeMarkerOpType := markerOpType;

        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'insertToMarker: inString = [' );
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', inString);
            "GG_ADMIN" .trace_put_line ('DDLTRACE1','], type = ['
                                        || to_char(runtimeMarkerOpType) || ']' || ' target = [' || to_char(target) || ']' );
        END IF;

        IF runtimeMarkerOpType = SOLE_FRAGMENT OR runtimeMarkerOpType = BEGIN_FRAGMENT THEN
            IF target = GENERIC_MARKER THEN
                SELECT "GG_ADMIN" ."GGS_MARKER_SEQ" .NEXTVAL INTO currentMarkerSeq FROM dual;
            END IF;
            -- reset fragment.
            current_fragment := 0;
            current_fragment_raw := '';
        END IF;

        IF trace_level >= 2 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'insertToMarker: marker optype = [' || to_char(runtimeMarkerOpType)
                                        || '], current_fragment = ['
                                        || to_char(current_fragment) || ']');
        END IF;

       -- gathers as much data as possible before flushing 4K chunks.
        current_fragment_raw := utl_raw.concat(current_fragment_raw, utl_raw.cast_to_raw(inString));
        IF utl_raw.length(current_fragment_raw) > 4000 THEN
            runtimeMarkerOpType := ADD_FRAGMENT_AND_FLUSH;
        END IF;

        IF trace_level >= 2 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'insertToMarker: marker optype = [' || to_char(runtimeMarkerOpType)
                                        || '], current_fragment = ['
                                        || to_char(current_fragment) || ']');
        END IF;

        IF (runtimeMarkerOpType = BEGIN_FRAGMENT OR runtimeMarkerOpType = ADD_FRAGMENT) THEN
            RETURN;
        END IF;


        IF trace_level >= 1 THEN
            "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'insertToMarker: length current_fragment_raw total = [' || to_char(utl_raw.length(current_fragment_raw)) || ']' );
        END IF;


        -- check if we have fragment from previous call.
        IF utl_raw.length(current_fragment_raw) > 0 THEN
           current_fragment_leftover_pos := 0;

           WHILE (current_fragment_leftover_pos < utl_raw.length(current_fragment_raw) AND end_frag = 0) LOOP
               IF (utl_raw.length(current_fragment_raw) - current_fragment_leftover_pos < 4000) THEN
                  string_chunk := utl_raw.cast_to_varchar2(utl_raw.substr(current_fragment_raw, current_fragment_leftover_pos + 1));
                  end_frag := 1;
               ELSE
                   string_chunk := utl_raw.cast_to_varchar2(utl_raw.substr(current_fragment_raw, current_fragment_leftover_pos + 1, 4000));
               END IF;
               IF trace_level >= 2 THEN
                    "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'insertToMarker: string_chunk = [' ||
                                                string_chunk || '] current_fragment_leftover_pos = [' ||  to_char(current_fragment_leftover_pos)
                                                || ']');
               END IF;

                -- check if multi byte DDL.
                IF length(string_chunk) <> lengthb(string_chunk) THEN
                    IF trace_level >= 2 THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'MB DDL found: ' ||
                                                    to_char(length(string_chunk)) || ' characters, ' ||
                                                    to_char(lengthb(string_chunk)) || ' bytes.');
                    END IF;

                    -- extract only valid characters, so that we don't truncate by middle of character.
                    fragment := substr(string_chunk, 1, length(string_chunk));

                    IF trace_level >= 2 THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'MB DDL fragment: ' ||
                                                    to_char(length(fragment)) || ' characters, ' ||
                                                    fragment);
                    END IF;

                    fragment_raw_length := utl_raw.length(utl_raw.cast_to_raw(fragment));
                    current_fragment_leftover_pos := current_fragment_leftover_pos + fragment_raw_length;
                    IF lengthb(string_chunk) > fragment_raw_length THEN
                        current_fragment_leftover := utl_raw.substr(utl_raw.cast_to_raw(string_chunk),
                                                               fragment_raw_length + 1);
                         IF trace_level >= 2 THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'left over happen [ bytes length:'
                                                    ||  to_char(lengthb(string_chunk))
                                                    || 'character bytes:'
                                                    ||to_char(fragment_raw_length)
                                                    ||']');
                         END IF;

                    ELSE
                        current_fragment_leftover := '';
                    END IF;

                    IF trace_level >= 2 THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE2', 'fragment_raw_length: ' ||
                                                    to_char(fragment_raw_length) || ' bytes.');
                    END IF;
                ELSE
                    fragment := string_chunk;
                    current_fragment_leftover_pos := current_fragment_leftover_pos +  length(string_chunk);
                    current_fragment_leftover := '';
                END IF;


                IF fragment IS NOT NULL THEN
                    -- update fragment number.
                    current_fragment := current_fragment + 1;

                    -- insert into marker table
                    CASE target
                        WHEN GENERIC_MARKER THEN
                            BEGIN
                                IF trace_level >= 1 THEN
                                    "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'insertToMarker: inserting into marker');
                                END IF;
                                INSERT INTO "GG_ADMIN" ."GGS_MARKER" (
                                    seqNo,
                                    fragmentNo,
                                    optime,
                                    TYPE,
                                    SUBTYPE,
                                    marker_text
                                    )
                                    VALUES (
                                    currentMarkerSeq,
                                    current_fragment,
                                    TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS'),
                                    inType,
                                    inSubType,
                                    fragment
                                );
                            END;
                        WHEN DDL_HISTORY THEN
                            BEGIN
                                IF trace_level >= 1 THEN
                                    "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'insertToMarker: inserting into history, objId ['
                                                                || to_char (DDLReplication.currentObjectId) || ']');
                                END IF;
                                INSERT INTO "GG_ADMIN" ."GGS_DDL_HIST" (
                                    seqNo,
                                    objectId,
                                    dataObjectId,
                                    ddlType,
                                    objectName,
                                    objectOwner,
                                    objectType,
                                    fragmentNo,
                                    optime,
                                    startSCN,
                                    metadata_text,
                                    auditcol
                                )
                                VALUES (
                                    currentDDLSeq,
                                    DDLReplication.currentObjectId,
                                    DDLReplication.currentDataObjectId,
                                    DDLReplication.currentDDLType,
                                    DDLReplication.currentObjectName,
                                    DDLReplication.currentObjectOwner,
                                    DDLReplication.currentObjectType,
                                    current_fragment,
                                    TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS'),
                                    "GG_ADMIN" .DDLReplication.SCNB + "GG_ADMIN" .DDLReplication.SCNW * power (2, 32),
                                    fragment,
                                    DDLReplication.currentRowid -- currently for sequences only
                                );
                            END;
                    END CASE;

                    IF trace_level >= 1 THEN
                        "GG_ADMIN" .trace_put_line ('DDLTRACE1', 'insertToMarker: done inserting');
                    END IF;
                END IF;
            END LOOP;
            current_fragment_raw := current_fragment_leftover;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'insertToMarker: ' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END insertToMarker;





    /*
    PROCEDURE CONVERTTOUPPER
    Converts all the unquoted part in a sql statement to upper case and remain the quoted identifiers intact.

    para[in]  stmt                       VARCHAR2                    The sql statement that needs to be converted

    return upperStmt                                                 The converted sql statement
    */

    FUNCTION convertToUpper(
                             stmt IN VARCHAR2
                             )
    RETURN VARCHAR2
    IS
    upperStmt VARCHAR2(32767);
    counter NUMBER;
    tmpChar VARCHAR2(1);
    convert BOOLEAN := TRUE;
    BEGIN
        for counter IN 1..length(stmt)
        LOOP
            tmpChar  := substr(stmt, counter, 1);

        IF tmpChar = '"'  THEN
            convert := NOT convert;
        END IF;

        IF convert  THEN
            upperStmt := upperStmt || upper(tmpChar);
        ELSE
            upperStmt := upperStmt || tmpChar;
        END IF;

    END LOOP;
    return upperStmt;

    EXCEPTION
        WHEN OTHERS THEN
           errorMessage := 'convertToUpper' || ':' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
         RAISE;
    END convertToUpper;



END DDLReplication;
/

