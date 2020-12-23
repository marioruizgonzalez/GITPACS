CREATE OR REPLACE TRIGGER GG_ADMIN.TR_WAREHOUSE_STOCK_AVAILABILITY_2
  FOR insert or delete or update ON erp.MTL_SERIAL_NUMBERS
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
      SELECT OH.ORGANIZATION_ID              ORG_ID,
             IL.segment1                     LOCATOR,
             MSI.segment1                    SKU_ID,
             OH.PRIMARY_TRANSACTION_QUANTITY QTY,
             OH.CREATION_DATE                ADD_DATE,
             OH.LAST_UPDATE_DATE             MOD_DATE,
             OH.SUBINVENTORY_CODE            SUBINVENTORY,
             OH.TRANSACTION_UOM_CODE         UOM,
             MSN.SERIAL_NUMBER               SERIAL_NO,
             OH.LOT_NUMBER
        FROM erp.MTL_ONHAND_QUANTITIES_DETAIL OH,
             erp.MTL_ITEM_LOCATIONS           IL,
             erp.MTL_SYSTEM_ITEMS_B           MSI,
             erp.MTL_SERIAL_NUMBERS           MSN
       WHERE oh.organization_id(+) = msi.organization_id
         AND oh.inventory_item_id(+) = msi.inventory_item_id
         AND oh.organization_id = il.organization_id(+)
         AND oh.locator_id = il.inventory_location_id(+)
         AND oh.inventory_item_id = msn.inventory_item_id(+)
         AND oh.last_update_date = msn.last_update_date(+)
				 and msn.inventory_item_id = :new.inventory_item_id
				 and msn.last_update_date = :new.last_update_date
				 and msn.serial_number = :new.serial_number
				 and msn.current_status = 2;


			CURSOR C_DATOS_OUT IS
      SELECT OH.ORGANIZATION_ID              ORG_ID,
             IL.segment1                     LOCATOR,
             MSI.segment1                    SKU_ID,
             OH.PRIMARY_TRANSACTION_QUANTITY QTY,
             OH.CREATION_DATE                ADD_DATE,
             OH.LAST_UPDATE_DATE             MOD_DATE,
             OH.SUBINVENTORY_CODE            SUBINVENTORY,
             OH.TRANSACTION_UOM_CODE         UOM,
             MSN.SERIAL_NUMBER               SERIAL_NO,
             OH.LOT_NUMBER
        FROM erp.MTL_ONHAND_QUANTITIES_DETAIL OH,
             erp.MTL_ITEM_LOCATIONS           IL,
             erp.MTL_SYSTEM_ITEMS_B           MSI,
             erp.MTL_SERIAL_NUMBERS           MSN
       WHERE oh.organization_id(+) = msi.organization_id
         AND oh.inventory_item_id(+) = msi.inventory_item_id
         AND oh.organization_id = il.organization_id(+)
         AND oh.locator_id = il.inventory_location_id(+)
         AND oh.inventory_item_id = msn.inventory_item_id(+)
         AND oh.last_update_date = msn.last_update_date(+)
         and msn.inventory_item_id = :new.inventory_item_id
         and msn.last_update_date = :new.last_update_date
         and msn.serial_number = :new.serial_number
         and msn.current_status <> 2;




    TYPE ARRAY IS TABLE OF GG_ADMIN.WH_STOCK_AVAIL_EXC_SITE_T%ROWTYPE;
    l_data ARRAY;

		P_SERIAL_NO erp.MTL_SERIAL_NUMBERS.serial_number%TYPE:=:OLD.SERIAL_NUMBER;
    v_nombre_trigger          varchar2(100):='GG_ADMIN.TR_WAREHOUSE_STOCK_AVAILABILITY_2';
		v_limit number:= 1000;
		v_SERIAL_NO varchar2(50):='SERIAL_NO|';

  BEGIN

    if inserting then

		BEGIN 
      OPEN C_DATOS;
      LOOP
        FETCH C_DATOS BULK COLLECT
          INTO l_data LIMIT v_limit;

        FORALL i IN 1 .. l_data.COUNT
          INSERT INTO GG_ADMIN.WH_STOCK_AVAIL_EXC_SITE_T
          VALUES l_data
            (i);

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
                                        v_SERIAL_NO || SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX);
          END LOOP;
      END;


    elsif deleting then

    BEGIN
        DELETE FROM GG_ADMIN.WH_STOCK_AVAIL_EXC_SITE_T DEL
         WHERE del.SERIAL_NO = P_SERIAL_NO;
    EXCEPTION
        WHEN OTHERS THEN
          gg_admin.p_bitacora_trigger(v_nombre_trigger,
                                        sysdate,
                                        sqlcode,
                                        sqlerrm,
                                        dbms_utility.format_error_backtrace,
                                        v_SERIAL_NO || P_SERIAL_NO);
      END;

    elsif updating then

    BEGIN
    OPEN C_DATOS;
      LOOP
        FETCH C_DATOS BULK COLLECT
          INTO l_data LIMIT v_limit;

    FORALL indx IN 1 .. l_data.COUNT
        UPDATE GG_ADMIN.WH_STOCK_AVAIL_EXC_SITE_T UPD
           SET UPD.ORG_ID       = l_data(indx).ORG_ID,
               UPD.LOCATOR      = l_data(indx).LOCATOR,
               UPD.SKU_ID       = l_data(indx).SKU_ID,
               UPD.qty          = l_data(indx).QTY,
               UPD.ADD_DATE     = l_data(indx).ADD_DATE,
               UPD.MOD_DATE     = l_data(indx).MOD_DATE,
               UPD.SUBINVENTORY = l_data(indx).SUBINVENTORY,
               UPD.UOM          = l_data(indx).UOM,
               UPD.SERIAL_NO    = l_data(indx).SERIAL_NO,
               UPD.LOT_NUMBER   = l_data(indx).LOT_NUMBER
         WHERE UPD.SERIAL_NO = l_data(indx).SERIAL_NO;

            EXIT WHEN C_DATOS%NOTFOUND;
      END LOOP;
      CLOSE C_DATOS;

    OPEN C_DATOS_OUT;
      LOOP
        FETCH C_DATOS BULK COLLECT
          INTO l_data LIMIT v_limit;

		FOR I IN 1..l_data.COUNT
			LOOP
    DELETE FROM GG_ADMIN.WH_STOCK_AVAIL_EXC_SITE_T DEL
         WHERE del.SERIAL_NO = l_data(i).SERIAL_NO;
		 END LOOP;

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
                                        v_SERIAL_NO || SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX);
          END LOOP;
      END;

    end if;

  END AFTER STATEMENT;
END TR_WAREHOUSE_STOCK_AVAILABILITY_2;
/

