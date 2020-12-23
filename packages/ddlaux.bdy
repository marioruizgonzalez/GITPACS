CREATE OR REPLACE PACKAGE BODY GG_ADMIN.DDLAux AS

  FUNCTION addRule(obj_name IN VARCHAR2 DEFAULT NULL,
                   base_obj_name IN VARCHAR2 DEFAULT NULL,
                   owner_name IN VARCHAR2 DEFAULT NULL,
                   base_owner_name IN VARCHAR2 DEFAULT NULL,
                   base_obj_property IN NUMBER DEFAULT NULL,
                   obj_type IN NUMBER  DEFAULT NULL,
                   command IN VARCHAR2  DEFAULT NULL,
                   inclusion IN boolean DEFAULT NULL ,
                   sno IN NUMBER DEFAULT NULL)
  RETURN NUMBER IS
   new_sno NUMBER;
   cnt NUMBER;
   to_include number;
  BEGIN
    if inclusion then
    to_include := 1;
    else
    to_include := 0;
    end if;
    BEGIN
      /* If SNO is not specified then find the next SNO automatically */
      IF SNO IS NULL THEN
        BEGIN
          SELECT count(*) ,MAX(SNO) into cnt,NEW_SNO
          FROM "GG_ADMIN"."GGS_DDL_RULES";

          /* MAX(SNO) + 1 */
          IF cnt = 0 THEN
           NEW_SNO := 1;
          ELSE
           NEW_SNO := NEW_SNO + 1;
          END IF;
        EXCEPTION WHEN OTHERS THEN
          new_sno := 1;
        END;
      ELSE
        NEW_SNO := SNO;
      END IF;

      INSERT INTO "GG_ADMIN"."GGS_DDL_RULES" VALUES
      (NEW_SNO, OBJ_NAME, OWNER_NAME, BASE_OBJ_NAME, BASE_OWNER_NAME,
       base_obj_PROPERTY, OBJ_TYPE, command, to_include);

      COMMIT;
      RETURN NEW_SNO;
    EXCEPTION WHEN OTHERS THEN
     --dbms_output.put_line (SQLERRM);
     IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
       "GG_ADMIN" .trace_put_line ('DDLTRACE1','INSERT INTO GGS_DDL_RULES ERROR:'||
                                   SQLERRM);
     END IF;
    END;
    RETURN -1;
  END;

  FUNCTION dropRule(dsno IN NUMBER) RETURN BOOLEAN IS
  BEGIN
    BEGIN
      DELETE FROM "GG_ADMIN"."GGS_DDL_RULES" WHERE SNO = dsno;
      COMMIT;
      RETURN TRUE;
    EXCEPTION WHEN OTHERS THEN
     IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
       "GG_ADMIN" .trace_put_line ('DDLTRACE1','DELETE FROM GGS_DDL_RULES ERROR:'||
                                   SQLERRM);
     END IF;
    END;
    RETURN FALSE;
  END;

  PROCEDURE listRules IS
  BEGIN
      NULL;
  END;

  PROCEDURE recordExclusion(sno IN NUMBER, OBJ_NAME varchar2,
                       obj_owner varchar2,
                       obj_type NUMBEr, base_obj_name varchar2,
                       base_owner_name varchar2, base_obj_property number,
                       command varchar2) IS
  BEGIN
    BEGIN
      INSERT INTO "GG_ADMIN"."GGS_DDL_RULES_LOG" VALUES
      (sno, OBJ_NAME, obj_owner, BASE_OBJ_NAME, BASE_OWNER_NAME,
       base_obj_PROPERTY, OBJ_TYPE, command);

    EXCEPTION WHEN OTHERS THEN
     --dbms_output.put_line('recordEx:'||SQLERRM);
     IF "GG_ADMIN" .DDLReplication.trace_level >= 1 THEN
       "GG_ADMIN" .trace_put_line ('DDLTRACE1','INSERT INTO GGS_DDL_RULES_LOG ERROR:'||
                                   SQLERRM);
     END IF;
   END;
  END;

  FUNCTION SKIP_OBJECT(obj_id IN NUMBER, base_obj_id IN OUT NUMBER,
                       obj_name varchar2, obj_owner varchar2,
                       obj_type NUMBER, base_obj_name varchar2,
                       base_owner_name varchar2, command varchar2)
  RETURN BOOLEAN IS
    tab_prop number;
    obj_name_match boolean;
    owner_name_match boolean;
    type_match boolean;
    property_match boolean;
    base_obj_match boolean;
    base_owner_match boolean;
    command_match boolean;
    exclude boolean;
  BEGIN
    --dbms_output.put_line('SKIPRULE');
    FOR n IN ignoreObj LOOP
      obj_name_match := false;
      owner_name_match := false;
      type_match := false;
      base_obj_match := false;
      base_owner_match := false;
      property_match := false;
      command_match := false;

      --dbms_output.put_line('SKIP_RULE:no:'||n.sno);

      -- TODO : Need to upper ? Using exactly allows user to choose
      -- tables with mixed case names as well.
      obj_name_match := (obj_name) like (n.obj_name) or
                        n.obj_name is null;
      owner_name_match := (obj_owner) like (n.owner_name) or
                           n.owner_name is null;
      type_match := (obj_type) like (n.obj_type) or
                    n.obj_type is null;

      base_owner_match := (base_owner_name) like (n.base_owner_name)
                          or n.base_owner_name is NULL;

      base_obj_match := (base_obj_name) like (n.base_obj_name) or
                        n.base_obj_name is null;

      command_match := (command) like (n.command) or n.command is null;

      /* the default is exclusion rule */
      exclude := (n.inclusion is null or n.inclusion = 0);

      IF (obj_name_match and owner_name_match and type_match and
          base_owner_match and base_obj_match and command_match) --5
      THEN
         /* If property was specified then check if it matches */
         IF n.base_obj_property is not null -- 3
         THEN
           BEGIN
             /* For everything other than "create table" we should be
              * able to get the table property
              */
             if command <> CMD_CREATE  or n.obj_type <> TYPE_TABLE -- 2
             THEN
               if base_obj_id is null or base_obj_id = -1 then
                 select o.obj# into base_obj_id from sys.obj$ o, sys.user$ u
                 where o.name = base_obj_name and u.name = base_owner_name
                       and o.owner# = u.user# and o.subname is NULL  and o.remoteowner is null and o.linkname is null;
               end if;

               --dbms_output.put_line('SKIP_RULE:bo_id:'||base_obj_id);
               select t.property into tab_prop from sys.tab$ t
               where t.obj# = base_obj_id;
             ELSE
               /* if its create table then check if rdbms code filled the
                * property
                */
               if "GG_ADMIN".DDLReplication.ddlBaseObjProperty <> -1
               THEN
                 tab_prop := "GG_ADMIN".DDLReplication.ddlBaseObjProperty;
               ELSE
                 tab_prop := 0;
               END IF;
             END IF; --2
               --dbms_output.put_line('SKIP_RULE:matching:'||base_obj_id);
           property_match := bitand(tab_prop, n.base_obj_property) <> 0;
               --dbms_output.put_line('SKIP_RULE:matching:'||tab_prop);
           EXCEPTION WHEN NO_DATA_FOUND THEN
            --dbms_output.put_line('SKIP_RULE:'||SQLERRM);
            property_match := false;
           END;
           IF property_match THEN
             IF exclude THEN
                recordExclusion(n.sno, OBJ_NAME, obj_owner,
                       obj_type, base_obj_name ,
                       base_owner_name , tab_prop ,
                       command);
             END IF;
             return  exclude;
           END IF;
        ELSE
             IF exclude THEN
                recordExclusion(n.sno, OBJ_NAME, obj_owner,
                       obj_type, base_obj_name ,
                       base_owner_name , tab_prop ,
                       command);
             END IF;
          return exclude;
        END IF; --3
      END IF; -- 5
   END LOOP;
   RETURN FALSE; -- if no rule matched , default is to include
  END;


END DDLAux;
/

