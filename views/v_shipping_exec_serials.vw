create or replace force view gg_admin.v_shipping_exec_serials as
select a.ERP_INVENTORY_ID,
       a.ORG_ID,
       a.ORDER_NO,
       a.Inventory_serial_no,
       a.STATUS_SHIPPING_ORDER,
       a.LPN_NO,
       a.DELIVERY SHIPMENT_NO,
       a.SHIP_TO
from gg_admin.SHIPPING_EXEC_LOB a;

