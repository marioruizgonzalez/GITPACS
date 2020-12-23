create or replace force view gg_admin.v_nw_location_master_1 as
select a.HZ_LOCATION_ID, a.FA_LOCATION_ID, a.HR_LOCATION_ID, a.SITE_CODE, a.DESCRIPTION, a.REGION,bb.PROJECT_ID
from gg_admin.NW_LOCATIONMASTER a
left outer join
(select b.PROJECT_ID,c.TASK_ID,d.SITE_CODE
from gg_admin.PROJECT_PLAN_SYNC b, gg_admin.PROJECT_PLAN_SYNC_DETAIL c,gg_admin.PROJECT_SITE_PLAN_SYNC_REL d
where b.PROJECT_ID=c.PROJECT_ID
and c.TASK_ID=d.TASK_ID) bb
on a.SITE_CODE=to_char(bb.SITE_CODE);

