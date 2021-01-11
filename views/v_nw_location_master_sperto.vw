CREATE OR REPLACE FORCE EDITIONABLE VIEW "GG_ADMIN"."V_NW_LOCATION_MASTER_SPERTO" ("HZ_LOCATION_ID", "FA_LOCATION_ID", "HR_LOCATION_ID", "ENABLED_FLAG", "SITE_CODE", "DESCRIPTION", "ADDRESS_1", "ADDRESS_2", "ADDRESS_3", "CITY", "REGION", "STATE", "POSTAL_CODE", "MOD_DATE", "CREATION_DATE", "INSTALL_DESCRIPTION", "ANTENNA_TYPE", "SITE_LOCATION_CODE") AS
  SELECT HZLO.location_id HZ_LOCATION_ID,
          FLOC.location_id FA_LOCATION_ID,
          HRLA.location_id HR_LOCATION_ID,
          FLOC.enabled_flag ENABLED_FLAG,
          FLOC.segment1 SITE_CODE,
          HZLO.description DESCRIPTION,
          HZLO.address2 ADDRESS_1,
          HZLO.address3 ADDRESS_2,
          HZLO.address4 ADDRESS_3,
          HZLO.city CITY,
          --HRLA.region_1 REGION, -- CAMBIO DE REGION A ESTADO
          HZLO.state REGION,
          HZLO.state STATE,
          HRLA.postal_code POSTAL_CODE,
          FLOC.last_update_date MOD_DATE,
          HZLO.creation_date CREATION_DATE,
          FLOC.attribute2 INSTALL_DESCRIPTION,
          FLOC.attribute3 ANTENNA_TYPE,
          FLOC.attribute6 SITE_LOCATION_CODE
     FROM AR.hz_locations@of_iplnk HZLO,
          FA.fa_locations@of_iplnk FLOC,
          APPS.hr_locations_all@of_iplnk HRLA
    WHERE     FLOC.attribute1 IN
                 ('SITIO 3G',
                  'SITIO',
                  'RFN',
                  'ENLACE FO',
                  'IBS',
                  'RF REPEATER',
                  'NOC',
                  'MW REPEATER',
                  'SITIO LTE',
                  'FSO',
                  'SITIO ANALOGICO',
                  'MOVILES',
                  'MSO',
                  'TRAMO FO',
                  'WIFI')
          AND HZLO.address1 = FLOC.segment1
          AND HRLA.description(+) = HZLO.description
          AND HRLA.location_code(+) LIKE '%' || FLOC.segment1;
