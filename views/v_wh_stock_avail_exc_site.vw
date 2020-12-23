CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_WH_STOCK_AVAIL_EXC_SITE AS
SELECT OH.ORGANIZATION_ID ORG_ID,
          IL.segment1 LOCATOR,
          MSI.segment1 SKU_ID,
          OH.PRIMARY_TRANSACTION_QUANTITY QTY,
          OH.CREATION_DATE ADD_DATE,
          OH.LAST_UPDATE_DATE MOD_DATE,
          OH.SUBINVENTORY_CODE SUBINVENTORY,
          OH.TRANSACTION_UOM_CODE UOM,
          MSN.SERIAL_NUMBER SERIAL_NO,
          OH.LOT_NUMBER
     FROM APPS.MTL_ONHAND_QUANTITIES_DETAIL OH,                      ---28 000
          APPS.MTL_ITEM_LOCATIONS IL,
          APPS.MTL_SYSTEM_ITEMS_B MSI,
          APPS.MTL_SERIAL_NUMBERS MSN
    WHERE                                           --oh.organization_id = 215
              --AND oh.inventory_item_id = 2169421
              oh.organization_id(+) = msi.organization_id
          AND oh.inventory_item_id(+) = msi.inventory_item_id
          AND oh.organization_id = il.organization_id(+)
          AND oh.locator_id = il.inventory_location_id(+)
          AND oh.inventory_item_id = msn.inventory_item_id(+)
          AND oh.last_update_date = msn.last_update_date(+)
          AND msn.creation_date >=
                 apps.fnd_date.canonical_to_date ('2019/06/01 00:00:00')
;

