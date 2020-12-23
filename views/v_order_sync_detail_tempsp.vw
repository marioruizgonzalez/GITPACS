CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_ORDER_SYNC_DETAIL_TEMPSP AS
SELECT DISTINCT "LINE_ID",
          "HEADER_ID",
          "LINE_NUMBER",
          "ORGANIZATION_ID",
          "INVENTORY_ITEM_ID",
          "FROM_SUBINVENTORY_CODE",
          "FROM_LOCATOR_ID",
          "TO_SUBINVENTORY_CODE",
          "TO_LOCATOR_ID",
          "LOT_NUMBER",
          "SERIAL_NUMBER_START",
          "SERIAL_NUMBER_END",
          "UOM_CODE",
          "QUANTITY",
          "QUANTITY_DELIVERED",
          "QUANTITY_DETAILED",
          "DATE_REQUIRED",
          "REASON_NAME",
          "REASON_DESC",
          "REFERENCE",
          "PROJECT_ID",
          "TASK_ID",
          "STATUS",
          "STATUS_DATE",
          "MOD_DATE",
          "ADD_DATE",
          "TRANSACTION_TYPE",
          "TRANSACTION_DESC",
          "SOURCE_TYPE",
          "SOURCE_TYPE_DESC",
          "PRIMARY_QUANTITY",
          "TO_ORGANIZATION_ID",
          "SHIP_TO_LOCATION_ID",
          "LPN_ID",
          "TO_LPN_ID",
          "CONTAINER_ITEM_ID",
          "CARTON_GROUPING_ID",
          "SECONDARY_QUANTITY",
          "SECONDARY_QUANTITY_DELIVERED",
          "SECONDARY_QUANTITY_DETAILED",
          "SECONDARY_REQUIRED_QUANTITY",
          "SECONDARY_UOM_CODE",
          "SHIPMENT_TYPE",
          "TXN_SOURCE_ID"
     FROM (SELECT /*+ FIRST_ROWS(10) */
       MTRL.LINE_ID LINE_ID,
       MTRL.HEADER_ID HEADER_ID,
       MTRL.LINE_NUMBER LINE_NUMBER,
       MTRL.ORGANIZATION_ID ORGANIZATION_ID,
       MTRL.INVENTORY_ITEM_ID INVENTORY_ITEM_ID,
       MTRL.FROM_SUBINVENTORY_CODE FROM_SUBINVENTORY_CODE,
       MTRL.FROM_LOCATOR_ID FROM_LOCATOR_ID,
       MTRL.TO_SUBINVENTORY_CODE TO_SUBINVENTORY_CODE,
       MTRL.TO_LOCATOR_ID TO_LOCATOR_ID,
       TRX.LOT_NUMBER LOT_NUMBER,
       NVL(TRX.SERIAL_NUMBER, MTRL.SERIAL_NUMBER_END)SERIAL_NUMBER_START,
       NVL(MTRL.SERIAL_NUMBER_END, TRX.SERIAL_NUMBER) SERIAL_NUMBER_END,
       MTRL.UOM_CODE UOM_CODE,
       MTRL.QUANTITY QUANTITY,
       MTRL.QUANTITY_DELIVERED QUANTITY_DELIVERED,
       MTRL.QUANTITY_DETAILED QUANTITY_DETAILED,
       MTRL.DATE_REQUIRED DATE_REQUIRED,
       (SELECT MTR.REASON_NAME
          FROM APPS.MTL_TRANSACTION_REASONS@OFNX_SPERTO MTR
         WHERE 1 = 1 AND MTR.REASON_ID = MTRL.REASON_ID)
          REASON_NAME,
       (SELECT MTR.DESCRIPTION
          FROM APPS.MTL_TRANSACTION_REASONS@OFNX_SPERTO MTR
         WHERE 1 = 1 AND MTR.REASON_ID = MTRL.REASON_ID)
          REASON_DESC,
       MTRL.REFERENCE REFERENCE,
       MTRL.PROJECT_ID PROJECT_ID,
       MTRL.TASK_ID TASK_ID,
       (SELECT FLV.MEANING
          FROM APPLSYS.FND_LOOKUP_VALUES@OFNX_SPERTO FLV
         WHERE     1 = 1
               AND FLV.LOOKUP_TYPE = 'MTL_TXN_REQUEST_STATUS'
               AND FLV.LOOKUP_CODE(+) = MTRL.LINE_STATUS
               AND FLV.LANGUAGE = 'ESA')
          STATUS,
       MTRL.STATUS_DATE STATUS_DATE,
       MTRL.LAST_UPDATE_DATE MOD_DATE,
       MTRL.CREATION_DATE ADD_DATE,
       MTT.TRANSACTION_TYPE_NAME TRANSACTION_TYPE,
       MTT.DESCRIPTION TRANSACTION_DESC,
       MTST.TRANSACTION_SOURCE_TYPE_NAME SOURCE_TYPE,
       MTST.DESCRIPTION SOURCE_TYPE_DESC,
       MTRL.PRIMARY_QUANTITY PRIMARY_QUANTITY,
       MTRL.TO_ORGANIZATION_ID TO_ORGANIZATION_ID,
       MTRL.SHIP_TO_LOCATION_ID SHIP_TO_LOCATION_ID,
       MTRL.LPN_ID LPN_ID,
       MTRL.TO_LPN_ID TO_LPN_ID,
       MTRL.CONTAINER_ITEM_ID CONTAINER_ITEM_ID,
       MTRL.CARTON_GROUPING_ID CARTON_GROUPING_ID,
       MTRL.SECONDARY_QUANTITY SECONDARY_QUANTITY,
       MTRL.SECONDARY_QUANTITY_DELIVERED SECONDARY_QUANTITY_DELIVERED,
       MTRL.SECONDARY_QUANTITY_DETAILED SECONDARY_QUANTITY_DETAILED,
       MTRL.SECONDARY_REQUIRED_QUANTITY SECONDARY_REQUIRED_QUANTITY,
       MTRL.SECONDARY_UOM_CODE SECONDARY_UOM_CODE,
       MTRL.ATTRIBUTE1 SHIPMENT_TYPE,
       MTRL.TXN_SOURCE_ID
  FROM APPS.MTL_TXN_REQUEST_LINES@OFNX_SPERTO MTRL,
       APPS.MTL_TRANSACTION_TYPES@OFNX_SPERTO MTT,
       APPS.MTL_TXN_SOURCE_TYPES@OFNX_SPERTO MTST,
       (SELECT /*+ FIRST_ROWS(10) */
               MSN.LOT_NUMBER,
               MSN.SERIAL_NUMBER,
               MMT.MOVE_ORDER_LINE_ID
          FROM APPS.MTL_MATERIAL_TRANSACTIONS@OFNX_SPERTO MMT
LEFT JOIN inv.mtl_serial_numbers@OFNX_SPERTO MSN
                ON MSN.LAST_TRANSACTION_ID = MMT.TRANSACTION_ID
            LEFT JOIN APPS.MTL_TRANSACTION_LOT_NUMBERS@OFNX_SPERTO MTLN
ON MMT.TRANSACTION_ID = MTLN.TRANSACTION_ID
) TRX
 WHERE     1 = 1
       AND MTRL.LINE_ID = TRX.MOVE_ORDER_LINE_ID(+)
       AND MTRL.LAST_UPDATE_DATE > to_date('2020/11/01', 'yyyy/mm/dd')
       --apps.fnd_date.canonical_to_date@OFNX_SPERTO ('2020/11/01 00:00:00')
       AND MTRL.TRANSACTION_TYPE_ID = MTT.TRANSACTION_TYPE_ID
       AND MTRL.TRANSACTION_SOURCE_TYPE_ID = MTST.TRANSACTION_SOURCE_TYPE_ID
       AND MTT.TRANSACTION_SOURCE_TYPE_ID = MTST.TRANSACTION_SOURCE_TYPE_ID)
;

