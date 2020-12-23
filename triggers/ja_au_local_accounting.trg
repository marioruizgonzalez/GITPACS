CREATE OR REPLACE TRIGGER GG_ADMIN."JA_AU_LOCAL_ACCOUNTING"
after update of costed_flag on "MTL_MATERIAL_TRANSACTIONS"
for each row
   WHEN (old.transaction_type_id in (50,54,61,62) and
                   old.transaction_source_type_id = 8 and
                   new.costed_flag is null and
                   ((sys_context('JG','JGZZ_COUNTRY_CODE') in ('AU'))
       OR (to_char(new.ORGANIZATION_ID) <> nvl(sys_context('JG','JGZZ_ORG_ID'),'XX')))) Declare
l_country_code VARCHAR2(5);
BEGIN

   IF (to_char(:new.organization_id) <> nvl(sys_context('JG','JGZZ_ORG_ID'),'XX')) THEN

     l_country_code := FND_PROFILE.value('JGZZ_COUNTRY_CODE');

     JG_CONTEXT.name_value('JGZZ_COUNTRY_CODE',l_country_code);

     JG_CONTEXT.name_value('JGZZ_ORG_ID',to_char(:new.organization_id));

   END IF;

   IF (sys_context('JG','JGZZ_COUNTRY_CODE') = 'AU') THEN

     ja_au_costproc_pkg.ja_au_local_account(:old.organization_id,
                                          :old.subinventory_code,
                                          :old.inventory_item_id,
                                          :old.transaction_id);
   END IF;

END;
/

