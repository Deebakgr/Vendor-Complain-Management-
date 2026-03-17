CLASS lhc_ComplaintHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION IMPORTING keys REQUEST requested_authorizations FOR ComplaintHeader RESULT result.
    METHODS create FOR MODIFY IMPORTING entities FOR CREATE ComplaintHeader.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE ComplaintHeader.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE ComplaintHeader.
    METHODS read FOR READ IMPORTING keys FOR READ ComplaintHeader RESULT result.
    METHODS lock FOR LOCK IMPORTING keys FOR LOCK ComplaintHeader.
    METHODS rba_Item FOR READ IMPORTING keys_rba FOR READ ComplaintHeader\_Item FULL result_requested RESULT result LINK association_links.
    METHODS cba_Item FOR MODIFY IMPORTING entities_cba FOR CREATE ComplaintHeader\_Item.
    METHODS earlynumbering_create FOR NUMBERING IMPORTING entities FOR CREATE ComplaintHeader.
    METHODS earlynumbering_cba_Item FOR NUMBERING IMPORTING entities FOR CREATE ComplaintHeader\_Item.
    METHODS submitComplaint FOR MODIFY IMPORTING keys FOR ACTION ComplaintHeader~submitComplaint RESULT result.
ENDCLASS.

CLASS lhc_ComplaintHeader IMPLEMENTATION.
  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA: lv_new_id TYPE char10.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>) USING KEY entity.
      IF <entity>-complaint_id IS INITIAL.
        lv_new_id = zcl_vc_util=>get_next_complaint_id( ).
      ELSE.
        lv_new_id = <entity>-complaint_id.
      ENDIF.
      APPEND VALUE #(
        %cid       = <entity>-%cid
        %is_draft  = <entity>-%is_draft
        complaint_id = lv_new_id
      ) TO mapped-complaintheader.
    ENDLOOP.
  ENDMETHOD.

  METHOD create.
    DATA ls_header TYPE zvc_header.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      ls_header-client       = sy-mandt.
      ls_header-complaint_id = <entity>-complaint_id.
      ls_header-vendor_id    = <entity>-vendor_id.
      ls_header-vendor_name  = <entity>-vendor_name.
      ls_header-description  = <entity>-description.

      " Default Status
      ls_header-status = COND #(
        WHEN <entity>-status IS INITIAL THEN 'Open'
        ELSE <entity>-status ).

      " Smart Priority Determination from keywords
      DATA(lv_desc_upper) = to_upper( <entity>-description ).
      IF lv_desc_upper CS 'URGENT' OR lv_desc_upper CS 'CRITICAL'
      OR lv_desc_upper CS 'BROKEN' OR lv_desc_upper CS 'FIRE'.
        ls_header-priority = 'Critical'.
      ELSEIF lv_desc_upper CS 'DELAY' OR lv_desc_upper CS 'SHORTAGE'
          OR lv_desc_upper CS 'MISSING'.
        ls_header-priority = 'High'.
      ELSEIF lv_desc_upper CS 'MINOR' OR lv_desc_upper CS 'COSMETIC'.
        ls_header-priority = 'Low'.
      ELSEIF <entity>-priority IS NOT INITIAL.
        ls_header-priority = <entity>-priority.
      ELSE.
        ls_header-priority = 'Medium'.
      ENDIF.

      " Default Date & Admin
      ls_header-complaint_date = COND #(
        WHEN <entity>-complaint_date IS INITIAL THEN sy-datum
        ELSE <entity>-complaint_date ).
      ls_header-created_by = sy-uname.
      GET TIME STAMP FIELD ls_header-created_at.

      zcl_vc_util=>buffer_header_create( ls_header ).
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    DATA ls_header TYPE zvc_header.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      ls_header = zcl_vc_util=>get_header_from_buffer( CONV #( <entity>-complaint_id ) ).
      IF ls_header IS INITIAL.
        SELECT SINGLE * FROM zvc_header WHERE complaint_id = @<entity>-complaint_id INTO @ls_header.
      ENDIF.

      IF ls_header IS NOT INITIAL.
        IF <entity>-%control-vendor_id = if_abap_behv=>mk-on.     ls_header-vendor_id   = <entity>-vendor_id.     ENDIF.
        IF <entity>-%control-vendor_name = if_abap_behv=>mk-on.   ls_header-vendor_name = <entity>-vendor_name.   ENDIF.
        IF <entity>-%control-complaint_date = if_abap_behv=>mk-on. ls_header-complaint_date = <entity>-complaint_date. ENDIF.

        IF <entity>-%control-description = if_abap_behv=>mk-on.
          ls_header-description = <entity>-description.
          DATA(lv_desc_upper) = to_upper( ls_header-description ).
          IF lv_desc_upper CS 'URGENT' OR lv_desc_upper CS 'CRITICAL' OR lv_desc_upper CS 'BROKEN' OR lv_desc_upper CS 'FIRE'.
            ls_header-priority = 'Critical'.
          ELSEIF lv_desc_upper CS 'DELAY' OR lv_desc_upper CS 'SHORTAGE' OR lv_desc_upper CS 'MISSING'.
            ls_header-priority = 'High'.
          ELSEIF lv_desc_upper CS 'MINOR' OR lv_desc_upper CS 'COSMETIC'.
            ls_header-priority = 'Low'.
          ELSE.
            ls_header-priority = 'Medium'.
          ENDIF.
        ENDIF.

        IF <entity>-%control-priority = if_abap_behv=>mk-on. ls_header-priority = <entity>-priority. ENDIF.

        " ── SMART AUTOMATION: If user changes Status dropdown manually ──
        IF <entity>-%control-status = if_abap_behv=>mk-on.
          ls_header-status = <entity>-status.

          DATA(lv_status_check) = to_upper( ls_header-status ).

          IF lv_status_check = 'RESOLVED'.
            ls_header-resolved_date   = sy-datum.
            ls_header-resolution_note = ''. " Clear note until it is fully closed

          ELSEIF lv_status_check = 'CLOSED'.
            ls_header-resolved_date   = sy-datum.
            ls_header-resolution_note = 'The complaint request is completed.'.

          ELSE.
            " If they change it back to Open/Review, clear the resolution data
            ls_header-resolved_date   = '00000000'.
            ls_header-resolution_note = ''.
          ENDIF.
        ENDIF.

        ls_header-changed_by = sy-uname.
        GET TIME STAMP FIELD ls_header-changed_at.
        zcl_vc_util=>buffer_header_update( ls_header ).

      ELSE.
        APPEND VALUE #( %tky = <entity>-%tky ) TO failed-complaintheader.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      zcl_vc_util=>buffer_header_delete( CONV #( <key>-complaint_id ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      DATA(ls_buffer) = zcl_vc_util=>get_header_from_buffer(
                          CONV #( <key>-complaint_id ) ).
      DATA ls_result LIKE LINE OF result.
      IF ls_buffer IS NOT INITIAL.
        ls_result      = CORRESPONDING #( ls_buffer ).
        ls_result-%tky = VALUE #(
          complaint_id = ls_buffer-complaint_id
          %is_draft    = <key>-%is_draft ).
        INSERT ls_result INTO TABLE result.
      ELSE.
        SELECT SINGLE * FROM zvc_header
          WHERE complaint_id = @<key>-complaint_id
          INTO @DATA(ls_db).
        IF sy-subrc = 0.
          ls_result      = CORRESPONDING #( ls_db ).
          ls_result-%tky = VALUE #(
            complaint_id = ls_db-complaint_id
            %is_draft    = <key>-%is_draft ).
          INSERT ls_result INTO TABLE result.
        ELSE.
          APPEND VALUE #( %tky = <key>-%tky ) TO failed-complaintheader.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      TRY.
          cl_abap_lock_object_factory=>get_instance(
            iv_name = 'EZVC_HEADER' )->enqueue(
              it_parameter = VALUE #(
                ( name  = 'COMPLAINT_ID'
                  value = REF #( <key>-complaint_id ) ) ) ).
        CATCH cx_abap_lock_failure cx_abap_foreign_lock.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_Item.
    DATA lt_db_items TYPE TABLE OF zvcm_comp_item.
    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<key_rba>).
      SELECT * FROM zvcm_comp_item
        WHERE complaint_id = @<key_rba>-complaint_id
        INTO TABLE @lt_db_items.
      IF sy-subrc = 0.
        LOOP AT lt_db_items ASSIGNING FIELD-SYMBOL(<ls_item>).
          IF result_requested = abap_true.
            DATA ls_result LIKE LINE OF result.
            ls_result      = CORRESPONDING #( <ls_item> ).
            ls_result-%tky = VALUE #(
              complaint_id = <ls_item>-complaint_id
              item_id      = <ls_item>-item_id
              %is_draft    = <key_rba>-%is_draft ).
            INSERT ls_result INTO TABLE result.
          ENDIF.
          INSERT VALUE #(
            source-%tky = <key_rba>-%tky
            target-%tky = VALUE #(
              complaint_id = <ls_item>-complaint_id
              item_id      = <ls_item>-item_id
              %is_draft    = <key_rba>-%is_draft )
          ) INTO TABLE association_links.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD cba_Item.
    DATA ls_item TYPE zvcm_comp_item.
    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<header_entity>).
      LOOP AT <header_entity>-%target ASSIGNING FIELD-SYMBOL(<item_create>).
        ls_item-client        = sy-mandt.
        ls_item-complaint_id  = <header_entity>-complaint_id.
        ls_item-item_id       = <item_create>-item_id.
        ls_item-material_id   = <item_create>-material_id.
        ls_item-material_desc = <item_create>-material_desc.
        ls_item-quantity      = <item_create>-quantity.
        ls_item-unit          = <item_create>-unit.
        ls_item-defect_type   = <item_create>-defect_type.
        ls_item-defect_desc   = <item_create>-defect_desc.
        ls_item-created_by    = sy-uname.
        GET TIME STAMP FIELD ls_item-created_at.
        zcl_vc_util=>buffer_item_create( ls_item ).
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_cba_Item.
    DATA: lv_max TYPE numc4.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<header_entity>).
      SELECT MAX( item_id ) FROM zvcm_comp_item
        WHERE complaint_id = @<header_entity>-complaint_id
        INTO @DATA(lv_max_db).
      DATA(lv_max_buf) = zcl_vc_util=>get_max_item_id_from_buffer(
                           CONV #( <header_entity>-complaint_id ) ).
      lv_max = COND #(
        WHEN lv_max_db > lv_max_buf THEN lv_max_db
        ELSE lv_max_buf ).
      LOOP AT <header_entity>-%target ASSIGNING FIELD-SYMBOL(<item_create>).
        lv_max = lv_max + 10.
        APPEND VALUE #(
          %cid         = <item_create>-%cid
          %is_draft    = <item_create>-%is_draft
          complaint_id = <header_entity>-complaint_id
          item_id      = lv_max
        ) TO mapped-complaintitem.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

    METHOD submitComplaint.
    DATA ls_header TYPE zvc_header.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      ls_header = zcl_vc_util=>get_header_from_buffer( CONV #( <key>-complaint_id ) ).
      IF ls_header IS INITIAL.
        SELECT SINGLE * FROM zvc_header WHERE complaint_id = @<key>-complaint_id INTO @ls_header.
      ENDIF.

      DATA(lv_status_upper) = to_upper( ls_header-status ).

      CASE lv_status_upper.
        WHEN 'OPEN' OR ''.
          ls_header-status        = 'Review'.
          ls_header-resolved_date = '00000000'.

        WHEN 'REVIEW'.
          ls_header-status        = 'Resolved'.
          ls_header-resolved_date = sy-datum.   " ← AUTO SET DATE when Resolved

        WHEN 'RESOLVED'.
          ls_header-status          = 'Closed'.
          ls_header-resolved_date   = sy-datum.
          ls_header-resolution_note = 'The complaint request is completed.'. " ← AUTO SET NOTE when Closed

        WHEN 'CLOSED'.
          APPEND VALUE #(
            %tky = <key>-%tky
            %msg = new_message_with_text(
              severity = if_abap_behv_message=>severity-error
              text     = 'Complaint is already closed and cannot be changed.' )
          ) TO reported-complaintheader.
          APPEND VALUE #( %tky = <key>-%tky ) TO failed-complaintheader.
          CONTINUE.

        WHEN OTHERS.
          ls_header-status = 'Review'.
      ENDCASE.

      zcl_vc_util=>buffer_header_update( ls_header ).
    ENDLOOP.

    " Return fresh data so Fiori UI refreshes instantly
    READ ENTITIES OF ZI_VC_HEADER IN LOCAL MODE
      ENTITY ComplaintHeader
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_complaints).

    result = VALUE #( FOR complaint IN lt_complaints
                      ( %tky   = complaint-%tky
                        %param = complaint ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_VC_HEADER DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize          REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save              REDEFINITION.
    METHODS cleanup           REDEFINITION.
ENDCLASS.

CLASS lsc_ZI_VC_HEADER IMPLEMENTATION.
  METHOD finalize.
  ENDMETHOD.
  METHOD check_before_save.
  ENDMETHOD.
  METHOD save.
    zcl_vc_util=>save( ).
  ENDMETHOD.
  METHOD cleanup.
    zcl_vc_util=>cleanup( ).
  ENDMETHOD.
ENDCLASS.
