create or replace procedure gg_admin.p_sku_instance_both is
  V_ERROR              VARCHAR2(32767);
  v_TRANSACTION_ID     number;
  v_VISTA_SKU_INSTANCE varchar2(32767);
  v_limit              number := 1000;
  v_limit2             number := 1000;
  P_MAX_TRANSACTION_ID number;
  v_counter_write      number:= 0;
  TYPE ARRAY IS TABLE OF GG_ADMIN.SKU_INSTANCE_HIST%ROWTYPE;
  l_data ARRAY;

  TYPE ARRAY1 IS TABLE OF GG_ADMIN.SKU_INSTANCE_DETAIL_HIST%ROWTYPE;
  l_data_DETAIL ARRAY1;

  CURSOR C_SKU_INSTANCE(P_TRANSACTION_ID     NUMBER,
                        P_MAX_TRANSACTION_ID NUMBER) IS
    SELECT A.ERP_INVENTORY_ID,
           A.SKU,
           A.ADD_DATE,
           A.MOD_DATE,
           A.ORG_ID,
           A.UOM_,
           A.SUBINVENTORY_SHORT_CODE,
           A.LOCATOR_ID,
           A.LOCATOR_SHORT_NAME,
           A.SOURCE_TYPE,
           A.TRANSACTION_TYPE,
           A.TRANSACTION_SOURCE,
           A.TRANSACTION_TIME,
           A.LPN_NO,
           A.SHIPMENT_NO,
           A.TRANSACTION_ACTION,
           A.LOCATION,
           A.SOURCE_PROJECT_NUMBER,
           A.SOURCE_TASK_NUMBER,
           A.PROJECT_NUMBER,
           A.TASK_NUMBER,
           A.TO_PROJECT_NUMBER,
           A.TO_TASK_NUMBER,
           A.FROM_OWNING_PARTY,
           CASE
             WHEN TRANSACTION_TYPE_ID = 21 THEN
              A.FREIGHT_CODE
             WHEN TRANSACTION_TYPE_ID = 3 THEN
              A.CARRIER_ID
             WHEN TRANSACTION_TYPE_ID != 3 OR TRANSACTION_TYPE_ID != 21 OR
                  TRANSACTION_TYPE_ID != 64 THEN
              A.CARRIER_ID
           END TRANSPORT_COMPANY_ID,
           CASE
             WHEN TRANSACTION_TYPE_ID = 21 THEN
              A.FREIGHT_CODE1
             WHEN TRANSACTION_TYPE_ID = 3 THEN
              A.FREIGHT_CODE
             WHEN TRANSACTION_TYPE_ID != 3 OR TRANSACTION_TYPE_ID != 21 OR
                  TRANSACTION_TYPE_ID != 64 THEN
              A.FREIGHT_CODE1
           END TRANSPORT_COMPANY_NAME,
           CASE
             WHEN TRANSACTION_TYPE_ID = 21 THEN
              'NA'
             WHEN TRANSACTION_TYPE_ID = 3 THEN
              'NA'
             WHEN TRANSACTION_TYPE_ID != 3 OR TRANSACTION_TYPE_ID != 21 OR
                  TRANSACTION_TYPE_ID != 64 THEN
              A.NAME_DELIVERY_PERSON
           END NAME_DELIVERY_PERSON,
           CASE
             WHEN TRANSACTION_TYPE_ID = 21 THEN
              A.WAYBILL_AIRBILL
             WHEN TRANSACTION_TYPE_ID = 3 THEN
              A.WAYBILL_AIRBILL
             WHEN TRANSACTION_TYPE_ID != 3 OR TRANSACTION_TYPE_ID != 21 OR
                  TRANSACTION_TYPE_ID != 64 THEN
              A.VEHICLE_NUMBER
           END PLATE_NO,
           'NA' TRANSPORT_ATT_ID,
           A.MOD_BY,
           A.POSTAL_CODE FORM_ZIP_CODE,
           A.POSTAL_CODE TO_ZIP_CODE,
           A.ORG_DES,
           A.SUBINV_DES,
           A.LOC_DES,
           A.MOVE_ORDER_LINE_ID,
           A.TRANSACTION_SOURCE_ID,
           A.SHIP_TO_LOCATION_ID,
           A.OC,
           A.TRANSACTION_ID
      FROM (SELECT MMT.TRANSACTION_ID ERP_INVENTORY_ID,
                   (SELECT UNIQUE MSI.SEGMENT1
                      FROM APPS.MTL_SYSTEM_ITEMS_B@OFNX_SPERTO MSI
                     WHERE MSI.ORGANIZATION_ID = MMT.ORGANIZATION_ID
                       AND MSI.INVENTORY_ITEM_ID = MMT.INVENTORY_ITEM_ID) SKU,
                   MMT.CREATION_DATE ADD_DATE,
                   MMT.LAST_UPDATE_DATE MOD_DATE,
                   MMT.ORGANIZATION_ID ORG_ID,
                   MMT.TRANSACTION_UOM UOM_,
                   MMT.SUBINVENTORY_CODE SUBINVENTORY_SHORT_CODE,
                   MMT.LOCATOR_ID LOCATOR_ID,
                   (SELECT UNIQUE MIL.SEGMENT1
                      FROM APPS.MTL_ITEM_LOCATIONS@OFNX_SPERTO MIL
                     WHERE 1 = 1
                       AND INVENTORY_LOCATION_ID = MMT.LOCATOR_ID
                       AND ROWNUM = 1) LOCATOR_SHORT_NAME,
                   (SELECT UNIQUE MTST_ST.TRANSACTION_SOURCE_TYPE_NAME
                      FROM INV.MTL_TXN_SOURCE_TYPES@OFNX_SPERTO MTST_ST
                     WHERE 1 = 1
                       AND MTST_ST.TRANSACTION_SOURCE_TYPE_ID =
                           MMT.TRANSACTION_SOURCE_TYPE_ID
                       AND ROWNUM = 1) SOURCE_TYPE,
                   (SELECT UNIQUE TRANSACTION_TYPE_NAME
                      FROM INV.MTL_TRANSACTION_TYPES@OFNX_SPERTO MTTRX
                     WHERE 1 = 1
                       AND MTTRX.TRANSACTION_TYPE_ID =
                           MMT.TRANSACTION_TYPE_ID
                       AND ROWNUM = 1) TRANSACTION_TYPE,
                   MMT.TRANSACTION_SOURCE_NAME TRANSACTION_SOURCE,
                   MMT.TRANSACTION_DATE TRANSACTION_TIME,
                   (SELECT UNIQUE SLPN.LICENSE_PLATE_NUMBER
                      FROM APPS.WMS_LICENSE_PLATE_NUMBERS@OFNX_SPERTO SLPN
                     WHERE SLPN.LOCATOR_ID = MMT.LOCATOR_ID
                       AND ROWNUM = 1) LPN_NO,
                   MMT.SHIPMENT_NUMBER SHIPMENT_NO,
                   (SELECT UNIQUE NVL(FLV.MEANING, 'Def_Tx_Action')
                      FROM APPLSYS.FND_LOOKUP_VALUES@OFNX_SPERTO FLV
                     WHERE 1 = 1
                       AND FLV.LOOKUP_TYPE = 'MTL_TRANSACTION_ACTION'
                       AND LANGUAGE = 'ESA'
                       AND FLV.LOOKUP_CODE = MMT.TRANSACTION_ACTION_ID) TRANSACTION_ACTION,
                   (SELECT UNIQUE HLA.LOCATION_CODE
                      FROM APPS.HR_ALL_ORGANIZATION_UNITS@OFNX_SPERTO HAOU,
                           HR_LOCATIONS_ALL@OFNX_SPERTO               HLA
                     WHERE 1 = 1
                       AND HAOU.ORGANIZATION_ID = MMT.ORGANIZATION_ID
                       AND HAOU.LOCATION_ID = HLA.LOCATION_ID) LOCATION,
                   MMT.SOURCE_PROJECT_ID SOURCE_PROJECT_NUMBER,
                   MMT.SOURCE_TASK_ID SOURCE_TASK_NUMBER,
                   MMT.RCV_TRANSACTION_ID,
                   (SELECT UNIQUE NVL(RCV.PROJECT_ID, 0)
                      FROM APPS.RCV_TRANSACTIONS@OFNX_SPERTO RCV,
                           APPS.PA_PROJECTS_ALL@OFNX_SPERTO  PRO,
                           APPS.PA_TASKS@OFNX_SPERTO         TSK
                     WHERE 1 = 1
                       AND RCV.TRANSACTION_ID = MMT.RCV_TRANSACTION_ID --) Project_number
                       AND PRO.PROJECT_ID = RCV.PROJECT_ID ---+
                       AND TSK.TASK_ID = RCV.TASK_ID) PROJECT_NUMBER,
                   (SELECT UNIQUE NVL(RCV.TASK_ID, 0) ---Number
                      FROM APPS.RCV_TRANSACTIONS@OFNX_SPERTO RCV,
                           APPS.PA_PROJECTS_ALL@OFNX_SPERTO  PRO,
                           APPS.PA_TASKS@OFNX_SPERTO         TSK
                     WHERE 1 = 1
                       AND RCV.TRANSACTION_ID = MMT.RCV_TRANSACTION_ID --+
                       AND PRO.PROJECT_ID = RCV.PROJECT_ID --+
                       AND TSK.TASK_ID = RCV.TASK_ID) TASK_NUMBER,
                   MMT.TO_PROJECT_ID TO_PROJECT_NUMBER,
                   MMT.TO_TASK_ID TO_TASK_NUMBER,
                   MMT.XFR_OWNING_ORGANIZATION_ID FROM_OWNING_PARTY,
                   MMT.TRANSACTION_TYPE_ID,
                   MMT.WAYBILL_AIRBILL,
                   MMT.FREIGHT_CODE,
                   MMT.SOURCE_PROJECT_ID,
                   (SELECT UNIQUE FREIGHT_CODE
                      FROM APPS.WSH_CARRIERS@OFNX_SPERTO         WSC,
                           APPS.WSH_DELIVERY_DETAILS@OFNX_SPERTO WDD
                     WHERE 1 = 1
                       AND WSC.CARRIER_ID = WDD.CARRIER_ID
                       AND WDD.DELIVERY_DETAIL_ID = MMT.PICKING_LINE_ID) FREIGHT_CODE1,
                   (SELECT UNIQUE TO_CHAR(WSC.CARRIER_ID) CARRIER_ID
                      FROM APPS.WSH_CARRIERS@OFNX_SPERTO         WSC,
                           APPS.WSH_DELIVERY_DETAILS@OFNX_SPERTO WDD
                     WHERE 1 = 1
                       AND WSC.CARRIER_ID = WDD.CARRIER_ID
                       AND WDD.DELIVERY_DETAIL_ID = MMT.PICKING_LINE_ID) CARRIER_ID,
                   (SELECT UNIQUE WCCV.PERSON_FIRST_NAME || ' ' || WCCV.PERSON_LAST_NAME
                      FROM APPS.WSH_CARRIER_CONTACTS_V@OFNX_SPERTO WCCV,
                           APPS.WSH_DELIVERY_DETAILS@OFNX_SPERTO   WDD
                     WHERE 1 = 1
                       AND WCCV.CARRIER_ID = WDD.CARRIER_ID
                       AND WDD.DELIVERY_DETAIL_ID = MMT.PICKING_LINE_ID) NAME_DELIVERY_PERSON,
                   (SELECT UNIQUE WT.VEHICLE_NUMBER
                      FROM APPS.WSH_TRIPS@OFNX_SPERTO                WT,
                           APPS.WSH_TRIP_STOPS@OFNX_SPERTO           WTP,
                           APPS.WSH_TRIP_STOPS@OFNX_SPERTO           WTD,
                           APPS.WSH_DELIVERY_LEGS@OFNX_SPERTO        WDL,
                           APPS.WSH_DELIVERY_ASSIGNMENTS@OFNX_SPERTO WDA,
                           APPS.WSH_NEW_DELIVERIES@OFNX_SPERTO       WND,
                           APPS.WSH_DELIVERY_DETAILS@OFNX_SPERTO     WDD
                     WHERE 1 = 1
                       AND WT.TRIP_ID = WTP.TRIP_ID
                       AND WT.TRIP_ID = WTD.TRIP_ID
                       AND WTP.STOP_ID = WDL.PICK_UP_STOP_ID
                       AND WTD.STOP_ID = WDL.DROP_OFF_STOP_ID
                       AND WDD.DELIVERY_DETAIL_ID = WDA.DELIVERY_DETAIL_ID
                       AND WDA.DELIVERY_ID = WND.DELIVERY_ID
                       AND WDL.DELIVERY_ID = WND.DELIVERY_ID
                       AND WDD.DELIVERY_DETAIL_ID = MMT.PICKING_LINE_ID) VEHICLE_NUMBER,
                   (SELECT UNIQUE FU.USER_NAME
                      FROM FND_USER@OFNX_SPERTO FU
                     WHERE 1 = 1
                       AND FU.USER_ID = MMT.CREATED_BY) MOD_BY,
                   (SELECT UNIQUE HLA.POSTAL_CODE
                      FROM APPS.HR_ALL_ORGANIZATION_UNITS@OFNX_SPERTO HAOU,
                           HR_LOCATIONS_ALL                        HLA
                     WHERE 1 = 1
                       AND HAOU.ORGANIZATION_ID = MMT.ORGANIZATION_ID
                       AND HAOU.LOCATION_ID = HLA.LOCATION_ID) POSTAL_CODE,
                   (SELECT UNIQUE ORGANIZATION_CODE
                      FROM APPS.MTL_PARAMETERS@OFNX_SPERTO
                     WHERE 1 = 1
                       AND ORGANIZATION_ID = MMT.TRANSFER_ORGANIZATION_ID) ORG_DES,
                   MMT.TRANSFER_SUBINVENTORY SUBINV_DES,
                   (SELECT UNIQUE SEGMENT1
                      FROM APPS.MTL_ITEM_LOCATIONS@OFNX_SPERTO MIL
                     WHERE 1 = 1
                       AND MIL.INVENTORY_LOCATION_ID =
                           MMT.TRANSFER_LOCATOR_ID) LOC_DES,
                   MMT.MOVE_ORDER_LINE_ID,
                   MMT.TRANSACTION_SOURCE_ID,
                   MMT.SHIP_TO_LOCATION_ID,
                   (SELECT POH.SEGMENT1
                      FROM PO.PO_HEADERS_ALL@OFNX_SPERTO POH
                     WHERE 1 = 1
                       AND MMT.TRANSACTION_SOURCE_ID = POH.PO_HEADER_ID
                       AND MMT.TRANSACTION_SOURCE_TYPE_ID = NVL(NULL, 1)) OC,
                   MMT.TRANSACTION_ID
              FROM INV.MTL_MATERIAL_TRANSACTIONS@OFNX_SPERTO MMT
             WHERE 1 = 1
               AND MMT.TRANSACTION_ID > P_TRANSACTION_ID
               AND MMT.TRANSACTION_ID <= P_max_TRANSACTION_ID) A;

  CURSOR C_SKU_INSTANCE_DETAIL(P_TRANSACTION_ID     NUMBER,
                               P_MAX_TRANSACTION_ID NUMBER) IS
    SELECT MUT.TRANSACTION_ID          TRANSACTON_ID,
           MUT.SERIAL_NUMBER           SERIAL_NUMBER,
           MTL.LOT_NUMBER              LOT_NUMBER,
           MMT.INVENTORY_ITEM_ID       INVENTORY_ITEM_ID,
           MMT.TRANSACTION_DATE        TRANSACTION_DATE,
           MMT.TRANSACTION_SOURCE_NAME TRANSACTION_SOURCE_NAME,
           MUT.RECEIPT_ISSUE_TYPE      RECEIPT_ISSUE_TYPE,
           MUT.SHIP_ID                 SHIP_ID,
           MUT.ORIGINATION_DATE        ORIGINATION_DATE,
           MUT.STATUS_ID               STATUS_ID,
           MUT.PRODUCT_CODE            PRODUCT_CODE,
           MUT.PRODUCT_TRANSACTION_ID  PRODUCTO_TRANSACTION_ID,
           MUT.ATTRIBUTE3              ATTRIBUTE3,
           MUT.ATTRIBUTE4              ATTRIBUTE4
      FROM INV.MTL_UNIT_TRANSACTIONS@OFNX_SPERTO       MUT,
           INV.MTL_TRANSACTION_LOT_NUMBERS@OFNX_SPERTO MTL,
           INV.MTL_MATERIAL_TRANSACTIONS@OFNX_SPERTO   MMT
     WHERE 1 = 1
       AND MMT.TRANSACTION_ID > P_TRANSACTION_ID
       AND MMT.TRANSACTION_ID <= P_MAX_TRANSACTION_ID
       AND MUT.TRANSACTION_ID > P_TRANSACTION_ID
       AND MUT.TRANSACTION_ID <= P_MAX_TRANSACTION_ID
       AND MMT.TRANSACTION_ID = MTL.TRANSACTION_ID(+)
       AND MMT.ORGANIZATION_ID(+) = MUT.ORGANIZATION_ID --Nueva condicion
       AND MMT.TRANSACTION_ID(+) = MUT.TRANSACTION_ID --Se agreg¢ outer join
       AND MMT.ORGANIZATION_ID = MTL.ORGANIZATION_ID(+);

begin

  --||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

  begin
    select max(TRANSACTION_ID)
      into v_TRANSACTION_ID
      FROM GG_ADMIN.TBL_CONTROL_TRANSACTION_ID
     WHERE TABLE_ORIGIN = 2;
  exception
    when NO_DATA_FOUND then
      raise_application_error(-20002,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
      V_ERROR := sqlcode || sqlerrm || dbms_utility.format_error_backtrace;
    when others then
      raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
      V_ERROR := sqlcode || sqlerrm || dbms_utility.format_error_backtrace;
  end;
  ---------------------------------------------------------------

  BEGIN

    select max(TRANSACTION_ID)
      into P_MAX_TRANSACTION_ID
      FROM INV.MTL_MATERIAL_TRANSACTIONS@OFNX_SPERTO;

  exception
    when NO_DATA_FOUND then
      raise_application_error(-20002,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
      V_ERROR := sqlcode || sqlerrm || dbms_utility.format_error_backtrace;
    when others then
      raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
      V_ERROR := sqlcode || sqlerrm || dbms_utility.format_error_backtrace;
  END;

  ---------------------------------------------------------------

  BEGIN
    OPEN C_SKU_INSTANCE(v_TRANSACTION_ID, P_MAX_TRANSACTION_ID);
    LOOP
      FETCH C_SKU_INSTANCE BULK COLLECT
        INTO l_data LIMIT v_limit;

      FORALL i IN 1 .. l_data.COUNT
        INSERT INTO GG_ADMIN.SKU_INSTANCE_HIST VALUES l_data (i);
				      v_counter_write:=v_counter_write+TO_NUMBER(sql%rowcount);
      COMMIT;

      EXIT WHEN C_SKU_INSTANCE%NOTFOUND;
    END LOOP;
    CLOSE C_SKU_INSTANCE;
		
  begin
    insert into gg_admin.tbl_job_execute
      (job_name,
       date_execute,
       rows_inserted,
       status_end,
       type,
       tr_id_initial,
       tr_id_end)
    values
      ('JOB_SKU_INSTANCE_BOTH',
       SYSDATE,
       v_counter_write,
       nvl(V_ERROR, 'OK'),
       1,
			 v_TRANSACTION_ID,
			 p_MAX_TRANSACTION_ID);
    commit;
  end;
	
  EXCEPTION
    WHEN OTHERS THEN
      FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
				raise_application_error(-20003,v_TRANSACTION_ID || SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX);
        V_ERROR := v_TRANSACTION_ID || SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX;
      END LOOP;
  END;

  ---------------------------------------------------------------
  v_counter_write:=0;
  BEGIN
    OPEN C_SKU_INSTANCE_DETAIL(v_TRANSACTION_ID, P_MAX_TRANSACTION_ID);
    LOOP
      FETCH C_SKU_INSTANCE_DETAIL BULK COLLECT
        INTO l_data_DETAIL LIMIT v_limit2;

      FORALL i IN 1 .. l_data_DETAIL.COUNT
        INSERT INTO GG_ADMIN.SKU_INSTANCE_DETAIL_HIST
        VALUES l_data_DETAIL
          (i);
					 v_counter_write:=v_counter_write+TO_NUMBER(sql%rowcount);
      COMMIT;
     
      EXIT WHEN C_SKU_INSTANCE_DETAIL%NOTFOUND;
    END LOOP;
    CLOSE C_SKU_INSTANCE_DETAIL;

  begin
    insert into gg_admin.tbl_job_execute
      (job_name,
       date_execute,
       rows_inserted,
       status_end,
       type,
       tr_id_initial,
       tr_id_end)
    values
      ('JOB_SKU_INSTANCE_BOTH',
       SYSDATE,
       v_counter_write,
       nvl(V_ERROR, 'OK'),
       2,
			 v_TRANSACTION_ID,
			 p_MAX_TRANSACTION_ID);
    commit;
  end;


  EXCEPTION
    WHEN OTHERS THEN
      FOR indx IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
        raise_application_error(-20003,v_TRANSACTION_ID || SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX);
        V_ERROR := v_TRANSACTION_ID || SQL%BULK_EXCEPTIONS(indx).ERROR_INDEX;
      END LOOP;
  END;

  ----------------------------------------------------------------

  BEGIN

    UPDATE GG_ADMIN.TBL_CONTROL_TRANSACTION_ID
       SET TRANSACTION_ID = P_MAX_TRANSACTION_ID, TABLE_ORIGIN = 2;
    commit;

  exception
    when others then
      raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
      V_ERROR := sqlcode || sqlerrm || dbms_utility.format_error_backtrace;
  end;
  --------------------------------

exception
  when others then
    raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
end p_sku_instance_both;
/

