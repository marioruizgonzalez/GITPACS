CREATE OR REPLACE TRIGGER GG_ADMIN."MTL_SERIAL_NUMBERS_AIU"
/* $Header: invmsntr.sql 115.0 2002/01/14 10:26:23 pkm ship     $ */

BEFORE   INSERT
      OR UPDATE OF status_id
      ON MTL_SERIAL_NUMBERS
FOR EACH ROW
   WHEN (new.status_id is NULL) BEGIN
   :new.status_id := inv_globals.g_material_status_active;
END MTL_SERIAL_NUMBERS_AIU;
/

