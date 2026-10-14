MODULE status_0100 OUTPUT.
* 툴바 상태 설정
  PERFORM set_status.
ENDMODULE.
MODULE header_screen_0100 OUTPUT.
* 헤더 라벨 정렬
  PERFORM align_header_labels.
* 조회 및 수정 모드별 필드 속성 설정
  PERFORM set_header_attributes.
ENDMODULE.
MODULE header_ui_0100 OUTPUT.
* 포장 유형 목록 설정
  PERFORM set_packing_values CHANGING gv_error.
* 지급조건 명칭 조회
  PERFORM get_payment_text.
* 장문 에디터 상태 반영
  PERFORM set_remark_editor CHANGING gv_error.
* 문서 목록 표시
  PERFORM set_overview.
ENDMODULE.
MODULE set_alv_grid OUTPUT.
* 품목별 편집 가능 필드 설정
  PERFORM set_item_styles.
  gv_refresh = abap_true.
* 품목 ALV 표시
  PERFORM set_alv_grid CHANGING gv_error.
ENDMODULE.
MODULE status_0200 OUTPUT.
  SET PF-STATUS '0200'.
  SET TITLEBAR '0200'.
* 납품문서 선택 목록 표시
  PERFORM set_popup.
ENDMODULE.