CREATE OR REPLACE FORCE VIEW GG_ADMIN.HR_ORGANIZATION_UNITS AS
SELECT hao.organization_id,
           hao.ROWID,
           hao.business_group_id,
           hao.cost_allocation_keyflex_id,
           hao.location_id,
           hao.soft_coding_keyflex_id,
           hao.date_from,
           haotl.name,
           hao.comments,
           hao.date_to,
           hao.internal_external_flag,
           hao.internal_address_line,
           hao.TYPE,
           hao.request_id,
           hao.program_application_id,
           hao.program_id,
           hao.program_update_date,
           hao.attribute_category,
           hao.attribute1,
           hao.attribute2,
           hao.attribute3,
           hao.attribute4,
           hao.attribute5,
           hao.attribute6,
           hao.attribute7,
           hao.attribute8,
           hao.attribute9,
           hao.attribute10,
           hao.attribute11,
           hao.attribute12,
           hao.attribute13,
           hao.attribute14,
           hao.attribute15,
           hao.attribute16,
           hao.attribute17,
           hao.attribute18,
           hao.attribute19,
           hao.attribute20,
           hao.last_update_date,
           hao.last_updated_by,
           hao.last_update_login,
           hao.created_by,
           hao.creation_date,
           hao.object_version_number,
           hao.attribute21,
           hao.attribute22,
           hao.attribute23,
           hao.attribute24,
           hao.attribute25,
           hao.attribute26,
           hao.attribute27,
           hao.attribute28,
           hao.attribute29,
           hao.attribute30
      FROM HR_ALL_ORGANIZATION_UNITS HAO, HR_ALL_ORGANIZATION_UNITS_TL HAOTL
     WHERE     DECODE (
                   HR_SECURITY.VIEW_ALL,
                   'Y', 'TRUE',
                   HR_SECURITY.SHOW_RECORD ('HR_ALL_ORGANIZATION_UNITS',
                                            HAOTL.ORGANIZATION_ID)) =
               'TRUE'
           AND DECODE (hr_general.get_xbg_profile,
                       'Y', hao.business_group_id,
                       hr_general.get_business_group_id) =
               hao.business_group_id
           AND HAO.ORGANIZATION_ID = HAOTL.ORGANIZATION_ID
           AND HAOTL.LANGUAGE = USERENV ('LANG');

