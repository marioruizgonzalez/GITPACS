CREATE OR REPLACE FORCE VIEW GG_ADMIN.HR_LOCATIONS AS
SELECT loc.location_id,
           lot.location_code,
           'HR',
           loc.business_group_id + 0 business_group_id,
           lot.description,
           loc.ship_to_location_id,
           loc.ship_to_site_flag,
           loc.receiving_site_flag,
           loc.bill_to_site_flag,
           loc.in_organization_flag,
           loc.office_site_flag,
           loc.designated_receiver_id,
           loc.inventory_organization_id,
           loc.tax_name,
           loc.inactive_date,
           loc.style,
           loc.address_line_1,
           loc.address_line_2,
           loc.address_line_3,
           loc.town_or_city,
           loc.country,
           loc.postal_code,
           loc.region_1,
           loc.region_2,
           loc.region_3,
           loc.telephone_number_1,
           loc.telephone_number_2,
           loc.telephone_number_3,
           loc.loc_information13,
           loc.loc_information14,
           loc.loc_information15,
           loc.loc_information16,
           loc.loc_information17,
           loc.loc_information18,
           loc.loc_information19,
           loc.loc_information20,
           loc.attribute_category,
           loc.attribute1,
           loc.attribute2,
           loc.attribute3,
           loc.attribute4,
           loc.attribute5,
           loc.attribute6,
           loc.attribute7,
           loc.attribute8,
           loc.attribute9,
           loc.attribute10,
           loc.attribute11,
           loc.attribute12,
           loc.attribute13,
           loc.attribute14,
           loc.attribute15,
           loc.attribute16,
           loc.attribute17,
           loc.attribute18,
           loc.attribute19,
           loc.attribute20,
           loc.global_attribute_category,
           loc.global_attribute1,
           loc.global_attribute2,
           loc.global_attribute3,
           loc.global_attribute4,
           loc.global_attribute5,
           loc.global_attribute6,
           loc.global_attribute7,
           loc.global_attribute8,
           loc.global_attribute9,
           loc.global_attribute10,
           loc.global_attribute11,
           loc.global_attribute12,
           loc.global_attribute13,
           loc.global_attribute14,
           loc.global_attribute15,
           loc.global_attribute16,
           loc.global_attribute17,
           loc.global_attribute18,
           loc.global_attribute19,
           loc.global_attribute20,
           loc.last_update_date,
           loc.last_updated_by,
           loc.last_update_login,
           loc.created_by,
           loc.creation_date,
           loc.entered_by,
           loc.tp_header_id,
           loc.ece_tp_location_code,
           loc.object_version_number,
           loc.legal_address_flag,
           loc.timezone_code
      FROM hr_locations_all loc, hr_locations_all_tl lot
     WHERE     NVL (loc.business_group_id,
                    NVL (hr_general.get_business_group_id, -99)) =
               NVL (hr_general.get_business_group_id,
                    NVL (loc.business_group_id, -99))
           AND loc.location_id = lot.location_id
           AND lot.language = USERENV ('LANG');

