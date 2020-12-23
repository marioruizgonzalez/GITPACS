CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SHIPPING_EXEC_ORDER_SHP AS
SELECT   a.status_shipping_order, a.order_no, MIN (a.add_date) add_date,
            a.ship_to,min(a.subinventory) subinventory,min(a.org_id) org_id, a.source_type,
            a.delivery shipment_no, min(a.transaction_source_id) transaction_source_id, erp_inventory_id,
            requested_qty AS requested_qnty, shipped_qty AS shipped_qnty
       FROM gg_admin.shipping_exec_lob a
   GROUP BY a.status_shipping_order,
            a.order_no,
            a.ship_to,
            a.source_type,
            a.delivery,
            erp_inventory_id,
            requested_qty,
            shipped_qty;

