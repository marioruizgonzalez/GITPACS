CREATE OR REPLACE TRIGGER GG_ADMIN."DR$HR_LOCATIONS_N1TC" after insert or update on "HR_LOCATIONS_ALL" for each row
declare   reindex boolean := FALSE;   updop   boolean := FALSE; begin   ctxsys.drvdml.c_updtab.delete;   ctxsys.drvdml.c_numtab.delete;   ctxsys.drvdml.c_vctab.delete;   ctxsys.drvdml.c_rowid := :new.rowid;   if (inserting or updating('DERIVED_LOCALE')) then     reindex := TRUE;     updop := (not inserting);     ctxsys.drvdml.c_text_vc2 := :new."DERIVED_LOCALE";   end if;   ctxsys.drvdml.ctxcat_dml('HR','HR_LOCATIONS_N1', reindex, updop); end;
/

