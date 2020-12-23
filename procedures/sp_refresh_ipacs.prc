CREATE OR REPLACE PROCEDURE GG_ADMIN.sp_refresh_ipacs

 AS

BEGIN


  --1||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
  BEGIN
    /*dbms_mview.refresh@of_iplnk('MV_TRANS_TYPE_MASTER',ATOMIC_REFRESH=> FALSE, PARALLELISM=>4);*/
    dbms_mview.refresh('TRANSACTION_TYPE_MASTER');
  exception
    when others then
      raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
    
  end;
  --2||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||     
  BEGIN
    /*dbms_mview.refresh@of_iplnk('MV_ORDER_TYPE_MASTER',ATOMIC_REFRESH=> FALSE, PARALLELISM=>4);*/
    dbms_mview.refresh('ORDER_TYPE_MASTER');
  exception
    when others then
      raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
    
  end;
  --3|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| 
  BEGIN
    /*dbms_mview.refresh@of_iplnk('MV_NW_LOCATION_MASTER',ATOMIC_REFRESH=> FALSE, PARALLELISM=>4);*/
    dbms_mview.refresh('NW_LOCATIONMASTER');
  exception
    when others then
      raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
    
  end;

  --4||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||     
  BEGIN
    /*dbms_mview.refresh@of_iplnk('MV_PROJECT_PLAN', ATOMIC_REFRESH=> FALSE, PARALLELISM=>4);*/
    dbms_mview.refresh('PROJECT_PLAN_SYNC');
  exception
    when others then
      raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
    
  end;
  --5||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||     
  BEGIN
    /*dbms_mview.refresh@of_iplnk('MV_PROJECT_PLAN_TASK', ATOMIC_REFRESH=> FALSE, PARALLELISM=>4);*/
    dbms_mview.refresh('PROJECT_PLAN_TASK');
  exception
    when others then
      raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
    
  end;

  --||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||      

END;
/

