CREATE OR REPLACE FORCE VIEW GG_ADMIN.ORDER_SYNC AS
SELECT HEADER_ID,   REQUEST_ID,   TRANSACTION_TYPE,   TRANSACTION_DESC,
   MOVE_ORDER_TYPE,   MOVE_ORDER_DESC,   ORGANIZATION_ID,   DESCRIPTION,   DATE_REQUIRED,   FROM_SUBINVENTORY_CODE,
   TO_SUBINVENTORY_CODE,   STATUS,   STATUS_DATE,   MOD_DATE,   ADD_DATE,   SHIP_TO_LOCATION_ID,   FREIGTH_CODE,
   SHIPMENT_TYPE
FROM GG_ADMIN.MV_ORDER_SYNC_TR_ID
UNION ALL
SELECT HEADER_ID,   REQUEST_ID,   TRANSACTION_TYPE,   TRANSACTION_DESC,
   MOVE_ORDER_TYPE,   MOVE_ORDER_DESC,   ORGANIZATION_ID,   DESCRIPTION,   DATE_REQUIRED,   FROM_SUBINVENTORY_CODE,
   TO_SUBINVENTORY_CODE,   STATUS,   STATUS_DATE,   MOD_DATE,   ADD_DATE,   SHIP_TO_LOCATION_ID,   FREIGTH_CODE,
   SHIPMENT_TYPE
FROM GG_ADMIN.ORDER_SYNC_HIST;

