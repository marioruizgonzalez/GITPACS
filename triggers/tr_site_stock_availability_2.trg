CREATE OR REPLACE TRIGGER GG_ADMIN.TR_SITE_STOCK_AVAILABILITY_2
  FOR insert or delete or update ON gg_admin.FA_ADDITIONS_B
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
				 and FAAB.asset_id                =:new.asset_id                 
         and FAAB.attribute_category_code =:new.attribute_category_code  
         and FAAB.asset_id                =:new.asset_id                 
         and FAAB.ASSET_NUMBER            =:new.ASSET_NUMBER             
         and FAAB.current_units           =:new.current_units            
         and FAAB.asset_type              =:new.asset_type               
         and FAAB.tag_number              =:new.tag_number               
         and FAAB.asset_category_id       =:new.asset_category_id        
         and FAAB.serial_number           =:new.serial_number            
         and FAAB.last_update_date        =:new.last_update_date         
         and FAAB.creation_date           =:new.creation_date;

    TYPE ARRAY IS TABLE OF GG_ADMIN.SITE_STOCK_AVAILABILITY_T%ROWTYPE;
    l_data ARRAY;

    P_asset_id                FA_ADDITIONS_B.asset_id%TYPE := :OLD.asset_id;
    P_attribute_category_code FA_ADDITIONS_B.attribute_category_code%TYPE := :OLD.attribute_category_code;
    P_ASSET_NUMBER            FA_ADDITIONS_B.ASSET_NUMBER%TYPE := :OLD.ASSET_NUMBER;
    P_current_units           FA_ADDITIONS_B.current_units%TYPE := :OLD.current_units;
    P_asset_type              FA_ADDITIONS_B.asset_type%TYPE := :OLD.asset_type;
    P_tag_number              FA_ADDITIONS_B.tag_number%TYPE := :OLD.tag_number;
    P_asset_category_id       FA_ADDITIONS_B.asset_category_id%TYPE := :OLD.asset_category_id;
    P_serial_number           FA_ADDITIONS_B.serial_number%TYPE := :OLD.serial_number;
    P_last_update_date        FA_ADDITIONS_B.last_update_date%TYPE := :OLD.last_update_date;
    P_creation_date           FA_ADDITIONS_B.creation_date%TYPE := :OLD.creation_date;
    v_nombre_trigger          varchar2(100):='GG_ADMIN.TR_SITE_STOCK_AVAILABILITY_2';
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
            INSERT INTO GG_ADMIN.SITE_STOCK_AVAILABILITY_T
            VALUES l_data
              (i);
          EXIT WHEN C_DATOS%NOTFOUND;

        END LOOP;
        CLOSE C_DATOS;
      EXCEPTION
        WHEN others THEN
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
         WHERE DEL.asset_id = P_asset_id
           AND DEL.asset_category = P_attribute_category_code
           AND DEL.ASSET_NUMBER = P_ASSET_NUMBER
           AND DEL.current_units = P_current_units
           AND DEL.asset_type = P_asset_type
           AND DEL.tag_number = P_tag_number
           AND DEL.asset_category_id = P_asset_category_id
           AND DEL.serial_number = P_serial_number
           AND DEL.last_update_date = P_last_update_date
           AND DEL.creation_date = P_creation_date;
      EXCEPTION
        WHEN OTHERS THEN

            gg_admin.p_bitacora_trigger(v_nombre_trigger,
                                        sysdate,
                                        sqlcode,
                                        sqlerrm,
                                        dbms_utility.format_error_backtrace,
                                        'serial_number' || P_serial_number);

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
             WHERE UPD.asset_id = l_data(indx).asset_id
               AND UPD.asset_category = l_data(indx).asset_category
               AND UPD.ASSET_NUMBER = l_data(indx).ASSET_NUMBER
               AND UPD.current_units = l_data(indx).current_units
               AND UPD.asset_type = l_data(indx).asset_type
               AND UPD.tag_number = l_data(indx).tag_number
               AND UPD.asset_category_id = l_data(indx).asset_category_id
               AND UPD.serial_number = l_data(indx).serial_number
               AND UPD.last_update_date = l_data(indx).last_update_date
               AND UPD.creation_date = l_data(indx).creation_date;

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
END TR_SITE_STOCK_AVAILABILITY_2;
/

