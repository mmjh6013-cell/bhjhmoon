*&---------------------------------------------------------------------*
*& Include          ZSDR0151_I01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module exit INPUT
*&---------------------------------------------------------------------*
*& Function Type E 종료 명령 처리
*& - AT EXIT-COMMAND에서는 일반 PAI보다 먼저 현재 편집값을 동기화
*& - 입력 오류가 남으면 변경 상태로 처리하여 폐기 확인을 거침
*&---------------------------------------------------------------------*
MODULE exit INPUT.

  CASE gv_okcode.
    WHEN gc_back OR gc_canc OR gc_exit.
      gv_save_ok = gv_okcode.
      CLEAR gv_okcode.

      PERFORM sync_changes CHANGING gv_error.
      IF gv_error = abap_true.
        gv_changed = abap_true.
      ENDIF.

      PERFORM leave_invoice_screen USING gv_save_ok.
  ENDCASE.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module check_item_alv INPUT
*&---------------------------------------------------------------------*
*& 0110 서브스크린 PAI에서 ALV 편집값을 내부테이블에 반영
*& - 유효하지 않은 셀이 있으면 명령을 중단
*&---------------------------------------------------------------------*
MODULE check_item_alv INPUT.

  PERFORM check_item_alv CHANGING gv_error.
  IF gv_error = abap_true.
    CLEAR gv_okcode.
    MESSAGE TEXT-a23 TYPE gc_e.
  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module header_input_0100 INPUT
*&---------------------------------------------------------------------*
*& 헤더·품목·Shipping Remark 입력 동기화 및 변경 감지
*& - 기존 GET_REMARK_EDITOR 호출과 수동 변경 비교를 통합
*& - 에디터 내용을 화면에 쓰는 SET_REMARK_EDITOR와 역할이 다름
*&---------------------------------------------------------------------*
MODULE header_input_0100 INPUT.

  PERFORM sync_changes CHANGING gv_error.
  IF gv_error = abap_true.
    CLEAR gv_okcode.
    MESSAGE TEXT-a23 TYPE gc_e.
  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module user_command_0100 INPUT
*&---------------------------------------------------------------------*
*& 0100 화면 명령 처리
*& - LIST: Document Overview 표시/숨김 전환
*& - CHG_DIS / OPEN_INV: 현재 F01의 수정 전환 / 저장 문서 조회 연결
*& - 저장 필수값 검증은 SAVE_INVOICE_DATA 내부에서 수행
*& - 업로드·출력은 현재 F01의 미구현 안내 진입점으로 연결
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  gv_save_ok = gv_okcode.
  CLEAR gv_okcode.

  CASE gv_save_ok.
    WHEN gc_back OR gc_canc OR gc_exit.
      PERFORM leave_invoice_screen USING gv_save_ok.

    WHEN gc_list.
      gv_list_hide = xsdbool( gv_list_hide = abap_false ).

    WHEN gc_copy.
      PERFORM copy_header_data CHANGING gv_error.

    WHEN gc_save.
      PERFORM save_invoice_data CHANGING gv_error.

    WHEN 'CHG_DIS'.
      PERFORM toggle_mode CHANGING gv_error.

    WHEN 'OPEN_INV'.
      PERFORM open_invoice CHANGING gv_error.

    WHEN gc_upl_cip OR gc_upl_pl OR 'PLUPLOAD'.
      PERFORM upload_select.

    WHEN gc_pr_cip OR gc_pr_ci OR gc_pr_pl OR 'PRINT'.
      PERFORM print_select.

    WHEN 'DELIV_HOT'.
      IF gv_edit_mode = abap_false AND gs_head-zinvno IS NOT INITIAL.
        SET PARAMETER ID 'VL' FIELD gs_head-vbeln_vl.
        CALL TRANSACTION 'VL03N' AND SKIP FIRST SCREEN.
      ENDIF.
  ENDCASE.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module f4_zterm_0100 INPUT
*&---------------------------------------------------------------------*
*& 지급조건 선택 도움말
*& - 조회모드에서는 값을 변경하지 않음
*&---------------------------------------------------------------------*
MODULE f4_zterm_0100 INPUT.

  IF gv_edit_mode = abap_true.
    PERFORM f4_payment_term.
  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module f4_inco1_0100 INPUT
*&---------------------------------------------------------------------*
*& Incoterms 선택 도움말
*& - 조회모드에서는 값을 변경하지 않음
*&---------------------------------------------------------------------*
MODULE f4_inco1_0100 INPUT.

  IF gv_edit_mode = abap_true.
    PERFORM f4_incoterms.
  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module f4_invdate_0100 INPUT
*&---------------------------------------------------------------------*
*& Invoice Date 선택 도움말
*& - 조회모드에서는 값을 변경하지 않음
*&---------------------------------------------------------------------*
MODULE f4_invdate_0100 INPUT.

  IF gv_edit_mode = abap_true.
    PERFORM f4_header_date USING 'GS_HEAD-ZIVH15'.
  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module f4_onboard_0100 INPUT
*&---------------------------------------------------------------------*
*& On Board Date 선택 도움말
*& - 조회모드에서는 값을 변경하지 않음
*&---------------------------------------------------------------------*
MODULE f4_onboard_0100 INPUT.

  IF gv_edit_mode = abap_true.
    PERFORM f4_header_date USING 'GS_HEAD-ZIVH11'.
  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module f4_eta_0100 INPUT
*&---------------------------------------------------------------------*
*& ETA Date 선택 도움말
*& - 조회모드에서는 값을 변경하지 않음
*&---------------------------------------------------------------------*
MODULE f4_eta_0100 INPUT.

  IF gv_edit_mode = abap_true.
    PERFORM f4_header_date USING 'GS_HEAD-ZIVH19'.
  ENDIF.

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module user_command_0200 INPUT
*&---------------------------------------------------------------------*
*& Copy용 Delivery 선택 팝업 명령 처리
*& - 선택 결과를 GV_POP_VBELN으로 전달하고 화면 종료
*&---------------------------------------------------------------------*
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