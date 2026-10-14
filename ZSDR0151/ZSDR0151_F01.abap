FORM set_text.
  gs_text-h01 = TEXT-h01.          "Customer
  gs_text-h02 = TEXT-h02.          "Ship to Location
  gs_text-h03 = TEXT-h03.          "Consignee Location
  gs_text-h04 = TEXT-h04.          "Bill to Location
  gs_text-h05 = TEXT-h05.          "Notify Party 1
  gs_text-h06 = TEXT-h06.          "Notify Party 2
  gs_text-h07 = TEXT-h07.          "Import Invoice No.
  gs_text-h08 = TEXT-h08.          "Remarks 1
  gs_text-h09 = TEXT-h09.          "Remarks 2

  gs_text-h10 = TEXT-h10.          "Delivery Type
  gs_text-h11 = TEXT-h11.          "Delivery No.
  gs_text-h12 = TEXT-h12.          "Total Amount
  gs_text-h13 = TEXT-h13.          "Packing Type
  gs_text-h14 = TEXT-h14.          "Print Form Option

  gs_text-h15 = TEXT-h15.          "Invoice No.
  gs_text-h16 = TEXT-h16.          "Date of Invoice
  gs_text-h17 = TEXT-h17.          "Payment Term

  gs_text-h18 = TEXT-h18.          "House Waybill
  gs_text-h19 = TEXT-h19.          "Master Waybill
  gs_text-h20 = TEXT-h20.          "Forwarder

  gs_text-h21 = TEXT-h21.          "Port of Loading
  gs_text-h22 = TEXT-h22.          "Discharging Port
  gs_text-h23 = TEXT-h23.          "Destination

  gs_text-h24 = TEXT-h24.          "Voyage No.
  gs_text-h25 = TEXT-h25.          "Freight Terms
  gs_text-h26 = TEXT-h26.          "Incoterms

  gs_text-h27 = TEXT-h27.          "On Board Date
  gs_text-h28 = TEXT-h28.          "ETA Date
  gs_text-h29 = TEXT-h29.          "Shipping Method

  gs_text-h30 = TEXT-h30.          "Package
  gs_text-h31 = TEXT-h31.          "(Package)
  gs_text-h32 = TEXT-h32.          "Measurement
  gs_text-h33 = TEXT-h33.          "Net Weight
  gs_text-h34 = TEXT-h34.          "Gross Weight
  gs_text-h35 = TEXT-h35.          "Shipping Remark

  gv_pr_cip = TEXT-b01.
  gv_pr_ci  = TEXT-b02.
  gv_pr_pl  = TEXT-b03.
ENDFORM.

FORM set_screen.
  CLEAR c_vstel.
  CHECK s_vstel-low IS NOT INITIAL.
  SELECT SINGLE vtext
    FROM tvstt
   WHERE spras = @sy-langu
     AND vstel = @s_vstel-low
    INTO @c_vstel.
ENDFORM.

FORM check_input
  CHANGING pv_error TYPE abap_bool.

  DATA:
    lv_vstel TYPE tvst-vstel.

  CLEAR pv_error.

  IF s_vstel-low IS INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-e04 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  IF s_wadat[] IS INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-e05 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  IF s_vbeln-low IS INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-e06 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  IF lines( s_vstel[] ) <> 1.
    pv_error = abap_true.
    MESSAGE TEXT-e07 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  READ TABLE s_vstel INDEX 1.
  IF s_vstel-sign   <> gc_i
     OR s_vstel-option <> gc_eq
     OR s_vstel-high IS NOT INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-e07 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  IF lines( s_vbeln[] ) <> 1.
    pv_error = abap_true.
    MESSAGE TEXT-e08 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  READ TABLE s_vbeln INDEX 1.
  IF s_vbeln-sign   <> gc_i
     OR s_vbeln-option <> gc_eq
     OR s_vbeln-high IS NOT INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-e08 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  SELECT SINGLE vstel
    FROM tvst
   WHERE vstel = @s_vstel-low
    INTO @lv_vstel.

  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-e09 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
ENDFORM.

FORM align_header_labels.
  DATA: lv_name  TYPE fieldname,
        lv_index TYPE n LENGTH 2,
        lv_width TYPE i,
        lv_label TYPE c LENGTH 40.
  FIELD-SYMBOLS <lv_label> TYPE char40.

  DO 35 TIMES.
    lv_index = sy-index.
    CONCATENATE 'H' lv_index INTO lv_name.
    ASSIGN COMPONENT lv_name OF STRUCTURE gs_text TO <lv_label>.
    CHECK sy-subrc = 0.
    lv_label = <lv_label>.
    CONDENSE lv_label.
    IF sy-index <= 9 OR sy-index = 35.
      lv_width = 23.
    ELSEIF sy-index <= 13.
      lv_width = 24.
    ELSEIF sy-index = 14.
      CONTINUE.
    ELSE.
      lv_width = 20.
    ENDIF.
    CLEAR <lv_label>.
    WRITE lv_label TO <lv_label>(lv_width) RIGHT-JUSTIFIED.
  ENDDO.
ENDFORM.

FORM set_packing_values CHANGING pv_error TYPE abap_bool.
  DATA: lt_domain TYPE STANDARD TABLE OF dd07v,
        ls_domain TYPE dd07v,
        ls_value  TYPE vrm_value.
  CLEAR pv_error.
  IF gv_pack_loaded IS INITIAL.
    CALL FUNCTION 'DD_DOMVALUES_GET'
      EXPORTING
        domname        = gc_pack_domain
        text           = gc_x
        langu          = sy-langu
      TABLES
        dd07v_tab      = lt_domain
      EXCEPTIONS
        wrong_textflag = 1
        OTHERS         = 2.
    IF sy-subrc <> 0 OR lt_domain IS INITIAL.
      pv_error = abap_true.
      MESSAGE TEXT-r03 TYPE gc_s DISPLAY LIKE gc_e.
      RETURN.
    ENDIF.
    CLEAR gt_pack_values.
    LOOP AT lt_domain INTO ls_domain.
      IF ls_domain-domvalue_h IS NOT INITIAL.
        pv_error = abap_true.
        MESSAGE TEXT-r03 TYPE gc_s DISPLAY LIKE gc_e.
        RETURN.
      ENDIF.
      CLEAR ls_value.
      ls_value-key = ls_domain-domvalue_l.
      ls_value-text = ls_domain-ddtext.
      APPEND ls_value TO gt_pack_values.
    ENDLOOP.
    gv_pack_loaded = abap_true.
  ENDIF.
  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id              = gc_pack_field
      values          = gt_pack_values
    EXCEPTIONS
      id_illegal_name = 1
      OTHERS          = 2.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-r03 TYPE gc_s DISPLAY LIKE gc_e.
  ENDIF.
ENDFORM.

FORM get_payment_text.
  CLEAR gv_zterm_text.
  CHECK gs_head-zivh22 IS NOT INITIAL.
  SELECT SINGLE vtext INTO gv_zterm_text
    FROM tvzbt
    WHERE spras = sy-langu AND zterm = gs_head-zivh22.
ENDFORM.

FORM check_header_required CHANGING pv_error TYPE abap_bool.
  DATA: lv_label TYPE c LENGTH 40,
        lv_zterm TYPE t052-zterm,
        lv_inco1 TYPE tinc-inco1.
  CLEAR pv_error.
  IF gs_head-zivh01 IS INITIAL.
    lv_label = TEXT-h02.
  ELSEIF gs_head-zivh03 IS INITIAL.
    lv_label = TEXT-h04.
  ELSEIF gs_head-zivh28 IS INITIAL.
    lv_label = TEXT-h13.
  ELSEIF gs_head-zivh15 IS INITIAL.
    lv_label = TEXT-h16.
  ELSEIF gs_head-zivh22 IS INITIAL.
    lv_label = TEXT-h17.
  ELSEIF gs_head-zivh25 IS INITIAL.
    lv_label = TEXT-h26.
  ENDIF.
  IF lv_label IS NOT INITIAL.
    pv_error = abap_true.
    MESSAGE s001 WITH TEXT-r04 lv_label DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
    EXPORTING
      date                      = gs_head-zivh15
    EXCEPTIONS
      plausibility_check_failed = 1
      OTHERS                    = 2.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-r05 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

* 포장 유형 목록 설정
  PERFORM set_packing_values CHANGING pv_error.
  CHECK pv_error IS INITIAL.
  READ TABLE gt_pack_values TRANSPORTING NO FIELDS
    WITH KEY key = gs_head-zivh28.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-r06 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  SELECT SINGLE zterm INTO lv_zterm FROM t052
    WHERE zterm = gs_head-zivh22.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-r07 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  SELECT SINGLE inco1 INTO lv_inco1 FROM tinc
    WHERE inco1 = gs_head-zivh25.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-r08 TYPE gc_s DISPLAY LIKE gc_e.
  ENDIF.
ENDFORM.

FORM f4_payment_term.
  TYPES: BEGIN OF lty_payment,
           zterm TYPE tvzbt-zterm,
           vtext TYPE tvzbt-vtext,
         END OF lty_payment.
  DATA: lt_payment TYPE STANDARD TABLE OF lty_payment,
        lv_value   TYPE shvalue_d.
  SELECT DISTINCT a~zterm b~vtext INTO TABLE lt_payment
    FROM t052 AS a LEFT OUTER JOIN tvzbt AS b
      ON b~zterm = a~zterm AND b~spras = sy-langu
    ORDER BY a~zterm.
  IF lt_payment IS INITIAL.
    MESSAGE s022 DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  lv_value = zcl_cm_util=>f4_value_request(
    i_retfield = 'ZTERM' i_itab = lt_payment ).
  CHECK lv_value IS NOT INITIAL.
* 선택값을 현재 헤더 화면에 반영
  PERFORM update_header_dynpro USING 'GS_HEAD-ZIVH22' lv_value.
ENDFORM.

FORM f4_incoterms.
  TYPES: BEGIN OF lty_inco,
           inco1 TYPE tinc-inco1,
           bezei TYPE tinct-bezei,
         END OF lty_inco.
  DATA: lt_inco  TYPE STANDARD TABLE OF lty_inco,
        lv_value TYPE shvalue_d.
  SELECT a~inco1 b~bezei INTO TABLE lt_inco
    FROM tinc AS a LEFT OUTER JOIN tinct AS b
      ON b~inco1 = a~inco1 AND b~spras = sy-langu
    ORDER BY a~inco1.
  IF lt_inco IS INITIAL.
    MESSAGE s022 DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  lv_value = zcl_cm_util=>f4_value_request(
    i_retfield = 'INCO1' i_itab = lt_inco ).
  CHECK lv_value IS NOT INITIAL.
* 선택값을 현재 헤더 화면에 반영
  PERFORM update_header_dynpro USING 'GS_HEAD-ZIVH25' lv_value.
ENDFORM.

FORM update_header_dynpro USING pv_field TYPE dynfnam
                                pv_value TYPE clike.
  DATA: lt_fields TYPE STANDARD TABLE OF dynpread,
        ls_field  TYPE dynpread.
  ls_field-fieldname = pv_field.
  ls_field-fieldvalue = pv_value.
  APPEND ls_field TO lt_fields.
  IF pv_field = 'GS_HEAD-ZIVH22'.
    CLEAR ls_field.
    ls_field-fieldname = 'GV_ZTERM_TEXT'.
    SELECT SINGLE vtext INTO ls_field-fieldvalue FROM tvzbt
      WHERE spras = sy-langu AND zterm = pv_value.
    APPEND ls_field TO lt_fields.
  ENDIF.
  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname     = sy-repid
      dynumb     = gc_dynnr_main
    TABLES
      dynpfields = lt_fields
    EXCEPTIONS
      OTHERS     = 1.
  IF sy-subrc <> 0.
    MESSAGE TEXT-r09 TYPE gc_s DISPLAY LIKE gc_e.
  ENDIF.
ENDFORM.

FORM f4_header_date USING pv_field TYPE dynfnam.
  DATA: lt_fields TYPE STANDARD TABLE OF dynpread,
        ls_field  TYPE dynpread,
        lv_date   TYPE sy-datum,
        lv_text   TYPE c LENGTH 10.
  ls_field-fieldname = pv_field.
  APPEND ls_field TO lt_fields.
  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname     = sy-repid
      dynumb     = gc_dynnr_main
    TABLES
      dynpfields = lt_fields
    EXCEPTIONS
      OTHERS     = 1.
  IF sy-subrc = 0.
    READ TABLE lt_fields INTO ls_field INDEX 1.
    IF ls_field-fieldvalue IS NOT INITIAL.
      CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
        EXPORTING
          date_external            = ls_field-fieldvalue
        IMPORTING
          date_internal            = lv_date
        EXCEPTIONS
          date_external_is_invalid = 1
          OTHERS                   = 2.
      IF sy-subrc <> 0.
        CLEAR lv_date.
      ENDIF.
    ENDIF.
  ENDIF.
  IF lv_date IS INITIAL.
    lv_date = sy-datum.
  ENDIF.
  CALL FUNCTION 'F4_DATE'
    EXPORTING
      date_for_first_month         = lv_date
    IMPORTING
      select_date                  = lv_date
    EXCEPTIONS
      calendar_buffer_not_loadable = 1
      date_after_range             = 2
      date_before_range            = 3
      date_invalid                 = 4
      factory_calendar_not_found   = 5
      holiday_calendar_not_found   = 6
      parameter_conflict           = 7
      OTHERS                       = 8.
  CHECK sy-subrc = 0 AND lv_date IS NOT INITIAL.
  WRITE lv_date TO lv_text.
* 선택값을 현재 헤더 화면에 반영
  PERFORM update_header_dynpro USING pv_field lv_text.
ENDFORM.

FORM read_shipping_remark USING pv_invno TYPE zsdt0060-zinvno
                          CHANGING pt_remark TYPE gty_t_remark
                                   pv_error TYPE abap_bool.
  DATA: lt_lines TYPE STANDARD TABLE OF tline,
        ls_line  TYPE tline,
        lv_name  TYPE thead-tdname.
  CLEAR: pt_remark, pv_error.
  CHECK pv_invno IS NOT INITIAL.
  lv_name = pv_invno.
  IF gv_text_langu IS INITIAL.
    gv_text_langu = sy-langu.
  ENDIF.
  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      object                  = gc_text_object
      id                      = gc_text_id
      name                    = lv_name
      language                = gv_text_langu
    TABLES
      lines                   = lt_lines
    EXCEPTIONS
      id                      = 1
      language                = 2
      name                    = 3
      not_found               = 4
      object                  = 5
      reference_check         = 6
      wrong_access_to_archive = 7
      OTHERS                  = 8.
  CASE sy-subrc.
    WHEN 0.
      LOOP AT lt_lines INTO ls_line.
        APPEND ls_line-tdline TO pt_remark.
      ENDLOOP.
    WHEN 4.
    WHEN OTHERS.
      pv_error = abap_true.
      MESSAGE TEXT-r10 TYPE gc_s DISPLAY LIKE gc_e.
  ENDCASE.
ENDFORM.

FORM save_shipping_remark USING pv_invno TYPE zsdt0060-zinvno
                         CHANGING pv_error TYPE abap_bool.
  DATA: ls_header TYPE thead,
        lt_lines  TYPE STANDARD TABLE OF tline,
        ls_line   TYPE tline,
        lv_line   TYPE tline-tdline.
  CLEAR pv_error.
  IF pv_invno IS INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-r14 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  IF gv_text_langu IS INITIAL.
    gv_text_langu = sy-langu.
  ENDIF.
  ls_header-tdobject = gc_text_object.
  ls_header-tdid = gc_text_id.
  ls_header-tdname = pv_invno.
  ls_header-tdspras = gv_text_langu.
  LOOP AT gt_remark INTO lv_line.
    CLEAR ls_line.
    ls_line-tdformat = '*'.
    ls_line-tdline = lv_line.
    APPEND ls_line TO lt_lines.
  ENDLOOP.
  IF lt_lines IS INITIAL.
    CALL FUNCTION 'DELETE_TEXT'
      EXPORTING object = gc_text_object id = gc_text_id
                name = ls_header-tdname language = gv_text_langu
                savemode_direct = abap_true
      EXCEPTIONS not_found = 4 OTHERS = 8.
    IF sy-subrc <> 0 AND sy-subrc <> 4.
      pv_error = abap_true.
      MESSAGE TEXT-r15 TYPE gc_s DISPLAY LIKE gc_e.
    ENDIF.
    RETURN.
  ENDIF.
  CALL FUNCTION 'SAVE_TEXT'
    EXPORTING
      header          = ls_header
      savemode_direct = gc_x
    TABLES
      lines           = lt_lines
    EXCEPTIONS
      id              = 1
      language        = 2
      name            = 3
      object          = 4
      OTHERS          = 5.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-r15 TYPE gc_s DISPLAY LIKE gc_e.
  ENDIF.
ENDFORM.

FORM free_remark_editor.
  IF go_remark_edit IS BOUND.
    CALL METHOD go_remark_edit->free EXCEPTIONS OTHERS = 1.
    FREE go_remark_edit.
  ENDIF.
  IF go_remark_cont IS BOUND.
    CALL METHOD go_remark_cont->free EXCEPTIONS OTHERS = 1.
    FREE go_remark_cont.
  ENDIF.
  CLEAR: gv_remark_loaded, gv_remark_push, gv_remark_invno,
         gt_remark, gt_remark_old.
ENDFORM.

FORM set_alv_grid CHANGING pv_error TYPE abap_bool.
  CLEAR pv_error.
  IF go_grid IS BOUND.
    IF gv_refresh = abap_true.
* 품목 ALV 안정 갱신
      PERFORM refresh_item_alv CHANGING pv_error.
    ENDIF.
    RETURN.
  ENDIF.

  CREATE OBJECT go_cont
    EXPORTING
      container_name = gc_cont_item
      repid          = sy-repid
      dynnr          = gc_dynnr_item
    EXCEPTIONS
      OTHERS         = 1.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-a24 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  CREATE OBJECT go_grid
    EXPORTING
      i_parent = go_cont
    EXCEPTIONS
      OTHERS   = 1.
  IF sy-subrc <> 0.
* 품목 컨트롤 해제
    PERFORM free_item_alv.
    pv_error = abap_true.
    MESSAGE TEXT-a24 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

* 품목 필드카탈로그 생성
  PERFORM set_item_fcat.
* 품목 ALV 레이아웃 설정
  PERFORM set_item_layout.

  SET HANDLER lcl_event=>handle_toolbar FOR go_grid.
  SET HANDLER lcl_event=>handle_user_command FOR go_grid.
  SET HANDLER lcl_event=>changed FOR go_grid.
  SET HANDLER lcl_event=>finished FOR go_grid.
  go_grid->register_edit_event( cl_gui_alv_grid=>mc_evt_modified ).
  go_grid->register_edit_event( cl_gui_alv_grid=>mc_evt_enter ).

  CALL METHOD go_grid->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout
      is_variant                    = gs_variant
      i_save                        = gc_layout_save
      i_default                     = gc_x
      it_toolbar_excluding          = gt_exclude
    CHANGING
      it_outtab                     = gt_item
      it_fieldcatalog               = gt_fcat
      it_sort                       = gt_sort
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
* 품목 컨트롤 해제
    PERFORM free_item_alv.
    pv_error = abap_true.
    MESSAGE TEXT-a24 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  CALL METHOD go_grid->set_ready_for_input
    EXPORTING
      i_ready_for_input = 1.
  CALL METHOD cl_gui_cfw=>flush EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0.
* 품목 컨트롤 해제
    PERFORM free_item_alv.
    pv_error = abap_true.
    MESSAGE TEXT-a24 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  CLEAR gv_refresh.
ENDFORM.

FORM set_item_fcat.
  CLEAR gt_fcat.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'CHECK'    TEXT-a01 space      space     4.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'ZPKGNO'   TEXT-a02 'ZSDT0061' 'ZPKGNO'  10.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'MATNR'    TEXT-a03 'MARA'     'MATNR'   18.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'MAKTX'    TEXT-a04 'MAKT'     'MAKTX'   24.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'WADAT'    TEXT-a05 'LIKP'     'WADAT'   10.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'BSTKD_E'  TEXT-a06 'VBKD'     'BSTKD_E' 18.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'ZIVI01'   TEXT-a07 'ZSDT0061' 'ZIVI01'  15.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'MEINS'    TEXT-a08 'MARA'     'MEINS'   4.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'ZIVI04'   TEXT-a09 'ZSDT0061' 'ZIVI04'  15.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'ZIVI05'   TEXT-a10 'ZSDT0061' 'ZIVI05'  15.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'GEWEI'    TEXT-a11 'MARA'     'GEWEI'   4.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'ZIVI06'   TEXT-a12 'ZSDT0061' 'ZIVI06'  15.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'VOLEH'    TEXT-a13 'MARA'     'VOLEH'   4.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'ZIVI02'   TEXT-a14 'ZSDT0061' 'ZIVI02'  8.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'ZIVI03'   TEXT-a15 'ZSDT0061' 'ZIVI03'  8.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'NETPR'    TEXT-a16 'ZSDT0061' 'NETPR'   18.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'NETWR'    TEXT-a17 'ZSDT0061' 'NETWR'   18.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'WAERK'    TEXT-a18 'VBAK'     'WAERK'   5.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'VBELN_SO' TEXT-a19 'VBAK'     'VBELN'   12.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'POSNR_SO' TEXT-a20 'VBAP'     'POSNR'   8.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'POSNR' TEXT-a26 'LIPS' 'POSNR' 8.
* 품목 컬럼 정의 추가
  PERFORM append_item_fcat USING 'MESSAGE' TEXT-a27 space space 60.
ENDFORM.

FORM append_item_fcat USING pv_field TYPE lvc_fname
                            pv_text TYPE clike
                            pv_table TYPE tabname
                            pv_ref TYPE fieldname
                            pv_length TYPE i.
  DATA ls_fcat TYPE lvc_s_fcat.
  ls_fcat-col_pos = lines( gt_fcat ) + 1.
  ls_fcat-fieldname = pv_field.
  ls_fcat-ref_table = pv_table.
  ls_fcat-ref_field = pv_ref.
  ls_fcat-outputlen = pv_length.
  ls_fcat-coltext = pv_text.
  ls_fcat-scrtext_l = pv_text.
  ls_fcat-scrtext_m = pv_text.
  ls_fcat-scrtext_s = pv_text.
  ls_fcat-tooltip = pv_text.
  CASE pv_field.
    WHEN 'CHECK'.
      ls_fcat-checkbox = gc_x.
      ls_fcat-edit = gc_x.
      ls_fcat-inttype = 'C'.
      ls_fcat-datatype = 'CHAR'.
      DESCRIBE FIELD gs_item-check LENGTH ls_fcat-intlen IN BYTE MODE.
    WHEN 'ZIVI01'.
      ls_fcat-qfieldname = 'MEINS'.
      ls_fcat-edit = abap_true.
    WHEN 'ZIVI04' OR 'ZIVI05'.
      ls_fcat-qfieldname = 'GEWEI'.
      ls_fcat-edit = abap_true.
    WHEN 'ZIVI06'.
      ls_fcat-qfieldname = 'VOLEH'.
      ls_fcat-edit = abap_true.
    WHEN 'ZIVI02' OR 'ZIVI03'.
      ls_fcat-edit = abap_true.
    WHEN 'NETWR'.
      ls_fcat-cfieldname = 'WAERK'.
  ENDCASE.
  APPEND ls_fcat TO gt_fcat.
ENDFORM.

FORM set_item_layout.
  CLEAR: gs_layout, gs_variant, gt_sort, gt_exclude.
  gs_layout-zebra = gc_x.
  gs_layout-stylefname = 'STYLE'.
  gs_layout-sel_mode = gc_a.
  gs_variant-report = sy-repid.
  gs_variant-handle = gc_layout_item.

  APPEND cl_gui_alv_grid=>mc_fc_loc_append_row TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_copy TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_cut TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO gt_exclude.
  APPEND cl_gui_alv_grid=>mc_fc_loc_undo TO gt_exclude.
ENDFORM.

FORM check_item_alv CHANGING pv_error TYPE abap_bool.
  DATA lv_valid TYPE c LENGTH 1.
  CLEAR pv_error.
  IF go_grid IS NOT BOUND.
    pv_error = abap_true.
    RETURN.
  ENDIF.
  CALL METHOD go_grid->check_changed_data
    IMPORTING
      e_valid = lv_valid.
  IF lv_valid IS INITIAL.
    pv_error = abap_true.
  ENDIF.
ENDFORM.

FORM refresh_item_alv CHANGING pv_error TYPE abap_bool.
  CLEAR pv_error.
  CHECK go_grid IS BOUND.
  gs_stable-row = gc_x.
  gs_stable-col = gc_x.
  CALL METHOD go_grid->refresh_table_display
    EXPORTING
      is_stable = gs_stable
    EXCEPTIONS
      finished  = 1
      OTHERS    = 2.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-a25 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  CLEAR gv_refresh.
ENDFORM.

FORM handle_toolbar USING po_object TYPE REF TO cl_alv_event_toolbar_set
                          po_sender TYPE REF TO cl_gui_alv_grid.
  DATA ls_button TYPE stb_button.
  CHECK po_sender = go_grid AND po_object IS BOUND.
  DELETE po_object->mt_toolbar WHERE function = gc_tc_sall
                                  OR function = gc_tc_dall.
  ls_button-function = gc_tc_sall.
  ls_button-icon = icon_select_all.
  ls_button-text = TEXT-a21.
  ls_button-quickinfo = TEXT-a21.
  APPEND ls_button TO po_object->mt_toolbar.
  CLEAR ls_button.
  ls_button-function = gc_tc_dall.
  ls_button-icon = icon_deselect_all.
  ls_button-text = TEXT-a22.
  ls_button-quickinfo = TEXT-a22.
  APPEND ls_button TO po_object->mt_toolbar.
ENDFORM.

FORM handle_user_command USING pv_ucomm TYPE sy-ucomm
                               po_sender TYPE REF TO cl_gui_alv_grid.
  DATA lv_error TYPE abap_bool.
  FIELD-SYMBOLS <ls_item> TYPE gty_item.
  CHECK po_sender = go_grid.
  CHECK pv_ucomm = gc_tc_sall OR pv_ucomm = gc_tc_dall.

* ALV 최근 편집값 검증
  PERFORM check_item_alv CHANGING lv_error.
  IF lv_error = abap_true.
    MESSAGE TEXT-a23 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  LOOP AT gt_item ASSIGNING <ls_item>.
    IF pv_ucomm = gc_tc_sall.
      <ls_item>-check = abap_true.
    ELSE.
      <ls_item>-check = abap_false.
    ENDIF.
  ENDLOOP.
  gv_refresh = abap_true.
* 품목 ALV 안정 갱신
  PERFORM refresh_item_alv CHANGING lv_error.
ENDFORM.

FORM free_item_alv.
  IF go_grid IS BOUND.
    CALL METHOD go_grid->free EXCEPTIONS OTHERS = 1.
    FREE go_grid.
  ENDIF.
  IF go_cont IS BOUND.
    CALL METHOD go_cont->free EXCEPTIONS OTHERS = 1.
    FREE go_cont.
  ENDIF.
  CLEAR: gt_fcat, gt_sort, gs_layout, gs_stable, gs_variant, gt_exclude.
  gv_refresh = abap_true.
ENDFORM.


*---------------------------------------------------------------------*
* INITIALIZATION / STATE
*---------------------------------------------------------------------*
FORM init.
  gv_text_langu = sy-langu.
  gv_gewei = gc_kg.
  gv_voleh = gc_m3.
* 화면 라벨 초기화
  PERFORM set_text.
ENDFORM.

FORM capture_state CHANGING ps_state TYPE gty_state.
  ps_state-head = gs_head.
  ps_state-item = gt_item.
  ps_state-source = gt_source.
  ps_state-master = gt_master.
  ps_state-mara = gt_mara.
  ps_state-marm = gt_marm.
  ps_state-price = gt_price.
  ps_state-remark = gt_remark.
ENDFORM.

FORM restore_state USING ps_state TYPE gty_state.
  gs_head = ps_state-head.
  gt_item = ps_state-item.
  gt_source = ps_state-source.
  gt_master = ps_state-master.
  gt_mara = ps_state-mara.
  gt_marm = ps_state-marm.
  gt_price = ps_state-price.
  gt_remark = ps_state-remark.
ENDFORM.

FORM accept_baseline.
  gs_head_old = gs_head.
  gt_item_old = gt_item.
  gt_remark_old = gt_remark.
  CLEAR: gv_changed, gv_force_changed, gv_pack_dirty, gv_calc_error.
  gv_remark_loaded = abap_true.
  gv_remark_invno = gs_head-zinvno.
  gv_remark_push = abap_true.
  gv_refresh = abap_true.
ENDFORM.

FORM get_list CHANGING pv_error TYPE abap_bool.
* 납품문서 및 관련 마스터 조회
  PERFORM load_delivery USING s_vbeln-low abap_true CHANGING pv_error.
  CHECK pv_error IS INITIAL.
  CLEAR gt_remark.
  gv_edit_mode = abap_true.
  gv_list_hide = abap_false.
* 저장 및 조회 기준 버퍼 동기화
  PERFORM accept_baseline.
  gv_draft_head = gs_head.
  gt_draft_item = gt_item.
  gt_draft_remark = gt_remark.
* 문서 목록 재조회
  PERFORM select_inv_overview.
ENDFORM.

*---------------------------------------------------------------------*
* DELIVERY / MASTER / PRICING - 일괄 조회
*---------------------------------------------------------------------*
FORM load_delivery USING pv_vbeln TYPE likp-vbeln
                         pv_calculate TYPE abap_bool
                   CHANGING pv_error TYPE abap_bool.
  CLEAR pv_error.
  SELECT SINGLE vbeln, wadat, kunag, kunnr, lfart, inco1
    FROM likp
    WHERE vbeln = @pv_vbeln AND vstel IN @s_vstel
      AND wadat IN @s_wadat AND kunag IN @s_kunag
      AND kunnr IN @s_kunnr
    INTO @DATA(ls_likp).
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-n01 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  CLEAR: gs_head, gt_item, gt_source, gt_master, gt_mara, gt_marm, gt_price.
  gs_head-vbeln_vl = pv_vbeln.
  gs_head-kunag = ls_likp-kunag.
  gs_head-kunnr = ls_likp-kunnr.
  gs_head-lfart = ls_likp-lfart.
  gs_head-zivh25 = ls_likp-inco1.
  gs_head-zivh15 = sy-datum.
  SELECT SINGLE name1 FROM kna1 WHERE kunnr = @ls_likp-kunag
    INTO @gs_head-customer_name.
  SELECT SINGLE name1, stras, ort01 FROM kna1
    WHERE kunnr = @ls_likp-kunnr INTO @DATA(ls_ship).
  gs_head-zivh01 = ls_ship-name1.
  CONCATENATE ls_ship-name1 ls_ship-stras ls_ship-ort01
    INTO gs_head-zivh02 SEPARATED BY space.
  SELECT SINGLE vtext FROM tvlkt
    WHERE spras = @sy-langu AND lfart = @ls_likp-lfart
    INTO @gs_head-lfart_text.

  SELECT a~posnr, a~matnr, a~werks, a~lfimg, a~vrkme, a~meins,
         a~umvkz, a~umvkn, a~uecha,
         c~vbeln AS vbeln_so, c~posnr AS posnr_so,
         h~waerk, h~knumv, c~zzebeln, c~zzebelp,
         a~arktx AS maktx,
         d~bstkd_e, d~zterm
    FROM lips AS a
    LEFT OUTER JOIN vbap AS c ON c~vbeln = a~vgbel AND c~posnr = a~vgpos
    LEFT OUTER JOIN vbak AS h ON h~vbeln = c~vbeln
    LEFT OUTER JOIN vbkd AS d ON d~vbeln = c~vbeln AND d~posnr = c~posnr
    WHERE a~vbeln = @pv_vbeln
    INTO CORRESPONDING FIELDS OF TABLE @gt_source.
  IF gt_source IS INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-n02 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
* 배치분할 상위 품목을 제외하여 분할 수량 중복 집계 방지
  DATA(lt_all_source) = gt_source.
  LOOP AT lt_all_source INTO DATA(ls_child) WHERE uecha IS NOT INITIAL.
    DELETE gt_source WHERE posnr = ls_child-uecha.
  ENDLOOP.
  IF gt_source IS INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-n02 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  SORT gt_source BY posnr.
  SELECT matnr, spras, maktx FROM makt
    FOR ALL ENTRIES IN @gt_source
    WHERE matnr = @gt_source-matnr AND spras = @sy-langu
    INTO TABLE @DATA(lt_makt).
  SELECT vbeln, posnr, bstkd, zterm FROM vbkd
    FOR ALL ENTRIES IN @gt_source
    WHERE vbeln = @gt_source-vbeln_so AND posnr = @gc_zero_item
    INTO TABLE @DATA(lt_vbkd).
  SELECT * FROM zmmt2011 FOR ALL ENTRIES IN @gt_source
    WHERE matnr = @gt_source-matnr AND werks = @gt_source-werks
    INTO TABLE @gt_master.
  SELECT * FROM mara FOR ALL ENTRIES IN @gt_source
    WHERE matnr = @gt_source-matnr INTO TABLE @gt_mara.
  SELECT * FROM marm FOR ALL ENTRIES IN @gt_source
    WHERE matnr = @gt_source-matnr INTO TABLE @gt_marm.
  IF pv_calculate = abap_true.
    SELECT * FROM prcd_elements FOR ALL ENTRIES IN @gt_source
      WHERE knumv = @gt_source-knumv AND kposn = @gt_source-posnr_so
        AND ( kschl = @gc_zsr1 OR kschl = @gc_zsr2 ) AND kinak = @space
      INTO TABLE @gt_price.
  ENDIF.
  DATA: lt_currency TYPE SORTED TABLE OF waerk WITH UNIQUE KEY table_line,
        lt_zterm TYPE SORTED TABLE OF dzterm WITH UNIQUE KEY table_line,
        lt_payer TYPE SORTED TABLE OF kunnr WITH UNIQUE KEY table_line.
* 기존 요구사항의 PY/Payer 의미를 내부 파트너 코드 RG로 적용
  SELECT vbeln, kunnr FROM vbpa FOR ALL ENTRIES IN @gt_source
    WHERE vbeln = @gt_source-vbeln_so AND posnr = @gc_zero_item
      AND parvw = @gc_rg INTO TABLE @DATA(lt_partner).
  LOOP AT gt_source ASSIGNING FIELD-SYMBOL(<src>).
    READ TABLE lt_makt INTO DATA(ls_makt) WITH KEY matnr = <src>-matnr.
    IF sy-subrc = 0.
      <src>-maktx = ls_makt-maktx.
    ENDIF.
    READ TABLE lt_vbkd INTO DATA(ls_vbkd) WITH KEY vbeln = <src>-vbeln_so.
    IF sy-subrc = 0.
      IF <src>-bstkd_e IS INITIAL.
        <src>-bstkd_e = ls_vbkd-bstkd.
      ENDIF.
      IF <src>-zterm IS INITIAL.
        <src>-zterm = ls_vbkd-zterm.
      ENDIF.
    ENDIF.
    IF <src>-waerk IS NOT INITIAL.
      INSERT <src>-waerk INTO TABLE lt_currency.
    ENDIF.
    IF <src>-zterm IS NOT INITIAL.
      INSERT <src>-zterm INTO TABLE lt_zterm.
    ENDIF.
    READ TABLE lt_partner INTO DATA(ls_partner) WITH KEY vbeln = <src>-vbeln_so.
    IF sy-subrc = 0.
      INSERT ls_partner-kunnr INTO TABLE lt_payer.
    ENDIF.
    DATA(ls_item) = CORRESPONDING gty_item( <src> ).
    ls_item-zivi01 = <src>-lfimg.
    ls_item-meins = <src>-vrkme.
    ls_item-wadat = ls_likp-wadat.
    ls_item-gewei = gc_kg.
    ls_item-voleh = gc_m3.
    IF pv_calculate = abap_true.
* 기본단위 환산 및 품목 금액 중량 계산
      PERFORM calculate_item CHANGING ls_item pv_error.
      IF pv_error = abap_true.
        RETURN.
      ENDIF.
    ENDIF.
    APPEND ls_item TO gt_item.
  ENDLOOP.
  IF lines( lt_currency ) > 1 OR lt_currency IS INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-e13 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  READ TABLE lt_currency INTO gs_head-waerk INDEX 1.
  IF lines( lt_zterm ) = 1.
    READ TABLE lt_zterm INTO gs_head-zivh22 INDEX 1.
  ENDIF.
  IF lines( lt_payer ) = 1.
    READ TABLE lt_payer INTO DATA(lv_payer) INDEX 1.
    SELECT SINGLE name1 FROM kna1 WHERE kunnr = @lv_payer
      INTO @gs_head-zivh03.
  ELSEIF lt_payer IS INITIAL.
    gs_head-zivh03 = gs_head-customer_name.
  ENDIF.
* 복수 지급조건/지급처는 임의 첫 행을 선택하지 않고 필수 입력으로 남김
* 구매품목 기준 참조 송장 조회
  PERFORM get_import_invno CHANGING gs_head-import_invno.
  IF pv_calculate = abap_true.
* 품목 합계의 헤더 반영
    PERFORM calc_header_totals CHANGING pv_error.
  ENDIF.
ENDFORM.

FORM get_import_invno CHANGING pv_invno TYPE awkey.
  CLEAR pv_invno.
  DATA(lt_po) = gt_source.
  DELETE lt_po WHERE zzebeln IS INITIAL.
  CHECK lt_po IS NOT INITIAL.
  SELECT belnr FROM zmmt2200 FOR ALL ENTRIES IN @lt_po
    WHERE ebeln = @lt_po-zzebeln AND ebelp = @lt_po-zzebelp
    INTO TABLE @DATA(lt_belnr).
  SORT lt_belnr BY belnr.
  DELETE ADJACENT DUPLICATES FROM lt_belnr COMPARING belnr.
  DATA lv_text TYPE string.
  LOOP AT lt_belnr INTO DATA(ls_belnr) WHERE belnr IS NOT INITIAL.
    IF lv_text IS INITIAL.
      lv_text = ls_belnr-belnr.
    ELSE.
      lv_text = |{ lv_text }, { ls_belnr-belnr }|.
    ENDIF.
  ENDLOOP.
  pv_invno = lv_text.
ENDFORM.

*---------------------------------------------------------------------*
* UNIT / AMOUNT - 오류를 반환하지 않는 CM 단위 메서드 대신 검증형 환산
*---------------------------------------------------------------------*
FORM unit_to_base USING ps_src TYPE gty_source pv_unit TYPE meins
                  CHANGING pv_factor TYPE decfloat34 pv_error TYPE abap_bool.
  CLEAR: pv_error, pv_factor.
  READ TABLE gt_mara INTO DATA(ls_mara) WITH KEY matnr = ps_src-matnr.
  IF sy-subrc <> 0 OR pv_unit IS INITIAL.
    pv_error = abap_true.
  ELSEIF pv_unit = ls_mara-meins.
    pv_factor = 1.
  ELSEIF pv_unit = ps_src-vrkme AND ps_src-meins = ls_mara-meins
     AND ps_src-umvkz > 0 AND ps_src-umvkn > 0.
    pv_factor = CONV decfloat34( ps_src-umvkz ) / ps_src-umvkn.
  ELSE.
    READ TABLE gt_marm INTO DATA(ls_marm)
      WITH KEY matnr = ps_src-matnr meinh = pv_unit.
    IF sy-subrc = 0 AND ls_marm-umrez > 0 AND ls_marm-umren > 0.
      pv_factor = CONV decfloat34( ls_marm-umrez ) / ls_marm-umren.
    ELSE.
      pv_error = abap_true.
    ENDIF.
  ENDIF.
  IF pv_error = abap_true.
    MESSAGE TEXT-n03 TYPE gc_s DISPLAY LIKE gc_e.
  ENDIF.
ENDFORM.

FORM convert_physical USING pv_from TYPE msehi pv_to TYPE msehi
                      CHANGING pv_value TYPE decfloat34 pv_error TYPE abap_bool.
  DATA: lv_in TYPE p LENGTH 16 DECIMALS 10,
        lv_out TYPE p LENGTH 16 DECIMALS 10.
  CLEAR pv_error.
  CHECK pv_value <> 0.
  IF pv_from IS INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-n03 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  CHECK pv_from <> pv_to.
  lv_in = pv_value.
  CALL FUNCTION 'UNIT_CONVERSION_SIMPLE'
    EXPORTING input = lv_in unit_in = pv_from unit_out = pv_to
    IMPORTING output = lv_out
    EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-n03 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  pv_value = lv_out.
ENDFORM.

FORM calculate_item CHANGING ps_item TYPE gty_item pv_error TYPE abap_bool.
  DATA: lv_factor TYPE decfloat34, lv_price_factor TYPE decfloat34,
        lv_baseqty TYPE decfloat34, lv_net TYPE decfloat34,
        lv_gross TYPE decfloat34, lv_volume TYPE decfloat34,
        lv_box TYPE decfloat34, lv_external TYPE zcl_cm_util=>ty_dec31_14,
        lv_internal TYPE zcl_cm_util=>ty_dec31_14, lv_price TYPE decfloat34,
        lv_amount TYPE zcl_cm_util=>ty_dec31_14,
        ls_condition TYPE prcd_elements.
  CLEAR: pv_error, ps_item-message, ps_item-calc_failed.
  READ TABLE gt_source INTO DATA(ls_src) WITH KEY posnr = ps_item-posnr.
  IF sy-subrc <> 0 OR ps_item-zivi01 < 0.
    pv_error = abap_true.
    MESSAGE TEXT-n04 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  TRY.
* 자재 기본단위 환산계수 확인
      PERFORM unit_to_base USING ls_src ps_item-meins CHANGING lv_factor pv_error.
      CHECK pv_error IS INITIAL.
      lv_baseqty = ps_item-zivi01 * lv_factor.
      READ TABLE gt_mara INTO DATA(ls_mara) WITH KEY matnr = ps_item-matnr.
      READ TABLE gt_master INTO DATA(ls_master)
        WITH KEY matnr = ps_item-matnr werks = ps_item-werks.
      CLEAR: ps_item-zivi04, ps_item-zivi05, ps_item-zivi06.
      IF sy-subrc <> 0.
        ps_item-message = TEXT-w01.
        CLEAR: ps_item-zivi02, ps_item-zivi03.
      ELSE.
        lv_net = ls_master-ntgew * lv_baseqty.
        lv_gross = ls_master-brgew * lv_baseqty.
        lv_volume = ls_master-volum * lv_baseqty.
* 중량 및 체적 표시단위 환산
        PERFORM convert_physical USING ls_mara-gewei gc_kg
          CHANGING lv_net pv_error.
        CHECK pv_error IS INITIAL.
* 중량 및 체적 표시단위 환산
        PERFORM convert_physical USING ls_mara-gewei gc_kg
          CHANGING lv_gross pv_error.
        CHECK pv_error IS INITIAL.
* 중량 및 체적 표시단위 환산
        PERFORM convert_physical USING ls_mara-voleh gc_m3
          CHANGING lv_volume pv_error.
        CHECK pv_error IS INITIAL.
        ps_item-zivi04 = lv_net.
        ps_item-zivi05 = lv_gross.
        ps_item-zivi06 = lv_volume.
        IF ps_item-zpkgno IS INITIAL.
          TRY.
              lv_box = ls_master-box.
            CATCH cx_sy_conversion_no_number cx_sy_conversion_overflow.
              CLEAR lv_box.
          ENDTRY.
          IF lv_box > 0 AND lv_box = trunc( lv_box ) AND lv_box <= 2147483647.
            ps_item-zivi02 = lv_box.
          ELSE.
            CLEAR ps_item-zivi02.
          ENDIF.
        ENDIF.
        IF ps_item-zivi02 > 0.
          ps_item-zivi03 = ceil( lv_baseqty / ps_item-zivi02 ).
        ELSE.
          CLEAR ps_item-zivi03.
          ps_item-message = TEXT-w02.
        ENDIF.
      ENDIF.
      ps_item-gewei = gc_kg.
      ps_item-voleh = gc_m3.
      IF ps_item-zpkgno IS INITIAL.
*       ZSR2 우선. 동일 조건 다중 활성 행은 임의 선택하지 않음
        DATA(lt_cond) = gt_price.
        DELETE lt_cond WHERE knumv <> ls_src-knumv OR kposn <> ls_src-posnr_so.
        READ TABLE lt_cond TRANSPORTING NO FIELDS WITH KEY kschl = gc_zsr2.
        IF sy-subrc = 0.
          DELETE lt_cond WHERE kschl <> gc_zsr2.
        ELSE.
          DELETE lt_cond WHERE kschl <> gc_zsr1.
        ENDIF.
        IF lines( lt_cond ) <> 1.
          pv_error = abap_true.
          MESSAGE TEXT-n05 TYPE gc_s DISPLAY LIKE gc_e.
          RETURN.
        ENDIF.
        READ TABLE lt_cond INTO ls_condition INDEX 1.
        IF ls_condition-waers <> ps_item-waerk OR ls_condition-krech <> 'C'.
          pv_error = abap_true.
          MESSAGE TEXT-n06 TYPE gc_s DISPLAY LIKE gc_e.
          RETURN.
        ENDIF.
        IF ls_condition-kpein = 0.
          ls_condition-kpein = 1.
        ENDIF.
* 자재 기본단위 환산계수 확인
        PERFORM unit_to_base USING ls_src ls_condition-kmein
          CHANGING lv_price_factor pv_error.
        CHECK pv_error IS INITIAL.
*       CM 내부->외부 표현 변환. 환율 환산 아님
        lv_internal = ls_condition-kbetr.
        zcl_cm_util=>conv_curr(
          EXPORTING i_in = space i_currency = ps_item-waerk i_amount = lv_internal
          IMPORTING e_amount = lv_external ).
        lv_price = CONV decfloat34( lv_external ) / ls_condition-kpein
                   * lv_factor / lv_price_factor.
        ps_item-netpr = lv_price.
      ENDIF.
*     NETPR는 외부 단가(DEC), NETWR는 SAP 내부 금액(CURR)
      lv_amount = ps_item-zivi01 * ps_item-netpr.
      zcl_cm_util=>conv_curr(
        EXPORTING i_in = abap_true i_currency = ps_item-waerk i_amount = lv_amount
        IMPORTING e_amount = lv_internal ).
      ps_item-netwr = lv_internal.
    CATCH cx_sy_arithmetic_error cx_sy_conversion_error.
      pv_error = abap_true.
      MESSAGE TEXT-n07 TYPE gc_s DISPLAY LIKE gc_e.
  ENDTRY.
ENDFORM.

FORM calc_header_totals CHANGING pv_error TYPE abap_bool.
  DATA: lv_amount TYPE decfloat34, lv_net TYPE decfloat34,
        lv_gross TYPE decfloat34, lv_volume TYPE decfloat34.
  CLEAR pv_error.
  TRY.
      LOOP AT gt_item INTO DATA(ls_item).
        IF ls_item-waerk <> gs_head-waerk.
          pv_error = abap_true.
          MESSAGE TEXT-e13 TYPE gc_s DISPLAY LIKE gc_e.
          RETURN.
        ENDIF.
        lv_amount = lv_amount + ls_item-netwr.
        lv_net = lv_net + ls_item-zivi04.
        lv_gross = lv_gross + ls_item-zivi05.
        lv_volume = lv_volume + ls_item-zivi06.
      ENDLOOP.
      gs_head-total_amount = lv_amount.
      gs_head-zivh13 = lv_net.
      gs_head-zivh21 = lv_gross.
      gs_head-zivh27 = lv_volume.
    CATCH cx_sy_arithmetic_error cx_sy_conversion_error.
      pv_error = abap_true.
      MESSAGE TEXT-n07 TYPE gc_s DISPLAY LIKE gc_e.
  ENDTRY.
ENDFORM.

*---------------------------------------------------------------------*
* SAVED DOCUMENT / OVERVIEW / COPY
*---------------------------------------------------------------------*
FORM load_saved_invoice USING pv_invno TYPE zsdt0060-zinvno
                        CHANGING pv_error TYPE abap_bool.
  DATA: ls_before TYPE gty_state, lv_total TYPE decfloat34,
        lt_remark TYPE gty_t_remark.
  CLEAR pv_error.
* 현재 문서 임시 보관
  PERFORM capture_state CHANGING ls_before.
  SELECT SINGLE * FROM zsdt0060 WHERE zinvno = @pv_invno INTO @DATA(ls_db).
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-n08 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  SELECT * FROM zsdt0061 WHERE zinvno = @pv_invno INTO TABLE @DATA(lt_saved).
  DATA(lv_calc) = xsdbool( lt_saved IS INITIAL ).
* 납품문서 및 관련 마스터 조회
  PERFORM load_delivery USING ls_db-vbeln_vl lv_calc CHANGING pv_error.
  IF pv_error IS INITIAL.
    IF lt_saved IS NOT INITIAL.
      DATA(lt_template) = gt_item.
      CLEAR gt_item.
      SORT lt_saved BY zpkgno matnr.
      LOOP AT lt_saved INTO DATA(ls_saved).
        READ TABLE lt_template INTO DATA(ls_item)
          WITH KEY posnr = ls_saved-posnr matnr = ls_saved-matnr.
        IF sy-subrc <> 0 OR ( ls_saved-vbeln_vl IS NOT INITIAL
                           AND ls_saved-vbeln_vl <> ls_db-vbeln_vl ).
          pv_error = abap_true.
          MESSAGE TEXT-n09 TYPE gc_s DISPLAY LIKE gc_e.
          EXIT.
        ENDIF.
        ls_item-zpkgno = ls_saved-zpkgno.
        ls_item-zivi01 = ls_saved-zivi01.
        ls_item-zivi02 = ls_saved-zivi02.
        ls_item-zivi03 = ls_saved-zivi03.
        ls_item-zivi04 = ls_saved-zivi04.
        ls_item-zivi05 = ls_saved-zivi05.
        ls_item-zivi06 = ls_saved-zivi06.
        ls_item-netpr = ls_saved-netpr.
        ls_item-netwr = ls_saved-netwr.
        IF ls_saved-meins IS NOT INITIAL.
          ls_item-meins = ls_saved-meins.
        ENDIF.
        IF ls_saved-waers IS NOT INITIAL.
          ls_item-waerk = ls_saved-waers.
        ENDIF.
        IF gt_item IS INITIAL.
          gs_head-waerk = ls_item-waerk.
        ELSEIF gs_head-waerk <> ls_item-waerk.
          pv_error = abap_true.
          MESSAGE TEXT-e13 TYPE gc_s DISPLAY LIKE gc_e.
          EXIT.
        ENDIF.
        lv_total = lv_total + ls_item-netwr.
        APPEND ls_item TO gt_item.
      ENDLOOP.
      TRY.
          gs_head-total_amount = lv_total.
        CATCH cx_sy_conversion_error.
          pv_error = abap_true.
      ENDTRY.
    ENDIF.
  ENDIF.
  IF pv_error IS INITIAL.
* 저장 장문 조회
    PERFORM read_shipping_remark USING pv_invno CHANGING lt_remark pv_error.
  ENDIF.
  IF pv_error = abap_true.
* 조회 실패 시 기존 문서 복원
    PERFORM restore_state USING ls_before.
    RETURN.
  ENDIF.
* DB 저장 헤더를 덮어써 Copy 보존 중량/체적을 재집계하지 않음
  MOVE-CORRESPONDING ls_db TO gs_head.
  gt_remark = lt_remark.
ENDFORM.

FORM select_inv_overview.
  CLEAR gt_overview.
  SELECT h~zinvno, h~vbeln_vl, h~zivh15, k~name1 AS customer_name, h~zivh28
    FROM zsdt0060 AS h
    INNER JOIN likp AS l ON l~vbeln = h~vbeln_vl
    LEFT OUTER JOIN kna1 AS k ON k~kunnr = l~kunag
    WHERE l~vstel IN @s_vstel AND l~wadat IN @s_wadat
      AND l~kunag IN @s_kunag AND l~kunnr IN @s_kunnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_overview.
  IF gt_overview IS NOT INITIAL.
*   FAE 중복 제거로 동액 품목이 사라지지 않도록 전체 품목 키 포함
    SELECT i~zinvno, i~zpkgno, i~matnr, i~waers, i~netwr,
           h~waerk AS source_currency
      FROM zsdt0061 AS i
      LEFT OUTER JOIN lips AS l ON l~vbeln = i~vbeln_vl AND l~posnr = i~posnr
      LEFT OUTER JOIN vbak AS h ON h~vbeln = l~vgbel
      FOR ALL ENTRIES IN @gt_overview WHERE i~zinvno = @gt_overview-zinvno
      INTO TABLE @DATA(lt_sum).
    LOOP AT gt_overview ASSIGNING FIELD-SYMBOL(<inv>).
      DATA(lv_mixed) = abap_false.
      TRY.
          LOOP AT lt_sum INTO DATA(ls_sum) WHERE zinvno = <inv>-zinvno.
            IF ls_sum-waers IS INITIAL.
              ls_sum-waers = ls_sum-source_currency.
            ENDIF.
            IF ls_sum-waers IS INITIAL.
              lv_mixed = abap_true.
            ENDIF.
            IF <inv>-waerk IS INITIAL.
              <inv>-waerk = ls_sum-waers.
            ELSEIF <inv>-waerk <> ls_sum-waers.
              lv_mixed = abap_true.
            ENDIF.
            <inv>-total_amount = <inv>-total_amount + ls_sum-netwr.
          ENDLOOP.
        CATCH cx_sy_arithmetic_error cx_sy_conversion_error.
          lv_mixed = abap_true.
      ENDTRY.
      IF lv_mixed = abap_true.
        CLEAR: <inv>-total_amount, <inv>-waerk.
      ENDIF.
    ENDLOOP.
  ENDIF.
  SORT gt_overview BY zivh15 DESCENDING zinvno DESCENDING.
  IF go_inv_grid IS BOUND.
    go_inv_grid->refresh_table_display( is_stable = VALUE #( row = abap_true col = abap_true ) ).
  ENDIF.
ENDFORM.

FORM set_overview.
  IF go_inv_cont IS NOT BOUND.
    CREATE OBJECT go_inv_cont EXPORTING container_name = 'CC_INV'.
    CREATE OBJECT go_inv_grid EXPORTING i_parent = go_inv_cont.
    zcl_cm_util=>table_to_fieldcatalog(
      EXPORTING it_tab = gt_overview
      RECEIVING rt_fieldcatalog = gt_inv_fcat
      EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc <> 0.
      MESSAGE TEXT-a24 TYPE gc_s DISPLAY LIKE gc_e.
      RETURN.
    ENDIF.
    LOOP AT gt_inv_fcat ASSIGNING FIELD-SYMBOL(<fc>).
      CASE <fc>-fieldname.
        WHEN 'ZINVNO'. <fc>-coltext = TEXT-h15.
        WHEN 'VBELN_VL'. <fc>-coltext = TEXT-h11.
        WHEN 'ZIVH15'. <fc>-coltext = TEXT-h16.
        WHEN 'CUSTOMER_NAME'. <fc>-coltext = TEXT-h01.
        WHEN 'TOTAL_AMOUNT'.
          <fc>-coltext = TEXT-h12.
          <fc>-cfieldname = 'WAERK'.
          <fc>-no_zero = abap_true.
        WHEN 'WAERK'. <fc>-coltext = TEXT-a18.
        WHEN 'ZIVH28'. <fc>-coltext = TEXT-h13.
      ENDCASE.
    ENDLOOP.
    gs_inv_layout-zebra = abap_true.
    gs_inv_layout-cwidth_opt = abap_true.
    gs_inv_layout-no_toolbar = abap_true.
    SET HANDLER lcl_event=>double_click FOR go_inv_grid.
    go_inv_grid->set_table_for_first_display(
      EXPORTING is_layout = gs_inv_layout
      CHANGING it_outtab = gt_overview it_fieldcatalog = gt_inv_fcat ).
  ENDIF.
  go_inv_cont->set_visible( xsdbool( gv_list_hide = abap_false ) ).
ENDFORM.

FORM open_invoice CHANGING pv_error TYPE abap_bool.
  CLEAR pv_error.
  CHECK gv_pending_invno IS NOT INITIAL.
  IF gv_changed = abap_true.
    DATA(lv_answer) = zcl_cm_util=>popup_to_confirm(
      i_text_question = TEXT-q01 i_display_cancel_button = abap_true ).
    CHECK lv_answer = gc_yes.
  ENDIF.
* 저장 헤더 및 패킹 품목 조회
  PERFORM load_saved_invoice USING gv_pending_invno CHANGING pv_error.
  CHECK pv_error IS INITIAL.
* 새 문서 조회 성공 후 기존 잠금 해제
* 보유 문서 잠금 해제
  PERFORM unlock_invoice.
  gv_edit_mode = abap_false.
* 저장 및 조회 기준 버퍼 동기화
  PERFORM accept_baseline.
  CLEAR gv_pending_invno.
ENDFORM.

FORM copy_header_data CHANGING pv_error TYPE abap_bool.
  DATA ls_before TYPE gty_state.
  CLEAR pv_error.
  IF gs_head-zinvno IS INITIAL OR gv_changed = abap_true.
    pv_error = abap_true.
    MESSAGE TEXT-n10 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
* 현재 문서 임시 보관
  PERFORM capture_state CHANGING ls_before.
  CLEAR: gt_pop_deliv, gv_pop_vbeln, gv_pop_pick.
  SELECT vbeln, wadat, kunag, kunnr FROM likp
    WHERE vstel IN @s_vstel AND wadat IN @s_wadat
      AND kunag IN @s_kunag AND kunnr IN @s_kunnr
      AND kunnr = @gs_head-kunnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_pop_deliv.
  IF gt_pop_deliv IS NOT INITIAL.
    SELECT vbeln, posnr FROM lips FOR ALL ENTRIES IN @gt_pop_deliv
      WHERE vbeln = @gt_pop_deliv-vbeln INTO TABLE @DATA(lt_lips).
    SELECT vbeln_vl, zinvno FROM zsdt0060 FOR ALL ENTRIES IN @gt_pop_deliv
      WHERE vbeln_vl = @gt_pop_deliv-vbeln INTO TABLE @DATA(lt_inv).
    LOOP AT gt_pop_deliv ASSIGNING FIELD-SYMBOL(<pop>).
      LOOP AT lt_lips TRANSPORTING NO FIELDS WHERE vbeln = <pop>-vbeln.
        <pop>-item_cnt = <pop>-item_cnt + 1.
      ENDLOOP.
      LOOP AT lt_inv TRANSPORTING NO FIELDS WHERE vbeln_vl = <pop>-vbeln.
        <pop>-inv_cnt = <pop>-inv_cnt + 1.
      ENDLOOP.
    ENDLOOP.
  ENDIF.
  CALL SCREEN 0200 STARTING AT 10 5 ENDING AT 130 27.
* 팝업 컨트롤 해제
  PERFORM free_popup.
  CHECK gv_pop_vbeln IS NOT INITIAL.
  SELECT SINGLE kunnr FROM likp WHERE vbeln = @gv_pop_vbeln INTO @DATA(lv_ship).
  IF sy-subrc <> 0 OR lv_ship <> ls_before-head-kunnr.
    pv_error = abap_true.
    MESSAGE TEXT-n11 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
* 납품문서 및 관련 마스터 조회
  PERFORM load_delivery USING gv_pop_vbeln abap_true CHANGING pv_error.
  IF pv_error = abap_true.
* 조회 실패 시 기존 문서 복원
    PERFORM restore_state USING ls_before.
    RETURN.
  ENDIF.
  DATA(ls_new_head) = gs_head.
* MD v3: Invoice 번호/Delivery/금액만 교체, 주소/Import/중량/장문 유지
  gs_head = ls_before-head.
  CLEAR: gs_head-zinvno, gs_head-erdat, gs_head-erzet, gs_head-ernam,
         gs_head-aedat, gs_head-aezet, gs_head-aenam.
  gs_head-vbeln_vl = ls_new_head-vbeln_vl.
  gs_head-lfart = ls_new_head-lfart.
  gs_head-lfart_text = ls_new_head-lfart_text.
  gs_head-total_amount = ls_new_head-total_amount.
  gs_head-waerk = ls_new_head-waerk.
  gt_remark = ls_before-remark.
* 보유 문서 잠금 해제
  PERFORM unlock_invoice.
  gv_edit_mode = abap_true.
* 저장 및 조회 기준 버퍼 동기화
  PERFORM accept_baseline.
  gv_force_changed = abap_true.
  gv_changed = abap_true.
  gv_draft_head = gs_head.
  gt_draft_item = gt_item.
  gt_draft_remark = gt_remark.
  MESSAGE TEXT-n12 TYPE gc_s.
ENDFORM.

FORM set_popup.
  DATA: lt_fcat TYPE lvc_t_fcat, ls_layout TYPE lvc_s_layo.
  CHECK go_pop_grid IS NOT BOUND.
  CREATE OBJECT go_pop_cont EXPORTING container_name = 'CC_POP'.
  CREATE OBJECT go_pop_grid EXPORTING i_parent = go_pop_cont.
  zcl_cm_util=>table_to_fieldcatalog(
    EXPORTING it_tab = gt_pop_deliv RECEIVING rt_fieldcatalog = lt_fcat
    EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc <> 0.
    MESSAGE TEXT-a24 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  LOOP AT lt_fcat ASSIGNING FIELD-SYMBOL(<fc>).
    CASE <fc>-fieldname.
      WHEN 'VBELN'. <fc>-coltext = TEXT-h11.
      WHEN 'WADAT'. <fc>-coltext = TEXT-s02.
      WHEN 'KUNAG'. <fc>-coltext = TEXT-s03.
      WHEN 'KUNNR'. <fc>-coltext = TEXT-s04.
      WHEN 'ITEM_CNT'. <fc>-coltext = TEXT-p01.
      WHEN 'INV_CNT'. <fc>-coltext = TEXT-p02.
    ENDCASE.
  ENDLOOP.
  ls_layout-sel_mode = 'B'.
  ls_layout-zebra = abap_true.
  ls_layout-cwidth_opt = abap_true.
  SET HANDLER lcl_event=>double_click FOR go_pop_grid.
  go_pop_grid->set_table_for_first_display(
    EXPORTING is_layout = ls_layout
    CHANGING it_outtab = gt_pop_deliv it_fieldcatalog = lt_fcat ).
ENDFORM.

FORM free_popup.
  IF go_pop_grid IS BOUND.
    go_pop_grid->free( ).
    FREE go_pop_grid.
  ENDIF.
  IF go_pop_cont IS BOUND.
    go_pop_cont->free( ).
    FREE go_pop_cont.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
* LOCK / NUMBER RANGE / SAVE
*---------------------------------------------------------------------*
FORM lock_invoice USING pv_invno TYPE zsdt0060-zinvno
                  CHANGING pv_error TYPE abap_bool.
  CLEAR pv_error.
  CHECK pv_invno IS NOT INITIAL.
  CHECK gv_locked_invno <> pv_invno.
  CALL FUNCTION 'ENQUEUE_EZ_ZSDT0060'
    EXPORTING mandt = sy-mandt zinvno = pv_invno _scope = '1'
    EXCEPTIONS foreign_lock = 1 system_failure = 2 OTHERS = 3.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-n13 TYPE gc_s DISPLAY LIKE gc_e.
  ELSE.
    gv_locked_invno = pv_invno.
  ENDIF.
ENDFORM.

FORM unlock_invoice.
  CHECK gv_locked_invno IS NOT INITIAL.
  CALL FUNCTION 'DEQUEUE_EZ_ZSDT0060'
    EXPORTING mandt = sy-mandt zinvno = gv_locked_invno _scope = '1'.
  CLEAR gv_locked_invno.
ENDFORM.

FORM numbering_key CHANGING pv_subobject TYPE inri-subobject
                            pv_error TYPE abap_bool.
  DATA: lv_name TYPE kna1-name4, lv_org TYPE likp-vkorg,
        lv_code TYPE char1.
  CLEAR: pv_subobject, pv_error.
  SELECT SINGLE name4 FROM kna1 WHERE kunnr = @gs_head-kunnr INTO @lv_name.
  CONDENSE lv_name NO-GAPS.
  TRANSLATE lv_name TO UPPER CASE.
  IF strlen( lv_name ) < 3.
    pv_error = abap_true.
    MESSAGE TEXT-n14 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  SELECT SINGLE vkorg FROM likp WHERE vbeln = @gs_head-vbeln_vl INTO @lv_org.
  CASE lv_org.
    WHEN '1000'. lv_code = 'A'.
    WHEN '2200'. lv_code = 'S'.
    WHEN '2300'. lv_code = 'P'.
    WHEN '2600'. lv_code = 'K'.
    WHEN OTHERS.
      pv_error = abap_true.
      MESSAGE TEXT-n15 TYPE gc_s DISPLAY LIKE gc_e.
      RETURN.
  ENDCASE.
  CONCATENATE lv_name(3) lv_code INTO pv_subobject.
ENDFORM.

FORM ensure_number_interval USING pv_subobject TYPE inri-subobject
                                  pv_year TYPE inri-toyear
                            CHANGING pv_error TYPE abap_bool.
  DATA: ls_sub TYPE zsdt0062, ls_interval TYPE inriv,
        lt_interval TYPE STANDARD TABLE OF inriv,
        lt_error TYPE STANDARD TABLE OF inriv,
        lv_error TYPE abap_bool.
  CLEAR pv_error.
* 번호 구간 준비만 별도 LUW. 이 FORM 이전에는 업무 DB 변경 금지
  CALL FUNCTION 'NUMBER_RANGE_ENQUEUE'
    EXPORTING object = gc_nr_object
    EXCEPTIONS OTHERS = 1.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-n16 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  TRY.
      SELECT SINGLE * FROM zsdt0062 WHERE subobject = @pv_subobject INTO @ls_sub.
      IF sy-subrc <> 0.
        ls_sub-mandt = sy-mandt.
        ls_sub-subobject = pv_subobject.
        ls_sub-erdat = sy-datum.
        ls_sub-erzet = sy-uzeit.
        ls_sub-ernam = sy-uname.
        INSERT zsdt0062 FROM @ls_sub.
        IF sy-subrc <> 0.
          pv_error = abap_true.
        ENDIF.
      ENDIF.
      IF pv_error IS INITIAL.
*       잠금 후 재확인하여 다른 세션에서 생성한 기존 구간 보존
        SELECT SINGLE * FROM nriv
          WHERE object = @gc_nr_object AND subobject = @pv_subobject
            AND nrrangenr = @gc_nr_range AND toyear = @pv_year
          INTO @DATA(ls_nriv).
        IF sy-subrc <> 0.
          ls_interval-subobject = pv_subobject.
          ls_interval-nrrangenr = gc_nr_range.
          ls_interval-toyear = pv_year.
          ls_interval-fromnumber = '00000000000000000001'.
          ls_interval-tonumber = '00000000000000009999'.
          ls_interval-nrlevel = 0.
          ls_interval-procind = 'I'.
          APPEND ls_interval TO lt_interval.
          CALL FUNCTION 'NUMBER_RANGE_INTERVAL_UPDATE'
            EXPORTING object = gc_nr_object subobject = pv_subobject
            IMPORTING error_occured = lv_error
            TABLES interval = lt_interval error_iv = lt_error
            EXCEPTIONS OTHERS = 1.
          IF sy-subrc <> 0 OR lv_error = abap_true OR lt_error IS NOT INITIAL.
            pv_error = abap_true.
          ELSE.
            CALL FUNCTION 'NUMBER_RANGE_UPDATE_CLOSE'
              EXPORTING object = gc_nr_object
              EXCEPTIONS OTHERS = 1.
            IF sy-subrc <> 0.
              pv_error = abap_true.
            ENDIF.
          ENDIF.
        ELSEIF ls_nriv-externind = abap_true
           OR ls_nriv-fromnumber <> '00000000000000000001'
           OR ls_nriv-tonumber <> '00000000000000009999'.
          pv_error = abap_true.
        ENDIF.
      ENDIF.
    CATCH cx_sy_open_sql_db.
      pv_error = abap_true.
  ENDTRY.
  IF pv_error = abap_true.
    ROLLBACK WORK.
    CALL FUNCTION 'NUMBER_RANGE_UPDATE_INIT'
      EXPORTING object = gc_nr_object EXCEPTIONS OTHERS = 1.
  ELSE.
    COMMIT WORK AND WAIT.
    IF sy-subrc <> 0.
      pv_error = abap_true.
    ENDIF.
  ENDIF.
  CALL FUNCTION 'NUMBER_RANGE_DEQUEUE'
    EXPORTING object = gc_nr_object EXCEPTIONS OTHERS = 1.
* 저장된 실제 구간 확인. 메모리 갱신만으로 성공 처리하지 않음
  IF pv_error IS INITIAL.
    SELECT SINGLE nrrangenr FROM nriv
      WHERE object = @gc_nr_object AND subobject = @pv_subobject
        AND nrrangenr = @gc_nr_range AND toyear = @pv_year
      INTO @DATA(lv_range).
    IF sy-subrc <> 0.
      pv_error = abap_true.
    ENDIF.
  ENDIF.
  IF pv_error = abap_true.
    MESSAGE TEXT-n16 TYPE gc_s DISPLAY LIKE gc_e.
  ENDIF.
ENDFORM.

FORM next_invoice_number CHANGING pv_invno TYPE zsdt0060-zinvno
                                  pv_error TYPE abap_bool.
  DATA: lv_subobject TYPE inri-subobject, lv_year TYPE inri-toyear,
        lv_number TYPE inri-nrlevel, lv_short TYPE n LENGTH 4,
        lv_rc TYPE inri-returncode.
  CLEAR: pv_invno, pv_error.
  lv_year = sy-datum(4).
* 신규 채번 접두어 및 영업조직 검증
  PERFORM numbering_key CHANGING lv_subobject pv_error.
  CHECK pv_error IS INITIAL.
* 없는 연도별 번호 구간 준비
  PERFORM ensure_number_interval USING lv_subobject lv_year CHANGING pv_error.
  CHECK pv_error IS INITIAL.
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING object = gc_nr_object subobject = lv_subobject
              nr_range_nr = gc_nr_range toyear = lv_year
    IMPORTING number = lv_number returncode = lv_rc
    EXCEPTIONS interval_overflow = 1 OTHERS = 2.
  IF sy-subrc <> 0 OR lv_number < 1 OR lv_number > 9999 OR lv_rc = '3'.
    pv_error = abap_true.
    MESSAGE TEXT-n17 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  lv_short = lv_number.
  pv_invno = |{ lv_subobject(3) }-{ lv_subobject+3(1) }-{ lv_year+2(2) }-{ lv_short }|.
ENDFORM.

FORM save_invoice_data CHANGING pv_error TYPE abap_bool.
  DATA: ls_db TYPE zsdt0060, ls_item_db TYPE zsdt0061,
        lt_db TYPE SORTED TABLE OF zsdt0061 WITH UNIQUE KEY mandt zinvno zpkgno matnr,
        lv_invno TYPE zsdt0060-zinvno, lv_new TYPE abap_bool,
        ls_check TYPE zsdt0060, lv_date TYPE d.
  CLEAR pv_error.
  IF gv_edit_mode IS INITIAL OR gv_calc_error = abap_true.
    pv_error = abap_true.
    MESSAGE TEXT-n18 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
* 헤더 필수값 및 코드 검증
  PERFORM check_header_required CHANGING pv_error.
  CHECK pv_error IS INITIAL.
  DO 2 TIMES.
    lv_date = COND #( WHEN sy-index = 1 THEN gs_head-zivh11 ELSE gs_head-zivh19 ).
    IF lv_date IS NOT INITIAL.
      CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
        EXPORTING date = lv_date EXCEPTIONS OTHERS = 1.
      IF sy-subrc <> 0.
        pv_error = abap_true.
        MESSAGE TEXT-r05 TYPE gc_s DISPLAY LIKE gc_e.
        RETURN.
      ENDIF.
    ENDIF.
  ENDDO.
  lv_new = xsdbool( gs_head-zinvno IS INITIAL ).
  IF lv_new = abap_false AND gv_locked_invno <> gs_head-zinvno.
    pv_error = abap_true.
    MESSAGE TEXT-n13 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
* 채번 전에 패킹 키/입력값 검증. 초안 표시 품목은 0061 저장 대상 아님
  IF gv_pack_dirty = abap_true.
    IF gt_item IS INITIAL.
      pv_error = abap_true.
      MESSAGE TEXT-n19 TYPE gc_s DISPLAY LIKE gc_e.
      RETURN.
    ENDIF.
    LOOP AT gt_item INTO DATA(ls_item).
      IF ls_item-zpkgno IS INITIAL OR ls_item-matnr IS INITIAL
         OR ls_item-posnr IS INITIAL OR ls_item-meins IS INITIAL
         OR ls_item-waerk IS INITIAL OR ls_item-zivi01 < 0
         OR ls_item-zivi02 < 0 OR ls_item-zivi03 < 0
         OR ls_item-zivi04 < 0 OR ls_item-zivi05 < 0 OR ls_item-zivi06 < 0.
        pv_error = abap_true.
        EXIT.
      ENDIF.
      ls_item_db = CORRESPONDING #( ls_item ).
      ls_item_db-mandt = sy-mandt.
      ls_item_db-vbeln_vl = gs_head-vbeln_vl.
      ls_item_db-waers = ls_item-waerk.
      INSERT ls_item_db INTO TABLE lt_db.
      IF sy-subrc <> 0.
        pv_error = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF pv_error = abap_true.
      MESSAGE TEXT-n19 TYPE gc_s DISPLAY LIKE gc_e.
      RETURN.
    ENDIF.
  ENDIF.
  lv_invno = gs_head-zinvno.
  IF lv_new = abap_true.
* 신규 송장 번호 채번
    PERFORM next_invoice_number CHANGING lv_invno pv_error.
    CHECK pv_error IS INITIAL.
* 문서 잠금 취득
    PERFORM lock_invoice USING lv_invno CHANGING pv_error.
    CHECK pv_error IS INITIAL.
  ENDIF.
  TRY.
      ls_db = CORRESPONDING #( gs_head ).
      ls_db-mandt = sy-mandt.
      ls_db-zinvno = lv_invno.
      IF lv_new = abap_true.
        ls_db-erdat = sy-datum.
        ls_db-erzet = sy-uzeit.
        ls_db-ernam = sy-uname.
        CLEAR: ls_db-aedat, ls_db-aezet, ls_db-aenam.
*       신규는 INSERT만 허용: 중복 번호로 기존 문서 덮어쓰기 금지
        INSERT zsdt0060 FROM @ls_db.
      ELSE.
        SELECT SINGLE * FROM zsdt0060 WHERE zinvno = @lv_invno INTO @ls_check.
        IF sy-subrc = 0 AND ls_check-vbeln_vl = gs_head-vbeln_vl.
          ls_db-erdat = ls_check-erdat.
          ls_db-erzet = ls_check-erzet.
          ls_db-ernam = ls_check-ernam.
          ls_db-aedat = sy-datum.
          ls_db-aezet = sy-uzeit.
          ls_db-aenam = sy-uname.
          UPDATE zsdt0060 FROM @ls_db.
        ELSE.
          pv_error = abap_true.
        ENDIF.
      ENDIF.
      IF sy-subrc <> 0.
        pv_error = abap_true.
      ENDIF.
      IF pv_error IS INITIAL AND gv_pack_dirty = abap_true.
        SELECT * FROM zsdt0061 WHERE zinvno = @lv_invno INTO TABLE @DATA(lt_old_db).
        DATA lt_insert TYPE STANDARD TABLE OF zsdt0061 WITH EMPTY KEY.
        LOOP AT lt_db INTO ls_item_db.
          ls_item_db-zinvno = lv_invno.
          READ TABLE lt_old_db INTO DATA(ls_old_db)
            WITH KEY zpkgno = ls_item_db-zpkgno matnr = ls_item_db-matnr.
          IF sy-subrc = 0.
            ls_item_db-erdat = ls_old_db-erdat.
            ls_item_db-erzet = ls_old_db-erzet.
            ls_item_db-ernam = ls_old_db-ernam.
            ls_item_db-aedat = sy-datum.
            ls_item_db-aezet = sy-uzeit.
            ls_item_db-aenam = sy-uname.
          ELSE.
            ls_item_db-erdat = sy-datum.
            ls_item_db-erzet = sy-uzeit.
            ls_item_db-ernam = sy-uname.
          ENDIF.
          APPEND ls_item_db TO lt_insert.
        ENDLOOP.
        DELETE FROM zsdt0061 WHERE zinvno = @lv_invno.
        INSERT zsdt0061 FROM TABLE @lt_insert.
        IF sy-subrc <> 0.
          pv_error = abap_true.
        ENDIF.
      ENDIF.
      IF pv_error IS INITIAL.
* 동일 업무 LUW에서 장문 저장
        PERFORM save_shipping_remark USING lv_invno CHANGING pv_error.
      ENDIF.
    CATCH cx_sy_open_sql_db cx_sy_conversion_error.
      pv_error = abap_true.
  ENDTRY.
  IF pv_error = abap_true.
    ROLLBACK WORK.
    IF lv_new = abap_true.
* 보유 문서 잠금 해제
      PERFORM unlock_invoice.
    ENDIF.
    MESSAGE TEXT-n20 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  COMMIT WORK AND WAIT.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-n20 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  MOVE-CORRESPONDING ls_db TO gs_head.
  gv_edit_mode = abap_false.
* 보유 문서 잠금 해제
  PERFORM unlock_invoice.
* 저장 및 조회 기준 버퍼 동기화
  PERFORM accept_baseline.
* 문서 목록 재조회
  PERFORM select_inv_overview.
  MESSAGE TEXT-n21 TYPE gc_s.
ENDFORM.

FORM toggle_mode CHANGING pv_error TYPE abap_bool.
  CLEAR pv_error.
  IF gv_edit_mode = abap_false.
* 문서 잠금 취득
    PERFORM lock_invoice USING gs_head-zinvno CHANGING pv_error.
    CHECK pv_error IS INITIAL.
*   조회 이후 타 세션에서 바뀐 내용은 잠금 취득 후 다시 읽음
    IF gs_head-zinvno IS NOT INITIAL.
      DATA(lv_invno) = gs_head-zinvno.
* 저장 헤더 및 패킹 품목 조회
      PERFORM load_saved_invoice USING lv_invno CHANGING pv_error.
      IF pv_error = abap_true.
* 보유 문서 잠금 해제
        PERFORM unlock_invoice.
        RETURN.
      ENDIF.
    ENDIF.
* 저장 및 조회 기준 버퍼 동기화
    PERFORM accept_baseline.
    gv_edit_mode = abap_true.
  ELSE.
    IF gv_changed = abap_true.
      DATA(lv_answer) = zcl_cm_util=>popup_to_confirm(
        i_text_question = TEXT-q03 i_display_cancel_button = abap_true ).
      CHECK lv_answer = gc_yes.
    ENDIF.
    IF gs_head-zinvno IS NOT INITIAL.
      lv_invno = gs_head-zinvno.
* 저장 헤더 및 패킹 품목 조회
      PERFORM load_saved_invoice USING lv_invno CHANGING pv_error.
      CHECK pv_error IS INITIAL.
    ELSE.
      gs_head = gv_draft_head.
      gt_item = gt_draft_item.
      gt_remark = gt_draft_remark.
    ENDIF.
* 보유 문서 잠금 해제
    PERFORM unlock_invoice.
    gv_edit_mode = abap_false.
* 저장 및 조회 기준 버퍼 동기화
    PERFORM accept_baseline.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
* SCREEN / EDITOR / CHANGE DETECTION
*---------------------------------------------------------------------*
FORM set_header_attributes.
  LOOP AT SCREEN.
    IF screen-name CP 'GS_TEXT-*' OR screen-group1 = 'DIS'
       OR screen-name = 'GV_ZTERM_TEXT'
       OR screen-name = 'GS_HEAD-ZIVH13'
       OR screen-name = 'GS_HEAD-ZIVH21'
       OR screen-name = 'GS_HEAD-ZIVH27'.
      screen-input = 0.
      screen-required = 0.
    ELSEIF screen-name CP 'GS_HEAD-*'.
      screen-input = COND #( WHEN gv_edit_mode = abap_true THEN 1 ELSE 0 ).
      screen-required = 0.
      IF gv_edit_mode = abap_true.
        CASE screen-name.
          WHEN 'GS_HEAD-ZIVH01' OR 'GS_HEAD-ZIVH03' OR 'GS_HEAD-ZIVH28'
            OR 'GS_HEAD-ZIVH15' OR 'GS_HEAD-ZIVH22' OR 'GS_HEAD-ZIVH25'.
            screen-required = 2.
        ENDCASE.
      ENDIF.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.
ENDFORM.

FORM set_remark_editor CHANGING pv_error TYPE abap_bool.
  DATA lv_readonly TYPE i.
  CLEAR pv_error.
  IF go_remark_cont IS NOT BOUND.
    CREATE OBJECT go_remark_cont EXPORTING container_name = gc_cont_remark
      EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.
  ENDIF.
  IF go_remark_edit IS NOT BOUND.
    CREATE OBJECT go_remark_edit
      EXPORTING parent = go_remark_cont
        wordwrap_mode = cl_gui_textedit=>wordwrap_at_fixed_position
        wordwrap_position = gc_remark_width
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true
      EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.
    gv_remark_push = abap_true.
  ENDIF.
  lv_readonly = COND #( WHEN gv_edit_mode = abap_true THEN 0 ELSE 1 ).
  CALL METHOD go_remark_edit->set_readonly_mode
    EXPORTING readonly_mode = lv_readonly EXCEPTIONS OTHERS = 1.
  IF gv_remark_push = abap_true.
    CALL METHOD go_remark_edit->set_text_as_r3table
      EXPORTING table = gt_remark EXCEPTIONS OTHERS = 1.
    IF sy-subrc = 0.
      CALL METHOD cl_gui_cfw=>flush EXCEPTIONS OTHERS = 1.
    ENDIF.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      MESSAGE TEXT-r01 TYPE gc_s DISPLAY LIKE gc_e.
      RETURN.
    ENDIF.
    CLEAR gv_remark_push.
  ENDIF.
ENDFORM.

FORM sync_changes CHANGING pv_error TYPE abap_bool.
  DATA: lt_remark TYPE gty_t_remark,
        lt_current TYPE gty_t_item, lt_old TYPE gty_t_item.
  CLEAR pv_error.
  IF go_grid IS BOUND.
* ALV 최근 편집값 검증
    PERFORM check_item_alv CHANGING pv_error.
    CHECK pv_error IS INITIAL.
  ENDIF.
  IF go_remark_edit IS BOUND AND gv_remark_push IS INITIAL.
    CALL METHOD go_remark_edit->get_text_as_r3table
      EXPORTING only_when_modified = cl_gui_textedit=>false
      IMPORTING table = lt_remark EXCEPTIONS OTHERS = 1.
    IF sy-subrc = 0.
      CALL METHOD cl_gui_cfw=>flush EXCEPTIONS OTHERS = 1.
    ENDIF.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      MESSAGE TEXT-r01 TYPE gc_s DISPLAY LIKE gc_e.
      RETURN.
    ENDIF.
    gt_remark = lt_remark.
  ENDIF.
  CHECK gv_edit_mode = abap_true.
  lt_current = gt_item.
  lt_old = gt_item_old.
  LOOP AT lt_current ASSIGNING FIELD-SYMBOL(<cur>).
    CLEAR: <cur>-check, <cur>-style, <cur>-message.
  ENDLOOP.
  LOOP AT lt_old ASSIGNING FIELD-SYMBOL(<old>).
    CLEAR: <old>-check, <old>-style, <old>-message.
  ENDLOOP.
  gv_changed = xsdbool( gs_head <> gs_head_old OR lt_current <> lt_old
                    OR gt_remark <> gt_remark_old OR gv_force_changed = abap_true ).
ENDFORM.

FORM set_item_styles.
  LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<item>).
    CLEAR <item>-style.
    IF gv_edit_mode IS INITIAL OR <item>-zpkgno IS INITIAL.
      APPEND VALUE #( fieldname = 'ZIVI01' style = cl_gui_alv_grid=>mc_style_disabled ) TO <item>-style.
      APPEND VALUE #( fieldname = 'ZIVI02' style = cl_gui_alv_grid=>mc_style_disabled ) TO <item>-style.
      APPEND VALUE #( fieldname = 'ZIVI03' style = cl_gui_alv_grid=>mc_style_disabled ) TO <item>-style.
      APPEND VALUE #( fieldname = 'ZIVI04' style = cl_gui_alv_grid=>mc_style_disabled ) TO <item>-style.
      APPEND VALUE #( fieldname = 'ZIVI05' style = cl_gui_alv_grid=>mc_style_disabled ) TO <item>-style.
      APPEND VALUE #( fieldname = 'ZIVI06' style = cl_gui_alv_grid=>mc_style_disabled ) TO <item>-style.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM validate_cells USING po_changed TYPE REF TO cl_alv_changed_data_protocol.
  DATA: lv_number TYPE decfloat34, lv_bad TYPE abap_bool,
        ls_trial TYPE gty_item.
  LOOP AT po_changed->mt_mod_cells INTO DATA(ls_cell).
    CHECK ls_cell-fieldname <> 'CHECK'.
    CLEAR lv_bad.
    READ TABLE gt_item INTO ls_trial INDEX ls_cell-row_id.
    IF sy-subrc <> 0 OR gv_edit_mode IS INITIAL OR ls_trial-zpkgno IS INITIAL.
      lv_bad = abap_true.
    ELSE.
      TRY.
          lv_number = ls_cell-value.
          IF lv_number < 0.
            lv_bad = abap_true.
          ENDIF.
          IF ls_cell-fieldname = 'ZIVI02' OR ls_cell-fieldname = 'ZIVI03'.
            IF lv_number <> trunc( lv_number ) OR lv_number > 2147483647.
              lv_bad = abap_true.
            ENDIF.
          ENDIF.
          ASSIGN COMPONENT ls_cell-fieldname OF STRUCTURE ls_trial TO FIELD-SYMBOL(<value>).
          IF sy-subrc = 0.
            <value> = lv_number.
          ELSE.
            lv_bad = abap_true.
          ENDIF.
        CATCH cx_sy_conversion_error cx_sy_arithmetic_error.
          lv_bad = abap_true.
      ENDTRY.
    ENDIF.
    IF lv_bad = abap_true.
      po_changed->add_protocol_entry(
        i_msgid = '00' i_msgno = '398' i_msgty = gc_e
        i_msgv1 = TEXT-n22 i_fieldname = ls_cell-fieldname i_row_id = ls_cell-row_id ).
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM finish_cells USING pt_cells TYPE lvc_t_modi.
  DATA: lt_rows TYPE SORTED TABLE OF i WITH UNIQUE KEY table_line,
        lv_error TYPE abap_bool, lv_business TYPE abap_bool.
  LOOP AT pt_cells INTO DATA(ls_cell) WHERE fieldname <> 'CHECK'.
    lv_business = abap_true.
    IF ls_cell-fieldname = 'ZIVI01' OR ls_cell-fieldname = 'ZIVI02'.
      INSERT ls_cell-row_id INTO TABLE lt_rows.
    ENDIF.
  ENDLOOP.
  CHECK lv_business = abap_true.
  gv_changed = abap_true.
  gv_pack_dirty = abap_true.
  CLEAR gv_calc_error.
  LOOP AT lt_rows INTO DATA(lv_row).
    READ TABLE gt_item ASSIGNING FIELD-SYMBOL(<item>) INDEX lv_row.
    CHECK sy-subrc = 0.
* 기본단위 환산 및 품목 금액 중량 계산
    PERFORM calculate_item CHANGING <item> lv_error.
    IF lv_error = abap_true.
      gv_calc_error = abap_true.
      <item>-message = TEXT-n07.
      <item>-calc_failed = abap_true.
    ENDIF.
  ENDLOOP.
  LOOP AT gt_item TRANSPORTING NO FIELDS WHERE calc_failed = abap_true.
    gv_calc_error = abap_true.
    EXIT.
  ENDLOOP.
  IF gv_calc_error IS INITIAL.
* 품목 합계의 헤더 반영
    PERFORM calc_header_totals CHANGING gv_calc_error.
  ENDIF.
  gv_refresh = abap_true.
ENDFORM.

FORM set_status.
  CLEAR gt_fcode.
  IF gv_edit_mode IS INITIAL.
    APPEND 'SAVE' TO gt_fcode.
    APPEND 'PLUPLOAD' TO gt_fcode.
  ENDIF.
  IF gs_head-zinvno IS INITIAL.
    APPEND 'COPY' TO gt_fcode.
    APPEND 'PRINT' TO gt_fcode.
    APPEND 'DELIV_HOT' TO gt_fcode.
  ELSE.
    SELECT SINGLE zinvno FROM zsdt0061 WHERE zinvno = @gs_head-zinvno
      INTO @DATA(lv_invno).
    IF sy-subrc <> 0.
      APPEND 'PRINT' TO gt_fcode.
    ENDIF.
  ENDIF.
  IF gv_edit_mode = abap_true.
    APPEND 'DELIV_HOT' TO gt_fcode.
  ENDIF.
  IF gv_list_hide = abap_false.
    gv_list_btn-text = TEXT-b04.
    gv_list_btn-icon_id = icon_close.
  ELSE.
    gv_list_btn-text = TEXT-b05.
    gv_list_btn-icon_id = icon_overview.
  ENDIF.
  SET PF-STATUS '0100' EXCLUDING gt_fcode.
  SET TITLEBAR '0100'.
ENDFORM.

FORM leave_invoice_screen USING pv_ucomm TYPE sy-ucomm.
  IF gv_changed = abap_true.
    DATA(lv_answer) = zcl_cm_util=>popup_to_confirm(
      i_text_question = TEXT-q02 i_display_cancel_button = abap_true ).
    CHECK lv_answer = gc_yes.
  ENDIF.
* 보유 문서 잠금 해제
  PERFORM unlock_invoice.
* 품목 컨트롤 해제
  PERFORM free_item_alv.
* 장문 컨트롤 해제
  PERFORM free_remark_editor.
* 팝업 컨트롤 해제
  PERFORM free_popup.
  IF go_inv_grid IS BOUND.
    go_inv_grid->free( ).
    FREE go_inv_grid.
  ENDIF.
  IF go_inv_cont IS BOUND.
    go_inv_cont->free( ).
    FREE go_inv_cont.
  ENDIF.
  IF pv_ucomm = gc_exit.
    LEAVE PROGRAM.
  ELSE.
    LEAVE TO SCREEN 0.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
* UPLOAD / PRINT - 현 단계는 종류 선택과 분기까지만 구현
*---------------------------------------------------------------------*
FORM upload_select.
  DATA: lv_path TYPE string, lv_message TYPE string.
  CHECK gv_edit_mode = abap_true.
  CALL SELECTION-SCREEN 0400 STARTING AT 20 5.
  CHECK sy-subrc = 0.
  lv_path = zcl_cm_util=>file_open_dialog(
    EXPORTING i_title = TEXT-t04 i_def_ext = 'xlsx'
    IMPORTING e_msg = lv_message ).
  IF lv_message IS NOT INITIAL.
    MESSAGE lv_message TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  CHECK lv_path IS NOT INITIAL.
  IF p_ucipl = abap_true.
* 송장 및 패킹 업로드 분기
    PERFORM upload_ci_pl USING lv_path.
  ELSE.
* 패킹 업로드 분기
    PERFORM upload_pl USING lv_path.
  ENDIF.
ENDFORM.
FORM upload_ci_pl USING pv_path TYPE string.
* 후속 파싱: 임시 테이블 검증 성공 후 전체 교체 및 GV_PACK_DIRTY 설정
  MESSAGE TEXT-r02 TYPE gc_s DISPLAY LIKE gc_w.
ENDFORM.
FORM upload_pl USING pv_path TYPE string.
  MESSAGE TEXT-r02 TYPE gc_s DISPLAY LIKE gc_w.
ENDFORM.
FORM print_select.
  IF gs_head-zinvno IS INITIAL OR gv_changed = abap_true.
    MESSAGE TEXT-n23 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  SELECT SINGLE zinvno FROM zsdt0061 WHERE zinvno = @gs_head-zinvno
    INTO @DATA(lv_invno).
  IF sy-subrc <> 0.
    MESSAGE TEXT-n24 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  CALL SELECTION-SCREEN 0300 STARTING AT 20 5.
  CHECK sy-subrc = 0.
  IF p_cipl = abap_true.
* 송장 및 패킹 출력 분기
    PERFORM print_ci_pl.
  ELSEIF p_ci = abap_true.
* 송장 출력 분기
    PERFORM print_ci.
  ELSE.
* 패킹 출력 분기
    PERFORM print_pl.
  ENDIF.
ENDFORM.
FORM print_ci_pl.
  MESSAGE TEXT-n25 TYPE gc_s DISPLAY LIKE gc_w.
ENDFORM.
FORM print_ci.
  MESSAGE TEXT-n25 TYPE gc_s DISPLAY LIKE gc_w.
ENDFORM.
FORM print_pl.
  MESSAGE TEXT-n25 TYPE gc_s DISPLAY LIKE gc_w.
ENDFORM.