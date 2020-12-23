CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SKU_INSTANCE_HS AS
SELECT b.categoria_articulo item_category, d.serial_number, a.locator_id,
          a.subinventory_short_code, d.lot_number, a.lpn_no,
          a.transaction_action status_id, a.org_id, d.inventory_item_id,
          a.sku, c.shipment_no, c.trip_no, c.add_date, c.order_no, 1 quantity,
          d.origination_date, a.mod_by, a.mod_date, a.loc_des
     FROM gg_admin.sku_instance a,
          gg_admin.sku_instance_detail d,
          gg_admin.sku_master b,
          gg_admin.shipping_exec c
    WHERE a.erp_inventory_id = d.transacton_id
      AND d.inventory_item_id = b.erp_inventory_id(+)
      AND d.inventory_item_id = c.erp_inventory_id(+)
      AND d.serial_number = c.inventory_serial_no(+);

