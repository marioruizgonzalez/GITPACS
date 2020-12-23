CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SKU_INSTANCE_NW_ORG AS
SELECT b.status_id, a.sku, b.serial_number, b.lot_number, a.org_id,
          a.loc_des, a.locator_id, b.origination_date,
          c.add_date creation_date, osd.line_id line_id, a.project_number,
          a.to_project_number, a.add_date, b.inventory_item_id,
          a.transaction_source_id transaction_source_id,
          a.transaction_source transaction_source, a.subinventory_short_code,
          a.LOCATION, a.locator_short_name, c.organization_id,
          a.org_des site_id, a.uom_ uom,
          DECODE (a.source_type,
                  'Orden de Compra', a.transaction_source,
                  NULL
                 ) po_no,
          osd.quantity
     FROM gg_admin.sku_instance a,
          gg_admin.sku_instance_detail b,
          gg_admin.order_sync c,
          gg_admin.order_sync_detail osd
    WHERE c.header_id = osd.header_id
      AND b.inventory_item_id = osd.inventory_item_id
      AND a.erp_inventory_id = b.transacton_id
      AND a.transaction_source_id = c.header_id;

