CREATE OR REPLACE TRIGGER GG_ADMIN."JAI_OE_OHA_ARIUD_T1"
AFTER INSERT OR UPDATE OR DELETE ON "OE_ORDER_HEADERS_ALL"
for each row
DECLARE

  v_operating_id        NUMBER                  :=:NEW.ORG_ID;
  l_debug_level         CONSTANT NUMBER := oe_debug_pub.g_debug_level;
  v_gl_set_of_bks_id    gl_sets_of_books.set_of_books_id%type;
  r_new                 OE_ORDER_HEADERS_ALL%ROWTYPE  ;
  r_old                 OE_ORDER_HEADERS_ALL%ROWTYPE  ;
  le_error              EXCEPTION                     ;
  lv_action             VARCHAR2(20)                  ;
  lv_object             VARCHAR2(61)                  ;
  lv_process_message    VARCHAR2(4000)                ;
  lv_process_flag       VARCHAR2(2)                   ;


  --Get Set of Books Id.
  CURSOR Fetch_Book_Id_Cur IS
  SELECT Set_Of_Books_Id
  FROM   Org_Organization_Definitions
  WHERE  NVL(Operating_unit,0)  = v_operating_id;



  --Get Currency Code for given set of books.
  CURSOR Sob_Cur IS
  select Currency_code
  from gl_sets_of_books
  where set_of_books_id = v_gl_set_of_bks_id;


  --Store Incoming  values into a record, "r_new".
  PROCEDURE init_new
  IS
  BEGIN

    r_new.header_id             := :new.header_id        ;
    r_new.flow_status_code      := :new.flow_status_code ;
    r_new.ship_from_org_id      := :new.ship_from_org_id ;
    /*Added below code for bug#7277211 */
    r_new.org_id                := :new.org_id;
    r_new.creation_date            := :new.creation_date;
    r_new.sold_to_org_id        := :new.sold_to_org_id;
    --End bug#7277211
  END init_new;

  --Store existing values into a record, "r_old".
  PROCEDURE init_old
  IS
  BEGIN
    r_old.header_id             := :old.header_id        ;
    r_old.flow_status_code      := :old.flow_status_code ;
    r_old.ship_from_org_id      := :old.ship_from_org_id ;

  END init_old;

 BEGIN
   -- Main body  Start.
   IF l_debug_level > 0 THEN
   oe_debug_pub.add(  'Entered Trigger JAI_OE_ARIUD_T1') ;
   END IF;


   --Get id for set of books in a local variable v_gl_set_of_bks_id.

   OPEN  Fetch_Book_Id_Cur ;
   FETCH Fetch_Book_Id_Cur INTO v_gl_set_of_bks_id;
   CLOSE Fetch_Book_Id_Cur;

   --Check if set of book exists

   IF jai_cmn_utils_pkg.check_jai_exists(  p_calling_object => 'JAI_OE_ARIUD_T1',
                                    p_set_of_books_id => v_gl_set_of_bks_id ) = FALSE THEN
    RETURN;

   END IF;
   IF l_debug_level > 0 THEN
   oe_debug_pub.add(  'After jai_cmn_utils_pkg.check_jai_exists') ;
   END IF;


    lv_object := 'JAI_OE_ARIUD_T1' ;
    lv_action := 'INIT_NEW';

  --Set values of local records based on intended action

    if updating or inserting then
    init_new;
    end if;

   IF l_debug_level > 0 THEN
   oe_debug_pub.add(  'After checking for Update or Insert') ;
   END IF;


   lv_action := 'INIT_OLD';

   if updating or deleting then
    init_old;
   end if;


   IF l_debug_level > 0 THEN
   oe_debug_pub.add( 'After Checking for Update or Delete') ;
   END IF;



 --Pass values for further processing

     IF ( :old.flow_status_code IS NULL                                    OR
       :old.flow_status_code  <> jai_constants.order_booked
      )                                                                 AND
     nvl(:new.flow_status_code,'###') = jai_constants.order_booked
    THEN
       IF l_debug_level > 0 THEN
       oe_debug_pub.add( 'Before Passing Values to jai_ar_tcs_rep_pkg.process_transactions') ;
       END IF;
       jai_cmn_utils_pkg.print_log('oeh.log','before call to the tcs_rep_package');
              jai_ar_tcs_rep_pkg.process_transactions   (  p_ooh                => r_new                      ,
                                                p_event              => jai_constants.order_booked ,
                                                p_process_flag       => lv_process_flag            ,
                                                p_process_message    => lv_process_message
                                                  );
       jai_cmn_utils_pkg.print_log('oeh.log','after call to the tcs_rep pkg error is
' || lv_process_message || lv_process_flag);
        IF l_debug_level > 0 THEN
        oe_debug_pub.add( 'After  jai_ar_tcs_rep_pkg.process_transactions'||'p_process_flag'|| lv_process_flag ||'p_process_message'|| lv_process_message) ;
        END IF;
  IF l_debug_level > 0 THEN  oe_debug_pub.add( 'Passed values to jai_ar_tcs_rep_pkg.process_transactions ') ;
   END IF;



    IF lv_process_flag = jai_constants.expected_error    OR
       lv_process_flag = jai_constants.unexpected_error
    THEN
      raise le_error;
    END IF;

    END IF;

    IF l_debug_level > 0 THEN  oe_debug_pub.add( 'Reached end of trigger ') ;
   END IF;


 EXCEPTION
  WHEN le_error THEN

    jai_cmn_utils_pkg.print_log('oeh.log','in the exception' ||
lv_process_message || lv_object || lv_action);
    IF lv_process_flag   = jai_constants.unexpected_error THEN
      lv_process_message := substr (lv_process_message || ' Object=' || lv_object || ' Action=' || lv_action, 1,1999) ;
    END IF;

     fnd_message.set_name ( application => 'JA',
                           name        => 'JAI_ERR_DESC'
                         );

    fnd_message.set_token ( token => 'JAI_ERROR_DESCRIPTION',
                            value => lv_process_message
                           );
     /*
     ||add the message to the ont stack also
     */
     oe_msg_pub.add;
     RAISE fnd_api.g_exc_error;
         IF l_debug_level > 0 THEN  oe_debug_pub.add( 'Added the message to the ont stack ') ;
   END IF;
  WHEN others THEN
     jai_cmn_utils_pkg.print_log('oeh.log','in the exception' ||
     lv_process_message || lv_object || lv_action);


    fnd_message.set_name (  application => 'JA',
                            name        => 'JAI_ERR_DESC'
                         );
    fnd_message.set_token ( token => 'JAI_ERROR_DESCRIPTION',
                            value => 'Exception Occured in ' || ' Object=' || lv_object
                                                             || ' for Action=' || lv_action
                                                             || substr(sqlerrm,1,300)
                          );
    /*
    ||add the message to the ont stack also
    */
    oe_msg_pub.add;
    RAISE fnd_api.g_exc_error;

 END JAI_OE_OHA_ARIUD_T1;
/

