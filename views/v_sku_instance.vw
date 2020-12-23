create or replace force view gg_admin.v_sku_instance as
select b.ITEM_CATEGORY,
       a.serial_number,
       a.Locator_id,
       a.SubInventory_Short_code,
       a.LOT_NUMBER,
       a.LPN_NO,
       a.STATUS_ID,
       a.org_id,
       a.INVENTORY_ITEM_ID,
       a.SKU,
       c.SHIPMENT_NO,
       c.Trip_No,
       c.ADD_DATE,
       c.ORDER_NO,
       1 quantity,
       a.ORIGINATION_DATE,
       a.MOD_BY,
       a.MOD_DATE,
       a.LOC_DES
from SKU_INSTANCE a,
     SKU_MASTER b,
     SHIPPING_EXEC c
where a.INVENTORY_ITEM_ID=b.ERP_INVENTORY_ID
and a.INVENTORY_ITEM_ID=c.ERP_INVENTORY_ID
and a.SERIAL_NUMBER=c.INVENTORY_SERIAL_NO;

