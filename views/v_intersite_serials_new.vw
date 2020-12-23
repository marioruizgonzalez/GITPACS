CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_INTERSITE_SERIALS_NEW AS
SELECT   a.instance_id, a.inventory_id, a.master_organization_id,
            a.serial_number, a.fa_number, a.quantity, a.uom,
            a.location_type_code, a.location_id, a.organization_id,
            a.subinventory_name, a.project_id, a.project_task_id,
            a.install_date, a.return_by_date, a.actual_return_date,
            a.add_date, a.mod_date, a.install_location_id, a.capex,
            a.asset_category, a.asset_id, a.asset_number, a.current_units,
            a.asset_type, a.tag_number, a.asset_category_id,
            a.serial_number_fa, a.last_update_date, a.creation_date,
            a.quantity asset_quantity, 0 used_quantity
       FROM gg_admin.site_stock_availability a,
            ipacs.snd_intersite_request_serials b,
            ipacs.erp_nw_order_serials c
      WHERE a.location_id = b.location_id(+)
        AND a.inventory_id = b.inventory_id(+)
        AND a.serial_number = b.serial_number(+)
        AND a.location_id = c.ship_to_location_id(+)
        AND a.inventory_id = c.inventory_item_id(+)
        AND a.serial_number = c.serial_number(+)
        AND a.serial_number IS NOT NULL
        AND (b.status IS NULL OR b.status IN (1, 2, 200))
        AND b.serial_number IS NULL
        AND (c.status_id = 107 OR c.status_id IS NULL)
   ORDER BY 4;

