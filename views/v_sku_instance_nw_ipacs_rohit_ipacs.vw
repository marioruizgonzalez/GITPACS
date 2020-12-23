CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SKU_INSTANCE_NW_IPACS_ROHIT_IPACS AS
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
          po_qury.po_no po_no, osd.quantity, osd.ship_to_location_id
     FROM (SELECT aa.*, bb.serial_number
             FROM gg_admin.sku_instance aa, gg_admin.sku_instance_detail bb
            WHERE aa.erp_inventory_id = bb.transacton_id) a,
          gg_admin.order_sync c,
          gg_admin.order_sync_detail osd,
          gg_admin.sku_master sm,
          ipacs.erp_nw_order_serials os,
          (SELECT si.oc po_no, SID.inventory_item_id, SID.lot_number,
                  SID.serial_number
             FROM gg_admin.sku_instance si, gg_admin.sku_instance_detail SID
            WHERE si.erp_inventory_id = SID.transacton_id
              AND si.transaction_type = 'PO Receipt') po_qury
    WHERE c.header_id = osd.header_id
      AND osd.status = 'Cerrado'
      AND c.header_id = a.transaction_source_id(+)
      AND osd.serial_number_start = a.serial_number(+)
      AND osd.inventory_item_id = sm.erp_inventory_id
      AND c.header_id = os.transaction_source_id(+)
      AND osd.serial_number_start = os.serial_number(+)
      AND osd.inventory_item_id = os.inventory_item_id(+)
      AND osd.serial_number_start = po_qury.serial_number(+)
      AND osd.inventory_item_id = po_qury.inventory_item_id(+);

