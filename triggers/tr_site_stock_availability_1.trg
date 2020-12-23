CREATE OR REPLACE TRIGGER GG_ADMIN.TR_SITE_STOCK_AVAILABILITY_1
  FOR insert or delete or update ON gg_admin.CSI_ITEM_INSTANCES
  COMPOUND TRIGGER

  v_Contador NUMBER;

  -- Se lanzará después de cada fila actualizada
  AFTER EACH ROW IS
  BEGIN

    dbms_output.put_line('modificacion despues de cada fila');
  END AFTER EACH ROW;

  -- Se lanzará después de la sentencia
  AFTER STATEMENT IS

    CURSOR C_DATOS IS
      SELECT DISTINCT CIIN.instance_id                INSTANCE_ID,
                      CIIN.inventory_item_id          INVENTORY_ID,
                      CIIN.inv_master_organization_id MASTER_ORGANIZATION_ID,
                      CIIN.serial_number              SERIAL_NUMBER,
                      CIIN.lot_number                 FA_NUMBER,
                      CIIN.quantity                   QUANTITY,
                      CIIN.unit_of_measure            UOM,
                      CIIN.location_type_code         LOCATION_TYPE_CODE,
                      CIIN.location_id                LOCATION_ID,
                      CIIN.inv_organization_id        ORGANIZATION_ID,
                      CIIN.inv_subinventory_name      SUBINVENTORY_NAME,
                      CIIN.INV_LOCATOR_ID             LOCATOR_ID,
                      CIIN.pa_project_id              PROJECT_ID,
                      CIIN.pa_project_task_id         PROJECT_TASK_ID,
                      CIIN.install_date               INSTALL_DATE,
                      CIIN.return_by_date             RETURN_BY_DATE,
                      CIIN.actual_return_date         ACTUAL_RETURN_DATE,
                      CIIN.creation_date              ADD_DATE,
                      CIIN.last_update_date           MOD_DATE,
                      CIIN.install_location_id        INSTALL_LOCATION_ID,
                      FAAB.asset_id                   CAPEX,
                      FAAB.attribute_category_code    ASSET_CATEGORY,
                      FAAB.asset_id                   ASSET_ID,
                      FAAB.ASSET_NUMBER               ASSET_NUMBER,
                      FAAB.current_units              CURRENT_UNITS,
                      FAAB.asset_type                 ASSET_TYPE,
                      FAAB.tag_number                 TAG_NUMBER,
                      FAAB.asset_category_id          ASSET_CATEGORY_ID,
                      FAAB.serial_number              SERIAL_NUMBER_FA,
                      FAAB.last_update_date           LAST_UPDATE_DATE,
                      FAAB.creation_date              CREATION_DATE
        FROM erp.mtl_parameters MTLP,
             erp.csi_item_instances CIIN,
             gg_admin.csi_i_assets CIAS,
             gg_admin.fa_additions_b FAAB,
             (SELECT instance_id, transaction_id
                FROM gg_admin.CSI_ITEM_INSTANCES_H
               WHERE (instance_id, creation_date) IN
                     (SELECT instance_id, MAX(creation_date)
                        FROM gg_admin.CSI_ITEM_INSTANCES_H
                       GROUP BY instance_id)) CIH,
             gg_admin.CSI_TRANSACTIONS CT
       WHERE MTLP.attribute9 = 'INFRA'
         AND CT.TRANSACTION_ID = CIH.TRANSACTION_ID
         AND CIH.INSTANCE_ID = CIIN.INSTANCE_ID
         AND CIIN.last_vld_organization_id = MTLP.organization_id
         AND CIIN.instance_id = CIAS.instance_id(+)
         AND CIAS.fa_asset_id = FAAB.asset_id(+)
         and CIIN.instance_id               =:new.INSTANCE_ID
         and CIIN.inventory_item_id         =:new.inventory_item_id
         and CIIN.inv_master_organization_id=:new.inv_master_organization_id
         and CIIN.serial_number             =:new.SERIAL_NUMBER
         and CIIN.lot_number                =:new.lot_number
         and CIIN.quantity                  =:new.QUANTITY
         and CIIN.unit_of_measure           =:new.unit_of_measure
         and CIIN.location_type_code        =:new.LOCATION_TYPE_CODE
         and CIIN.location_id               =:new.LOCATION_ID
         and CIIN.inv_organization_id       =:new.inv_organization_id
         and CIIN.inv_subinventory_name     =:new.inv_subinventory_name
         and CIIN.INV_LOCATOR_ID            =:new.INV_LOCATOR_ID
         and CIIN.pa_project_id             =:new.pa_project_id
         and CIIN.pa_project_task_id        =:new.pa_project_task_id
         and CIIN.install_date              =:new.INSTALL_DATE
         and CIIN.return_by_date            =:new.RETURN_BY_DATE
         and CIIN.actual_return_date        =:new.ACTUAL_RETURN_DATE
         and CIIN.creation_date             =:new.creation_date
         and CIIN.last_update_date          =:new.last_update_date
         and CIIN.install_location_id       =:new.INSTALL_LOCATION_ID;





    TYPE ARRAY IS TABLE OF GG_ADMIN.SITE_STOCK_AVAILABILITY_T%ROWTYPE;
    l_data ARRAY;

				P_instance_id CSI_ITEM_INSTANCES.instance_id%TYPE := :OLD.instance_id;
    P_inventory_item_id CSI_ITEM_INSTANCES.inventory_item_id%TYPE := :OLD.inventory_item_id;
    P_inv_master_organization_id CSI_ITEM_INSTANCES.inv_master_organization_id%TYPE := :OLD.inv_master_organization_id;
    P_serial_number CSI_ITEM_INSTANCES.serial_number%TYPE := :OLD.serial_number;
    P_quantity CSI_ITEM_INSTANCES.quantity%TYPE := :OLD.quantity;
    P_unit_of_measure CSI_ITEM_INSTANCES.unit_of_measure%TYPE := :OLD.unit_of_measure;
    P_location_type_code CSI_ITEM_INSTANCES.location_type_code%TYPE := :OLD.location_type_code;
    P_location_id CSI_ITEM_INSTANCES.location_id%TYPE := :OLD.location_id;
    P_inv_organization_id CSI_ITEM_INSTANCES.inv_organization_id%TYPE := :OLD.inv_organization_id;
    P_inv_subinventory_name CSI_ITEM_INSTANCES.inv_subinventory_name%TYPE := :OLD.inv_subinventory_name;
    P_INV_LOCATOR_ID CSI_ITEM_INSTANCES.INV_LOCATOR_ID%TYPE := :OLD.INV_LOCATOR_ID;
    P_pa_project_id CSI_ITEM_INSTANCES.pa_project_id%TYPE := :OLD.pa_project_id;
    P_pa_project_task_id CSI_ITEM_INSTANCES.pa_project_task_id%TYPE := :OLD.pa_project_task_id;
    P_install_date CSI_ITEM_INSTANCES.install_date%TYPE := :OLD.install_date;
    P_return_by_date CSI_ITEM_INSTANCES.return_by_date%TYPE := :OLD.return_by_date;
    P_actual_return_date CSI_ITEM_INSTANCES.actual_return_date%TYPE := :OLD.actual_return_date;
    P_creation_date CSI_ITEM_INSTANCES.creation_date%TYPE := :OLD.creation_date;
    P_last_update_date  CSI_ITEM_INSTANCES.last_update_date%TYPE := :OLD.last_update_date;
    P_install_location_id CSI_ITEM_INSTANCES.install_location_id%TYPE := :OLD.install_location_id;

	  v_nombre_trigger          varchar2(100):='GG_ADMIN.TR_SITE_STOCK_AVAILABILITY_1';
		v_limit number:= 1000;
		v_INVENTORY_ID varchar2(50):='INVENTORY_ID|';

  BEGIN

    if inserting then

		BEGIN
      OPEN C_DATOS;
      LOOP
        FETCH C_DATOS BULK COLLECT
          INTO l_data LIMIT v_limit;

        FORALL i IN 1 .. l_data.COUNT
          INSERT INTO GG_ADMIN.SITE_STOCK_AVAILABILITY_T VALUES l_data (i);

        EXIT WHEN C_DATOS%NOTFOUND;
      END LOOP;
      CLOSE C_DATOS;
		EXCEPTION
        WHEN OTHERS THEN
          FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
            gg_admin.p_bitacora_trigger(v_nombre_trigger,
                                        sysdate,
                                        sqlcode,
                                        sqlerrm,
                                        dbms_utility.format_error_backtrace,
                                        v_INVENTORY_ID || SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX);
          END LOOP;
      END;

    elsif deleting then


    BEGIN
			DELETE FROM GG_ADMIN.SITE_STOCK_AVAILABILITY_T DEL
    WHERE DEL.instance_id = P_instance_id
             AND DEL.inventory_id  = P_inventory_item_id
             AND DEL.master_organization_id = P_inv_master_organization_id
             AND DEL.serial_number  = P_serial_number
             AND DEL.quantity = P_quantity
             AND DEL.uom  =  P_unit_of_measure
             AND DEL.location_type_code = P_location_type_code
             AND DEL.location_id = P_location_id
             AND DEL.organization_id = P_inv_organization_id
             AND DEL.subinventory_name = P_inv_subinventory_name
             AND DEL.LOCATOR_ID  = P_INV_LOCATOR_ID
             AND DEL.project_id = P_pa_project_id
             AND DEL.project_task_id = P_pa_project_task_id
             AND DEL.install_date = P_install_date
             AND DEL.return_by_date  =  P_return_by_date
             AND DEL.actual_return_date =  P_actual_return_date
             AND DEL.creation_date = P_creation_date
             AND DEL.last_update_date =  P_Last_update_date
             AND DEL.install_location_id =  P_install_location_id;
    EXCEPTION
        WHEN OTHERS THEN
          gg_admin.p_bitacora_trigger(v_nombre_trigger,
                                        sysdate,
                                        sqlcode,
                                        sqlerrm,
                                        dbms_utility.format_error_backtrace,
                                        v_INVENTORY_ID || P_inventory_item_id);
      END;

    elsif updating then

		BEGIN
		  OPEN C_DATOS;
      LOOP
        FETCH C_DATOS BULK COLLECT
          INTO l_data LIMIT v_limit;

      FORALL indx IN 1 .. l_data.COUNT
        UPDATE GG_ADMIN.SITE_STOCK_AVAILABILITY_T UPD
           SET UPD.instance_id            = l_data(indx).INSTANCE_ID,
               UPD.inventory_id           = l_data(indx).INVENTORY_ID,
               UPD.master_organization_id = l_data(indx).MASTER_ORGANIZATION_ID,
               UPD.SERIAL_NUMBER_FA       = l_data(indx).SERIAL_NUMBER_FA,
               UPD.FA_NUMBER              = l_data(indx).FA_NUMBER,
               UPD.quantity               = l_data(indx).QUANTITY,
               UPD.UOM                    = l_data(indx).UOM,
               UPD.location_type_code     = l_data(indx).LOCATION_TYPE_CODE,
               UPD.location_id            = l_data(indx).LOCATION_ID,
               UPD.organization_id        = l_data(indx).ORGANIZATION_ID,
               UPD.subinventory_name      = l_data(indx).SUBINVENTORY_NAME,
               UPD.LOCATOR_ID             = l_data(indx).LOCATOR_ID,
               UPD.project_id             = l_data(indx).PROJECT_ID,
               UPD.project_task_id        = l_data(indx).PROJECT_TASK_ID,
               UPD.install_date           = l_data(indx).INSTALL_DATE,
               UPD.return_by_date         = l_data(indx).RETURN_BY_DATE,
               UPD.actual_return_date     = l_data(indx).ACTUAL_RETURN_DATE,
               UPD.ADD_DATE               = l_data(indx).ADD_DATE,
               UPD.MOD_DATE               = l_data(indx).MOD_DATE,
               UPD.install_location_id    = l_data(indx).INSTALL_LOCATION_ID,
               UPD.CAPEX                  = l_data(indx).CAPEX,
               UPD.ASSET_CATEGORY         = l_data(indx).ASSET_CATEGORY,
               UPD.ASSET_ID               = l_data(indx).ASSET_ID,
               UPD.ASSET_NUMBER           = l_data(indx).ASSET_NUMBER,
               UPD.CURRENT_UNITS          = l_data(indx).CURRENT_UNITS,
               UPD.ASSET_TYPE             = l_data(indx).ASSET_TYPE,
               UPD.TAG_NUMBER             = l_data(indx).TAG_NUMBER,
               UPD.ASSET_CATEGORY_ID      = l_data(indx).ASSET_CATEGORY_ID,
               UPD.SERIAL_NUMBER_FA       = l_data(indx).SERIAL_NUMBER_FA,
               UPD.creation_date          = l_data(indx).CREATION_DATE,
               UPD.last_update_date       = l_data(indx).LAST_UPDATE_DATE
         WHERE UPD.instance_id = l_data(indx).instance_id
           AND UPD.inventory_id = l_data(indx).inventory_id
           AND UPD.master_organization_id = l_data(indx).master_organization_id
           AND UPD.serial_number = l_data(indx).serial_number
           AND UPD.quantity = l_data(indx).quantity
           AND UPD.uom = l_data(indx).UOM
           AND UPD.location_type_code = l_data(indx).location_type_code
           AND UPD.location_id = l_data(indx).location_id
           AND UPD.organization_id = l_data(indx).organization_id
           AND UPD.subinventory_name = l_data(indx).subinventory_name
           AND UPD.LOCATOR_ID = l_data(indx).LOCATOR_ID
           AND UPD.project_id = l_data(indx).project_id
           AND UPD.project_task_id = l_data(indx).project_task_id
           AND UPD.install_date = l_data(indx).install_date
           AND UPD.return_by_date = l_data(indx).return_by_date
           AND UPD.actual_return_date = l_data(indx).actual_return_date
           AND UPD.creation_date = l_data(indx).creation_date
           AND UPD.last_update_date = l_data(indx).last_update_date
           AND UPD.install_location_id = l_data(indx).install_location_id;

					 EXIT WHEN C_DATOS%NOTFOUND;
      END LOOP;
      CLOSE C_DATOS;
    EXCEPTION
        WHEN OTHERS THEN
          FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
            gg_admin.p_bitacora_trigger(v_nombre_trigger,
                                        sysdate,
                                        sqlcode,
                                        sqlerrm,
                                        dbms_utility.format_error_backtrace,
                                        v_INVENTORY_ID || SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX);
          END LOOP;
      END;

    end if;

  END AFTER STATEMENT;
END TR_SITE_STOCK_AVAILABILITY_1;
/

