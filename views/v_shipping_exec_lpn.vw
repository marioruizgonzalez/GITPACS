CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SHIPPING_EXEC_LPN AS
SELECT   a.order_no, delivery shipment_no, a.lpn_no, org_id, ship_to,
            b.reason_code, b.remarks, COUNT (1) total_records
       FROM gg_admin.shipping_exec_lob a, gg_admin.snd_hs_incidence_details b
      WHERE a.order_no = '' || b.order_id(+) AND a.delivery = b.delivery_id(+)
            AND a.lpn_no = b.lpn_no(+)
   GROUP BY a.order_no,
            a.delivery,
            a.lpn_no,
            org_id,
            ship_to,
            b.reason_code,
            b.remarks;

