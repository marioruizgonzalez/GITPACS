CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SHIPPING_EXEC_ORDERS AS
SELECT   a.status_shipping_order, a.order_no, MIN (a.add_date) add_date,
            a.ship_to, min(a.subinventory) subinventory, min(a.org_id) org_id, min(a.org_short_name) org_short_name,
            a.source_type, a.shipment_no, a.delivery, min(a.transaction_source_id) transaction_source_id,
            MAX (a.carrier) carrier
       FROM gg_admin.shipping_exec_lob a
   GROUP BY a.status_shipping_order,
            a.order_no,
            a.ship_to,
            a.source_type,
            a.shipment_no,
            delivery;

