CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SHIPPING_EXEC_TRANSPORT AS
SELECT order_no, delivery shipment_no, OPERATOR, vehicle_number, carrier,
          VEHICLE_NAME AS transport_type, VEHICLE_TYPE AS vehicle_type, ship_to, org_id
     FROM gg_admin.shipping_exec_lob;

