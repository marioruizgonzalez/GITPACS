create or replace force view gg_admin.v_nw_location_master as
select a.HZ_LOCATION_ID            TASK_ID,
       bb.project_id               PROJECT_ID,
       a.DESCRIPTION               TASK_NAME,
       a.SITE_CODE                 CARRYING_OUT_ORGANIZATION_ID,
       a.FA_LOCATION_ID            TASK_NUMBER,
       a.DESCRIPTION,
       a.REGION,
       to_char(greatest(nvl(a.CREATION_DATE, sysdate - 1000), nvl(a.MOD_DATE, sysdate - 1000)),
               'yyyymmddhh24miss') LAST_CHANGE_DATE
from gg_admin.NW_LOCATIONMASTER a
         left outer join
     (select b.PROJECT_ID, c.TASK_ID, d.SITE_CODE
      from gg_admin.PROJECT_PLAN_SYNC b,
           gg_admin.PROJECT_PLAN_SYNC_DETAIL c,
           gg_admin.PROJECT_SITE_PLAN_SYNC_REL d
      where b.PROJECT_ID = c.PROJECT_ID
        and c.TASK_ID = d.TASK_ID) bb
     on a.SITE_CODE = to_char(bb.SITE_CODE);

