MODULE user_command_0100 INPUT.
  gv_save_ok = gv_okcode.
  CLEAR gv_okcode.
* 화면 최신 입력 동기화 및 변경 감지
  PERFORM sync_changes CHANGING gv_error.
  IF gv_error = abap_true AND
     ( gv_save_ok = gc_back OR gv_save_ok = gc_exit OR gv_save_ok = gc_canc ).
*   잘못 입력된 ALV 값도 폐기 확인 후 종료할 수 있도록 처리
    gv_changed = abap_true.
* 변경 폐기 확인 및 종료
    PERFORM leave_invoice_screen USING gv_save_ok.
  ELSEIF gv_error IS INITIAL.
    CASE gv_save_ok.
      WHEN 'SAVE'.
* 송장 저장
        PERFORM save_invoice_data CHANGING gv_error.
      WHEN 'COPY'.
* 저장 문서 기준 신규 송장 복사
        PERFORM copy_header_data CHANGING gv_error.
      WHEN 'CHG_DIS'.
* 조회 및 수정 모드 전환
        PERFORM toggle_mode CHANGING gv_error.
      WHEN 'OPEN_INV'.
* 선택한 저장 문서 조회
        PERFORM open_invoice CHANGING gv_error.
      WHEN 'LIST'.
        gv_list_hide = xsdbool( gv_list_hide = abap_false ).
      WHEN 'PLUPLOAD'.
* 업로드 종류 및 파일 선택
        PERFORM upload_select.
      WHEN 'PRINT'.
* 출력 조건 검증 및 종류 선택
        PERFORM print_select.
      WHEN 'DELIV_HOT'.
        IF gv_edit_mode = abap_false AND gs_head-zinvno IS NOT INITIAL.
          SET PARAMETER ID 'VL' FIELD gs_head-vbeln_vl.
          CALL TRANSACTION 'VL03N' AND SKIP FIRST SCREEN.
        ENDIF.
      WHEN 'BACK' OR 'EXIT' OR 'CANC'.
* 변경 폐기 확인 및 종료
        PERFORM leave_invoice_screen USING gv_save_ok.
    ENDCASE.
  ENDIF.
ENDMODULE.
MODULE user_command_0200 INPUT.
  DATA: lv_pop_ucomm TYPE sy-ucomm, lt_rows TYPE lvc_t_roid.
  lv_pop_ucomm = gv_pop_okcode.
  CLEAR gv_pop_okcode.
  CASE lv_pop_ucomm.
    WHEN 'PICK'.
      IF gv_pop_pick IS NOT INITIAL.
        gv_pop_vbeln = gv_pop_pick.
        CLEAR gv_pop_pick.
      ENDIF.
      IF gv_pop_vbeln IS INITIAL AND go_pop_grid IS BOUND.
        go_pop_grid->get_selected_rows( IMPORTING et_row_no = lt_rows ).
        IF lines( lt_rows ) = 1.
          READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
          READ TABLE gt_pop_deliv INTO DATA(ls_pop) INDEX ls_row-row_id.
          IF sy-subrc = 0.
            gv_pop_vbeln = ls_pop-vbeln.
          ENDIF.
        ENDIF.
      ENDIF.
      IF gv_pop_vbeln IS NOT INITIAL.
        LEAVE TO SCREEN 0.
      ELSE.
        MESSAGE TEXT-n26 TYPE gc_s DISPLAY LIKE gc_e.
      ENDIF.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      CLEAR gv_pop_vbeln.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
MODULE f4_zterm_0100 INPUT.
  IF gv_edit_mode = abap_true.
* 지급조건 선택 도움말 호출
    PERFORM f4_payment_term.
  ENDIF.
ENDMODULE.
MODULE f4_inco1_0100 INPUT.
  IF gv_edit_mode = abap_true.
* 인코텀즈 선택 도움말 호출
    PERFORM f4_incoterms.
  ENDIF.
ENDMODULE.
MODULE f4_invdate_0100 INPUT.
  IF gv_edit_mode = abap_true.
* 날짜 선택 도움말 호출
    PERFORM f4_header_date USING 'GS_HEAD-ZIVH15'.
  ENDIF.
ENDMODULE.
MODULE f4_onboard_0100 INPUT.
  IF gv_edit_mode = abap_true.
* 날짜 선택 도움말 호출
    PERFORM f4_header_date USING 'GS_HEAD-ZIVH11'.
  ENDIF.
ENDMODULE.
MODULE f4_eta_0100 INPUT.
  IF gv_edit_mode = abap_true.
* 날짜 선택 도움말 호출
    PERFORM f4_header_date USING 'GS_HEAD-ZIVH19'.
  ENDIF.
ENDMODULE.