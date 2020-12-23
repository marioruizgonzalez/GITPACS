CREATE OR REPLACE PACKAGE GG_ADMIN.DDLAux AS

  TB_IOT CONSTANT NUMBER := 960;
  TB_CLUSTER CONSTANT NUMBER := 1024;
  TB_NESTED CONSTANT NUMBER := 8192;
  TB_TEMP CONSTANT NUMBER := 12582912;
  TB_EXTERNAL CONSTANT NUMBER := 2147483648;

  TYPE_INDEX CONSTANT NUMBER := 1;
  TYPE_TABLE CONSTANT NUMBER := 2;
  TYPE_VIEW CONSTANT NUMBER := 4;
  TYPE_SYNONYM CONSTANT NUMBER := 5;
  TYPE_SEQUENCE CONSTANT NUMBER := 6;
  TYPE_PROCEDURE CONSTANT NUMBER := 7;
  TYPE_FUNCTION CONSTANT NUMBER := 8;
  TYPE_PACKAGE CONSTANT NUMBER := 9;
  TYPE_TRIGGER CONSTANT NUMBER := 12;

  CMD_CREATE CONSTANT varchar2(10) := 'CREATE';
  CMD_DROP CONSTANT varchar2(10) := 'DROP';
  CMD_TRUNCATE CONSTANT varchar2(10) := 'TRUNCATE';
  CMD_ALTER CONSTANT varchar2(10) := 'ALTER';


  /* Add a rule for inclusion or exclusion so that DDL trigger will handle
   * the matching object appropriately. Rules are evaluated in the sorted
   * order (asc) of sno. If the sno is not specified then the rule will be
   * added in the tail end (max(sno) + 1). If the user
   * want to position the rule inbetween two already existing rule
   * could use decimals in between.
   * The users can place rules as 11.1, 11.2 etc.
   * The rules added will be placed in the table GGS_DDL_RULES
   * Rule addition examples
   * To exclude all objects having name like  GGS%
   *    addRule(obj_name=> 'GGS%');
   * To exclude all temporary table
   *    addRule(base_obj_property => TB_TEMP, obj_type => TYPE_TABLE);
   * To exclude all External table
   *    addRule(base_obj_property => TB_EXTERNAL, obj_type => TYPE_TABLE);
   * To exclude all INDEXES on External table
   *    addRule(base_obj_property => TB_EXTERNAL, obj_type => TYPE_INDEX);
   * To exclude all truncate table ddl
   *    addRule(obj_type=>TYPE_TABLE, command => CMD_TRUNCATE);
   *
   */
  FUNCTION addRule(obj_name IN VARCHAR2 DEFAULT NULL,
                   base_obj_name IN VARCHAR2 DEFAULT NULL,
                   owner_name IN VARCHAR2 DEFAULT NULL,
                   base_owner_name IN VARCHAR2 DEFAULT NULL,
                   base_obj_property IN NUMBER DEFAULT NULL,
                   obj_type IN NUMBER  DEFAULT NULL,
                   command IN VARCHAR2 DEFAULT NULL,
                   inclusion IN boolean DEFAULT NULL ,
                   sno IN NUMBER DEFAULT NULL)
  RETURN NUMBER;

  /* Drop rule by the rule serial number */
  FUNCTION dropRule(dsno IN NUMBER) RETURN BOOLEAN;

  PROCEDURE listRules;

  /* This function returns TRUE if the current ddl object should be skipped
   * FALSE if it should not be skipped.
   * This function consults the GGS_DDL_RULES table to check for inclusion
   * or exclusion. All excluded objects are logged into the table
   * GGS_DDL_RULES_LOG
   */
  FUNCTION SKIP_OBJECT(obj_id IN NUMBER, base_obj_id IN OUT NUMBER,
                       OBJ_NAME varchar2, obj_owner varchar2,
                       obj_type NUMBER, base_obj_name varchar2,
                       base_owner_name varchar2,
                       command varchar2)
  RETURN BOOLEAN ;

  /* Records an exclusion in GGS_DDL_RULES_LOG table */
  PROCEDURE recordExclusion(sno IN NUMBER, OBJ_NAME varchar2,
                       obj_owner varchar2,
                       obj_type NUMBER, base_obj_name varchar2,
                       base_owner_name varchar2, base_obj_property number,
                       command varchar2);

  CURSOR ignoreObj IS
         SELECT sno, obj_name, owner_name, base_obj_name, base_owner_name,
                base_obj_property, obj_type, command,  inclusion
         from "GG_ADMIN"."GGS_DDL_RULES" order by sno;
END DDLAux;
/

