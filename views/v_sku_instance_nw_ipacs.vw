CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SKU_INSTANCE_NW_IPACS AS
SELECT NVL(os.status_id, 0)                           status_id,
       sm.sku                                         sku,
       osd.serial_number_start                        serial_number,
       osd.lot_number                                 lot_number,
       osd.organization_id                            org_id,
       osd.ship_to_location_id loc_des,
       osd.from_locator_id					          locator_id,
       osd.add_date                                   origination_date,
       c.add_date                                     creation_date,
       osd.line_id                                    line_id,
       osd.project_id						          project_number,
       null											  to_project_number,
       osd.add_date                 				  add_date,
       osd.inventory_item_id,
       c.header_id                                    transaction_source_id,
       null                           			      transaction_source,
       osd.from_subinventory_code				 	  subinventory_short_code,
       osd.ship_to_location_id       				  LOCATION,
       osd.from_locator_id							  locator_short_name,
       c.organization_id,
       osd.ship_to_location_id                        site_id,
       osd.uom_code                                   uom,
       ssa.oc                                           po_no,
       decode(nvl(osd.serial_number_start,'NA'),'NA',osd.quantity,1) quantity,
       osd.ship_to_location_id
FROM 
     gg_admin.order_sync c,
     gg_admin.order_sync_detail osd,
     gg_admin.sku_master sm,
     ipacs.erp_nw_order_serials os,
	 gg_admin.site_stock_availability ssa

WHERE c.header_id = osd.header_id
  AND osd.status='Cerrado'
  AND osd.inventory_item_id = sm.erp_inventory_id
  AND c.HEADER_ID = os.TRANSACTION_SOURCE_ID(+)
  AND osd.serial_number_start = os.serial_number(+)
  AND osd.inventory_item_id = os.inventory_item_id(+)
  and NVL(osd.SERIAL_NUMBER_START,osd.LOT_NUMBER)=NVL(ssa.SERIAL_NUMBER(+),ssa.FA_NUMBER(+))
  and osd.INVENTORY_ITEM_ID=ssa.INVENTORY_ID(+);

