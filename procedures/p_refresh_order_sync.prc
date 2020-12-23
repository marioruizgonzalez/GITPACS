create or replace procedure gg_admin.P_REFRESH_ORDER_SYNC is
  --Mario Ruiz TechMahindra
begin
  dbms_mview.refresh('MV_ORDER_SYNC_DETAIL_TR_ID',
                     ATOMIC_REFRESH              => FALSE,
                     PARALLELISM                 => 2);
  dbms_mview.refresh('MV_ORDER_SYNC_TR_ID',
                     ATOMIC_REFRESH       => FALSE,
                     PARALLELISM          => 2);
exception
  when others then
    raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
end P_REFRESH_ORDER_SYNC;
/

