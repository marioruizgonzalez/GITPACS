CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_SKU_MASTER_SPERTO AS
SELECT MSI.INVENTORY_ITEM_ID ERP_INVENTORY_ID,
          MSI.SEGMENT1 SKU,
          MSI.DESCRIPTION DESCRIPTION_SKU,
          (SELECT MSIT.DESCRIPTION
             FROM apps.MTL_SYSTEM_ITEMS_TL@OFNX_SPERTO MSIT
            WHERE     1 = 1
                  AND MSIT.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MSIT.ORGANIZATION_ID = MSI.ORGANIZATION_ID
                  AND MSIT.LANGUAGE = 'ESA')
             DESCRIPTION_LONG,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'Modelo')
             MODEL,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'Fabricante')
             PROVIDER,
          MSI.INVENTORY_ITEM_STATUS_CODE LIFECYCLE_,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'Tipo de Producto')
             PRODUCT_TYPE,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'Price Tier')
             PRICE_TIER,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'Technology')
             TECHNOLOGY,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'Banner')
             BANNER,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'Internal Memory')
             MEMORY,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'Color')
             COLOR,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'Front Camera')
             FRONT_CAMERA,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'Rear Camera')
             REAR_CAMERA,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'Battery')
             BATTERY,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'Display Size')
             DISPLAY_SIZE,
          MSI.PRIMARY_UOM_CODE PRIMARY_UOM,
          MSI.CREATION_DATE ADD_DATE,
          MSI.LAST_UPDATE_DATE MOD_DATE,
          CASE WHEN MSI.ASSET_CATEGORY_ID IS NULL THEN 'Y' ELSE 'N' END
             OPEX_FLAG,
          CASE WHEN MSI.ASSET_CATEGORY_ID IS NOT NULL THEN 'Y' ELSE 'N' END
             CAPEX_FLAG,
          (SELECT    MCB.SEGMENT1
                  || '.'
                  || CASE
                        WHEN MCB.SEGMENT2 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT2
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT3 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT3
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT4 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT4
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT5 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT5
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT6 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT6
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT7 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT7
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT8 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT8
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT9 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT9
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT10 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT10
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT11 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT11
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT12 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT12
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT13 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT13
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT14 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT14
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT15 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT15
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT16 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT16
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT17 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT17
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT18 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT18
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT19 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT19
                     END
                  || ''
                  || CASE
                        WHEN MCB.SEGMENT20 IS NULL THEN ''
                        ELSE '.' || MCB.SEGMENT20
                     END
             FROM apps.MTL_CATEGORIES_B@OFNX_SPERTO MCB, apps.MTL_ITEM_CATEGORIES@OFNX_SPERTO MTC
            WHERE     1 = 1
                  AND MTC.CATEGORY_SET_ID =
                         (SELECT MCSTL.CATEGORY_SET_ID
                            FROM apps.MTL_CATEGORY_SETS_TL@OFNX_SPERTO MCSTL
                           WHERE     1 = 1
                                 AND MCSTL.CATEGORY_SET_NAME = 'Inventory'
                                 AND MCSTL.LANGUAGE = 'ESA')
                  AND MTC.CATEGORY_ID = MCB.CATEGORY_ID
                  AND MTC.ORGANIZATION_ID = MSI.ORGANIZATION_ID
                  AND MTC.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID)
             CATEGORIA_ARTICULO,
          (SELECT    FCB.SEGMENT1
                  || '-'
                  || CASE
                        WHEN FCB.SEGMENT2 IS NULL THEN ''
                        ELSE '-' || FCB.SEGMENT2
                     END
                  || ''
                  || CASE
                        WHEN FCB.SEGMENT3 IS NULL THEN ''
                        ELSE '-' || FCB.SEGMENT3
                     END
                  || ''
                  || CASE
                        WHEN FCB.SEGMENT4 IS NULL THEN ''
                        ELSE '-' || FCB.SEGMENT4
                     END
                  || ''
                  || CASE
                        WHEN FCB.SEGMENT5 IS NULL THEN ''
                        ELSE '-' || FCB.SEGMENT5
                     END
                  || ''
                  || CASE
                        WHEN FCB.SEGMENT6 IS NULL THEN ''
                        ELSE '-' || FCB.SEGMENT6
                     END
                  || ''
                  || CASE
                        WHEN FCB.SEGMENT7 IS NULL THEN ''
                        ELSE '-' || FCB.SEGMENT7
                     END
             FROM apps.FA_CATEGORIES_B@OFNX_SPERTO FCB
            WHERE 1 = 1 AND CATEGORY_ID = MSI.ASSET_CATEGORY_ID)
             CATEGORIA_ACTIVO,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'MARCA')
             MARCA,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'MODELO')
             MODELO,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'TIPO ELEMENTO')
             TIPO_ELEMENTO,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'ELEMENTO')
             ELEMENTO,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'NUMERO DE PARTE DEL PROVEEDOR')
             NUM_PARTE_PROV,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'VERSION')
             VERSION,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'TECNOLOGIA')
             TECNOLOGIA,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'UOM FRECUENCIA')
             UOM_FRECUENCIA,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'FRECUENCIA')
             FRECUENCIA,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'SUB-BANDA')
             SUB_BANDA,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'UOM POTENCIA')
             UOM_POTENCIA,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'POTENCIA')
             POTENCIA,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'UOM CAPACIDAD')
             UOM_CAPACIDAD,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'CAPACIDAD')
             CAPACIDAD,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'UOM LONGITUD')
             UOM_LONGITUD,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'LONGITUD')
             LONGITUD,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'TASA DE TRANSFERENCIA (MBPS)')
             TASA_TRANSFERENCIA_MBPS,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'TIPO DE FIBRA (SM / MM)')
             TIPO_FIBRA,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'CAPACIDAD TRANSMISION')
             CAPACIDAD_TRANSMISION,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'TRANSCEIVER')
             TRANSCEIVER,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'LONGITUD DE ONDA')
             LONGITUD_ONDA,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'LONGITUD DE ALCANCE')
             LONGITUD_ALCANCE,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'CAPACIDAD DE REDUNDANCIA    ')
             CAPACIDAD_REDUNDANCIA,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'PAG WEB REF TEC DEL PROVEEDOR')
             PAG_WEB_REF_PROV,
          (SELECT DISTINCT MDEV.ELEMENT_VALUE
             FROM apps.MTL_DESCR_ELEMENT_VALUES@OFNX_SPERTO MDEV
            WHERE     1 = 1
                  AND MDEV.INVENTORY_ITEM_ID = MSI.INVENTORY_ITEM_ID
                  AND MDEV.ELEMENT_NAME = 'CALIBRE DEL CABLE')
             CALIBRE_CABLE
     FROM INV.MTL_SYSTEM_ITEMS_B@OFNX_SPERTO MSI
    WHERE     1 = 1
          AND MSI.ORGANIZATION_ID IN (SELECT DISTINCT MASTER_ORGANIZATION_ID
                                        FROM INV.MTL_PARAMETERS@OFNX_SPERTO
                                       WHERE 1 = 1)
          AND msi.ENABLED_FLAG = 'Y';

