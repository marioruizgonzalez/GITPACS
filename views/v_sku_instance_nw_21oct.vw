CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SKU_INSTANCE_NW_21OCT AS
SELECT NVL (os.status_id, 0) status_id, sm.sku sku,
          osd.serial_number_start serial_number, osd.lot_number lot_number,
          osd.organization_id org_id, a.loc_des,
          NVL (a.locator_id, osd.from_locator_id) locator_id,
          osd.add_date origination_date, c.add_date creation_date,
          osd.line_id line_id,
          NVL (osd.project_id, a.project_number) project_number,
          a.to_project_number, NVL (osd.add_date, a.add_date) add_date,
          osd.inventory_item_id, c.header_id transaction_source_id,
          a.transaction_source transaction_source, a.subinventory_short_code,
          NVL (a.LOCATION, osd.ship_to_location_id) LOCATION,
          NVL (a.locator_short_name, osd.from_locator_id) locator_short_name,
          c.organization_id, a.org_des site_id, osd.uom_code uom,
          DECODE (a.source_type,
                  'Orden de Compra', a.transaction_source,
                  NULL
                 ) po_no,
          osd.quantity,
          osd.ship_to_location_id
     FROM gg_admin.sku_instance a,
          gg_admin.order_sync c,
          gg_admin.order_sync_detail osd,
          gg_admin.sku_master sm,
          ipacs.erp_nw_order_serials os
    WHERE c.header_id = osd.header_id
      AND c.header_id = a.transaction_source_id(+)
      AND osd.inventory_item_id = sm.erp_inventory_id
      AND c.HEADER_ID = os.TRANSACTION_SOURCE_ID(+)
      AND osd.serial_number_start = os.serial_number(+)
      AND osd.inventory_item_id = os.inventory_item_id(+);

