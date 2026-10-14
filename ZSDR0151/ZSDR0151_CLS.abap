CLASS lcl_event DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object sender.
    CLASS-METHODS handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm sender.
    CLASS-METHODS double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING es_row_no sender.
    CLASS-METHODS changed FOR EVENT data_changed OF cl_gui_alv_grid
      IMPORTING er_data_changed sender.
    CLASS-METHODS finished FOR EVENT data_changed_finished OF cl_gui_alv_grid
      IMPORTING e_modified et_good_cells sender.
ENDCLASS.
CLASS lcl_event IMPLEMENTATION.
  METHOD handle_toolbar.
* 품목 선택 버튼 구성
    PERFORM handle_toolbar USING e_object sender.
  ENDMETHOD.
  METHOD handle_user_command.
* 품목 선택 명령 처리
    PERFORM handle_user_command USING e_ucomm sender.
  ENDMETHOD.
  METHOD double_click.
    IF sender = go_inv_grid.
      READ TABLE gt_overview INTO DATA(ls_inv) INDEX es_row_no-row_id.
      CHECK sy-subrc = 0.
      gv_pending_invno = ls_inv-zinvno.
*     Dynpro 최근 입력을 PAI에서 반영한 뒤 문서 전환
      cl_gui_cfw=>set_new_ok_code( 'OPEN_INV' ).
    ELSEIF sender = go_pop_grid.
      READ TABLE gt_pop_deliv INTO DATA(ls_pop) INDEX es_row_no-row_id.
      CHECK sy-subrc = 0.
      gv_pop_pick = ls_pop-vbeln.
      cl_gui_cfw=>set_new_ok_code( 'PICK' ).
    ENDIF.
  ENDMETHOD.
  METHOD changed.
    CHECK sender = go_grid.
* 변경 셀 입력값 검증
    PERFORM validate_cells USING er_data_changed.
  ENDMETHOD.
  METHOD finished.
    CHECK sender = go_grid AND e_modified = abap_true.
* 변경 품목 재계산
    PERFORM finish_cells USING et_good_cells.
  ENDMETHOD.
ENDCLASS.