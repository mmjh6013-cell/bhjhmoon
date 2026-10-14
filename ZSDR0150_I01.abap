*&---------------------------------------------------------------------*
*& Include          ZSDR0150_I01
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* EXIT: Function Type E 종료 명령
* - 이 시점에는 헤더 입력값이 GS_HEAD로 전달되기 전일 수 있습니다.
* - 종료를 확인한 경우에만 컨트롤을 해제하고 화면을 종료합니다.
* - 취소 시 LEAVE SCREEN하지 않고 정상 PAI로 이어 입력을 유지합니다.
*----------------------------------------------------------------------*
MODULE exit INPUT.

  CASE gv_okcode.
    WHEN gc_back OR gc_canc OR gc_exit.
      gv_save_ok = gv_okcode.
      CLEAR gv_okcode.

* 아직 전달되지 않은 입력값도 버리지 않도록 종료 여부를 확인합니다.
      PERFORM leave_invoice_screen USING gv_save_ok.
  ENDCASE.

ENDMODULE.

*----------------------------------------------------------------------*
* 아이템 ALV에서 편집한 행 선택 체크를 GT_ITEM에 반영합니다.
* 서브스크린 PAI에서 Main 명령 처리 전에 실행됩니다.
*----------------------------------------------------------------------*
MODULE check_item_alv INPUT.

* ALV의 미반영 체크박스 값을 내부테이블로 전달하고 유효성을 확인합니다.
  PERFORM check_item_alv CHANGING gv_error.
  IF gv_error = abap_true.
    CLEAR gv_okcode.
    MESSAGE TEXT-a23 TYPE gc_e.
  ENDIF.

ENDMODULE.

*----------------------------------------------------------------------*
* Main PAI 공통 입력 동기화
* - 명령 분기는 USER_COMMAND_0100 한 곳에서만 수행합니다.
* - 이전 패치 HEADER_INPUT_0100의 Copy/Save 분기를 중복 적용하지 않습니다.
*----------------------------------------------------------------------*
MODULE header_input_0100 INPUT.

* 화면에서 편집한 Shipping Remark를 최신 상태로 가져옵니다.
  PERFORM get_remark_editor CHANGING gv_error.

  IF gv_error = abap_true.
    CLEAR gv_okcode.
    MESSAGE TEXT-r01 TYPE gc_e.
  ENDIF.

  IF gs_head <> gs_head_old OR gt_remark <> gt_remark_old.
    gv_changed = abap_true.
  ENDIF.

ENDMODULE.

*----------------------------------------------------------------------*
* Main 명령 처리
* - Copy: 헤더/장문 복사. 아이템 미변경.
* - Save: 필수 검사 연결. 채번/DB 저장은 현재 원본에도 미구현.
* - List/Print: 기존 미구현 안내 유지.
* - Upload: 두 명령을 구분하지만 본 처리는 후속 범위.
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  gv_save_ok = gv_okcode.
  CLEAR gv_okcode.

  CASE gv_save_ok.
    WHEN gc_back OR gc_canc OR gc_exit.
* 일반 Function Code로 들어온 종료 명령에도 동일한 확인을 적용합니다.
      PERFORM leave_invoice_screen USING gv_save_ok.

    WHEN gc_copy.
* 선택한 Invoice 헤더와 장문을 가져오고 Invoice 번호를 초기화합니다.
      PERFORM copy_header_data CHANGING gv_error.

    WHEN gc_save.
* 저장 전 헤더 필수 6개와 코드/날짜 유효성을 확인합니다.
      PERFORM check_header_required CHANGING gv_error.
      IF gv_error IS INITIAL.
* 채번/문서 저장 구현 전임을 알리고 DB 쓰기 없이 오류 상태를 반환합니다.
        PERFORM save_invoice_data CHANGING gv_error.
      ENDIF.

    WHEN gc_upl_cip OR gc_upl_pl.
      MESSAGE TEXT-r02 TYPE gc_s DISPLAY LIKE gc_w.

    WHEN gc_list OR gc_pr_cip OR gc_pr_ci OR gc_pr_pl.
      MESSAGE TEXT-e03 TYPE gc_s DISPLAY LIKE gc_w.
  ENDCASE.

ENDMODULE.
MODULE f4_zterm_0100 INPUT.
* 지급조건 F4 선택값과 설명을 화면에 반영합니다.
  PERFORM f4_payment_term.
ENDMODULE.

MODULE f4_inco1_0100 INPUT.
* Incoterms F4 선택값을 화면에 반영합니다.
  PERFORM f4_incoterms.
ENDMODULE.

MODULE f4_invdate_0100 INPUT.
* Invoice Date 달력 선택값을 화면에 반영합니다.
  PERFORM f4_header_date USING 'GS_HEAD-ZIVH15'.
ENDMODULE.

MODULE f4_onboard_0100 INPUT.
* On Board Date 달력 선택값을 화면에 반영합니다.
  PERFORM f4_header_date USING 'GS_HEAD-ZIVH11'.
ENDMODULE.

MODULE f4_eta_0100 INPUT.
* ETA Date 달력 선택값을 화면에 반영합니다.
  PERFORM f4_header_date USING 'GS_HEAD-ZIVH19'.
ENDMODULE.