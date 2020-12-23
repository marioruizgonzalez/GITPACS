CREATE OR REPLACE PROCEDURE GG_ADMIN.ddlora_getLobs (
                                                             powner IN VARCHAR2,
                                                             ptable IN VARCHAR2,
                                                             trueName IN VARCHAR2,
                                                             intcolNum IN NUMBER)
IS
    lobEncrypt VARCHAR2(400);
    lobCompress VARCHAR2(400);
    lobDedup VARCHAR2(400);
    errorMessage VARCHAR2(32767);
BEGIN
    BEGIN
        -- bug 13255581: dba_lobs uses fully qualified column name.
        -- This query can be simplified further if sys.lob$ is used instead,
        -- or if column number is used instead of column name.
        SELECT max(decode(l.encrypt, 'NO', 0, 'NONE', 0, 1)) isEnc,
               max(decode(l.compression, 'NO', 0, 'NONE', 0, 1)) isComp,
               max(decode(l.deduplication, 'NO', 0, 'NONE', 0, 1)) isDedup
          INTO lobEncrypt, lobCompress, lobDedup
          FROM dba_tab_cols c, dba_tab_cols tc, dba_lobs l
          WHERE c.owner = tc.owner AND c.table_name = tc.table_name
            AND c.owner = l.owner AND c.table_name = l.table_name
            AND c.column_id = tc.column_id AND c.qualified_col_name = l.column_name
            AND c.owner = powner AND c.table_name = ptable AND tc.column_name= trueName;

    EXCEPTION
        WHEN OTHERS THEN
            errorMessage := 'get LOB info, error: ' || SQLERRM;
            "GG_ADMIN" .trace_put_line ('DDL', errorMessage);
            RAISE;
    END;
    DDLReplication.insertToMarker (DDLReplication.DDL_HISTORY, '', '',
                                   DDLReplication.itemHeader (DDLReplication.MD_COL_LOB_ENCRYPT, to_char (intcolNum), trueName, lobEncrypt,
                                   DDLReplication.ITEM_WHOLE) ||
                                   DDLReplication.itemHeader (DDLReplication.MD_COL_LOB_DEDUP, to_char (intcolNum), trueName, lobDedup,
                                   DDLReplication.ITEM_WHOLE) ||
                                   DDLReplication.itemHeader (DDLReplication.MD_COL_LOB_COMPRESS, to_char (intcolNum), trueName, lobCompress,
                                   DDLReplication.ITEM_WHOLE)
                                   , DDLReplication.ADD_FRAGMENT);
    RETURN;
END;
/

