CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SHIPPING_EXEC AS
SELECT WDD.INVENTORY_ITEM_ID ERP_INVENTORY_ID,
          WDD.CREATION_DATE ADD_DATE,
          WDD.LAST_UPDATE_DATE MOD_DATE,
          WDD.ORGANIZATION_ID ORG_ID,
          (SELECT MP.ORGANIZATION_CODE
             FROM INV.MTL_PARAMETERS MP
            WHERE 1 = 1 AND WDD.ORGANIZATION_ID = MP.ORGANIZATION_ID)
             ORG_SHORT_NAME,
          msn.serial_number inventory_serial_no,
          (SELECT MUTO.UNIT_OF_MEASURE
             FROM INV.MTL_UNITS_OF_MEASURE_TL MUTO
            WHERE     1 = 1
                  AND MUTO.LANGUAGE = 'ESA'
                  AND MUTO.UOM_CODE = WDD.REQUESTED_QUANTITY_UOM)
             UOM,
          WDD.REQUESTED_QUANTITY QUANTITY,
          WDD.SUBINVENTORY SUBINVENTORY,
          (SELECT TRANSACTION_SOURCE_TYPE_NAME
             FROM INV.MTL_TXN_SOURCE_TYPES MTST
            WHERE     1 = 1
                  AND MTST.TRANSACTION_SOURCE_TYPE_ID(+) =
                         WDD.SOURCE_DOCUMENT_TYPE_ID)
             SOURCE_TYPE,
          WDD.SOURCE_HEADER_ID TRANSACTION_SOURCE_ID,
          MMT.TRANSACTION_DATE TRANSACTION_TIME,
          (SELECT FLV.MEANING
             FROM APPLSYS.FND_LOOKUP_VALUES FLV
            WHERE     1 = 1
                  AND FLV.LOOKUP_TYPE = 'MTL_TRANSACTION_ACTION'
                  AND FLV.LOOKUP_CODE(+) = MMT.TRANSACTION_ACTION_ID
                  AND FLV.LANGUAGE = 'ESA')
             TRANSACTION_ACTION,
          (SELECT WLPN.LICENSE_PLATE_NUMBER
             FROM WMS.WMS_LICENSE_PLATE_NUMBERS WLPN
            WHERE 1 = 1 AND WLPN.LPN_ID(+) = WDD.LPN_ID)
             LPN_NO,
          RCV.RECEIPT_NUM SHIPMENT_NO,
          (SELECT ADDRESS1
             FROM AR.HZ_LOCATIONS HLOC
            WHERE 1 = 1 AND HLOC.location_id = WDD.DELIVER_TO_LOCATION_ID)
             ADDRESS1,
          (SELECT ADDRESS2
             FROM AR.HZ_LOCATIONS HLOC
            WHERE 1 = 1 AND HLOC.location_id = WDD.DELIVER_TO_LOCATION_ID)
             ADDRESS2,
          (SELECT ADDRESS3
             FROM AR.HZ_LOCATIONS HLOC
            WHERE 1 = 1 AND HLOC.location_id = WDD.DELIVER_TO_LOCATION_ID)
             ADDRESS3,
          (SELECT ADDRESS4
             FROM AR.HZ_LOCATIONS HLOC
            WHERE 1 = 1 AND HLOC.location_id = WDD.DELIVER_TO_LOCATION_ID)
             ADDRESS4,
          WDD.SHIP_TO_LOCATION_ID SHIP_TO,
          WDD.DELIVER_TO_LOCATION_ID DELIVER_TO,
          (SELECT order_number
             FROM apps.oe_order_headers_all OEH
            WHERE wdd.SOURCE_HEADER_ID = oeh.header_id)
             order_no,
          (SELECT FLV.MEANING
             FROM APPLSYS.FND_LOOKUP_VALUES FLV
            WHERE     1 = 1
                  AND flv.lookup_type = 'SHIP_METHOD'
                  AND language = 'ESA'
                  AND FLV.LOOKUP_CODE(+) = WDD.SHIP_METHOD_CODE)
             SHIPPING_METHOD,
          wda.delivery_id DELIVERY,
          wdd.requested_quantity requested_qty,
          wdd.shipped_quantity shipped_qty,
          wdd.CYCLE_COUNT_QUANTITY BACKORDER_QTY,
          (SELECT MP.ORGANIZATION_CODE
             FROM INV.MTL_PARAMETERS MP
            WHERE 1 = 1 AND WDD.ORGANIZATION_ID = MP.ORGANIZATION_ID)
             ship_from,
          (SELECT FREIGHT_CODE
             FROM WSH.WSH_CARRIERS wc
            WHERE 1 = 1 AND wc.carrier_id = wdd.carrier_id)
             CARRIER,
          (SELECT HZ.party_name
             FROM APPS.HZ_PARTIES HZ
            WHERE 1 = 1 AND hz.party_id(+) = wdd.customer_id)
             CONSIGNEE,
          (SELECT PERSON_FIRST_NAME || PERSON_LAST_NAME
             FROM apps.WSH_CARRIER_CONTACTS_V wc
            WHERE wc.carrier_id = wdd.carrier_id)
             OPERATOR,
          wdd.SEAL_CODE SEAL_CODE,
          (SELECT MP.ORGANIZATION_CODE
             FROM INV.MTL_PARAMETERS MP
            WHERE 1 = 1 AND WDD.ORGANIZATION_ID = MP.ORGANIZATION_ID)
             VEHICLE_ORG_CODE,
          (SELECT t.VEHICLE_NUMBER
             FROM apps.wsh_trips t,
                  apps.fnd_lookup_values lv,
                  apps.wsh_trip_stops pickup_stop,
                  apps.wsh_trip_stops dropoff_stop,
                  apps.wsh_delivery_legs dl,
                  apps.wsh_delivery_assignments wa,
                  apps.wsh_new_deliveries wnd
            WHERE     1 = 1
                  AND lv.lookup_type = 'TRIP_STATUS'
                  AND lv.lookup_code = t.status_code
                  AND lv.language = 'ESA'
                  AND view_application_id = 665
                  AND security_group_id = 0
                  AND pickup_stop.stop_id = dl.pick_up_stop_id
                  AND dropoff_stop.stop_id = dl.drop_off_stop_id
                  AND pickup_stop.trip_id = t.trip_id
                  AND wnd.delivery_id = dl.delivery_id
                  AND wnd.delivery_id = wa.delivery_id
                  AND wa.delivery_detail_id = wdd.delivery_detail_id
                  AND NVL (wnd.shipment_direction, 'O') IN ('O', 'IO')
                  AND NVL (t.shipments_type_flag, 'O') IN ('O', 'M'))
             VEHICLE_NUMBER,
          MTS.SEGMENT1 VEHICLE_ITEM_NAME,
          (SELECT    ADDRESS1
                  || ' '
                  || ADDRESS2
                  || ' '
                  || ADDRESS3
                  || ' '
                  || CITY
                  || ', '
                  || POSTAL_CODE
                  || ', '
                  || COUNTRY
             FROM AR.HZ_LOCATIONS HLOC
            WHERE 1 = 1 AND HLOC.location_id = WDD.DELIVER_TO_LOCATION_ID)
             BILL_TO_ADDRESS,
          (SELECT OEH.CUST_PO_NUMBER
             FROM apps.oe_order_headers_all OEH
            WHERE wdd.SOURCE_HEADER_ID = oeh.header_id)
             CUSTOMER_PO_NUMBER,
          (SELECT FLV.MEANING
             FROM APPLSYS.FND_LOOKUP_VALUES FLV
            WHERE     1 = 1
                  AND flv.lookup_type = 'PICK_STATUS'
                  AND language = 'ESA'
                  AND FLV.LOOKUP_CODE(+) = WDD.RELEASED_STATUS)
             STATUS_SHIPPING_ORDER,
          WDD.ATtribute1 CUSTODY,
          (SELECT t.name
             FROM apps.wsh_trips t,
                  apps.fnd_lookup_values lv,
                  apps.wsh_trip_stops pickup_stop,
                  apps.wsh_trip_stops dropoff_stop,
                  apps.wsh_delivery_legs dl,
                  apps.wsh_delivery_assignments wa,
                  apps.wsh_new_deliveries wnd
            WHERE     1 = 1
                  AND lv.lookup_type = 'TRIP_STATUS'
                  AND lv.lookup_code = t.status_code
                  AND lv.language = 'ESA'
                  AND view_application_id = 665
                  AND security_group_id = 0
                  AND pickup_stop.stop_id = dl.pick_up_stop_id
                  AND dropoff_stop.stop_id = dl.drop_off_stop_id
                  AND pickup_stop.trip_id = t.trip_id
                  AND wnd.delivery_id = dl.delivery_id
                  AND wnd.delivery_id = wa.delivery_id
                  AND wa.delivery_detail_id = wdd.delivery_detail_id
                  AND NVL (wnd.shipment_direction, 'O') IN ('O', 'IO')
                  AND NVL (t.shipments_type_flag, 'O') IN ('O', 'M'))
             TRIP_NO,
          CTR.TRX_NUMBER,
          (SELECT POSTAL_CODE
             FROM AR.HZ_LOCATIONS HLOC
            WHERE 1 = 1 AND HLOC.location_id = WDD.DELIVER_TO_LOCATION_ID)
             ZIP_CODE,
          'N' HOLD_FLAG,
          WDD.SOURCE_HEADER_TYPE_NAME
     FROM WSH.WSH_DELIVERY_DETAILS WDD,
          wsh.wsh_delivery_assignments WDA,
          AR.HZ_LOCATIONS HL,
          INV.MTL_MATERIAL_TRANSACTIONS MMT,
          INV.MTL_SYSTEM_ITEMS_B MTS,
          apps.mtl_serial_numbers msn,
          apps.ra_customer_trx_all CTR,
          PO.RCV_SHIPMENT_HEADERS RCV
    WHERE     1 = 1
          AND wdd.delivery_detail_id = mmt.picking_line_id
          AND wdd.delivery_detail_id = wda.delivery_detail_id
          AND wda.delivery_id = CTR.interface_header_attribute3(+)
          AND TO_CHAR (wda.delivery_id) = RCV.shipment_num(+)
          AND msn.inventory_item_id = wdd.inventory_item_id
          AND WDD.INVENTORY_ITEM_ID = MTS.INVENTORY_ITEM_ID
          AND WDD.ORGANIZATION_ID = MTS.ORGANIZATION_ID
          AND msn.current_organization_id = wdd.organization_id
          AND msn.last_transaction_id = mmt.transaction_id
          AND wdd.ship_to_location_id = hl.location_id
          --and wdd.organization_id = 215
          AND wdd.date_requested >=
                 apps.fnd_date.canonical_to_date ('2019/06/01 00:00:00')
;

