CREATE OR REPLACE TRIGGER GG_ADMIN.TR_WAREHOUSE_STOCK_AVAILABILITY_1
  FOR insert or delete or update ON GG_ADMIN.MTL_ONHAND_QUANTITIES_DETAIL
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
         and oh.ORGANIZATION_ID = :new.ORGANIZATION_ID
         and oh.PRIMARY_TRANSACTION_QUANTITY =
             :new.PRIMARY_TRANSACTION_QUANTITY
         and oh.CREATION_DATE = :new.CREATION_DATE
         and oh.LAST_UPDATE_DATE = :new.LAST_UPDATE_DATE
         and oh.SUBINVENTORY_CODE = :new.SUBINVENTORY_CODE
         and oh.TRANSACTION_UOM_CODE = :new.TRANSACTION_UOM_CODE
         and oh.LOT_NUMBER = :new.LOT_NUMBER;

    TYPE ARRAY IS TABLE OF GG_ADMIN.WH_STOCK_AVAIL_EXC_SITE_T%ROWTYPE;
    l_data ARRAY;

    P_ORGANIZATION_ID              MTL_ONHAND_QUANTITIES_DETAIL.ORGANIZATION_ID%TYPE := :OLD.ORGANIZATION_ID;
    P_PRIMARY_TRANSACTION_QUANTITY MTL_ONHAND_QUANTITIES_DETAIL.PRIMARY_TRANSACTION_QUANTITY%TYPE := :OLD.PRIMARY_TRANSACTION_QUANTITY;
    P_CREATION_DATE                MTL_ONHAND_QUANTITIES_DETAIL.CREATION_DATE%TYPE := :OLD.CREATION_DATE;
    P_LAST_UPDATE_DATE             MTL_ONHAND_QUANTITIES_DETAIL.LAST_UPDATE_DATE%TYPE := :OLD.LAST_UPDATE_DATE;
    P_SUBINVENTORY_CODE            MTL_ONHAND_QUANTITIES_DETAIL.SUBINVENTORY_CODE%TYPE := :OLD.SUBINVENTORY_CODE;
    P_TRANSACTION_UOM_CODE         MTL_ONHAND_QUANTITIES_DETAIL.TRANSACTION_UOM_CODE%TYPE := :OLD.TRANSACTION_UOM_CODE;
    P_LOT_NUMBER                   MTL_ONHAND_QUANTITIES_DETAIL.LOT_NUMBER%TYPE := :OLD.LOT_NUMBER;
    v_nombre_trigger          varchar2(100):='GG_ADMIN.TR_WAREHOUSE_STOCK_AVAILABILITY_1';
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
         WHERE del.ORG_ID = P_ORGANIZATION_ID
           and del.qty = P_PRIMARY_TRANSACTION_QUANTITY
           and del.ADD_DATE = P_CREATION_DATE
           and del.MOD_DATE = P_LAST_UPDATE_DATE
           and del.SUBINVENTORY = P_SUBINVENTORY_CODE
           and del.UOM = P_TRANSACTION_UOM_CODE
           and del.LOT_NUMBER = P_LOT_NUMBER;
      EXCEPTION
        WHEN OTHERS THEN
          gg_admin.p_bitacora_trigger(v_nombre_trigger,
                                        sysdate,
                                        sqlcode,
                                        sqlerrm,
                                        dbms_utility.format_error_backtrace,
                                        'inventory_item_id|' || :old.inventory_item_id);
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
             WHERE UPD.ORG_ID = l_data(indx).ORG_ID
               and UPD.qty = l_data(indx).QTY
               and UPD.ADD_DATE = l_data(indx).ADD_DATE
               and UPD.MOD_DATE = l_data(indx).MOD_DATE
               and UPD.SUBINVENTORY = l_data(indx).SUBINVENTORY
               and UPD.UOM = l_data(indx).UOM
               and UPD.LOT_NUMBER = l_data(indx).LOT_NUMBER;

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

END TR_WAREHOUSE_STOCK_AVAILABILITY_1;
/

