CREATE OR REPLACE TRIGGER GG_ADMIN."JAI_OM_WDD_ARIUD_T1"
AFTER INSERT OR UPDATE OR DELETE ON "WSH_DELIVERY_DETAILS"
FOR EACH ROW
DECLARE
  t_old_rec             WSH_DELIVERY_DETAILS%rowtype ;
  t_new_rec             WSH_DELIVERY_DETAILS%rowtype ;
  lv_return_message     VARCHAR2(2000);
  lv_return_code        VARCHAR2(100) ;
  le_error              EXCEPTION     ;
  lv_action             VARCHAR2(20)  ;

  -- added by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 begin
  t_rec_line OE_ORDER_LINES_ALL%rowtype;

  CURSOR c_get_order_line (cp_header_id OE_ORDER_LINES_ALL.HEADER_ID%TYPE,
                           cp_line_id   OE_ORDER_LINES_ALL.LINE_ID%TYPE)
  IS
  SELECT *
  FROM   oe_order_lines_all
  WHERE  header_id = cp_header_id AND line_id = cp_line_id;
  -- added by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 end.

  /*
  || Here initialising the pr_new record type in the inline procedure
  ||
  */

  PROCEDURE populate_new IS
  BEGIN

    t_new_rec.DELIVERY_DETAIL_ID                       := :new.DELIVERY_DETAIL_ID                            ;
    t_new_rec.SOURCE_CODE                              := :new.SOURCE_CODE                                   ;
    t_new_rec.SOURCE_HEADER_ID                         := :new.SOURCE_HEADER_ID                              ;
    t_new_rec.SOURCE_LINE_ID                           := :new.SOURCE_LINE_ID                                ;
    t_new_rec.SOURCE_HEADER_TYPE_ID                    := :new.SOURCE_HEADER_TYPE_ID                         ;
    t_new_rec.SOURCE_HEADER_TYPE_NAME                  := :new.SOURCE_HEADER_TYPE_NAME                       ;
    t_new_rec.CUST_PO_NUMBER                           := :new.CUST_PO_NUMBER                                ;
    t_new_rec.CUSTOMER_ID                              := :new.CUSTOMER_ID                                   ;
    t_new_rec.SOLD_TO_CONTACT_ID                       := :new.SOLD_TO_CONTACT_ID                            ;
    t_new_rec.INVENTORY_ITEM_ID                        := :new.INVENTORY_ITEM_ID                             ;
    t_new_rec.ITEM_DESCRIPTION                         := :new.ITEM_DESCRIPTION                              ;
    t_new_rec.SHIP_SET_ID                              := :new.SHIP_SET_ID                                   ;
    t_new_rec.ARRIVAL_SET_ID                           := :new.ARRIVAL_SET_ID                                ;
    t_new_rec.TOP_MODEL_LINE_ID                        := :new.TOP_MODEL_LINE_ID                             ;
    t_new_rec.ATO_LINE_ID                              := :new.ATO_LINE_ID                                   ;
    t_new_rec.HOLD_CODE                                := :new.HOLD_CODE                                     ;
    t_new_rec.SHIP_MODEL_COMPLETE_FLAG                 := :new.SHIP_MODEL_COMPLETE_FLAG                      ;
    t_new_rec.HAZARD_CLASS_ID                          := :new.HAZARD_CLASS_ID                               ;
    t_new_rec.COUNTRY_OF_ORIGIN                        := :new.COUNTRY_OF_ORIGIN                             ;
    t_new_rec.CLASSIFICATION                           := :new.CLASSIFICATION                                ;
    t_new_rec.SHIP_FROM_LOCATION_ID                    := :new.SHIP_FROM_LOCATION_ID                         ;
    t_new_rec.ORGANIZATION_ID                          := :new.ORGANIZATION_ID                               ;
    t_new_rec.SHIP_TO_LOCATION_ID                      := :new.SHIP_TO_LOCATION_ID                           ;
    t_new_rec.SHIP_TO_CONTACT_ID                       := :new.SHIP_TO_CONTACT_ID                            ;
    t_new_rec.DELIVER_TO_LOCATION_ID                   := :new.DELIVER_TO_LOCATION_ID                        ;
    t_new_rec.DELIVER_TO_CONTACT_ID                    := :new.DELIVER_TO_CONTACT_ID                         ;
    t_new_rec.INTMED_SHIP_TO_LOCATION_ID               := :new.INTMED_SHIP_TO_LOCATION_ID                    ;
    t_new_rec.INTMED_SHIP_TO_CONTACT_ID                := :new.INTMED_SHIP_TO_CONTACT_ID                     ;
    t_new_rec.SHIP_TOLERANCE_ABOVE                     := :new.SHIP_TOLERANCE_ABOVE                          ;
    t_new_rec.SHIP_TOLERANCE_BELOW                     := :new.SHIP_TOLERANCE_BELOW                          ;
    t_new_rec.SRC_REQUESTED_QUANTITY                   := :new.SRC_REQUESTED_QUANTITY                        ;
    t_new_rec.SRC_REQUESTED_QUANTITY_UOM               := :new.SRC_REQUESTED_QUANTITY_UOM                    ;
    t_new_rec.CANCELLED_QUANTITY                       := :new.CANCELLED_QUANTITY                            ;
    t_new_rec.REQUESTED_QUANTITY                       := :new.REQUESTED_QUANTITY                            ;
    t_new_rec.REQUESTED_QUANTITY_UOM                   := :new.REQUESTED_QUANTITY_UOM                        ;
    t_new_rec.SHIPPED_QUANTITY                         := :new.SHIPPED_QUANTITY                              ;
    t_new_rec.DELIVERED_QUANTITY                       := :new.DELIVERED_QUANTITY                            ;
    t_new_rec.QUALITY_CONTROL_QUANTITY                 := :new.QUALITY_CONTROL_QUANTITY                      ;
    t_new_rec.CYCLE_COUNT_QUANTITY                     := :new.CYCLE_COUNT_QUANTITY                          ;
    t_new_rec.MOVE_ORDER_LINE_ID                       := :new.MOVE_ORDER_LINE_ID                            ;
    t_new_rec.SUBINVENTORY                             := :new.SUBINVENTORY                                  ;
    t_new_rec.REVISION                                 := :new.REVISION                                      ;
    t_new_rec.LOT_NUMBER                               := :new.LOT_NUMBER                                    ;
    t_new_rec.RELEASED_STATUS                          := :new.RELEASED_STATUS                               ;
    t_new_rec.CUSTOMER_REQUESTED_LOT_FLAG              := :new.CUSTOMER_REQUESTED_LOT_FLAG                   ;
    t_new_rec.SERIAL_NUMBER                            := :new.SERIAL_NUMBER                                 ;
    t_new_rec.LOCATOR_ID                               := :new.LOCATOR_ID                                    ;
    t_new_rec.DATE_REQUESTED                           := :new.DATE_REQUESTED                                ;
    t_new_rec.DATE_SCHEDULED                           := :new.DATE_SCHEDULED                                ;
    t_new_rec.MASTER_CONTAINER_ITEM_ID                 := :new.MASTER_CONTAINER_ITEM_ID                      ;
    t_new_rec.DETAIL_CONTAINER_ITEM_ID                 := :new.DETAIL_CONTAINER_ITEM_ID                      ;
    t_new_rec.LOAD_SEQ_NUMBER                          := :new.LOAD_SEQ_NUMBER                               ;
    t_new_rec.SHIP_METHOD_CODE                         := :new.SHIP_METHOD_CODE                              ;
    t_new_rec.CARRIER_ID                               := :new.CARRIER_ID                                    ;
    t_new_rec.FREIGHT_TERMS_CODE                       := :new.FREIGHT_TERMS_CODE                            ;
    t_new_rec.SHIPMENT_PRIORITY_CODE                   := :new.SHIPMENT_PRIORITY_CODE                        ;
    t_new_rec.FOB_CODE                                 := :new.FOB_CODE                                      ;
    t_new_rec.CUSTOMER_ITEM_ID                         := :new.CUSTOMER_ITEM_ID                              ;
    t_new_rec.DEP_PLAN_REQUIRED_FLAG                   := :new.DEP_PLAN_REQUIRED_FLAG                        ;
    t_new_rec.CUSTOMER_PROD_SEQ                        := :new.CUSTOMER_PROD_SEQ                             ;
    t_new_rec.CUSTOMER_DOCK_CODE                       := :new.CUSTOMER_DOCK_CODE                            ;
    t_new_rec.NET_WEIGHT                               := :new.NET_WEIGHT                                    ;
    t_new_rec.WEIGHT_UOM_CODE                          := :new.WEIGHT_UOM_CODE                               ;
    t_new_rec.VOLUME                                   := :new.VOLUME                                        ;
    t_new_rec.VOLUME_UOM_CODE                          := :new.VOLUME_UOM_CODE                               ;
    t_new_rec.SHIPPING_INSTRUCTIONS                    := :new.SHIPPING_INSTRUCTIONS                         ;
    t_new_rec.PACKING_INSTRUCTIONS                     := :new.PACKING_INSTRUCTIONS                          ;
    t_new_rec.PROJECT_ID                               := :new.PROJECT_ID                                    ;
    t_new_rec.TASK_ID                                  := :new.TASK_ID                                       ;
    t_new_rec.ORG_ID                                   := :new.ORG_ID                                        ;
    t_new_rec.OE_INTERFACED_FLAG                       := :new.OE_INTERFACED_FLAG                            ;
    t_new_rec.MVT_STAT_STATUS                          := :new.MVT_STAT_STATUS                               ;
    t_new_rec.TRACKING_NUMBER                          := :new.TRACKING_NUMBER                               ;
    t_new_rec.TRANSACTION_TEMP_ID                      := :new.TRANSACTION_TEMP_ID                           ;
    t_new_rec.TP_ATTRIBUTE_CATEGORY                    := :new.TP_ATTRIBUTE_CATEGORY                         ;
    t_new_rec.TP_ATTRIBUTE1                            := :new.TP_ATTRIBUTE1                                 ;
    t_new_rec.TP_ATTRIBUTE2                            := :new.TP_ATTRIBUTE2                                 ;
    t_new_rec.TP_ATTRIBUTE3                            := :new.TP_ATTRIBUTE3                                 ;
    t_new_rec.TP_ATTRIBUTE4                            := :new.TP_ATTRIBUTE4                                 ;
    t_new_rec.TP_ATTRIBUTE5                            := :new.TP_ATTRIBUTE5                                 ;
    t_new_rec.TP_ATTRIBUTE6                            := :new.TP_ATTRIBUTE6                                 ;
    t_new_rec.TP_ATTRIBUTE7                            := :new.TP_ATTRIBUTE7                                 ;
    t_new_rec.TP_ATTRIBUTE8                            := :new.TP_ATTRIBUTE8                                 ;
    t_new_rec.TP_ATTRIBUTE9                            := :new.TP_ATTRIBUTE9                                 ;
    t_new_rec.TP_ATTRIBUTE10                           := :new.TP_ATTRIBUTE10                                ;
    t_new_rec.TP_ATTRIBUTE11                           := :new.TP_ATTRIBUTE11                                ;
    t_new_rec.TP_ATTRIBUTE12                           := :new.TP_ATTRIBUTE12                                ;
    t_new_rec.TP_ATTRIBUTE13                           := :new.TP_ATTRIBUTE13                                ;
    t_new_rec.TP_ATTRIBUTE14                           := :new.TP_ATTRIBUTE14                                ;
    t_new_rec.TP_ATTRIBUTE15                           := :new.TP_ATTRIBUTE15                                ;
    t_new_rec.ATTRIBUTE_CATEGORY                       := :new.ATTRIBUTE_CATEGORY                            ;
    t_new_rec.ATTRIBUTE1                               := :new.ATTRIBUTE1                                    ;
    t_new_rec.ATTRIBUTE2                               := :new.ATTRIBUTE2                                    ;
    t_new_rec.ATTRIBUTE3                               := :new.ATTRIBUTE3                                    ;
    t_new_rec.ATTRIBUTE4                               := :new.ATTRIBUTE4                                    ;
    t_new_rec.ATTRIBUTE5                               := :new.ATTRIBUTE5                                    ;
    t_new_rec.ATTRIBUTE6                               := :new.ATTRIBUTE6                                    ;
    t_new_rec.ATTRIBUTE7                               := :new.ATTRIBUTE7                                    ;
    t_new_rec.ATTRIBUTE8                               := :new.ATTRIBUTE8                                    ;
    t_new_rec.ATTRIBUTE9                               := :new.ATTRIBUTE9                                    ;
    t_new_rec.ATTRIBUTE10                              := :new.ATTRIBUTE10                                   ;
    t_new_rec.ATTRIBUTE11                              := :new.ATTRIBUTE11                                   ;
    t_new_rec.ATTRIBUTE12                              := :new.ATTRIBUTE12                                   ;
    t_new_rec.ATTRIBUTE13                              := :new.ATTRIBUTE13                                   ;
    t_new_rec.ATTRIBUTE14                              := :new.ATTRIBUTE14                                   ;
    t_new_rec.ATTRIBUTE15                              := :new.ATTRIBUTE15                                   ;
    t_new_rec.CREATION_DATE                            := :new.CREATION_DATE                                 ;
    t_new_rec.CREATED_BY                               := :new.CREATED_BY                                    ;
    t_new_rec.LAST_UPDATE_DATE                         := :new.LAST_UPDATE_DATE                              ;
    t_new_rec.LAST_UPDATED_BY                          := :new.LAST_UPDATED_BY                               ;
    t_new_rec.LAST_UPDATE_LOGIN                        := :new.LAST_UPDATE_LOGIN                             ;
    t_new_rec.PROGRAM_APPLICATION_ID                   := :new.PROGRAM_APPLICATION_ID                        ;
    t_new_rec.PROGRAM_ID                               := :new.PROGRAM_ID                                    ;
    t_new_rec.PROGRAM_UPDATE_DATE                      := :new.PROGRAM_UPDATE_DATE                           ;
    t_new_rec.REQUEST_ID                               := :new.REQUEST_ID                                    ;
    t_new_rec.MOVEMENT_ID                              := :new.MOVEMENT_ID                                   ;
    t_new_rec.SPLIT_FROM_DELIVERY_DETAIL_ID            := :new.SPLIT_FROM_DELIVERY_DETAIL_ID                 ;
    t_new_rec.INV_INTERFACED_FLAG                      := :new.INV_INTERFACED_FLAG                           ;
    t_new_rec.SEAL_CODE                                := :new.SEAL_CODE                                     ;
    t_new_rec.MINIMUM_FILL_PERCENT                     := :new.MINIMUM_FILL_PERCENT                          ;
    t_new_rec.MAXIMUM_VOLUME                           := :new.MAXIMUM_VOLUME                                ;
    t_new_rec.MAXIMUM_LOAD_WEIGHT                      := :new.MAXIMUM_LOAD_WEIGHT                           ;
    t_new_rec.MASTER_SERIAL_NUMBER                     := :new.MASTER_SERIAL_NUMBER                          ;
    t_new_rec.GROSS_WEIGHT                             := :new.GROSS_WEIGHT                                  ;
    t_new_rec.FILL_PERCENT                             := :new.FILL_PERCENT                                  ;
    t_new_rec.CONTAINER_NAME                           := :new.CONTAINER_NAME                                ;
    t_new_rec.CONTAINER_TYPE_CODE                      := :new.CONTAINER_TYPE_CODE                           ;
    t_new_rec.CONTAINER_FLAG                           := :new.CONTAINER_FLAG                                ;
    t_new_rec.PREFERRED_GRADE                          := :new.PREFERRED_GRADE                               ;
    t_new_rec.SRC_REQUESTED_QUANTITY2                  := :new.SRC_REQUESTED_QUANTITY2                       ;
    t_new_rec.SRC_REQUESTED_QUANTITY_UOM2              := :new.SRC_REQUESTED_QUANTITY_UOM2                   ;
    t_new_rec.REQUESTED_QUANTITY2                      := :new.REQUESTED_QUANTITY2                           ;
    t_new_rec.SHIPPED_QUANTITY2                        := :new.SHIPPED_QUANTITY2                             ;
    t_new_rec.DELIVERED_QUANTITY2                      := :new.DELIVERED_QUANTITY2                           ;
    t_new_rec.CANCELLED_QUANTITY2                      := :new.CANCELLED_QUANTITY2                           ;
    t_new_rec.QUALITY_CONTROL_QUANTITY2                := :new.QUALITY_CONTROL_QUANTITY2                     ;
    t_new_rec.CYCLE_COUNT_QUANTITY2                    := :new.CYCLE_COUNT_QUANTITY2                         ;
    t_new_rec.REQUESTED_QUANTITY_UOM2                  := :new.REQUESTED_QUANTITY_UOM2                       ;
    t_new_rec.SUBLOT_NUMBER                            := :new.SUBLOT_NUMBER                                 ;
    t_new_rec.UNIT_PRICE                               := :new.UNIT_PRICE                                    ;
    t_new_rec.CURRENCY_CODE                            := :new.CURRENCY_CODE                                 ;
    t_new_rec.UNIT_NUMBER                              := :new.UNIT_NUMBER                                   ;
    t_new_rec.FREIGHT_CLASS_CAT_ID                     := :new.FREIGHT_CLASS_CAT_ID                          ;
    t_new_rec.COMMODITY_CODE_CAT_ID                    := :new.COMMODITY_CODE_CAT_ID                         ;
    t_new_rec.LPN_ID                                   := :new.LPN_ID                                        ;
    t_new_rec.INSPECTION_FLAG                          := :new.INSPECTION_FLAG                               ;
    t_new_rec.SHIP_TO_SITE_USE_ID                      := :new.SHIP_TO_SITE_USE_ID                           ;
    t_new_rec.DELIVER_TO_SITE_USE_ID                   := :new.DELIVER_TO_SITE_USE_ID                        ;
    t_new_rec.ORIGINAL_SUBINVENTORY                    := :new.ORIGINAL_SUBINVENTORY                         ;
    t_new_rec.PICKABLE_FLAG                            := :new.PICKABLE_FLAG                                 ;
    t_new_rec.SOURCE_HEADER_NUMBER                     := :new.SOURCE_HEADER_NUMBER                          ;
    t_new_rec.SOURCE_LINE_NUMBER                       := :new.SOURCE_LINE_NUMBER                            ;
    t_new_rec.TO_SERIAL_NUMBER                         := :new.TO_SERIAL_NUMBER                              ;
    t_new_rec.PICKED_QUANTITY                          := :new.PICKED_QUANTITY                               ;
    t_new_rec.PICKED_QUANTITY2                         := :new.PICKED_QUANTITY2                              ;
    t_new_rec.CUSTOMER_PRODUCTION_LINE                 := :new.CUSTOMER_PRODUCTION_LINE                      ;
    t_new_rec.CUSTOMER_JOB                             := :new.CUSTOMER_JOB                                  ;
    t_new_rec.CUST_MODEL_SERIAL_NUMBER                 := :new.CUST_MODEL_SERIAL_NUMBER                      ;
    t_new_rec.RECEIVED_QUANTITY                        := :new.RECEIVED_QUANTITY                             ;
    t_new_rec.RECEIVED_QUANTITY2                       := :new.RECEIVED_QUANTITY2                            ;
    t_new_rec.SOURCE_LINE_SET_ID                       := :new.SOURCE_LINE_SET_ID                            ;
    t_new_rec.BATCH_ID                                 := :new.BATCH_ID                                      ;
    t_new_rec.TRANSACTION_ID                           := :new.TRANSACTION_ID                                ;
    t_new_rec.SERVICE_LEVEL                            := :new.SERVICE_LEVEL                                 ;
    t_new_rec.MODE_OF_TRANSPORT                        := :new.MODE_OF_TRANSPORT                             ;
    t_new_rec.EARLIEST_PICKUP_DATE                     := :new.EARLIEST_PICKUP_DATE                          ;
    t_new_rec.LATEST_PICKUP_DATE                       := :new.LATEST_PICKUP_DATE                            ;
    t_new_rec.EARLIEST_DROPOFF_DATE                    := :new.EARLIEST_DROPOFF_DATE                         ;
    t_new_rec.LATEST_DROPOFF_DATE                      := :new.LATEST_DROPOFF_DATE                           ;
    t_new_rec.REQUEST_DATE_TYPE_CODE                   := :new.REQUEST_DATE_TYPE_CODE                        ;
    t_new_rec.TP_DELIVERY_DETAIL_ID                    := :new.TP_DELIVERY_DETAIL_ID                         ;
    t_new_rec.SOURCE_DOCUMENT_TYPE_ID                  := :new.SOURCE_DOCUMENT_TYPE_ID                       ;
    t_new_rec.VENDOR_ID                                := :new.VENDOR_ID                                     ;
    t_new_rec.SHIP_FROM_SITE_ID                        := :new.SHIP_FROM_SITE_ID                             ;
    t_new_rec.IGNORE_FOR_PLANNING                      := :new.IGNORE_FOR_PLANNING                           ;
    t_new_rec.LINE_DIRECTION                           := :new.LINE_DIRECTION                                ;
    t_new_rec.PARTY_ID                                 := :new.PARTY_ID                                      ;
    t_new_rec.ROUTING_REQ_ID                           := :new.ROUTING_REQ_ID                                ;
    t_new_rec.SHIPPING_CONTROL                         := :new.SHIPPING_CONTROL                              ;
    t_new_rec.SOURCE_BLANKET_REFERENCE_ID              := :new.SOURCE_BLANKET_REFERENCE_ID                   ;
    t_new_rec.SOURCE_BLANKET_REFERENCE_NUM             := :new.SOURCE_BLANKET_REFERENCE_NUM                  ;
    t_new_rec.PO_SHIPMENT_LINE_ID                      := :new.PO_SHIPMENT_LINE_ID                           ;
    t_new_rec.PO_SHIPMENT_LINE_NUMBER                  := :new.PO_SHIPMENT_LINE_NUMBER                       ;
    t_new_rec.SCHEDULED_QUANTITY                       := :new.SCHEDULED_QUANTITY                            ;
    t_new_rec.RETURNED_QUANTITY                        := :new.RETURNED_QUANTITY                             ;
    t_new_rec.SCHEDULED_QUANTITY2                      := :new.SCHEDULED_QUANTITY2                           ;
    t_new_rec.RETURNED_QUANTITY2                       := :new.RETURNED_QUANTITY2                            ;
    t_new_rec.SOURCE_LINE_TYPE_CODE                    := :new.SOURCE_LINE_TYPE_CODE                         ;
    t_new_rec.RCV_SHIPMENT_LINE_ID                     := :new.RCV_SHIPMENT_LINE_ID                          ;
    t_new_rec.SUPPLIER_ITEM_NUMBER                     := :new.SUPPLIER_ITEM_NUMBER                          ;
    t_new_rec.FILLED_VOLUME                            := :new.FILLED_VOLUME                                 ;
    t_new_rec.UNIT_WEIGHT                              := :new.UNIT_WEIGHT                                   ;
    t_new_rec.UNIT_VOLUME                              := :new.UNIT_VOLUME                                   ;
    t_new_rec.WV_FROZEN_FLAG                           := :new.WV_FROZEN_FLAG                                ;
    t_new_rec.PO_REVISION_NUMBER                       := :new.PO_REVISION_NUMBER                            ;
    t_new_rec.RELEASE_REVISION_NUMBER                  := :new.RELEASE_REVISION_NUMBER                       ;
  END populate_new ;

  PROCEDURE populate_old IS
  BEGIN
    t_old_rec.DELIVERY_DETAIL_ID                       := :old.DELIVERY_DETAIL_ID                            ;
    t_old_rec.SOURCE_CODE                              := :old.SOURCE_CODE                                   ;
    t_old_rec.SOURCE_HEADER_ID                         := :old.SOURCE_HEADER_ID                              ;
    t_old_rec.SOURCE_LINE_ID                           := :old.SOURCE_LINE_ID                                ;
    t_old_rec.SOURCE_HEADER_TYPE_ID                    := :old.SOURCE_HEADER_TYPE_ID                         ;
    t_old_rec.SOURCE_HEADER_TYPE_NAME                  := :old.SOURCE_HEADER_TYPE_NAME                       ;
    t_old_rec.CUST_PO_NUMBER                           := :old.CUST_PO_NUMBER                                ;
    t_old_rec.CUSTOMER_ID                              := :old.CUSTOMER_ID                                   ;
    t_old_rec.SOLD_TO_CONTACT_ID                       := :old.SOLD_TO_CONTACT_ID                            ;
    t_old_rec.INVENTORY_ITEM_ID                        := :old.INVENTORY_ITEM_ID                             ;
    t_old_rec.ITEM_DESCRIPTION                         := :old.ITEM_DESCRIPTION                              ;
    t_old_rec.SHIP_SET_ID                              := :old.SHIP_SET_ID                                   ;
    t_old_rec.ARRIVAL_SET_ID                           := :old.ARRIVAL_SET_ID                                ;
    t_old_rec.TOP_MODEL_LINE_ID                        := :old.TOP_MODEL_LINE_ID                             ;
    t_old_rec.ATO_LINE_ID                              := :old.ATO_LINE_ID                                   ;
    t_old_rec.HOLD_CODE                                := :old.HOLD_CODE                                     ;
    t_old_rec.SHIP_MODEL_COMPLETE_FLAG                 := :old.SHIP_MODEL_COMPLETE_FLAG                      ;
    t_old_rec.HAZARD_CLASS_ID                          := :old.HAZARD_CLASS_ID                               ;
    t_old_rec.COUNTRY_OF_ORIGIN                        := :old.COUNTRY_OF_ORIGIN                             ;
    t_old_rec.CLASSIFICATION                           := :old.CLASSIFICATION                                ;
    t_old_rec.SHIP_FROM_LOCATION_ID                    := :old.SHIP_FROM_LOCATION_ID                         ;
    t_old_rec.ORGANIZATION_ID                          := :old.ORGANIZATION_ID                               ;
    t_old_rec.SHIP_TO_LOCATION_ID                      := :old.SHIP_TO_LOCATION_ID                           ;
    t_old_rec.SHIP_TO_CONTACT_ID                       := :old.SHIP_TO_CONTACT_ID                            ;
    t_old_rec.DELIVER_TO_LOCATION_ID                   := :old.DELIVER_TO_LOCATION_ID                        ;
    t_old_rec.DELIVER_TO_CONTACT_ID                    := :old.DELIVER_TO_CONTACT_ID                         ;
    t_old_rec.INTMED_SHIP_TO_LOCATION_ID               := :old.INTMED_SHIP_TO_LOCATION_ID                    ;
    t_old_rec.INTMED_SHIP_TO_CONTACT_ID                := :old.INTMED_SHIP_TO_CONTACT_ID                     ;
    t_old_rec.SHIP_TOLERANCE_ABOVE                     := :old.SHIP_TOLERANCE_ABOVE                          ;
    t_old_rec.SHIP_TOLERANCE_BELOW                     := :old.SHIP_TOLERANCE_BELOW                          ;
    t_old_rec.SRC_REQUESTED_QUANTITY                   := :old.SRC_REQUESTED_QUANTITY                        ;
    t_old_rec.SRC_REQUESTED_QUANTITY_UOM               := :old.SRC_REQUESTED_QUANTITY_UOM                    ;
    t_old_rec.CANCELLED_QUANTITY                       := :old.CANCELLED_QUANTITY                            ;
    t_old_rec.REQUESTED_QUANTITY                       := :old.REQUESTED_QUANTITY                            ;
    t_old_rec.REQUESTED_QUANTITY_UOM                   := :old.REQUESTED_QUANTITY_UOM                        ;
    t_old_rec.SHIPPED_QUANTITY                         := :old.SHIPPED_QUANTITY                              ;
    t_old_rec.DELIVERED_QUANTITY                       := :old.DELIVERED_QUANTITY                            ;
    t_old_rec.QUALITY_CONTROL_QUANTITY                 := :old.QUALITY_CONTROL_QUANTITY                      ;
    t_old_rec.CYCLE_COUNT_QUANTITY                     := :old.CYCLE_COUNT_QUANTITY                          ;
    t_old_rec.MOVE_ORDER_LINE_ID                       := :old.MOVE_ORDER_LINE_ID                            ;
    t_old_rec.SUBINVENTORY                             := :old.SUBINVENTORY                                  ;
    t_old_rec.REVISION                                 := :old.REVISION                                      ;
    t_old_rec.LOT_NUMBER                               := :old.LOT_NUMBER                                    ;
    t_old_rec.RELEASED_STATUS                          := :old.RELEASED_STATUS                               ;
    t_old_rec.CUSTOMER_REQUESTED_LOT_FLAG              := :old.CUSTOMER_REQUESTED_LOT_FLAG                   ;
    t_old_rec.SERIAL_NUMBER                            := :old.SERIAL_NUMBER                                 ;
    t_old_rec.LOCATOR_ID                               := :old.LOCATOR_ID                                    ;
    t_old_rec.DATE_REQUESTED                           := :old.DATE_REQUESTED                                ;
    t_old_rec.DATE_SCHEDULED                           := :old.DATE_SCHEDULED                                ;
    t_old_rec.MASTER_CONTAINER_ITEM_ID                 := :old.MASTER_CONTAINER_ITEM_ID                      ;
    t_old_rec.DETAIL_CONTAINER_ITEM_ID                 := :old.DETAIL_CONTAINER_ITEM_ID                      ;
    t_old_rec.LOAD_SEQ_NUMBER                          := :old.LOAD_SEQ_NUMBER                               ;
    t_old_rec.SHIP_METHOD_CODE                         := :old.SHIP_METHOD_CODE                              ;
    t_old_rec.CARRIER_ID                               := :old.CARRIER_ID                                    ;
    t_old_rec.FREIGHT_TERMS_CODE                       := :old.FREIGHT_TERMS_CODE                            ;
    t_old_rec.SHIPMENT_PRIORITY_CODE                   := :old.SHIPMENT_PRIORITY_CODE                        ;
    t_old_rec.FOB_CODE                                 := :old.FOB_CODE                                      ;
    t_old_rec.CUSTOMER_ITEM_ID                         := :old.CUSTOMER_ITEM_ID                              ;
    t_old_rec.DEP_PLAN_REQUIRED_FLAG                   := :old.DEP_PLAN_REQUIRED_FLAG                        ;
    t_old_rec.CUSTOMER_PROD_SEQ                        := :old.CUSTOMER_PROD_SEQ                             ;
    t_old_rec.CUSTOMER_DOCK_CODE                       := :old.CUSTOMER_DOCK_CODE                            ;
    t_old_rec.NET_WEIGHT                               := :old.NET_WEIGHT                                    ;
    t_old_rec.WEIGHT_UOM_CODE                          := :old.WEIGHT_UOM_CODE                               ;
    t_old_rec.VOLUME                                   := :old.VOLUME                                        ;
    t_old_rec.VOLUME_UOM_CODE                          := :old.VOLUME_UOM_CODE                               ;
    t_old_rec.SHIPPING_INSTRUCTIONS                    := :old.SHIPPING_INSTRUCTIONS                         ;
    t_old_rec.PACKING_INSTRUCTIONS                     := :old.PACKING_INSTRUCTIONS                          ;
    t_old_rec.PROJECT_ID                               := :old.PROJECT_ID                                    ;
    t_old_rec.TASK_ID                                  := :old.TASK_ID                                       ;
    t_old_rec.ORG_ID                                   := :old.ORG_ID                                        ;
    t_old_rec.OE_INTERFACED_FLAG                       := :old.OE_INTERFACED_FLAG                            ;
    t_old_rec.MVT_STAT_STATUS                          := :old.MVT_STAT_STATUS                               ;
    t_old_rec.TRACKING_NUMBER                          := :old.TRACKING_NUMBER                               ;
    t_old_rec.TRANSACTION_TEMP_ID                      := :old.TRANSACTION_TEMP_ID                           ;
    t_old_rec.TP_ATTRIBUTE_CATEGORY                    := :old.TP_ATTRIBUTE_CATEGORY                         ;
    t_old_rec.TP_ATTRIBUTE1                            := :old.TP_ATTRIBUTE1                                 ;
    t_old_rec.TP_ATTRIBUTE2                            := :old.TP_ATTRIBUTE2                                 ;
    t_old_rec.TP_ATTRIBUTE3                            := :old.TP_ATTRIBUTE3                                 ;
    t_old_rec.TP_ATTRIBUTE4                            := :old.TP_ATTRIBUTE4                                 ;
    t_old_rec.TP_ATTRIBUTE5                            := :old.TP_ATTRIBUTE5                                 ;
    t_old_rec.TP_ATTRIBUTE6                            := :old.TP_ATTRIBUTE6                                 ;
    t_old_rec.TP_ATTRIBUTE7                            := :old.TP_ATTRIBUTE7                                 ;
    t_old_rec.TP_ATTRIBUTE8                            := :old.TP_ATTRIBUTE8                                 ;
    t_old_rec.TP_ATTRIBUTE9                            := :old.TP_ATTRIBUTE9                                 ;
    t_old_rec.TP_ATTRIBUTE10                           := :old.TP_ATTRIBUTE10                                ;
    t_old_rec.TP_ATTRIBUTE11                           := :old.TP_ATTRIBUTE11                                ;
    t_old_rec.TP_ATTRIBUTE12                           := :old.TP_ATTRIBUTE12                                ;
    t_old_rec.TP_ATTRIBUTE13                           := :old.TP_ATTRIBUTE13                                ;
    t_old_rec.TP_ATTRIBUTE14                           := :old.TP_ATTRIBUTE14                                ;
    t_old_rec.TP_ATTRIBUTE15                           := :old.TP_ATTRIBUTE15                                ;
    t_old_rec.ATTRIBUTE_CATEGORY                       := :old.ATTRIBUTE_CATEGORY                            ;
    t_old_rec.ATTRIBUTE1                               := :old.ATTRIBUTE1                                    ;
    t_old_rec.ATTRIBUTE2                               := :old.ATTRIBUTE2                                    ;
    t_old_rec.ATTRIBUTE3                               := :old.ATTRIBUTE3                                    ;
    t_old_rec.ATTRIBUTE4                               := :old.ATTRIBUTE4                                    ;
    t_old_rec.ATTRIBUTE5                               := :old.ATTRIBUTE5                                    ;
    t_old_rec.ATTRIBUTE6                               := :old.ATTRIBUTE6                                    ;
    t_old_rec.ATTRIBUTE7                               := :old.ATTRIBUTE7                                    ;
    t_old_rec.ATTRIBUTE8                               := :old.ATTRIBUTE8                                    ;
    t_old_rec.ATTRIBUTE9                               := :old.ATTRIBUTE9                                    ;
    t_old_rec.ATTRIBUTE10                              := :old.ATTRIBUTE10                                   ;
    t_old_rec.ATTRIBUTE11                              := :old.ATTRIBUTE11                                   ;
    t_old_rec.ATTRIBUTE12                              := :old.ATTRIBUTE12                                   ;
    t_old_rec.ATTRIBUTE13                              := :old.ATTRIBUTE13                                   ;
    t_old_rec.ATTRIBUTE14                              := :old.ATTRIBUTE14                                   ;
    t_old_rec.ATTRIBUTE15                              := :old.ATTRIBUTE15                                   ;
    t_old_rec.CREATION_DATE                            := :old.CREATION_DATE                                 ;
    t_old_rec.CREATED_BY                               := :old.CREATED_BY                                    ;
    t_old_rec.LAST_UPDATE_DATE                         := :old.LAST_UPDATE_DATE                              ;
    t_old_rec.LAST_UPDATED_BY                          := :old.LAST_UPDATED_BY                               ;
    t_old_rec.LAST_UPDATE_LOGIN                        := :old.LAST_UPDATE_LOGIN                             ;
    t_old_rec.PROGRAM_APPLICATION_ID                   := :old.PROGRAM_APPLICATION_ID                        ;
    t_old_rec.PROGRAM_ID                               := :old.PROGRAM_ID                                    ;
    t_old_rec.PROGRAM_UPDATE_DATE                      := :old.PROGRAM_UPDATE_DATE                           ;
    t_old_rec.REQUEST_ID                               := :old.REQUEST_ID                                    ;
    t_old_rec.MOVEMENT_ID                              := :old.MOVEMENT_ID                                   ;
    t_old_rec.SPLIT_FROM_DELIVERY_DETAIL_ID            := :old.SPLIT_FROM_DELIVERY_DETAIL_ID                 ;
    t_old_rec.INV_INTERFACED_FLAG                      := :old.INV_INTERFACED_FLAG                           ;
    t_old_rec.SEAL_CODE                                := :old.SEAL_CODE                                     ;
    t_old_rec.MINIMUM_FILL_PERCENT                     := :old.MINIMUM_FILL_PERCENT                          ;
    t_old_rec.MAXIMUM_VOLUME                           := :old.MAXIMUM_VOLUME                                ;
    t_old_rec.MAXIMUM_LOAD_WEIGHT                      := :old.MAXIMUM_LOAD_WEIGHT                           ;
    t_old_rec.MASTER_SERIAL_NUMBER                     := :old.MASTER_SERIAL_NUMBER                          ;
    t_old_rec.GROSS_WEIGHT                             := :old.GROSS_WEIGHT                                  ;
    t_old_rec.FILL_PERCENT                             := :old.FILL_PERCENT                                  ;
    t_old_rec.CONTAINER_NAME                           := :old.CONTAINER_NAME                                ;
    t_old_rec.CONTAINER_TYPE_CODE                      := :old.CONTAINER_TYPE_CODE                           ;
    t_old_rec.CONTAINER_FLAG                           := :old.CONTAINER_FLAG                                ;
    t_old_rec.PREFERRED_GRADE                          := :old.PREFERRED_GRADE                               ;
    t_old_rec.SRC_REQUESTED_QUANTITY2                  := :old.SRC_REQUESTED_QUANTITY2                       ;
    t_old_rec.SRC_REQUESTED_QUANTITY_UOM2              := :old.SRC_REQUESTED_QUANTITY_UOM2                   ;
    t_old_rec.REQUESTED_QUANTITY2                      := :old.REQUESTED_QUANTITY2                           ;
    t_old_rec.SHIPPED_QUANTITY2                        := :old.SHIPPED_QUANTITY2                             ;
    t_old_rec.DELIVERED_QUANTITY2                      := :old.DELIVERED_QUANTITY2                           ;
    t_old_rec.CANCELLED_QUANTITY2                      := :old.CANCELLED_QUANTITY2                           ;
    t_old_rec.QUALITY_CONTROL_QUANTITY2                := :old.QUALITY_CONTROL_QUANTITY2                     ;
    t_old_rec.CYCLE_COUNT_QUANTITY2                    := :old.CYCLE_COUNT_QUANTITY2                         ;
    t_old_rec.REQUESTED_QUANTITY_UOM2                  := :old.REQUESTED_QUANTITY_UOM2                       ;
    t_old_rec.SUBLOT_NUMBER                            := :old.SUBLOT_NUMBER                                 ;
    t_old_rec.UNIT_PRICE                               := :old.UNIT_PRICE                                    ;
    t_old_rec.CURRENCY_CODE                            := :old.CURRENCY_CODE                                 ;
    t_old_rec.UNIT_NUMBER                              := :old.UNIT_NUMBER                                   ;
    t_old_rec.FREIGHT_CLASS_CAT_ID                     := :old.FREIGHT_CLASS_CAT_ID                          ;
    t_old_rec.COMMODITY_CODE_CAT_ID                    := :old.COMMODITY_CODE_CAT_ID                         ;
    t_old_rec.LPN_ID                                   := :old.LPN_ID                                        ;
    t_old_rec.INSPECTION_FLAG                          := :old.INSPECTION_FLAG                               ;
    t_old_rec.SHIP_TO_SITE_USE_ID                      := :old.SHIP_TO_SITE_USE_ID                           ;
    t_old_rec.DELIVER_TO_SITE_USE_ID                   := :old.DELIVER_TO_SITE_USE_ID                        ;
    t_old_rec.ORIGINAL_SUBINVENTORY                    := :old.ORIGINAL_SUBINVENTORY                         ;
    t_old_rec.PICKABLE_FLAG                            := :old.PICKABLE_FLAG                                 ;
    t_old_rec.SOURCE_HEADER_NUMBER                     := :old.SOURCE_HEADER_NUMBER                          ;
    t_old_rec.SOURCE_LINE_NUMBER                       := :old.SOURCE_LINE_NUMBER                            ;
    t_old_rec.TO_SERIAL_NUMBER                         := :old.TO_SERIAL_NUMBER                              ;
    t_old_rec.PICKED_QUANTITY                          := :old.PICKED_QUANTITY                               ;
    t_old_rec.PICKED_QUANTITY2                         := :old.PICKED_QUANTITY2                              ;
    t_old_rec.CUSTOMER_PRODUCTION_LINE                 := :old.CUSTOMER_PRODUCTION_LINE                      ;
    t_old_rec.CUSTOMER_JOB                             := :old.CUSTOMER_JOB                                  ;
    t_old_rec.CUST_MODEL_SERIAL_NUMBER                 := :old.CUST_MODEL_SERIAL_NUMBER                      ;
    t_old_rec.RECEIVED_QUANTITY                        := :old.RECEIVED_QUANTITY                             ;
    t_old_rec.RECEIVED_QUANTITY2                       := :old.RECEIVED_QUANTITY2                            ;
    t_old_rec.SOURCE_LINE_SET_ID                       := :old.SOURCE_LINE_SET_ID                            ;
    t_old_rec.BATCH_ID                                 := :old.BATCH_ID                                      ;
    t_old_rec.TRANSACTION_ID                           := :old.TRANSACTION_ID                                ;
    t_old_rec.SERVICE_LEVEL                            := :old.SERVICE_LEVEL                                 ;
    t_old_rec.MODE_OF_TRANSPORT                        := :old.MODE_OF_TRANSPORT                             ;
    t_old_rec.EARLIEST_PICKUP_DATE                     := :old.EARLIEST_PICKUP_DATE                          ;
    t_old_rec.LATEST_PICKUP_DATE                       := :old.LATEST_PICKUP_DATE                            ;
    t_old_rec.EARLIEST_DROPOFF_DATE                    := :old.EARLIEST_DROPOFF_DATE                         ;
    t_old_rec.LATEST_DROPOFF_DATE                      := :old.LATEST_DROPOFF_DATE                           ;
    t_old_rec.REQUEST_DATE_TYPE_CODE                   := :old.REQUEST_DATE_TYPE_CODE                        ;
    t_old_rec.TP_DELIVERY_DETAIL_ID                    := :old.TP_DELIVERY_DETAIL_ID                         ;
    t_old_rec.SOURCE_DOCUMENT_TYPE_ID                  := :old.SOURCE_DOCUMENT_TYPE_ID                       ;
    t_old_rec.VENDOR_ID                                := :old.VENDOR_ID                                     ;
    t_old_rec.SHIP_FROM_SITE_ID                        := :old.SHIP_FROM_SITE_ID                             ;
    t_old_rec.IGNORE_FOR_PLANNING                      := :old.IGNORE_FOR_PLANNING                           ;
    t_old_rec.LINE_DIRECTION                           := :old.LINE_DIRECTION                                ;
    t_old_rec.PARTY_ID                                 := :old.PARTY_ID                                      ;
    t_old_rec.ROUTING_REQ_ID                           := :old.ROUTING_REQ_ID                                ;
    t_old_rec.SHIPPING_CONTROL                         := :old.SHIPPING_CONTROL                              ;
    t_old_rec.SOURCE_BLANKET_REFERENCE_ID              := :old.SOURCE_BLANKET_REFERENCE_ID                   ;
    t_old_rec.SOURCE_BLANKET_REFERENCE_NUM             := :old.SOURCE_BLANKET_REFERENCE_NUM                  ;
    t_old_rec.PO_SHIPMENT_LINE_ID                      := :old.PO_SHIPMENT_LINE_ID                           ;
    t_old_rec.PO_SHIPMENT_LINE_NUMBER                  := :old.PO_SHIPMENT_LINE_NUMBER                       ;
    t_old_rec.SCHEDULED_QUANTITY                       := :old.SCHEDULED_QUANTITY                            ;
    t_old_rec.RETURNED_QUANTITY                        := :old.RETURNED_QUANTITY                             ;
    t_old_rec.SCHEDULED_QUANTITY2                      := :old.SCHEDULED_QUANTITY2                           ;
    t_old_rec.RETURNED_QUANTITY2                       := :old.RETURNED_QUANTITY2                            ;
    t_old_rec.SOURCE_LINE_TYPE_CODE                    := :old.SOURCE_LINE_TYPE_CODE                         ;
    t_old_rec.RCV_SHIPMENT_LINE_ID                     := :old.RCV_SHIPMENT_LINE_ID                          ;
    t_old_rec.SUPPLIER_ITEM_NUMBER                     := :old.SUPPLIER_ITEM_NUMBER                          ;
    t_old_rec.FILLED_VOLUME                            := :old.FILLED_VOLUME                                 ;
    t_old_rec.UNIT_WEIGHT                              := :old.UNIT_WEIGHT                                   ;
    t_old_rec.UNIT_VOLUME                              := :old.UNIT_VOLUME                                   ;
    t_old_rec.WV_FROZEN_FLAG                           := :old.WV_FROZEN_FLAG                                ;
    t_old_rec.PO_REVISION_NUMBER                       := :old.PO_REVISION_NUMBER                            ;
    t_old_rec.RELEASE_REVISION_NUMBER                  := :old.RELEASE_REVISION_NUMBER                       ;
  END populate_old ;

BEGIN
  jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','462 begin of trigger JAI_OM_WDD_ARIUD_T1');
  /*
  || assign the new values depending upon the triggering event.
  */
  IF UPDATING OR INSERTING THEN
     jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','467 before calling to procedure populate_new');
     populate_new;
  END IF;


  /*
  || assign the old values depending upon the triggering event.
  */

  IF UPDATING OR DELETING THEN
     jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','477 before calling to procedure populate_old');
     populate_old;
  END IF;


  /*
  || make a call to the INR check package.
  */
  jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1',':new.org_id '||:new.org_id);
  IF jai_cmn_utils_pkg.check_jai_exists(P_CALLING_OBJECT => 'JAI_OM_WDD_ARIUD_T1', P_ORG_ID => :new.org_id) = FALSE THEN
       jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','486 before RETURN ');
       RETURN;
  END IF;

  /*
  || check for action in trigger and pass the same to the procedure
  */
  IF    INSERTING THEN
        lv_action := jai_constants.inserting ;
        jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','495 lv_action '||lv_action);
  ELSIF UPDATING THEN
        lv_action := jai_constants.updating ;
        jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','497 lv_action '||lv_action);
  ELSIF DELETING THEN
        lv_action := jai_constants.deleting ;
        jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','501 lv_action '||lv_action);
  END IF ;

  IF UPDATING THEN
fnd_file.put_line(fnd_file.LOG,' Debug level 0: Updating the Table ');

    IF ( :NEW.cycle_count_quantity > 0 ) THEN
      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','508 before call to JAI_OM_WDD_TRIGGER_PKG.ARU_T1 ');
      JAI_OM_WDD_TRIGGER_PKG.ARU_T1 (
                        pr_old            =>  t_old_rec         ,
                        pr_new            =>  t_new_rec         ,
                        pv_action         =>  lv_action         ,
                        pv_return_code    =>  lv_return_code    ,
                        pv_return_message =>  lv_return_message
                      );

      IF lv_return_code <> jai_constants.successful   then
             RAISE le_error;
      END IF;

    END IF ;

    jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','523 :NEW.Released_status '||:NEW.Released_status||', :OLD.Released_status '||:OLD.Released_status);
    IF (  nvl(:NEW.Released_status,'N') = 'C' AND nvl(:OLD.Released_status,'N') <> 'C'  ) OR ( nvl(:NEW.Released_status,'N') = 'B' AND nvl(:OLD.Released_status,'N') <> 'B' ) THEN
      -- commented out by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 begin
      /*JAI_OM_WDD_TRIGGER_PKG.ARU_T2 (
                        pr_old            =>  t_old_rec         ,
                        pr_new            =>  t_new_rec         ,
                        pv_action         =>  lv_action         ,
                        pv_return_code    =>  lv_return_code    ,
                        pv_return_message =>  lv_return_message
                      );*/
      -- commented out by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 end.

      -- added by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 begin

    IF (  nvl(:NEW.Released_status,'N') = 'C' AND nvl(:OLD.Released_status,'N') <> 'C'  ) THEN /*Added by mmurtuza for bug 17650577*/

      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','536 t_new_rec.source_header_id '||t_new_rec.source_header_id||', t_new_rec.source_line_id '||t_new_rec.source_line_id);
      open c_get_order_line (t_new_rec.source_header_id, t_new_rec.source_line_id);
      fetch c_get_order_line into t_rec_line;
      close c_get_order_line;

      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','541 before call to JAI_OM_TAX_PROCESSING_PKG.ORDER_LINE_VALIDATION ');
      JAI_OM_TAX_PROCESSING_PKG.ORDER_LINE_VALIDATION (
                        p_rec_old            =>  null              ,
                        p_rec_new            =>  t_rec_line        ,
                        p_action             =>  lv_action         ,
                        px_return_code       =>  lv_return_code    ,
                        px_return_message    =>  lv_return_message
                      );
     jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','549 after the call JAI_OM_TAX_PROCESSING_PKG.ORDER_LINE_VALIDATION ');

      IF lv_return_code <> jai_constants.successful   then
             RAISE le_error;
      END IF;
    END IF;

      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','556 before call to JAI_OM_WDD_PROCESSING_PKG.DELIVER_DETAILS ');
      JAI_OM_WDD_PROCESSING_PKG.DELIVER_DETAILS (
                        pr_old            =>  t_old_rec         ,
                        pr_new            =>  t_new_rec         ,
                        pv_action         =>  lv_action         ,
                        pv_return_code    =>  lv_return_code    ,
                        pv_return_message =>  lv_return_message
                      );
      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','563 after the call JAI_OM_WDD_PROCESSING_PKG.DELIVER_DETAILS ');

      -- added by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 end.

      IF lv_return_code <> jai_constants.successful   then
             RAISE le_error;
      END IF;

    END IF ;

    jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','573 :NEW.OE_Interfaced_Flag '||:NEW.OE_Interfaced_Flag||', :OLD.OE_Interfaced_Flag '||:OLD.OE_Interfaced_Flag);
    IF NVL(:NEW.OE_Interfaced_Flag,'N') = 'Y' AND NVL(:OLD.OE_Interfaced_Flag,'N') <> 'Y' THEN
      -- commented out by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 begin
      /*JAI_OM_WDD_TRIGGER_PKG.ARU_T3 (
                        pr_old            =>  t_old_rec         ,
                        pr_new            =>  t_new_rec         ,
                        pv_action         =>  lv_action         ,
                        pv_return_code    =>  lv_return_code    ,
                        pv_return_message =>  lv_return_message
                      );*/
     /*bug 10213327  - accounting entries for RG23D reversal by abezgam  BEGIN*/
    /*JAI_OM_WDD_TRIGGER_PKG.RG23D_REV_ACCOUNTING  (pr_trig_row   => t_new_rec         ,
        pv_return_code =>lv_return_code    ,
        pv_return_message  => lv_return_message);*/
        /*bug 10213327  -END*/
      -- commented out by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 end.

      -- added by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 begin
      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','591 before the call to JAI_OM_WDD_PROCESSING_PKG.PROCESS_INTERFACED ');
      JAI_OM_WDD_PROCESSING_PKG.PROCESS_INTERFACED (pr_old            =>  t_old_rec         ,
                                                    pr_new            =>  t_new_rec         ,
                                                    pv_action         =>  lv_action         ,
                                                    pv_return_code    =>  lv_return_code    ,
                                                    pv_return_message =>  lv_return_message);
      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','597 before the call  to JAI_OM_WDD_PROCESSING_PKG.RG23D_REV_ACCOUNTING ');

      JAI_OM_WDD_PROCESSING_PKG.RG23D_REV_ACCOUNTING (pr_trig_row        =>  t_new_rec         ,
                                                          pv_return_code     =>  lv_return_code    ,
                                                          pv_return_message  =>  lv_return_message);
      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','602 after the call JAI_OM_WDD_PROCESSING_PKG.RG23D_REV_ACCOUNTING ');

--start additions by vkaranam for bug#21031547


      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','603 before the call  to JAI_OM_WDD_PROCESSING_PKG.iso_other_accounting ');

      JAI_OM_WDD_PROCESSING_PKG.iso_other_accounting (pr_wdd_row        =>   t_new_rec         ,
                                                          pv_return_code     =>  lv_return_code    ,
                                                          pv_return_message  =>  lv_return_message);
      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','604 after the call JAI_OM_WDD_PROCESSING_PKG.iso_other_accounting ');


--end additions by vkaranam for bug#21031547
     -- added by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 end.

      IF lv_return_code <> jai_constants.successful   then
             RAISE le_error;
      END IF;

    END IF ;
    --Added below code by JMEENA for bug#6731913
    jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','612 :NEW.Released_status '||:NEW.Released_status);
    IF NVL(:NEW.Released_status,'N') = 'Y'  THEN
        -- commented out by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 begin
            /*JAI_OM_WDD_TRIGGER_PKG.ARU_T4 (
                        pr_old            =>  t_old_rec         ,
                        pr_new            =>  t_new_rec         ,
                        pv_action         =>  lv_action         ,
                        pv_return_code    =>  lv_return_code    ,
                        pv_return_message =>  lv_return_message
                      );*/
        -- commented out by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 end.

        -- added by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 begin
        jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','624 before the call to  JAI_OM_WDD_PROCESSING_PKG.PROCESS_RELEASED ');
        JAI_OM_WDD_PROCESSING_PKG.PROCESS_RELEASED (
                        pr_old            =>  t_old_rec         ,
                        pr_new            =>  t_new_rec         ,
                        pv_action         =>  lv_action         ,
                        pv_return_code    =>  lv_return_code    ,
                        pv_return_message =>  lv_return_message
                      );
        jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','633 after the call JAI_OM_WDD_PROCESSING_PKG.PROCESS_RELEASED ');
        -- added by zhiwei.xin for Trigger Replacement bug#15968958 on 20-Dec-2012 end.
    END IF;

     END IF ;

  IF DELETING THEN
      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','640 before the call to JAI_OM_WDD_TRIGGER_PKG.ARD_T1 ');
      JAI_OM_WDD_TRIGGER_PKG.ARD_T1 (
                        pr_old            =>  t_old_rec         ,
                        pr_new            =>  t_new_rec         ,
                        pv_action         =>  lv_action         ,
                        pv_return_code    =>  lv_return_code    ,
                        pv_return_message =>  lv_return_message
                      );
      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','648 after the call JAI_OM_WDD_TRIGGER_PKG.ARD_T1 ');

      IF lv_return_code <> jai_constants.successful   then
             jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','652 before RAISE le_error; ');
             RAISE le_error;
      END IF;

  END IF ;

jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','658 End of trigger JAI_OM_WDD_ARIUD_T1 ');

EXCEPTION

  WHEN le_error THEN

     app_exception.raise_exception (
                                     EXCEPTION_TYPE  => 'APP'  ,
                                     EXCEPTION_CODE  => -20110 ,
                                     EXCEPTION_TEXT  => lv_return_message
                                   );

  WHEN OTHERS THEN

      app_exception.raise_exception (
                                      EXCEPTION_TYPE  => 'APP',
                                      EXCEPTION_CODE  => -20110 ,
                                      EXCEPTION_TEXT  => 'Encountered the error in trigger JAI_OM_WDD_ARIUD_T1' || substr(sqlerrm,1,1900)
                                    );
      jai_cmn_utils_pkg.write_fnd_log_msg('JAI_OM_WDD_ARIUD_T1','677 Exception occured in JAI_OM_WDD_ARIUD_T1 trigger sqlcode '||sqlcode||', sqlerrm '||sqlerrm);

END JAI_OM_WDD_ARIUD_T1 ;
/

