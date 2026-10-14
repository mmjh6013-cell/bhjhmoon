*&---------------------------------------------------------------------*
*& Include          ZSDR0150_CLS
*&---------------------------------------------------------------------*
CLASS lcl_event DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object sender,
      handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm sender,
      handle_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id sender,
      handle_on_f4 FOR EVENT onf4 OF cl_gui_alv_grid
        IMPORTING e_fieldname e_fieldvalue es_row_no er_event_data
                  et_bad_cells e_display sender.
ENDCLASS.
CLASS lcl_event IMPLEMENTATION.
  METHOD handle_toolbar.
* 오른쪽 아이템 ALV의 전체선택/해제 툴바 버튼을 구성합니다.
    PERFORM handle_toolbar USING e_object sender.
  ENDMETHOD.
  METHOD handle_user_command.
* 오른쪽 아이템 ALV에서 발생한 사용자 명령을 처리합니다.
    PERFORM handle_user_command USING e_ucomm sender.
  ENDMETHOD.

  METHOD handle_hotspot_click.
* 기존 메서드명 유지. 업무 필드 조회 전용 단계에서는 등록하지 않습니다.
  ENDMETHOD.

  METHOD handle_on_f4.
* 헤더 F4는 Dynpro POV에서 처리. 아이템 F4는 현재 등록하지 않습니다.
  ENDMETHOD.
ENDCLASS.