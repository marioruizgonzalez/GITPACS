CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_ORDER_SYNC_TR_ID AS
SELECT MTRH.HEADER_ID HEADER_ID,
          MTRH.REQUEST_NUMBER REQUEST_ID,
          MTT.TRANSACTION_TYPE_NAME TRANSACTION_TYPE,
          MTT.DESCRIPTION TRANSACTION_DESC,
          MTST.TRANSACTION_SOURCE_TYPE_NAME MOVE_ORDER_TYPE,
          MTST.DESCRIPTION MOVE_ORDER_DESC,
          MTRH.ORGANIZATION_ID ORGANIZATION_ID,
          MTRH.DESCRIPTION DESCRIPTION,
          MTRH.DATE_REQUIRED DATE_REQUIRED,
          MTRH.FROM_SUBINVENTORY_CODE FROM_SUBINVENTORY_CODE,
          MTRH.TO_SUBINVENTORY_CODE TO_SUBINVENTORY_CODE,
          (SELECT FLV.MEANING
             FROM APPLSYS.FND_LOOKUP_VALUES@OFNX_SPERTO FLV
            WHERE     1 = 1
                  AND FLV.LOOKUP_TYPE = 'MTL_TXN_REQUEST_STATUS'
                  AND FLV.LOOKUP_CODE(+) = MTRH.HEADER_STATUS
                  AND FLV.LANGUAGE = 'ESA')
             STATUS,
          MTRH.STATUS_DATE STATUS_DATE,
          MTRH.LAST_UPDATE_DATE MOD_DATE,
          MTRH.CREATION_DATE ADD_DATE,
          MTRH.SHIP_TO_LOCATION_ID SHIP_TO_LOCATION_ID,
          MTRH.FREIGHT_CODE FREIGTH_CODE,
          MTRH.ATTRIBUTE1 SHIPMENT_TYPE
     FROM APPS.MTL_TXN_REQUEST_HEADERS@OFNX_SPERTO MTRH,
          APPS.MTL_TRANSACTION_TYPES@OFNX_SPERTO MTT,
          APPS.MTL_TXN_SOURCE_TYPES@OFNX_SPERTO MTST
    WHERE     1 = 1
          AND MTRH.TRANSACTION_TYPE_ID = MTT.TRANSACTION_TYPE_ID
          AND MTT.TRANSACTION_SOURCE_TYPE_ID =
                 MTST.TRANSACTION_SOURCE_TYPE_ID;

