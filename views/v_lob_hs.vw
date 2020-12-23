create or replace force view gg_admin.v_lob_hs as
select distinct
        (transaction_source_id) order_id
        ,(CASE
            when shexc.transaction_action = 'Intransit shipment' then 'C. Propio'
            when shexc.transaction_action = 'Emitir desde almacenes' then
                CASE 
                    when shexc.source_header_type_name like '%RET%' then 'BBRs'
                    when shexc.source_header_type_name like '%INTERCO%' then 'interco'
                    when shexc.source_header_type_name like '%DEALER%' then 'DNE'
                    when shexc.vehicle_item_name like '%IOT%' then 'IoT Control Center'
                    else 'EBS telesale'
                END
        END) lob   
    from gg_admin.shipping_exec shexc
    where 1=1
    and shexc.transaction_action IN ('Intransit shipment', 'Emitir desde almacenes');

