CREATE OR REPLACE FORCE VIEW GG_ADMIN.SHIPPING_EXEC_LOB AS
SELECT "ERP_INVENTORY_ID", "ADD_DATE", "MOD_DATE", "ORG_ID",
          "ORG_SHORT_NAME", "INVENTORY_SERIAL_NO", "UOM", "QUANTITY",
          "SUBINVENTORY", "SOURCE_TYPE", "TRANSACTION_SOURCE_ID",
          "TRANSACTION_TIME", "TRANSACTION_ACTION", "LPN_NO", "SHIPMENT_NO",
          "ADDRESS1", "ADDRESS2", "ADDRESS3", "ADDRESS4", "SHIP_TO",
          "DELIVER_TO", "ORDER_NO", "SHIPPING_METHOD", "DELIVERY",
          "REQUESTED_QTY", "SHIPPED_QTY", "CARRIER", "CONSIGNEE", "OPERATOR",
          "SEAL_CODE", "VEHICLE_ORG_CODE", "VEHICLE_NUMBER",
          "VEHICLE_ITEM_NAME", "VEHICLE_NAME", "VEHICLE_TYPE",
          "BILL_TO_ADDRESS", "CUSTOMER_PO_NUMBER", "STATUS_SHIPPING_ORDER",
          "CUSTODY", "TRIP_NO", "TRX_NUMBER", "ZIP_CODE", "HOLD_FLAG", "LOB"
     FROM (SELECT erp_inventory_id, add_date, mod_date, org_id,
                  org_short_name, inventory_serial_no, uom, quantity,
                  subinventory, source_type, transaction_source_id,
                  transaction_time, transaction_action, lpn_no, shipment_no,
                  address1, address2, address3, address4, ship_to, deliver_to,
                  TO_CHAR (order_no) order_no, shipping_method, TO_CHAR (delivery) delivery,
                  requested_qty, shipped_qty, carrier, consignee, OPERATOR,
                  seal_code, vehicle_org_code, vehicle_number,
                  vehicle_item_name, vehicle_name, vehicle_type,
                  bill_to_address, customer_po_number, status_shipping_order,
                  custody, trip_no, trx_number, zip_code, hold_flag,
                  (CASE
                      WHEN shex.source_header_type_name = 'MEX P GROSS ADD 3G'
                         THEN 'IOT'
                      WHEN shex.source_header_type_name =
                                       'D' || CHR (38)
                                       || 'R MEX P VTA INTERCO'
                         THEN 'Intercompany'
                      WHEN loor.superchannel = 'BBR'
                         THEN 'BBRs'
                      WHEN loor.superchannel = 'B2C'
                         THEN 'EBS Telesales'
                      WHEN loor.superchannel = 'DEALERS EXCLUSIVOS'
                       OR loor.superchannel = 'TIENDAS'
                         THEN 'C.Propio'
                      ELSE NULL
                   END
                  ) AS LOB
             FROM shipping_exec shex LEFT JOIN lob_orders loor
                  ON shex.source_header_type_name = loor.NAME
           UNION ALL
           SELECT erp_inventory_id, add_date, mod_date, org_id,
                  org_short_name, inventory_serial_no, uom, quantity,
                  subinventory, source_type, transaction_source_id,
                  transaction_time, transaction_action, lpn_no, shipment_no,
                  address1, address2, address3, address4, ship_to, deliver_to,
                  TO_CHAR (order_no) order_no, shipping_method, TO_CHAR (delivery) delivery,
                  requested_qty, shipped_qty, carrier, consignee, OPERATOR,
                  seal_code, vehicle_org_code, vehicle_number,
                  vehicle_item_name, vehicle_name, vehicle_type,
                  bill_to_address, customer_po_number, status_shipping_order,
                  custody, trip_no, trx_number, zip_code, hold_flag,
                  source_header_type_name AS LOB
             FROM mv_shipping_exec_cp);

