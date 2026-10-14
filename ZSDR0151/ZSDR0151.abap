REPORT zsdr0151 MESSAGE-ID zsdm.
INCLUDE zsdr0151_top.
INCLUDE zsdr0151_cls.
INCLUDE zsdr0151_scn.
INCLUDE zsdr0151_f01.
INCLUDE zsdr0151_o01.
INCLUDE zsdr0151_i01.
INITIALIZATION.
* 프로그램 초기화
  PERFORM init.
AT SELECTION-SCREEN OUTPUT.
  IF sy-dynnr = '1000'.
* 조회조건 명칭 표시
    PERFORM set_screen.
  ENDIF.
START-OF-SELECTION.
* 조회조건 검증
  PERFORM check_input CHANGING gv_error.
  CHECK gv_error IS INITIAL.
* 신규 초안 조회
  PERFORM get_list CHANGING gv_error.
  CHECK gv_error IS INITIAL.
  CALL SCREEN 0100.