CLASS zcl_vc_util DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES:
      tt_header TYPE STANDARD TABLE OF zvc_header      WITH DEFAULT KEY,
      tt_item   TYPE STANDARD TABLE OF zvcm_comp_item  WITH DEFAULT KEY.

    CLASS-DATA:
      gt_header_create TYPE tt_header,
      gt_header_update TYPE tt_header,
      gt_header_delete TYPE tt_header,
      gt_item_create   TYPE tt_item,
      gt_item_update   TYPE tt_item,
      gt_item_delete   TYPE tt_item.

    CLASS-METHODS:
      buffer_header_create IMPORTING is_header       TYPE zvc_header,
      buffer_header_update IMPORTING is_header       TYPE zvc_header,
      buffer_header_delete IMPORTING iv_complaint_id TYPE char10,
      buffer_item_create   IMPORTING is_item         TYPE zvcm_comp_item,
      buffer_item_update   IMPORTING is_item         TYPE zvcm_comp_item,
      buffer_item_delete   IMPORTING iv_complaint_id TYPE char10 iv_item_id TYPE numc4,
      get_header_from_buffer IMPORTING iv_complaint_id  TYPE char10 RETURNING VALUE(rs_header) TYPE zvc_header,
      get_header_create_buffer RETURNING VALUE(rt_header) TYPE tt_header,
      get_item_from_buffer IMPORTING iv_complaint_id TYPE char10 iv_item_id TYPE numc4 RETURNING VALUE(rs_item) TYPE zvcm_comp_item,
      get_max_item_id_from_buffer IMPORTING iv_complaint_id TYPE char10 RETURNING VALUE(rv_max_id) TYPE numc4,
      save,
      cleanup,
      get_next_complaint_id RETURNING VALUE(rv_id) TYPE char10.
ENDCLASS.

CLASS zcl_vc_util IMPLEMENTATION.

  METHOD buffer_header_create.
    " DEFENSIVE FIX: Check if it's already in the buffer before appending.
    " This prevents Fiori Draft from duplicating data if it triggers Create twice.
    READ TABLE gt_header_create TRANSPORTING NO FIELDS
      WITH KEY complaint_id = is_header-complaint_id.
    IF sy-subrc <> 0.
      APPEND is_header TO gt_header_create.
    ENDIF.
  ENDMETHOD.

  METHOD buffer_header_update.
    READ TABLE gt_header_create ASSIGNING FIELD-SYMBOL(<fs_c>) WITH KEY complaint_id = is_header-complaint_id.
    IF sy-subrc = 0.
      <fs_c> = is_header.
    ELSE.
      READ TABLE gt_header_update ASSIGNING FIELD-SYMBOL(<fs_u>) WITH KEY complaint_id = is_header-complaint_id.
      IF sy-subrc = 0.
        <fs_u> = is_header.
      ELSE.
        APPEND is_header TO gt_header_update.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD buffer_header_delete.
    APPEND VALUE #( client = sy-mandt complaint_id = iv_complaint_id ) TO gt_header_delete.
  ENDMETHOD.

  METHOD buffer_item_create.
    " DEFENSIVE FIX: Prevent duplicate items from being added to the buffer.
    READ TABLE gt_item_create TRANSPORTING NO FIELDS
      WITH KEY complaint_id = is_item-complaint_id
               item_id      = is_item-item_id.
    IF sy-subrc <> 0.
      APPEND is_item TO gt_item_create.
    ENDIF.
  ENDMETHOD.

  METHOD buffer_item_update.
    READ TABLE gt_item_create ASSIGNING FIELD-SYMBOL(<fs_c>) WITH KEY complaint_id = is_item-complaint_id item_id = is_item-item_id.
    IF sy-subrc = 0.
      <fs_c> = is_item.
    ELSE.
      READ TABLE gt_item_update ASSIGNING FIELD-SYMBOL(<fs_u>) WITH KEY complaint_id = is_item-complaint_id item_id = is_item-item_id.
      IF sy-subrc = 0.
        <fs_u> = is_item.
      ELSE.
        APPEND is_item TO gt_item_update.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD buffer_item_delete.
    APPEND VALUE #( client = sy-mandt complaint_id = iv_complaint_id item_id = iv_item_id ) TO gt_item_delete.
  ENDMETHOD.

  METHOD get_header_from_buffer.
    READ TABLE gt_header_create INTO rs_header WITH KEY complaint_id = iv_complaint_id.
    IF sy-subrc <> 0.
      READ TABLE gt_header_update INTO rs_header WITH KEY complaint_id = iv_complaint_id.
    ENDIF.
  ENDMETHOD.

  METHOD get_header_create_buffer.
    rt_header = gt_header_create.
  ENDMETHOD.

  METHOD get_item_from_buffer.
    READ TABLE gt_item_create INTO rs_item WITH KEY complaint_id = iv_complaint_id item_id = iv_item_id.
    IF sy-subrc <> 0.
      READ TABLE gt_item_update INTO rs_item WITH KEY complaint_id = iv_complaint_id item_id = iv_item_id.
    ENDIF.
  ENDMETHOD.

  METHOD get_max_item_id_from_buffer.
    rv_max_id = 0.
    LOOP AT gt_item_create INTO DATA(ls_item) WHERE complaint_id = iv_complaint_id.
      IF ls_item-item_id > rv_max_id. rv_max_id = ls_item-item_id. ENDIF.
    ENDLOOP.
    LOOP AT gt_item_update INTO ls_item WHERE complaint_id = iv_complaint_id.
      IF ls_item-item_id > rv_max_id. rv_max_id = ls_item-item_id. ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD save.
    " 1. Use MODIFY to safely combine Creates and Updates without crashing
    DATA: lt_header_mod TYPE tt_header,
          lt_item_mod   TYPE tt_item.

    lt_header_mod = gt_header_create.
    APPEND LINES OF gt_header_update TO lt_header_mod.
    IF lt_header_mod IS NOT INITIAL.
      MODIFY zvc_header FROM TABLE @lt_header_mod.
    ENDIF.

    lt_item_mod = gt_item_create.
    APPEND LINES OF gt_item_update TO lt_item_mod.
    IF lt_item_mod IS NOT INITIAL.
      MODIFY zvcm_comp_item FROM TABLE @lt_item_mod.
    ENDIF.

    " 2. Handle Deletes securely
    IF gt_item_delete IS NOT INITIAL.
      DELETE zvcm_comp_item FROM TABLE @gt_item_delete.
    ENDIF.

    IF gt_header_delete IS NOT INITIAL.
      DELETE zvc_header FROM TABLE @gt_header_delete.
      " CRITICAL FIX: Delete orphaned items so they don't show up in the future!
      LOOP AT gt_header_delete INTO DATA(ls_del_hdr).
        DELETE FROM zvcm_comp_item WHERE complaint_id = @ls_del_hdr-complaint_id.
      ENDLOOP.
    ENDIF.

    cleanup( ).
  ENDMETHOD.

  METHOD cleanup.
    CLEAR: gt_header_create, gt_header_update, gt_header_delete,
           gt_item_create,   gt_item_update,   gt_item_delete.
  ENDMETHOD.

  METHOD get_next_complaint_id.
    DATA: lv_time TYPE string,
          lo_rand TYPE REF TO cl_abap_random_int,
          lv_rand TYPE string.

    " 1. Get current system time (HHMMSS = 6 characters)
    lv_time = sy-uzeit.

    " 2. Generate a random 2-digit number (10 to 99) using system clock as seed
    lo_rand = cl_abap_random_int=>create( seed = cl_abap_random=>seed( )
                                          min  = 10
                                          max  = 99 ).
    lv_rand = CONV string( lo_rand->get_next( ) ).

    " 3. Combine them to fit perfectly in your CHAR(10) database field.
    " Example output: C-14352287  (C- + Time + Random)
    rv_id = 'C-' && lv_time && lv_rand.
  ENDMETHOD.
ENDCLASS.
