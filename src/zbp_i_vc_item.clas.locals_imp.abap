CLASS lhc_ComplaintItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE ComplaintItem.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE ComplaintItem.
    METHODS read FOR READ IMPORTING keys FOR READ ComplaintItem RESULT result.
    METHODS rba_Header FOR READ IMPORTING keys_rba FOR READ ComplaintItem\_Header FULL result_requested RESULT result LINK association_links.
ENDCLASS.

CLASS lhc_ComplaintItem IMPLEMENTATION.
  METHOD update.
    DATA ls_item TYPE zvcm_comp_item.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      ls_item = zcl_vc_util=>get_item_from_buffer( iv_complaint_id = CONV #( <entity>-complaint_id ) iv_item_id = CONV #( <entity>-item_id ) ).
      IF ls_item IS INITIAL.
        SELECT SINGLE * FROM zvcm_comp_item WHERE complaint_id = @<entity>-complaint_id AND item_id = @<entity>-item_id INTO @ls_item.
      ENDIF.

      IF ls_item IS NOT INITIAL.
        IF <entity>-%control-material_id = if_abap_behv=>mk-on.   ls_item-material_id = <entity>-material_id.     ENDIF.
        IF <entity>-%control-material_desc = if_abap_behv=>mk-on. ls_item-material_desc = <entity>-material_desc. ENDIF.
        IF <entity>-%control-quantity = if_abap_behv=>mk-on.      ls_item-quantity = <entity>-quantity.           ENDIF.
        IF <entity>-%control-unit = if_abap_behv=>mk-on.          ls_item-unit = <entity>-unit.                   ENDIF.
        IF <entity>-%control-defect_type = if_abap_behv=>mk-on.   ls_item-defect_type = <entity>-defect_type.     ENDIF.
        IF <entity>-%control-defect_desc = if_abap_behv=>mk-on.   ls_item-defect_desc = <entity>-defect_desc.    ENDIF.
        zcl_vc_util=>buffer_item_update( ls_item ).
      ELSE.
        APPEND VALUE #( %tky = <entity>-%tky ) TO failed-complaintitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      zcl_vc_util=>buffer_item_delete( iv_complaint_id = CONV #( <key>-complaint_id ) iv_item_id = CONV #( <key>-item_id ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      DATA ls_result LIKE LINE OF result.
      DATA(ls_buffer) = zcl_vc_util=>get_item_from_buffer( iv_complaint_id = CONV #( <key>-complaint_id ) iv_item_id = CONV #( <key>-item_id ) ).
      IF ls_buffer IS NOT INITIAL.
        ls_result      = CORRESPONDING #( ls_buffer ).
        ls_result-%tky = VALUE #( complaint_id = ls_buffer-complaint_id item_id = ls_buffer-item_id %is_draft = <key>-%is_draft ).
        INSERT ls_result INTO TABLE result.
      ELSE.
        SELECT SINGLE * FROM zvcm_comp_item WHERE complaint_id = @<key>-complaint_id AND item_id = @<key>-item_id INTO @DATA(ls_db).
        IF sy-subrc = 0.
          ls_result      = CORRESPONDING #( ls_db ).
          ls_result-%tky = VALUE #( complaint_id = ls_db-complaint_id item_id = ls_db-item_id %is_draft = <key>-%is_draft ).
          INSERT ls_result INTO TABLE result.
        ELSE.
          APPEND VALUE #( %tky = <key>-%tky ) TO failed-complaintitem.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_Header.
    DATA ls_header TYPE zvc_header.
    LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<key_rba>).
      ls_header = zcl_vc_util=>get_header_from_buffer( CONV #( <key_rba>-complaint_id ) ).
      IF ls_header IS INITIAL.
        SELECT SINGLE * FROM zvc_header WHERE complaint_id = @<key_rba>-complaint_id INTO @ls_header.
      ENDIF.

      IF ls_header IS NOT INITIAL.
        IF result_requested = abap_true.
          DATA ls_result LIKE LINE OF result.
          ls_result      = CORRESPONDING #( ls_header ).
          ls_result-%tky = VALUE #( complaint_id = ls_header-complaint_id %is_draft = <key_rba>-%is_draft ).
          INSERT ls_result INTO TABLE result.
        ENDIF.
        INSERT VALUE #( source-%tky = <key_rba>-%tky
                        target-%tky = VALUE #( complaint_id = ls_header-complaint_id %is_draft = <key_rba>-%is_draft ) )
               INTO TABLE association_links.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
