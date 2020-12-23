CREATE OR REPLACE TRIGGER GG_ADMIN."HR_ALL_ORGANIZATION_UNITS_OVN"
BEFORE INSERT OR UPDATE ON "HR_ALL_ORGANIZATION_UNITS"
FOR EACH ROW
BEGIN
if hr_general.g_data_migrator_mode <> 'Y' then
 IF NOT hr_oru_shd.return_api_dml_status THEN
   IF INSERTING THEN
     :NEW.object_version_number := 1;
   ELSE
     :NEW.object_version_number := :OLD.object_version_number + 1;
   END IF;
 END IF;
end if;
END HR_ALL_ORGANIZATION_UNITS_OVN;
/

