CREATE OR REPLACE FORCE VIEW GG_ADMIN.V_RUEBA_SPERTO AS
SELECT DISTINCT
          HOU.ORGANIZATION_ID ORG_ID,
          MP.ORGANIZATION_CODE ORG_SHORT_NAME,
          HOU.NAME ORG_NAME,
          HLAT.LOCATION_CODE LOCATION_,
          HLA.ADDRESS_LINE_1 LOCATION_ADDRESS1,
          HLA.ADDRESS_LINE_2 LOCATION_ADDRESS2,
          HLA.ADDRESS_LINE_3 LOCATION_ADDRESS3,
          HLA.POSTAL_CODE LOCATION_POSTAL_CODE,
          HLA.REGION_1 LOCATION_CITY,
          HLA.REGION_2 LOCATION_STATE,
          HLA.COUNTRY LOCATION_COUNTRY,
          HLA.TELEPHONE_NUMBER_1 LOCATION_TELEPHONE1,
          HLA.TELEPHONE_NUMBER_2 LOCATION_TELEPHONE2,
          HLA.TELEPHONE_NUMBER_3 LOCATION_TELEPHONE3,
          (SELECT HAOU_LE.NAME
             FROM apps.HR_ALL_ORGANIZATION_UNITS@OFNX_SPERTO HAOU_LE
            WHERE HAOU_LE.ORGANIZATION_ID =
                     (SELECT DECODE (
                                HOI_2.ORG_INFORMATION_CONTEXT,
                                'Accounting Information', TO_NUMBER (
                                                             HOI_2.ORG_INFORMATION2),
                                NULL)
                        FROM apps.HR_ORGANIZATION_UNITS@OFNX_SPERTO HOU1,
                             apps.HR_ORGANIZATION_INFORMATION@OFNX_SPERTO HOI_1,
                             apps.HR_ORGANIZATION_INFORMATION@OFNX_SPERTO HOI_2,
                             apps.GL_LEDGERS@OFNX_SPERTO LGR_
                       WHERE     HOU1.ORGANIZATION_ID = HOI_1.ORGANIZATION_ID
                             AND HOU1.ORGANIZATION_ID = HOI_2.ORGANIZATION_ID
                             AND HOI_1.ORG_INFORMATION1 = 'INV'
                             AND HOI_1.ORG_INFORMATION2 = 'Y'
                             AND (HOI_1.ORG_INFORMATION_CONTEXT || '') =
                                    'CLASS'
                             AND (HOI_2.ORG_INFORMATION_CONTEXT || '') =
                                    'Accounting Information'
                             AND TO_NUMBER (
                                    DECODE (
                                       RTRIM (
                                          TRANSLATE (HOI_2.ORG_INFORMATION1,
                                                     '0123456789',
                                                     ' ')),
                                       NULL, HOI_2.ORG_INFORMATION1,
                                       -99999)) = LGR_.LEDGER_ID
                             AND LGR_.OBJECT_TYPE_CODE = 'L'
                             AND NVL (LGR_.COMPLETE_FLAG, 'Y') = 'Y'
                             AND HOU1.ORGANIZATION_ID = HOU.ORGANIZATION_ID))
             LEGAL_ENTITY,
          HOU.DATE_FROM FROM_DATE,
          HOU.DATE_TO TO_DATE_,
          HOU.CREATION_DATE ADD_DATE,
          HOU.LAST_UPDATE_DATE MOD_DATE,
          HOU.TYPE TYPE_,
          TPO.CLASIFICATION1 CLASIFICATION1,
          TPO.CLASIFICATION2 CLASIFICATION2,
          TPO.CLASIFICATION3 CLASIFICATION3,
          TPO.CLASIFICATION4 CLASIFICATION4,
          TPO.CLASIFICATION5 CLASIFICATION5
     FROM apps.HR_ALL_ORGANIZATION_UNITS@OFNX_SPERTO HOU,
          apps.HR_ORGANIZATION_INFORMATION@OFNX_SPERTO HOI1,
          apps.HR_ORGANIZATION_INFORMATION@OFNX_SPERTO HOI2,
          apps.MTL_PARAMETERS@OFNX_SPERTO MP,
          apps.GL_LEDGERS@OFNX_SPERTO LGR,
          apps.HR_LOCATIONS_ALL@OFNX_SPERTO HLA,
          apps.HR_LOCATIONS_ALL_TL@OFNX_SPERTO HLAT,
          (  SELECT I.ORGANIZATION_ID AS ID_ORG,
                    MAX (
                       DECODE (HL.DESCRIPTION,
                               'Auditable Unit for use by AMW', HL.DESCRIPTION,
                               NULL))
                       AS CLASIFICATION1,
                    MAX (
                       DECODE (HL.DESCRIPTION,
                               'GRE / Legal Entity', HL.DESCRIPTION,
                               NULL))
                       AS CLASIFICATION2,
                    MAX (
                       DECODE (HL.DESCRIPTION,
                               'Inventory Organization', HL.DESCRIPTION,
                               NULL))
                       AS CLASIFICATION3,
                    MAX (
                       DECODE (HL.DESCRIPTION,
                               'Operating Unit', HL.DESCRIPTION,
                               NULL))
                       AS CLASIFICATION4,
                    MAX (
                       DECODE (HL.DESCRIPTION,
                               'Auditable Unit for use by AMW', NULL,
                               'GRE / Legal Entity', NULL,
                               'Inventory Organization', NULL,
                               'Operating Unit', NULL,
                               HL.DESCRIPTION))
                       AS CLASIFICATION5
               FROM apps.HR_ORGANIZATION_INFORMATION@OFNX_SPERTO I,
                    xxn.XXN_HR_LOOKUPS@OFNX_SPERTO HL,               --apps.HR_LOOKUPS HL,
                    apps.HR_ALL_ORGANIZATION_UNITS@OFNX_SPERTO HAOU
              WHERE     1 = 1
                    AND I.ORG_INFORMATION1 = HL.LOOKUP_CODE(+)
                    AND HL.LOOKUP_TYPE = 'ORG_CLASS'
                    AND HAOU.ORGANIZATION_ID = I.ORGANIZATION_ID
           GROUP BY I.ORGANIZATION_ID
           ORDER BY I.ORGANIZATION_ID) TPO
    WHERE     1 = 1
          AND HOU.ORGANIZATION_ID = HOI1.ORGANIZATION_ID
          AND HOU.ORGANIZATION_ID = HOI2.ORGANIZATION_ID
          AND HOU.ORGANIZATION_ID = MP.ORGANIZATION_ID(+)
          AND HOI1.ORG_INFORMATION1 = 'INV'
          AND HOI1.ORG_INFORMATION2 = 'Y'
          AND (HOI1.ORG_INFORMATION_CONTEXT || '') = 'CLASS'
          AND (HOI2.ORG_INFORMATION_CONTEXT || '') = 'Accounting Information'
          AND TO_NUMBER (
                 DECODE (
                    RTRIM (
                       TRANSLATE (HOI2.ORG_INFORMATION1, '0123456789', ' ')),
                    NULL, HOI2.ORG_INFORMATION1,
                    -99999)) = LGR.LEDGER_ID
          AND LGR.OBJECT_TYPE_CODE = 'L'
          AND NVL (LGR.COMPLETE_FLAG, 'Y') = 'Y'
          AND HOU.LOCATION_ID = HLA.LOCATION_ID
          AND HOU.LOCATION_ID = HLAT.LOCATION_ID
          --AND NVL (HLA.BUSINESS_GROUP_ID, NVL (HR_GENERAL.GET_BUSINESS_GROUP_ID, -99)) =
          --            NVL (HR_GENERAL.GET_BUSINESS_GROUP_ID, NVL (HLA.BUSINESS_GROUP_ID, -99))?
          AND HLA.LOCATION_ID = HLAT.LOCATION_ID
          AND HLAT.LANGUAGE = 'ESA'                         --USERENV ('LANG')
          AND HOU.ORGANIZATION_ID = TPO.ID_ORG
;

