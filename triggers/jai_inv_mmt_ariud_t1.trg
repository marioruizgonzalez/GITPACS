CREATE OR REPLACE TRIGGER GG_ADMIN."JAI_INV_MMT_ARIUD_T1"
AFTER INSERT OR UPDATE OR DELETE ON "MTL_MATERIAL_TRANSACTIONS"
FOR EACH ROW
DECLARE
  t_old_rec             MTL_MATERIAL_TRANSACTIONS%rowtype ;
  t_new_rec             MTL_MATERIAL_TRANSACTIONS%rowtype ;
  lv_return_message     VARCHAR2(2000);
  lv_return_code        VARCHAR2(100) ;
  le_error              EXCEPTION     ;
  lv_action             VARCHAR2(20)  ;

  /* Bug 5413264. Added by Lakshmi Gopalsami
   | Removed the reference to org_organization_definitions
   | Removed cursor Fetch_Book_Id_Cur
   */

  v_gl_set_of_bks_id  gl_sets_of_books.set_of_books_id%TYPE;



  /*
  || Here initialising the pr_new record type in the inline procedure
  ||
  */
  /* Bug 5413264. Added by Lakshmi Gopalsami */
  l_func_curr_det jai_plsql_cache_pkg.func_curr_details;
  v_currency_code    gl_sets_of_books.currency_code%type;

  PROCEDURE populate_new IS
  BEGIN

    t_new_rec.TRANSACTION_ID                           := :new.TRANSACTION_ID                                ;
    t_new_rec.LAST_UPDATE_DATE                         := :new.LAST_UPDATE_DATE                              ;
    t_new_rec.LAST_UPDATED_BY                          := :new.LAST_UPDATED_BY                               ;
    t_new_rec.CREATION_DATE                            := :new.CREATION_DATE                                 ;
    t_new_rec.CREATED_BY                               := :new.CREATED_BY                                    ;
    t_new_rec.LAST_UPDATE_LOGIN                        := :new.LAST_UPDATE_LOGIN                             ;
    t_new_rec.REQUEST_ID                               := :new.REQUEST_ID                                    ;
    t_new_rec.PROGRAM_APPLICATION_ID                   := :new.PROGRAM_APPLICATION_ID                        ;
    t_new_rec.PROGRAM_ID                               := :new.PROGRAM_ID                                    ;
    t_new_rec.PROGRAM_UPDATE_DATE                      := :new.PROGRAM_UPDATE_DATE                           ;
    t_new_rec.INVENTORY_ITEM_ID                        := :new.INVENTORY_ITEM_ID                             ;
    t_new_rec.REVISION                                 := :new.REVISION                                      ;
    t_new_rec.ORGANIZATION_ID                          := :new.ORGANIZATION_ID                               ;
    t_new_rec.SUBINVENTORY_CODE                        := :new.SUBINVENTORY_CODE                             ;
    t_new_rec.LOCATOR_ID                               := :new.LOCATOR_ID                                    ;
    t_new_rec.TRANSACTION_TYPE_ID                      := :new.TRANSACTION_TYPE_ID                           ;
    t_new_rec.TRANSACTION_ACTION_ID                    := :new.TRANSACTION_ACTION_ID                         ;
    t_new_rec.TRANSACTION_SOURCE_TYPE_ID               := :new.TRANSACTION_SOURCE_TYPE_ID                    ;
    t_new_rec.TRANSACTION_SOURCE_ID                    := :new.TRANSACTION_SOURCE_ID                         ;
    t_new_rec.TRANSACTION_SOURCE_NAME                  := :new.TRANSACTION_SOURCE_NAME                       ;
    t_new_rec.TRANSACTION_QUANTITY                     := :new.TRANSACTION_QUANTITY                          ;
    t_new_rec.TRANSACTION_UOM                          := :new.TRANSACTION_UOM                               ;
    t_new_rec.PRIMARY_QUANTITY                         := :new.PRIMARY_QUANTITY                              ;
    t_new_rec.TRANSACTION_DATE                         := :new.TRANSACTION_DATE                              ;
    t_new_rec.VARIANCE_AMOUNT                          := :new.VARIANCE_AMOUNT                               ;
    t_new_rec.ACCT_PERIOD_ID                           := :new.ACCT_PERIOD_ID                                ;
    t_new_rec.TRANSACTION_REFERENCE                    := :new.TRANSACTION_REFERENCE                         ;
    t_new_rec.REASON_ID                                := :new.REASON_ID                                     ;
    t_new_rec.DISTRIBUTION_ACCOUNT_ID                  := :new.DISTRIBUTION_ACCOUNT_ID                       ;
    t_new_rec.ENCUMBRANCE_ACCOUNT                      := :new.ENCUMBRANCE_ACCOUNT                           ;
    t_new_rec.ENCUMBRANCE_AMOUNT                       := :new.ENCUMBRANCE_AMOUNT                            ;
    t_new_rec.COST_UPDATE_ID                           := :new.COST_UPDATE_ID                                ;
    t_new_rec.COSTED_FLAG                              := :new.COSTED_FLAG                                   ;
    t_new_rec.INVOICED_FLAG                            := :new.INVOICED_FLAG                                 ;
    t_new_rec.ACTUAL_COST                              := :new.ACTUAL_COST                                   ;
    t_new_rec.TRANSACTION_COST                         := :new.TRANSACTION_COST                              ;
    t_new_rec.PRIOR_COST                               := :new.PRIOR_COST                                    ;
    t_new_rec.NEW_COST                                 := :new.NEW_COST                                      ;
    t_new_rec.CURRENCY_CODE                            := :new.CURRENCY_CODE                                 ;
    t_new_rec.CURRENCY_CONVERSION_RATE                 := :new.CURRENCY_CONVERSION_RATE                      ;
    t_new_rec.CURRENCY_CONVERSION_TYPE                 := :new.CURRENCY_CONVERSION_TYPE                      ;
    t_new_rec.CURRENCY_CONVERSION_DATE                 := :new.CURRENCY_CONVERSION_DATE                      ;
    t_new_rec.USSGL_TRANSACTION_CODE                   := :new.USSGL_TRANSACTION_CODE                        ;
    t_new_rec.QUANTITY_ADJUSTED                        := :new.QUANTITY_ADJUSTED                             ;
    t_new_rec.EMPLOYEE_CODE                            := :new.EMPLOYEE_CODE                                 ;
    t_new_rec.DEPARTMENT_ID                            := :new.DEPARTMENT_ID                                 ;
    t_new_rec.OPERATION_SEQ_NUM                        := :new.OPERATION_SEQ_NUM                             ;
    t_new_rec.MASTER_SCHEDULE_UPDATE_CODE              := :new.MASTER_SCHEDULE_UPDATE_CODE                   ;
    t_new_rec.RECEIVING_DOCUMENT                       := :new.RECEIVING_DOCUMENT                            ;
    t_new_rec.PICKING_LINE_ID                          := :new.PICKING_LINE_ID                               ;
    t_new_rec.TRX_SOURCE_LINE_ID                       := :new.TRX_SOURCE_LINE_ID                            ;
    t_new_rec.TRX_SOURCE_DELIVERY_ID                   := :new.TRX_SOURCE_DELIVERY_ID                        ;
    t_new_rec.REPETITIVE_LINE_ID                       := :new.REPETITIVE_LINE_ID                            ;
    t_new_rec.PHYSICAL_ADJUSTMENT_ID                   := :new.PHYSICAL_ADJUSTMENT_ID                        ;
    t_new_rec.CYCLE_COUNT_ID                           := :new.CYCLE_COUNT_ID                                ;
    t_new_rec.RMA_LINE_ID                              := :new.RMA_LINE_ID                                   ;
    t_new_rec.TRANSFER_TRANSACTION_ID                  := :new.TRANSFER_TRANSACTION_ID                       ;
    t_new_rec.TRANSACTION_SET_ID                       := :new.TRANSACTION_SET_ID                            ;
    t_new_rec.RCV_TRANSACTION_ID                       := :new.RCV_TRANSACTION_ID                            ;
    t_new_rec.MOVE_TRANSACTION_ID                      := :new.MOVE_TRANSACTION_ID                           ;
    t_new_rec.COMPLETION_TRANSACTION_ID                := :new.COMPLETION_TRANSACTION_ID                     ;
    t_new_rec.SOURCE_CODE                              := :new.SOURCE_CODE                                   ;
    t_new_rec.SOURCE_LINE_ID                           := :new.SOURCE_LINE_ID                                ;
    t_new_rec.VENDOR_LOT_NUMBER                        := :new.VENDOR_LOT_NUMBER                             ;
    t_new_rec.TRANSFER_ORGANIZATION_ID                 := :new.TRANSFER_ORGANIZATION_ID                      ;
    t_new_rec.TRANSFER_SUBINVENTORY                    := :new.TRANSFER_SUBINVENTORY                         ;
    t_new_rec.TRANSFER_LOCATOR_ID                      := :new.TRANSFER_LOCATOR_ID                           ;
    t_new_rec.SHIPMENT_NUMBER                          := :new.SHIPMENT_NUMBER                               ;
    t_new_rec.TRANSFER_COST                            := :new.TRANSFER_COST                                 ;
    t_new_rec.TRANSPORTATION_DIST_ACCOUNT              := :new.TRANSPORTATION_DIST_ACCOUNT                   ;
    t_new_rec.TRANSPORTATION_COST                      := :new.TRANSPORTATION_COST                           ;
    t_new_rec.TRANSFER_COST_DIST_ACCOUNT               := :new.TRANSFER_COST_DIST_ACCOUNT                    ;
    t_new_rec.WAYBILL_AIRBILL                          := :new.WAYBILL_AIRBILL                               ;
    t_new_rec.FREIGHT_CODE                             := :new.FREIGHT_CODE                                  ;
    t_new_rec.NUMBER_OF_CONTAINERS                     := :new.NUMBER_OF_CONTAINERS                          ;
    t_new_rec.VALUE_CHANGE                             := :new.VALUE_CHANGE                                  ;
    t_new_rec.PERCENTAGE_CHANGE                        := :new.PERCENTAGE_CHANGE                             ;
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
    t_new_rec.MOVEMENT_ID                              := :new.MOVEMENT_ID                                   ;
    t_new_rec.TRANSACTION_GROUP_ID                     := :new.TRANSACTION_GROUP_ID                          ;
    t_new_rec.TASK_ID                                  := :new.TASK_ID                                       ;
    t_new_rec.TO_TASK_ID                               := :new.TO_TASK_ID                                    ;
    t_new_rec.PROJECT_ID                               := :new.PROJECT_ID                                    ;
    t_new_rec.TO_PROJECT_ID                            := :new.TO_PROJECT_ID                                 ;
    t_new_rec.SOURCE_PROJECT_ID                        := :new.SOURCE_PROJECT_ID                             ;
    t_new_rec.PA_EXPENDITURE_ORG_ID                    := :new.PA_EXPENDITURE_ORG_ID                         ;
    t_new_rec.SOURCE_TASK_ID                           := :new.SOURCE_TASK_ID                                ;
    t_new_rec.EXPENDITURE_TYPE                         := :new.EXPENDITURE_TYPE                              ;
    t_new_rec.ERROR_CODE                               := :new.ERROR_CODE                                    ;
    t_new_rec.ERROR_EXPLANATION                        := :new.ERROR_EXPLANATION                             ;
    t_new_rec.PRIOR_COSTED_QUANTITY                    := :new.PRIOR_COSTED_QUANTITY                         ;
    t_new_rec.FINAL_COMPLETION_FLAG                    := :new.FINAL_COMPLETION_FLAG                         ;
    t_new_rec.PM_COST_COLLECTED                        := :new.PM_COST_COLLECTED                             ;
    t_new_rec.PM_COST_COLLECTOR_GROUP_ID               := :new.PM_COST_COLLECTOR_GROUP_ID                    ;
    t_new_rec.SHIPMENT_COSTED                          := :new.SHIPMENT_COSTED                               ;
    t_new_rec.TRANSFER_PERCENTAGE                      := :new.TRANSFER_PERCENTAGE                           ;
    t_new_rec.MATERIAL_ACCOUNT                         := :new.MATERIAL_ACCOUNT                              ;
    t_new_rec.MATERIAL_OVERHEAD_ACCOUNT                := :new.MATERIAL_OVERHEAD_ACCOUNT                     ;
    t_new_rec.RESOURCE_ACCOUNT                         := :new.RESOURCE_ACCOUNT                              ;
    t_new_rec.OUTSIDE_PROCESSING_ACCOUNT               := :new.OUTSIDE_PROCESSING_ACCOUNT                    ;
    t_new_rec.OVERHEAD_ACCOUNT                         := :new.OVERHEAD_ACCOUNT                              ;
    t_new_rec.COST_GROUP_ID                            := :new.COST_GROUP_ID                                 ;
    t_new_rec.TRANSFER_COST_GROUP_ID                   := :new.TRANSFER_COST_GROUP_ID                        ;
    t_new_rec.FLOW_SCHEDULE                            := :new.FLOW_SCHEDULE                                 ;
    t_new_rec.TRANSFER_PRIOR_COSTED_QUANTITY           := :new.TRANSFER_PRIOR_COSTED_QUANTITY                ;
    t_new_rec.SHORTAGE_PROCESS_CODE                    := :new.SHORTAGE_PROCESS_CODE                         ;
    t_new_rec.QA_COLLECTION_ID                         := :new.QA_COLLECTION_ID                              ;
    t_new_rec.OVERCOMPLETION_TRANSACTION_QTY           := :new.OVERCOMPLETION_TRANSACTION_QTY                ;
    t_new_rec.OVERCOMPLETION_PRIMARY_QTY               := :new.OVERCOMPLETION_PRIMARY_QTY                    ;
    t_new_rec.OVERCOMPLETION_TRANSACTION_ID            := :new.OVERCOMPLETION_TRANSACTION_ID                 ;
    t_new_rec.MVT_STAT_STATUS                          := :new.MVT_STAT_STATUS                               ;
    t_new_rec.COMMON_BOM_SEQ_ID                        := :new.COMMON_BOM_SEQ_ID                             ;
    t_new_rec.COMMON_ROUTING_SEQ_ID                    := :new.COMMON_ROUTING_SEQ_ID                         ;
    t_new_rec.ORG_COST_GROUP_ID                        := :new.ORG_COST_GROUP_ID                             ;
    t_new_rec.COST_TYPE_ID                             := :new.COST_TYPE_ID                                  ;
    t_new_rec.PERIODIC_PRIMARY_QUANTITY                := :new.PERIODIC_PRIMARY_QUANTITY                     ;
    t_new_rec.MOVE_ORDER_LINE_ID                       := :new.MOVE_ORDER_LINE_ID                            ;
    t_new_rec.TASK_GROUP_ID                            := :new.TASK_GROUP_ID                                 ;
    t_new_rec.PICK_SLIP_NUMBER                         := :new.PICK_SLIP_NUMBER                              ;
    t_new_rec.LPN_ID                                   := :new.LPN_ID                                        ;
    t_new_rec.TRANSFER_LPN_ID                          := :new.TRANSFER_LPN_ID                               ;
    t_new_rec.PICK_STRATEGY_ID                         := :new.PICK_STRATEGY_ID                              ;
    t_new_rec.PICK_RULE_ID                             := :new.PICK_RULE_ID                                  ;
    t_new_rec.PUT_AWAY_STRATEGY_ID                     := :new.PUT_AWAY_STRATEGY_ID                          ;
    t_new_rec.PUT_AWAY_RULE_ID                         := :new.PUT_AWAY_RULE_ID                              ;
    t_new_rec.CONTENT_LPN_ID                           := :new.CONTENT_LPN_ID                                ;
    t_new_rec.PICK_SLIP_DATE                           := :new.PICK_SLIP_DATE                                ;
    t_new_rec.COST_CATEGORY_ID                         := :new.COST_CATEGORY_ID                              ;
    t_new_rec.ORGANIZATION_TYPE                        := :new.ORGANIZATION_TYPE                             ;
    t_new_rec.TRANSFER_ORGANIZATION_TYPE               := :new.TRANSFER_ORGANIZATION_TYPE                    ;
    t_new_rec.OWNING_ORGANIZATION_ID                   := :new.OWNING_ORGANIZATION_ID                        ;
    t_new_rec.OWNING_TP_TYPE                           := :new.OWNING_TP_TYPE                                ;
    t_new_rec.XFR_OWNING_ORGANIZATION_ID               := :new.XFR_OWNING_ORGANIZATION_ID                    ;
    t_new_rec.TRANSFER_OWNING_TP_TYPE                  := :new.TRANSFER_OWNING_TP_TYPE                       ;
    t_new_rec.PLANNING_ORGANIZATION_ID                 := :new.PLANNING_ORGANIZATION_ID                      ;
    t_new_rec.PLANNING_TP_TYPE                         := :new.PLANNING_TP_TYPE                              ;
    t_new_rec.XFR_PLANNING_ORGANIZATION_ID             := :new.XFR_PLANNING_ORGANIZATION_ID                  ;
    t_new_rec.TRANSFER_PLANNING_TP_TYPE                := :new.TRANSFER_PLANNING_TP_TYPE                     ;
    t_new_rec.SECONDARY_UOM_CODE                       := :new.SECONDARY_UOM_CODE                            ;
    t_new_rec.SECONDARY_TRANSACTION_QUANTITY           := :new.SECONDARY_TRANSACTION_QUANTITY                ;
    t_new_rec.SHIP_TO_LOCATION_ID                      := :new.SHIP_TO_LOCATION_ID                           ;
    t_new_rec.TRANSACTION_MODE                         := :new.TRANSACTION_MODE                              ;
    t_new_rec.TRANSACTION_BATCH_ID                     := :new.TRANSACTION_BATCH_ID                          ;
    t_new_rec.TRANSACTION_BATCH_SEQ                    := :new.TRANSACTION_BATCH_SEQ                         ;
    t_new_rec.INTRANSIT_ACCOUNT                        := :new.INTRANSIT_ACCOUNT                             ;
    t_new_rec.FOB_POINT                                := :new.FOB_POINT                                     ;
    t_new_rec.PARENT_TRANSACTION_ID                    := :new.PARENT_TRANSACTION_ID                         ;
    t_new_rec.LOGICAL_TRX_TYPE_CODE                    := :new.LOGICAL_TRX_TYPE_CODE                         ;
    t_new_rec.TRX_FLOW_HEADER_ID                       := :new.TRX_FLOW_HEADER_ID                            ;
    t_new_rec.LOGICAL_TRANSACTIONS_CREATED             := :new.LOGICAL_TRANSACTIONS_CREATED                  ;
    t_new_rec.LOGICAL_TRANSACTION                      := :new.LOGICAL_TRANSACTION                           ;
    t_new_rec.INTERCOMPANY_COST                        := :new.INTERCOMPANY_COST                             ;
    t_new_rec.INTERCOMPANY_PRICING_OPTION              := :new.INTERCOMPANY_PRICING_OPTION                   ;
    t_new_rec.RESERVATION_ID                           := :new.RESERVATION_ID                                ;
    t_new_rec.INTERCOMPANY_CURRENCY_CODE               := :new.INTERCOMPANY_CURRENCY_CODE                    ;
    t_new_rec.ORIGINAL_TRANSACTION_TEMP_ID             := :new.ORIGINAL_TRANSACTION_TEMP_ID                  ;
    t_new_rec.TRANSFER_PRICE                           := :new.TRANSFER_PRICE                                ;
    t_new_rec.EXPENSE_ACCOUNT_ID                       := :new.EXPENSE_ACCOUNT_ID                            ;
    t_new_rec.COGS_RECOGNITION_PERCENT                 := :new.COGS_RECOGNITION_PERCENT                      ;
    t_new_rec.SO_ISSUE_ACCOUNT_TYPE                    := :new.SO_ISSUE_ACCOUNT_TYPE                         ;
    t_new_rec.OPM_COSTED_FLAG                          := :new.OPM_COSTED_FLAG                               ;
  END populate_new ;

  PROCEDURE populate_old IS
  BEGIN
    t_old_rec.TRANSACTION_ID                           := :old.TRANSACTION_ID                                ;
    t_old_rec.LAST_UPDATE_DATE                         := :old.LAST_UPDATE_DATE                              ;
    t_old_rec.LAST_UPDATED_BY                          := :old.LAST_UPDATED_BY                               ;
    t_old_rec.CREATION_DATE                            := :old.CREATION_DATE                                 ;
    t_old_rec.CREATED_BY                               := :old.CREATED_BY                                    ;
    t_old_rec.LAST_UPDATE_LOGIN                        := :old.LAST_UPDATE_LOGIN                             ;
    t_old_rec.REQUEST_ID                               := :old.REQUEST_ID                                    ;
    t_old_rec.PROGRAM_APPLICATION_ID                   := :old.PROGRAM_APPLICATION_ID                        ;
    t_old_rec.PROGRAM_ID                               := :old.PROGRAM_ID                                    ;
    t_old_rec.PROGRAM_UPDATE_DATE                      := :old.PROGRAM_UPDATE_DATE                           ;
    t_old_rec.INVENTORY_ITEM_ID                        := :old.INVENTORY_ITEM_ID                             ;
    t_old_rec.REVISION                                 := :old.REVISION                                      ;
    t_old_rec.ORGANIZATION_ID                          := :old.ORGANIZATION_ID                               ;
    t_old_rec.SUBINVENTORY_CODE                        := :old.SUBINVENTORY_CODE                             ;
    t_old_rec.LOCATOR_ID                               := :old.LOCATOR_ID                                    ;
    t_old_rec.TRANSACTION_TYPE_ID                      := :old.TRANSACTION_TYPE_ID                           ;
    t_old_rec.TRANSACTION_ACTION_ID                    := :old.TRANSACTION_ACTION_ID                         ;
    t_old_rec.TRANSACTION_SOURCE_TYPE_ID               := :old.TRANSACTION_SOURCE_TYPE_ID                    ;
    t_old_rec.TRANSACTION_SOURCE_ID                    := :old.TRANSACTION_SOURCE_ID                         ;
    t_old_rec.TRANSACTION_SOURCE_NAME                  := :old.TRANSACTION_SOURCE_NAME                       ;
    t_old_rec.TRANSACTION_QUANTITY                     := :old.TRANSACTION_QUANTITY                          ;
    t_old_rec.TRANSACTION_UOM                          := :old.TRANSACTION_UOM                               ;
    t_old_rec.PRIMARY_QUANTITY                         := :old.PRIMARY_QUANTITY                              ;
    t_old_rec.TRANSACTION_DATE                         := :old.TRANSACTION_DATE                              ;
    t_old_rec.VARIANCE_AMOUNT                          := :old.VARIANCE_AMOUNT                               ;
    t_old_rec.ACCT_PERIOD_ID                           := :old.ACCT_PERIOD_ID                                ;
    t_old_rec.TRANSACTION_REFERENCE                    := :old.TRANSACTION_REFERENCE                         ;
    t_old_rec.REASON_ID                                := :old.REASON_ID                                     ;
    t_old_rec.DISTRIBUTION_ACCOUNT_ID                  := :old.DISTRIBUTION_ACCOUNT_ID                       ;
    t_old_rec.ENCUMBRANCE_ACCOUNT                      := :old.ENCUMBRANCE_ACCOUNT                           ;
    t_old_rec.ENCUMBRANCE_AMOUNT                       := :old.ENCUMBRANCE_AMOUNT                            ;
    t_old_rec.COST_UPDATE_ID                           := :old.COST_UPDATE_ID                                ;
    t_old_rec.COSTED_FLAG                              := :old.COSTED_FLAG                                   ;
    t_old_rec.INVOICED_FLAG                            := :old.INVOICED_FLAG                                 ;
    t_old_rec.ACTUAL_COST                              := :old.ACTUAL_COST                                   ;
    t_old_rec.TRANSACTION_COST                         := :old.TRANSACTION_COST                              ;
    t_old_rec.PRIOR_COST                               := :old.PRIOR_COST                                    ;
    t_old_rec.NEW_COST                                 := :old.NEW_COST                                      ;
    t_old_rec.CURRENCY_CODE                            := :old.CURRENCY_CODE                                 ;
    t_old_rec.CURRENCY_CONVERSION_RATE                 := :old.CURRENCY_CONVERSION_RATE                      ;
    t_old_rec.CURRENCY_CONVERSION_TYPE                 := :old.CURRENCY_CONVERSION_TYPE                      ;
    t_old_rec.CURRENCY_CONVERSION_DATE                 := :old.CURRENCY_CONVERSION_DATE                      ;
    t_old_rec.USSGL_TRANSACTION_CODE                   := :old.USSGL_TRANSACTION_CODE                        ;
    t_old_rec.QUANTITY_ADJUSTED                        := :old.QUANTITY_ADJUSTED                             ;
    t_old_rec.EMPLOYEE_CODE                            := :old.EMPLOYEE_CODE                                 ;
    t_old_rec.DEPARTMENT_ID                            := :old.DEPARTMENT_ID                                 ;
    t_old_rec.OPERATION_SEQ_NUM                        := :old.OPERATION_SEQ_NUM                             ;
    t_old_rec.MASTER_SCHEDULE_UPDATE_CODE              := :old.MASTER_SCHEDULE_UPDATE_CODE                   ;
    t_old_rec.RECEIVING_DOCUMENT                       := :old.RECEIVING_DOCUMENT                            ;
    t_old_rec.PICKING_LINE_ID                          := :old.PICKING_LINE_ID                               ;
    t_old_rec.TRX_SOURCE_LINE_ID                       := :old.TRX_SOURCE_LINE_ID                            ;
    t_old_rec.TRX_SOURCE_DELIVERY_ID                   := :old.TRX_SOURCE_DELIVERY_ID                        ;
    t_old_rec.REPETITIVE_LINE_ID                       := :old.REPETITIVE_LINE_ID                            ;
    t_old_rec.PHYSICAL_ADJUSTMENT_ID                   := :old.PHYSICAL_ADJUSTMENT_ID                        ;
    t_old_rec.CYCLE_COUNT_ID                           := :old.CYCLE_COUNT_ID                                ;
    t_old_rec.RMA_LINE_ID                              := :old.RMA_LINE_ID                                   ;
    t_old_rec.TRANSFER_TRANSACTION_ID                  := :old.TRANSFER_TRANSACTION_ID                       ;
    t_old_rec.TRANSACTION_SET_ID                       := :old.TRANSACTION_SET_ID                            ;
    t_old_rec.RCV_TRANSACTION_ID                       := :old.RCV_TRANSACTION_ID                            ;
    t_old_rec.MOVE_TRANSACTION_ID                      := :old.MOVE_TRANSACTION_ID                           ;
    t_old_rec.COMPLETION_TRANSACTION_ID                := :old.COMPLETION_TRANSACTION_ID                     ;
    t_old_rec.SOURCE_CODE                              := :old.SOURCE_CODE                                   ;
    t_old_rec.SOURCE_LINE_ID                           := :old.SOURCE_LINE_ID                                ;
    t_old_rec.VENDOR_LOT_NUMBER                        := :old.VENDOR_LOT_NUMBER                             ;
    t_old_rec.TRANSFER_ORGANIZATION_ID                 := :old.TRANSFER_ORGANIZATION_ID                      ;
    t_old_rec.TRANSFER_SUBINVENTORY                    := :old.TRANSFER_SUBINVENTORY                         ;
    t_old_rec.TRANSFER_LOCATOR_ID                      := :old.TRANSFER_LOCATOR_ID                           ;
    t_old_rec.SHIPMENT_NUMBER                          := :old.SHIPMENT_NUMBER                               ;
    t_old_rec.TRANSFER_COST                            := :old.TRANSFER_COST                                 ;
    t_old_rec.TRANSPORTATION_DIST_ACCOUNT              := :old.TRANSPORTATION_DIST_ACCOUNT                   ;
    t_old_rec.TRANSPORTATION_COST                      := :old.TRANSPORTATION_COST                           ;
    t_old_rec.TRANSFER_COST_DIST_ACCOUNT               := :old.TRANSFER_COST_DIST_ACCOUNT                    ;
    t_old_rec.WAYBILL_AIRBILL                          := :old.WAYBILL_AIRBILL                               ;
    t_old_rec.FREIGHT_CODE                             := :old.FREIGHT_CODE                                  ;
    t_old_rec.NUMBER_OF_CONTAINERS                     := :old.NUMBER_OF_CONTAINERS                          ;
    t_old_rec.VALUE_CHANGE                             := :old.VALUE_CHANGE                                  ;
    t_old_rec.PERCENTAGE_CHANGE                        := :old.PERCENTAGE_CHANGE                             ;
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
    t_old_rec.MOVEMENT_ID                              := :old.MOVEMENT_ID                                   ;
    t_old_rec.TRANSACTION_GROUP_ID                     := :old.TRANSACTION_GROUP_ID                          ;
    t_old_rec.TASK_ID                                  := :old.TASK_ID                                       ;
    t_old_rec.TO_TASK_ID                               := :old.TO_TASK_ID                                    ;
    t_old_rec.PROJECT_ID                               := :old.PROJECT_ID                                    ;
    t_old_rec.TO_PROJECT_ID                            := :old.TO_PROJECT_ID                                 ;
    t_old_rec.SOURCE_PROJECT_ID                        := :old.SOURCE_PROJECT_ID                             ;
    t_old_rec.PA_EXPENDITURE_ORG_ID                    := :old.PA_EXPENDITURE_ORG_ID                         ;
    t_old_rec.SOURCE_TASK_ID                           := :old.SOURCE_TASK_ID                                ;
    t_old_rec.EXPENDITURE_TYPE                         := :old.EXPENDITURE_TYPE                              ;
    t_old_rec.ERROR_CODE                               := :old.ERROR_CODE                                    ;
    t_old_rec.ERROR_EXPLANATION                        := :old.ERROR_EXPLANATION                             ;
    t_old_rec.PRIOR_COSTED_QUANTITY                    := :old.PRIOR_COSTED_QUANTITY                         ;
    t_old_rec.FINAL_COMPLETION_FLAG                    := :old.FINAL_COMPLETION_FLAG                         ;
    t_old_rec.PM_COST_COLLECTED                        := :old.PM_COST_COLLECTED                             ;
    t_old_rec.PM_COST_COLLECTOR_GROUP_ID               := :old.PM_COST_COLLECTOR_GROUP_ID                    ;
    t_old_rec.SHIPMENT_COSTED                          := :old.SHIPMENT_COSTED                               ;
    t_old_rec.TRANSFER_PERCENTAGE                      := :old.TRANSFER_PERCENTAGE                           ;
    t_old_rec.MATERIAL_ACCOUNT                         := :old.MATERIAL_ACCOUNT                              ;
    t_old_rec.MATERIAL_OVERHEAD_ACCOUNT                := :old.MATERIAL_OVERHEAD_ACCOUNT                     ;
    t_old_rec.RESOURCE_ACCOUNT                         := :old.RESOURCE_ACCOUNT                              ;
    t_old_rec.OUTSIDE_PROCESSING_ACCOUNT               := :old.OUTSIDE_PROCESSING_ACCOUNT                    ;
    t_old_rec.OVERHEAD_ACCOUNT                         := :old.OVERHEAD_ACCOUNT                              ;
    t_old_rec.COST_GROUP_ID                            := :old.COST_GROUP_ID                                 ;
    t_old_rec.TRANSFER_COST_GROUP_ID                   := :old.TRANSFER_COST_GROUP_ID                        ;
    t_old_rec.FLOW_SCHEDULE                            := :old.FLOW_SCHEDULE                                 ;
    t_old_rec.TRANSFER_PRIOR_COSTED_QUANTITY           := :old.TRANSFER_PRIOR_COSTED_QUANTITY                ;
    t_old_rec.SHORTAGE_PROCESS_CODE                    := :old.SHORTAGE_PROCESS_CODE                         ;
    t_old_rec.QA_COLLECTION_ID                         := :old.QA_COLLECTION_ID                              ;
    t_old_rec.OVERCOMPLETION_TRANSACTION_QTY           := :old.OVERCOMPLETION_TRANSACTION_QTY                ;
    t_old_rec.OVERCOMPLETION_PRIMARY_QTY               := :old.OVERCOMPLETION_PRIMARY_QTY                    ;
    t_old_rec.OVERCOMPLETION_TRANSACTION_ID            := :old.OVERCOMPLETION_TRANSACTION_ID                 ;
    t_old_rec.MVT_STAT_STATUS                          := :old.MVT_STAT_STATUS                               ;
    t_old_rec.COMMON_BOM_SEQ_ID                        := :old.COMMON_BOM_SEQ_ID                             ;
    t_old_rec.COMMON_ROUTING_SEQ_ID                    := :old.COMMON_ROUTING_SEQ_ID                         ;
    t_old_rec.ORG_COST_GROUP_ID                        := :old.ORG_COST_GROUP_ID                             ;
    t_old_rec.COST_TYPE_ID                             := :old.COST_TYPE_ID                                  ;
    t_old_rec.PERIODIC_PRIMARY_QUANTITY                := :old.PERIODIC_PRIMARY_QUANTITY                     ;
    t_old_rec.MOVE_ORDER_LINE_ID                       := :old.MOVE_ORDER_LINE_ID                            ;
    t_old_rec.TASK_GROUP_ID                            := :old.TASK_GROUP_ID                                 ;
    t_old_rec.PICK_SLIP_NUMBER                         := :old.PICK_SLIP_NUMBER                              ;
    t_old_rec.LPN_ID                                   := :old.LPN_ID                                        ;
    t_old_rec.TRANSFER_LPN_ID                          := :old.TRANSFER_LPN_ID                               ;
    t_old_rec.PICK_STRATEGY_ID                         := :old.PICK_STRATEGY_ID                              ;
    t_old_rec.PICK_RULE_ID                             := :old.PICK_RULE_ID                                  ;
    t_old_rec.PUT_AWAY_STRATEGY_ID                     := :old.PUT_AWAY_STRATEGY_ID                          ;
    t_old_rec.PUT_AWAY_RULE_ID                         := :old.PUT_AWAY_RULE_ID                              ;
    t_old_rec.CONTENT_LPN_ID                           := :old.CONTENT_LPN_ID                                ;
    t_old_rec.PICK_SLIP_DATE                           := :old.PICK_SLIP_DATE                                ;
    t_old_rec.COST_CATEGORY_ID                         := :old.COST_CATEGORY_ID                              ;
    t_old_rec.ORGANIZATION_TYPE                        := :old.ORGANIZATION_TYPE                             ;
    t_old_rec.TRANSFER_ORGANIZATION_TYPE               := :old.TRANSFER_ORGANIZATION_TYPE                    ;
    t_old_rec.OWNING_ORGANIZATION_ID                   := :old.OWNING_ORGANIZATION_ID                        ;
    t_old_rec.OWNING_TP_TYPE                           := :old.OWNING_TP_TYPE                                ;
    t_old_rec.XFR_OWNING_ORGANIZATION_ID               := :old.XFR_OWNING_ORGANIZATION_ID                    ;
    t_old_rec.TRANSFER_OWNING_TP_TYPE                  := :old.TRANSFER_OWNING_TP_TYPE                       ;
    t_old_rec.PLANNING_ORGANIZATION_ID                 := :old.PLANNING_ORGANIZATION_ID                      ;
    t_old_rec.PLANNING_TP_TYPE                         := :old.PLANNING_TP_TYPE                              ;
    t_old_rec.XFR_PLANNING_ORGANIZATION_ID             := :old.XFR_PLANNING_ORGANIZATION_ID                  ;
    t_old_rec.TRANSFER_PLANNING_TP_TYPE                := :old.TRANSFER_PLANNING_TP_TYPE                     ;
    t_old_rec.SECONDARY_UOM_CODE                       := :old.SECONDARY_UOM_CODE                            ;
    t_old_rec.SECONDARY_TRANSACTION_QUANTITY           := :old.SECONDARY_TRANSACTION_QUANTITY                ;
    t_old_rec.SHIP_TO_LOCATION_ID                      := :old.SHIP_TO_LOCATION_ID                           ;
    t_old_rec.TRANSACTION_MODE                         := :old.TRANSACTION_MODE                              ;
    t_old_rec.TRANSACTION_BATCH_ID                     := :old.TRANSACTION_BATCH_ID                          ;
    t_old_rec.TRANSACTION_BATCH_SEQ                    := :old.TRANSACTION_BATCH_SEQ                         ;
    t_old_rec.INTRANSIT_ACCOUNT                        := :old.INTRANSIT_ACCOUNT                             ;
    t_old_rec.FOB_POINT                                := :old.FOB_POINT                                     ;
    t_old_rec.PARENT_TRANSACTION_ID                    := :old.PARENT_TRANSACTION_ID                         ;
    t_old_rec.LOGICAL_TRX_TYPE_CODE                    := :old.LOGICAL_TRX_TYPE_CODE                         ;
    t_old_rec.TRX_FLOW_HEADER_ID                       := :old.TRX_FLOW_HEADER_ID                            ;
    t_old_rec.LOGICAL_TRANSACTIONS_CREATED             := :old.LOGICAL_TRANSACTIONS_CREATED                  ;
    t_old_rec.LOGICAL_TRANSACTION                      := :old.LOGICAL_TRANSACTION                           ;
    t_old_rec.INTERCOMPANY_COST                        := :old.INTERCOMPANY_COST                             ;
    t_old_rec.INTERCOMPANY_PRICING_OPTION              := :old.INTERCOMPANY_PRICING_OPTION                   ;
    t_old_rec.RESERVATION_ID                           := :old.RESERVATION_ID                                ;
    t_old_rec.INTERCOMPANY_CURRENCY_CODE               := :old.INTERCOMPANY_CURRENCY_CODE                    ;
    t_old_rec.ORIGINAL_TRANSACTION_TEMP_ID             := :old.ORIGINAL_TRANSACTION_TEMP_ID                  ;
    t_old_rec.TRANSFER_PRICE                           := :old.TRANSFER_PRICE                                ;
    t_old_rec.EXPENSE_ACCOUNT_ID                       := :old.EXPENSE_ACCOUNT_ID                            ;
    t_old_rec.COGS_RECOGNITION_PERCENT                 := :old.COGS_RECOGNITION_PERCENT                      ;
    t_old_rec.SO_ISSUE_ACCOUNT_TYPE                    := :old.SO_ISSUE_ACCOUNT_TYPE                         ;
    t_old_rec.OPM_COSTED_FLAG                          := :old.OPM_COSTED_FLAG                               ;
  END populate_old ;

BEGIN

  /*
  || assign the new values depending upon the triggering event.
  */
  IF UPDATING OR INSERTING THEN
     populate_new;
  END IF;


  /*
  || assign the old values depending upon the triggering event.
  */

  IF UPDATING OR DELETING THEN
     populate_old;
  END IF;

  /* Bug 5413264. Added by Lakshmi Gopalsami
     Removed cursor Fetch_Book_Id_Cur
     fetching from org_organization_definitions
     and implemented the same using cache.
  */

  l_func_curr_det := jai_plsql_cache_pkg.return_sob_curr
                            (p_org_id  => :new.organization_id );

  v_gl_set_of_bks_id := l_func_curr_det.ledger_id;
  v_currency_code    := l_func_curr_det.currency_code;

  IF v_currency_code <> 'INR' THEN
    RETURN ;
  END IF;

  /* Bug 5413264. Added by Lakshmi Gopalsami
   | commented the following call as the check
   | can be done using the variable retrieved using caching logic.
   | make a call to the INR check package.

  IF jai_cmn_utils_pkg.check_jai_exists(P_CALLING_OBJECT => 'JAI_INV_MMT_ARIUD_T1', p_set_of_books_id => v_gl_set_of_bks_id ) = FALSE THEN
       RETURN;
  END IF;
  */

  /*
  || check for action in trigger and pass the same to the procedure
  */
  IF    INSERTING THEN
        lv_action := jai_constants.inserting ;
  ELSIF UPDATING THEN
        lv_action := jai_constants.updating ;
  ELSIF DELETING THEN
        lv_action := jai_constants.deleting ;
  END IF ;

  IF INSERTING THEN

      JAI_INV_MMT_TRIGGER_PKG.ARI_T1 (
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
                                      EXCEPTION_TEXT  => 'Encountered the error in trigger JAI_INV_MMT_ARIUD_T1' || substr(sqlerrm,1,1900)
                                    );

END JAI_INV_MMT_ARIUD_T1 ;
/

