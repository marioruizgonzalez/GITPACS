CREATE OR REPLACE FORCE VIEW GG_ADMIN.WSH_CARRIER_CONTACTS_V AS
SELECT hr.party_id,
           hr.object_id,
           hr.subject_id,
           hp.person_pre_name_adjunct,
           hp.person_first_name,
           hp.person_last_name,
           hp.status
      FROM hz_parties hp, hz_relationships hr
     WHERE     hr.subject_id = hp.party_id
           AND subject_table_name = 'HZ_PARTIES'
           AND object_table_name = 'HZ_PARTIES'
           AND directional_flag = 'F'
           AND NOT EXISTS
                   (SELECT 'exists'
                      FROM hz_org_contacts org
                     WHERE     org.party_relationship_id = hr.relationship_id
                           AND org.party_site_id IS NOT NULL);

