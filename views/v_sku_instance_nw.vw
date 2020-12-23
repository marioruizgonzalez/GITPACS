CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SKU_INSTANCE_NW AS
SELECT 
    CASE
		WHEN (ssa.location_type_code = 'HZ_LOCATIONS' or ssa.LOCATION_TYPE_CODE is null)
			THEN CASE
				WHEN ssa.location_id = 2870115
					THEN 11 ---RMA REPAIR
				WHEN ssa.location_id = 22440945
					THEN 12 ---DESTRUCTION Y LOTEROS
				WHEN ssa.location_id = 30527592
					THEN 13 ---CORRECCIONES
				WHEN ssa.location_id = 2844822
					THEN 14 ---EQUIPO DBA
				ELSE NVL (os.tpt_status, 107)
				END
		WHEN ssa.location_type_code = 'INVENTORY'
			THEN CASE
				WHEN ssa.mod_date > os.last_update_date
					THEN 0
				WHEN os.tpt_status > 0
					THEN os.tpt_status
				WHEN os.lpn IS NOT NULL
					THEN 102                  -- LPN ASSIGNED
				WHEN os.assortment_status IS NOT NULL
					THEN TO_NUMBER (os.assortment_status)
				ELSE 0
				END
		ELSE NULL
    END status_id,
    sm.sku sku, NVL (os.serial_number, ssa.serial_number) serial_number,
    NVL (os.lot_number, ssa.fa_number) lot_number,
    NVL (ssa.organization_id, os.organization_id) org_id,
    NVL (os.ship_to_location_id,
    NVL (osd.ship_to_location_id,
			DECODE (ssa.location_type_code,'HZ_LOCATIONS', ssa.location_id,NULL)
		)
    ) loc_des,
    NVL (os.locator_id, ssa.locator_id) locator_id,
    os.origination_date origination_date,
    NVL (os.creation_date, ssa.add_date)creation_date,
    osd.line_id line_id,
    NVL (ssa.project_id, NULL) project_number, NULL to_project_number,
    NVL (os.creation_date, ssa.add_date) add_date,
    NVL (os.inventory_item_id, ssa.inventory_id) inventory_item_id,
    NVL (os.transaction_source_id, osd.header_id) transaction_source_id,
    NULL transaction_source,
    NVL (os.subinventory_code,
			ssa.subinventory_name
	) subinventory_short_code,
    NVL (os.ship_to_location_id,
		NVL (osd.ship_to_location_id,
  			DECODE (ssa.location_type_code,'HZ_LOCATIONS', ssa.location_id, NULL)
  		)
  	) LOCATION,
    NVL (os.locator_id, ssa.locator_id) locator_short_name,
    NVL (os.organization_id, ssa.organization_id) organization_id,
    NULL site_id, NVL (os.uom, ssa.uom) uom,
    NVL (os.po_no, ssa.oc) po_no,
    NVL (os.quantity, NVL (ssa.quantity, 1)) quantity,
    NVL (os.ship_to_location_id,
  	   NVL (osd.ship_to_location_id,
  			DECODE (ssa.location_type_code,'HZ_LOCATIONS', ssa.location_id,NULL)
  		)
  	) ship_to_location_id
FROM ipacs.v_erp_nw_order_serials os 
	LEFT JOIN gg_admin.order_sync_detail osd
		ON os.transaction_source_id = osd.header_id
		AND NVL (os.lot_number, os.serial_number) = NVL (osd.lot_number, osd.serial_number_start)
		AND os.inventory_item_id = osd.inventory_item_id
		AND osd.status IN ('Aprobada', 'Cerrado')
    LEFT JOIN
		(SELECT SID.serial_number, SID.lot_number, SID.inventory_item_id,
				sih.transaction_source_id, sih.move_order_line_id
			FROM gg_admin.sku_instance_detail SID 
				INNER JOIN gg_admin.sku_instance sih
					ON SID.transacton_id = sih.erp_inventory_id
  		) ski
		ON os.transaction_source_id = ski.transaction_source_id
		AND os.inventory_item_id = ski.inventory_item_id
		AND NVL (os.lot_number, os.serial_number) = NVL (ski.lot_number, ski.serial_number)
    FULL OUTER JOIN gg_admin.site_stock_availability ssa
		ON os.inventory_item_id = ssa.inventory_id
		AND (os.lot_number = ssa.fa_number OR os.serial_number = ssa.serial_number)
    , gg_admin.sku_master sm
    WHERE 1 = 1
		AND NVL (os.inventory_item_id, ssa.inventory_id) = sm.erp_inventory_id
;

