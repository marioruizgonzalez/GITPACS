create or replace procedure gg_admin.P_REFRESH_IPACS_24HRS is
begin
  
  --1||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||   
  BEGIN
    /*dbms_mview.refresh@of_iplnk('MV_ORG_MASTER', PARALLELISM=>4);*/
    dbms_mview.refresh('ORG_MASTER');
  exception
    when others then
      raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
    
  end;

   --2||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||   

  BEGIN
    /*dbms_mview.refresh@of_iplnk('MV_ORG_MASTER', PARALLELISM=>4);*/
    dbms_mview.refresh('SKU_MASTER');
  exception
    when others then
      raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
    
  end;
	  --||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||   


end P_REFRESH_IPACS_24HRS;
/

