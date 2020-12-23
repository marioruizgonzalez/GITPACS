CREATE OR REPLACE FORCE VIEW GG_ADMIN.ORG_ORGANIZATION_DEFINITIONS AS
SELECT HOU.ORGANIZATION_ID
               ORGANIZATION_ID,
           HOU.BUSINESS_GROUP_ID,
           HOU.DATE_FROM
               USER_DEFINITION_ENABLE_DATE,
           HOU.DATE_TO
               DISABLE_DATE,
           MP.ORGANIZATION_CODE
               ORGANIZATION_CODE,
           HOU.NAME
               ORGANIZATION_NAME,
           LGR.LEDGER_ID
               SET_OF_BOOKS_ID,
           LGR.CHART_OF_ACCOUNTS_ID
               CHART_OF_ACCOUNTS_ID,
           HOI1.ORG_INFORMATION2
               INVENTORY_ENABLED_FLAG,
           DECODE (
               HOI2.ORG_INFORMATION_CONTEXT,
               'Accounting Information', TO_NUMBER (HOI2.ORG_INFORMATION3),
               TO_NUMBER (NULL))
               OPERATING_UNIT,
           DECODE (
               HOI2.ORG_INFORMATION_CONTEXT,
               'Accounting Information', TO_NUMBER (HOI2.ORG_INFORMATION2),
               NULL)
               LEGAL_ENTITY
      FROM HR_ORGANIZATION_UNITS        HOU,
           HR_ORGANIZATION_INFORMATION  HOI1,
           HR_ORGANIZATION_INFORMATION  HOI2,
           MTL_PARAMETERS               MP,
           GL_LEDGERS                   LGR
     WHERE     HOU.ORGANIZATION_ID = HOI1.ORGANIZATION_ID
           AND HOU.ORGANIZATION_ID = HOI2.ORGANIZATION_ID
           AND HOU.ORGANIZATION_ID = MP.ORGANIZATION_ID
           AND HOI1.ORG_INFORMATION1 = 'INV'
           AND HOI1.ORG_INFORMATION2 = 'Y'
           AND (HOI1.ORG_INFORMATION_CONTEXT || '') = 'CLASS'
           AND (HOI2.ORG_INFORMATION_CONTEXT || '') =
               'Accounting Information'
           AND TO_NUMBER (
                   DECODE (
                       RTRIM (
                           TRANSLATE (HOI2.ORG_INFORMATION1,
                                      '0123456789',
                                      ' ')),
                       NULL, HOI2.ORG_INFORMATION1,
                       -99999)) =
               LGR.LEDGER_ID
           AND LGR.OBJECT_TYPE_CODE = 'L'
           AND NVL (LGR.COMPLETE_FLAG, 'Y') = 'Y';

