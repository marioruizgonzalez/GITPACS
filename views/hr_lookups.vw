CREATE OR REPLACE FORCE VIEW GG_ADMIN.HR_LOOKUPS AS
SELECT DECODE (SUBSTR (FLV.LOOKUP_TYPE, 1, 3), 'HXT', 808, 800),
           FLV.LOOKUP_TYPE,
           FLV.LOOKUP_CODE,
           FLV.MEANING,
           FLV.LAST_UPDATE_DATE,
           FLV.LAST_UPDATED_BY,
           FLV.ENABLED_FLAG,
           FLV.START_DATE_ACTIVE,
           FLV.END_DATE_ACTIVE,
           FLV.DESCRIPTION,
           FLV.LAST_UPDATE_LOGIN,
           FLV.CREATED_BY,
           FLV.CREATION_DATE
      FROM FND_LOOKUP_VALUES FLV
     WHERE     FLV.LANGUAGE = USERENV ('LANG')
           AND FLV.VIEW_APPLICATION_ID = 3
           AND flv.security_group_id =
               (  SELECT MAX (lt.security_group_id)
                    FROM fnd_lookup_types lt
                   WHERE     lt.view_application_id = 3
                         AND lt.security_group_id IN
                                 (0,
                                  TO_NUMBER (
                                      DECODE (
                                          SUBSTRB (USERENV ('CLIENT_INFO'),
                                                   55,
                                                   1),
                                          ' ', '0',
                                          NULL, '0',
                                          SUBSTRB (USERENV ('CLIENT_INFO'),
                                                   55,
                                                   10))))
                         AND lt.lookup_type = flv.lookup_type
                GROUP BY lt.lookup_type)
           AND DECODE (
                   FLV.TAG,
                   NULL, 'Y',
                   DECODE (
                       SUBSTR (FLV.TAG, 1, 1),
                       '+', DECODE (
                                SIGN (
                                    INSTR (FLV.TAG,
                                           HR_API.GET_LEGISLATION_CONTEXT)),
                                1, 'Y',
                                'N'),
                       '-', DECODE (
                                SIGN (
                                    INSTR (FLV.TAG,
                                           HR_API.GET_LEGISLATION_CONTEXT)),
                                1, 'N',
                                'Y'),
                       'Y')) =
               'Y';

