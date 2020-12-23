CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SHIPPING_EXEC_ORDER_SHP1 AS
SELECT NVL (s.text, o.status_shipping_order) status_shipping_order,
          o.order_no, o.add_date, o.ship_to, o.subinventory, o.org_id,
          o.source_type, o.shipment_no, o.transaction_source_id,
          o.erp_inventory_id, o.requested_qnty, o.shipped_qnty
     FROM gg_admin.v_shipping_exec_order_shp o,
          (SELECT DISTINCT d.order_id, d.shipment_id, d.status, b.LOB, c.text
                      FROM gg_admin.snd_order_transport_detail d,
                           gg_admin.snd_hs_delivery_history b,
                           gg_admin.snd_generic_dropdown_data c
                     WHERE d.order_id = b.order_id
                       AND d.shipment_id = b.delivery_id
                       AND d.status || '' = c.VALUE
                       AND b.LOB = c.field_id) s
    WHERE o.order_no = s.order_id(+) AND o.shipment_no = s.shipment_id(+);

