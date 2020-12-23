create or replace force view gg_admin.v_inventory_controll as
select
       c.SHIP_TO_LOCATION_ID org,
        a.SUBINVENTORY_SHORT_CODE sub_inventory,
       a.org_id warehouse,
       substr(a.SKU,0,1) inventory_type,
       a.SKU inventory,
       d.DESCRIPTION_SKU description,
       d.DESCRIPTION_SKU technical_description,
       a.UOM_ UOM,
       1 quantity,
       a.LOCATION,
       a.Locator_id hall,
       a.LOCATOR_SHORT_NAME wh_level,
       'N' pair,
       c.HEADER_ID po_number,
       b.serial_number,
       b.LOT_NUMBER,
       d.BANNER brand,
       d.PRODUCT_TYPE oem_part_no,
       d.MODEL model,
       d.PROVIDER oem_name,
       a.PROJECT_NUMBER project,
       case when (sysdate-nvl(a.ADD_DATE,sysdate))>30 then 'Lento Movimiento' else 'No Lento Movimiento' end Ageing,
       round((sysdate-a.ADD_DATE)) days_without_ageing,
       c.ORGANIZATION_ID organization_code,
       a.ORG_DES site_name,
       decode(d.CAPEX_FLAG,'Y','CAPEX','OPEX') capex_opex,
       c.ADD_DATE CREATION_DATE
from gg_admin.SKU_INSTANCE a,gg_admin.SKU_INSTANCE_DETAIL b,
     gg_admin.ORDER_SYNC c,gg_admin.SKU_MASTER d
where a.ERP_INVENTORY_ID=b.TRANSACTON_ID
    and to_char(a.TRANSACTION_SOURCE_ID)=to_char(c.HEADER_ID)
and a.SKU=d.SKU(+);

