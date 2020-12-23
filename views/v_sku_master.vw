CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SKU_MASTER AS
SELECT erp_inventory_id inventory_item_id, sku,
          description_sku description, description_long, provider,
          a.lifecycle_ lifecycle, product_type, primary_uom, add_date,
          opex_flag, capex_flag, a.categoria_articulo item_category,
          a.categoria_activo asset_category, 'true' serialize, mod_date,
          TO_CHAR (GREATEST (NVL (add_date, SYSDATE - 1000),
                             NVL (mod_date, SYSDATE - 1000)
                            ),
                   'yyyymmddhh24miss'
                  ) last_change_date
     FROM gg_admin.sku_master a;

