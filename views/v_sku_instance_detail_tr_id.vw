CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SKU_INSTANCE_DETAIL_TR_ID AS
SELECT  /*+ FIRST_ROWS(10) */
          MUT.TRANSACTION_ID TRANSACTON_ID,
          MUT.SERIAL_NUMBER SERIAL_NUMBER,
          MTL.LOT_NUMBER LOT_NUMBER,
          MUT.INVENTORY_ITEM_ID INVENTORY_ITEM_ID,
          MMT.TRANSACTION_DATE TRANSACTION_DATE,
          MMT.TRANSACTION_SOURCE_NAME TRANSACTION_SOURCE_NAME,
          MUT.RECEIPT_ISSUE_TYPE RECEIPT_ISSUE_TYPE,
          MUT.SHIP_ID SHIP_ID,
          MUT.ORIGINATION_DATE ORIGINATION_DATE,
          MUT.STATUS_ID STATUS_ID,
          MUT.PRODUCT_CODE PRODUCT_CODE,
          MUT.PRODUCT_TRANSACTION_ID PRODUCTO_TRANSACTION_ID,
          MUT.ATTRIBUTE3 ATTRIBUTE3,
          MUT.ATTRIBUTE4 ATTRIBUTE4
     FROM INV.MTL_UNIT_TRANSACTIONS@OFNX_SPERTO MUT,
          INV.MTL_TRANSACTION_LOT_NUMBERS@OFNX_SPERTO MTL,
          INV.MTL_MATERIAL_TRANSACTIONS@OFNX_SPERTO MMT
    WHERE     1 = 1
          AND MMT.TRANSACTION_ID >2780830206
          AND MUT.TRANSACTION_ID >2780830206
          AND MMT.TRANSACTION_ID = MTL.TRANSACTION_ID(+)
          AND MMT.ORGANIZATION_ID(+) = MUT.ORGANIZATION_ID   --Nueva condicion
          AND MMT.TRANSACTION_ID(+) = MUT.TRANSACTION_ID --Se agreg¢ outer join
          AND MMT.ORGANIZATION_ID = MTL.ORGANIZATION_ID(+)  --Nueva condicion
;

