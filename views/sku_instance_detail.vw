CREATE OR REPLACE FORCE VIEW GG_ADMIN.SKU_INSTANCE_DETAIL AS
SELECT  TRANSACTON_ID,   SERIAL_NUMBER,   LOT_NUMBER,   INVENTORY_ITEM_ID,   TRANSACTION_DATE,   TRANSACTION_SOURCE_NAME,   RECEIPT_ISSUE_TYPE,   SHIP_ID,   ORIGINATION_DATE,   STATUS_ID,   PRODUCT_CODE,   PRODUCTO_TRANSACTION_ID,   ATTRIBUTE3,
   ATTRIBUTE4
FROM SKU_INSTANCE_DETAIL_HIST;
