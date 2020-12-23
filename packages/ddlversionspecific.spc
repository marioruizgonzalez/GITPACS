CREATE OR REPLACE PACKAGE GG_ADMIN.DDLVersionSpecific AS

CURSOR uk_curs (powner IN VARCHAR2, ptable IN VARCHAR2) IS
    SELECT key.key_name index_name,
                    key.column_name,
                    key.descend
              FROM (SELECT c.constraint_name key_name,
                            c.column_name column_name,
                            c.position position,
                            'ASC' descend
                    FROM dba_cons_columns c
                    WHERE c.owner = powner
                        AND c.table_name = ptable
                        AND c.constraint_name = (
                              SELECT MIN(con1.name) FROM
                                     sys.user$ user1,
                                     sys.user$ user2,
                                     sys.cdef$ cdef,
                                     sys.con$ con1,
                                     sys.con$ con2,
                                     sys.obj$ obj1,
                                     sys.obj$ obj2
                               WHERE user1.name = powner
                                 AND obj1.name = ptable
                                 AND cdef.type# = 3
                                 AND bitand(cdef.defer, 4) = 4
                                 AND cdef.enabled is NOT NULL
                                 AND con2.owner# = user2.user#(+)
                                 AND cdef.robj# = obj2.obj#(+)
                                 AND cdef.rcon# = con2.con#(+)
                                 AND obj1.owner# = user1.user#
                                 AND cdef.con# = con1.con#
                                 AND cdef.obj# = obj1.obj#)
                        AND EXISTS (
                              SELECT 'x'
                                FROM dba_tab_columns t
                               WHERE t.owner = c.owner
                                 AND t.table_name = c.table_name
                                 AND t.column_name = c.column_name)
                      UNION
                      SELECT i.index_name key_name,
                             c.column_name column_name,
                             c.column_position position,
                             c.descend descend
                        FROM dba_indexes i,
                             dba_ind_columns c
                       WHERE i.table_owner = powner
                         AND i.table_name =  ptable
                         AND i.uniqueness = 'UNIQUE'
                         AND i.owner = c.index_owner
                         AND i.index_name = c.index_name
                         AND i.table_name = c.table_name
                         AND i.index_name in ( SELECT index_name
                                FROM dba_indexes
                               WHERE table_owner = powner
                                 AND table_name = ptable
                                AND (visibility != 'INVISIBLE' or 'FALSE' = 'TRUE')
                   AND uniqueness = 'UNIQUE')
                         AND i.index_name NOT IN (
                              SELECT c.constraint_name
                                FROM dba_cons_columns c
                               WHERE c.owner = powner
                                 AND c.table_name = ptable
                                 AND c.constraint_name IN (
                                      SELECT c1.name FROM
                                             sys.user$ u1,
                                             sys.user$ u2,
                                             sys.cdef$ d,
                                             sys.con$ c1,
                                             sys.con$ c2,
                                             sys.obj$ o1,
                                             sys.obj$ o2
                                       WHERE u1.name = powner
                                         AND o1.name = ptable
                                         AND d.type# in (2, 3)
                                         AND 1 = DECODE(1, 1, DECODE(d.enabled,NULL,0,1),1)
                                         AND (d.enabled is NULL
                                              OR d.defer is NULL
                                              OR bitand(d.defer, 32) in (0,32))
                                         AND c2.owner# = u2.user#(+)
                                         AND d.robj# = o2.obj#(+)
                                         AND d.rcon# = c2.con#(+)
                                         AND o1.owner# = u1.user#
                                         AND d.con# = c1.con#
                                         AND d.obj# = o1.obj#)
                                         AND EXISTS (
                                              SELECT 'X'
                                                FROM dba_tab_columns t
                                               WHERE t.owner = c.owner
                                                 AND t.table_name = c.table_name
                                                 AND t.column_name = c.column_name))
                         AND (EXISTS (
                              SELECT 'x'
                                FROM dba_tab_cols t
                               WHERE t.owner = c.table_owner
                                 AND t.table_name = c.table_name
                                 AND t.column_name = c.column_name)
                               OR c.descend = 'DESC')
              ) KEY
              ORDER BY key.key_name,
                       key.position ;

	--  unique keys all keys
    CURSOR uk_curs_all_keys (powner IN VARCHAR2, ptable IN VARCHAR2) IS
       SELECT key.key_name index_name,
            key.column_name ,
            key.descend
       FROM (SELECT  c.constraint_name key_name,
                    c.column_name column_name,
                    c.position position ,
                    'ASC' descend
               FROM dba_cons_columns c
              WHERE c.owner = powner
                AND c.table_name = ptable
                AND c.constraint_name in (
                      SELECT  con1.name
                        FROM sys.user$ user1,
                             sys.user$ user2,
                             sys.cdef$ cdef,
                             sys.con$ con1,
                             sys.con$ con2,
                             sys.obj$ obj1,
                             sys.obj$ obj2
                      WHERE user1.name = powner
                         AND obj1.name = ptable
                         AND cdef.type# = 3
                         AND con2.owner# = user2.user#(+)
                         AND cdef.robj# = obj2.obj#(+)
                         AND cdef.rcon# = con2.con#(+)
                         AND obj1.owner# = user1.user#
                         AND cdef.con# = con1.con#
                         AND cdef.obj# = obj1.obj#)
                AND EXISTS (
                      SELECT  'x'
                        FROM dba_tab_cols t
                       WHERE t.owner = c.owner
                         AND t.table_name = c.table_name
                         AND t.column_name = c.column_name
                         AND t.hidden_column = 'NO')
              UNION ALL
              SELECT  i.index_name key_name,
                     c.column_name column_name,
                     c.column_position position ,
                     c.descend descend
                FROM dba_indexes i,
                     dba_ind_columns c
               WHERE i.table_owner = powner
                 AND i.table_name = ptable
                 AND i.uniqueness = 'UNIQUE'
                 AND i.owner = c.index_owner
                 AND i.index_name = c.index_name
                 AND i.table_name = c.table_name
                 AND i.index_name in (
                      SELECT  index_name
                        FROM dba_indexes
                       WHERE table_owner = powner
                         AND table_name = ptable
                         AND (visibility != 'INVISIBLE' or 'FALSE' = 'TRUE')
                         AND uniqueness = 'UNIQUE')
                 AND NOT EXISTS (
                      SELECT  c.constraint_name
                        FROM dba_cons_columns c
                      WHERE c.owner = powner
                         AND c.table_name = ptable
                         AND c.constraint_name IN (
                              SELECT  c1.name
                                FROM sys.user$ u1,
                                     sys.user$ u2,
                                     sys.cdef$ d,
                                     sys.con$ c1,
                                     sys.con$ c2,
                                     sys.obj$ o1,
                                     sys.obj$ o2
                               WHERE u1.name = powner
                                 AND o1.name = ptable
                                 AND d.type# = 3
                                 AND c2.owner# = u2.user#(+)
                                 AND d.robj# = o2.obj#(+)
                                 AND d.rcon# = c2.con#(+)
                                 AND o1.owner# = u1.user#
                                 AND d.con# = c1.con#
                                 AND d.obj# = o1.obj#)
                                 AND EXISTS (
                                      SELECT  'X'
                                        FROM dba_tab_cols t
                                       WHERE t.owner = c.owner
                                         AND t.table_name = c.table_name
                                         AND t.column_name = c.column_name
                                         AND t.hidden_column = 'NO'))
                 AND (EXISTS (
                      SELECT  'x'
                        FROM dba_tab_cols t
                       WHERE t.owner = powner
                         AND t.table_name = ptable
                         AND t.column_name = c.column_name
                         AND t.hidden_column = 'NO')
                         OR c.descend = 'DESC' )
     ) KEY
     ORDER BY key.key_name,
              key.position;




END DDLVersionSpecific;
/

