CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_ORDER_SYNC_NEW AS
SELECT DISTINCT a.header_id, b.organization_id, b.ship_to_location_id,
                   a.date_required, a.add_date, a.status
              FROM order_sync a, order_sync_detail b
             WHERE a.header_id = b.header_id(+);

