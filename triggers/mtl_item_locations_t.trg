CREATE OR REPLACE TRIGGER GG_ADMIN."MTL_ITEM_LOCATIONS_T"
/* $Header: INVLOCTR.sql 120.0 2005/05/25 05:32:27 appldev noship $ */
--INVCONV kkillams
--END INVCONV kkillams
BEFORE INSERT
OR UPDATE
ON "MTL_ITEM_LOCATIONS"
FOR EACH ROW
DECLARE
--INVCONV kkillams
CURSOR cur_mat IS SELECT ms.reservable_type,
                         ms.availability_type,
                         ms.inventory_atp_code FROM mtl_material_statuses_b ms
                                               WHERE ms.status_id = :NEW.status_id;
--END INVCONV kkillams
  v_project_reference_enabled  number;
  v_pm_cost_collection_enabled number;
  v_project_control_level      number;
  v_success                    boolean;

BEGIN
  IF INSERTING THEN --INVCONV kkillams
  inv_project.update_project_task(:new.organization_id,
                                  to_number(:new.segment19),
                                  to_number(:new.segment20),
                                  :new.project_id,
                                  :new.task_id);
   END IF; --INVCONV kkillams
   --INVCONV KKILLAMS
   IF :NEW.status_id <> NVL(:OLD.STATUS_ID,-1) THEN
       OPEN cur_mat;
       FETCH cur_mat INTO :NEW.reservable_type,
                          :NEW.availability_type,
                          :NEW.inventory_atp_code;
       CLOSE cur_mat;
   END IF;
   --END INVCONV KKILLAMS
END;
/

