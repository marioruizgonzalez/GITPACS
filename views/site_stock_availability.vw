CREATE OR REPLACE FORCE VIEW GG_ADMIN.SITE_STOCK_AVAILABILITY AS
SELECT DISTINCT
          ssa1.INSTANCE_ID,
          ssa1.INVENTORY_ID,
          ssa1.MASTER_ORGANIZATION_ID,
          ssa1.SERIAL_NUMBER,
          ssa1.FA_NUMBER,
          NVL (ssa2.CURRENT_UNITS, ssa1.QUANTITY) QUANTITY,
          ssa1.UOM,
          ssa1.LOCATION_TYPE_CODE,
          ssa1.LOCATION_ID,
          ssa1.ORGANIZATION_ID,
          ssa1.SUBINVENTORY_NAME,
          ssa1.LOCATOR_ID,
          ssa1.PROJECT_ID,
          ssa1.PROJECT_TASK_ID,
          ssa1.INSTALL_DATE,
          ssa1.RETURN_BY_DATE,
          ssa1.ACTUAL_RETURN_DATE,
          ssa1.ADD_DATE,
          ssa1.MOD_DATE,
          ssa1.INSTALL_LOCATION_ID,
          CASE WHEN ssa2.ASSET_ID IS NOT NULL THEN 1 ELSE 0 END CAPEX,
          ssa2.ASSET_CATEGORY,
          ssa2.ASSET_ID,
          ssa2.ASSET_NUMBER,
          ssa2.CURRENT_UNITS,
          ssa2.ASSET_TYPE,
          ssa2.TAG_NUMBER,
          ssa2.ASSET_CATEGORY_ID,
          ssa2.SERIAL_NUMBER_FA,
          ssa2.LAST_UPDATE_DATE,
          ssa2.CREATION_DATE,
          ssa1.INV_MATERIAL_TRANSACTION_ID,
          ssa1.TRANSACTION_ID,
      ssa1.OC
     FROM gg_admin.mv_site_stock_avail_eib ssa1
        LEFT JOIN
      (SELECT ssatmp.*, nlm.hz_location_id
        FROM gg_admin.mv_site_stock_avail_fa ssatmp
                LEFT JOIN gg_admin.NW_LOCATIONMASTER nlm
                    ON ssatmp.FA_LOCATION_ID = nlm.fa_location_id
      ) ssa2
             ON  ssa1.INSTANCE_ID = ssa2.INSTANCE_ID
                AND NVL(ssa1.serial_number,ssa1.LOCATION_ID) = NVL(ssa2.serial_number_fa,ssa2.hz_location_id)
        AND NVL(ssa1.fa_number,1) = NVL(ssa2.tag_number,1)
          AND ssa2.update_status!= 'RETIRED';
comment on table GG_ADMIN.SITE_STOCK_AVAILABILITY is 'snapshot table for snapshot GG_ADMIN.SITE_STOCK_AVAILABILITY';

