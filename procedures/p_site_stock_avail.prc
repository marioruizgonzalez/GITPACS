create or replace procedure gg_admin.P_SITE_STOCK_AVAIL is
begin
	
  begin
    dbms_mview.refresh('MV_SITE_STOCK_AVAIL_EIB');
  exception
    when others then
      raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);

  end;

  begin
    dbms_mview.refresh('MV_SITE_STOCK_AVAIL_FA');
  exception
    when others then
      raise_application_error(-20001,sqlcode || sqlerrm ||
                           dbms_utility.format_error_backtrace);
  end;

end P_SITE_STOCK_AVAIL;
/

