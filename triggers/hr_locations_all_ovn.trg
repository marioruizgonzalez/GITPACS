CREATE OR REPLACE TRIGGER GG_ADMIN."HR_LOCATIONS_ALL_OVN"
before insert or update on hr_locations_all for each row
begin
  if hr_general.g_data_migrator_mode <> 'Y' then
    if not hr_loc_shd.return_api_dml_status then
      if inserting then
        :NEW.object_version_number := 1;
      else
        :NEW.object_version_number := :OLD.object_version_number + 1;
      end if;
    end if;
  end if;
end hr_locations_all_ovn;
/

