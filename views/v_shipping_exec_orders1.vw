CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SHIPPING_EXEC_ORDERS1 AS
SELECT CASE
             WHEN s.text IS NOT NULL
                THEN s.text
             WHEN UPPER (o.status_shipping_order) =
                                           'INTERFACED'
                THEN CASE
                       WHEN o.carrier IS NOT NULL
                          THEN 'Picked and Transport Assigned'
                       ELSE o.status_shipping_order
                    END
             ELSE o.status_shipping_order
          END status_shipping_order,
          o.order_no, o.add_date, o.ship_to, o.subinventory, o.org_id,
          o.org_short_name, o.source_type, o.shipment_no, o.delivery,
          o.transaction_source_id, o.ship_to ship_to_org_id
     FROM gg_admin.v_shipping_exec_orders o,
          (SELECT DISTINCT d.order_id, d.shipment_id, d.status, b.LOB, c.text
                      FROM gg_admin.snd_order_transport_detail d,
                           snd_hs_delivery_history b,
                           snd_generic_dropdown_data c
                     WHERE d.order_id = b.order_id
                       AND d.shipment_id = b.delivery_id
                       AND d.status || '' = c.VALUE
                       AND b.LOB = c.field_id) s
    WHERE o.order_no = s.order_id(+) AND o.delivery = s.shipment_id(+);

