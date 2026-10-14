*----------------------------------------------------------------------*
* SELECTION SCREEN
* - Shipping Point / Planned GI Date : 필수
* - 나머지 조건                     : 선택
* - Print Form Option은 상세 화면에 배치하므로 여기에는 선언하지 않음
* - 명세의 1000은 예시값으로 보고 기본값을 하드코딩하지 않음
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE TEXT-t01.

*----------------------------------------------------------------------*
* Shipping Point
* - 단일 Shipping Point 입력
* - 우측 Description은 C_VSTEL에 표시
*----------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(28) TEXT-s01 FOR FIELD s_vstel.
    SELECTION-SCREEN POSITION 30.
    SELECT-OPTIONS s_vstel FOR likp-vstel
      NO INTERVALS NO-EXTENSION OBLIGATORY.
    SELECTION-SCREEN COMMENT 45(30) c_vstel.
  SELECTION-SCREEN END OF LINE.

*----------------------------------------------------------------------*
* Planned Goods Issue Date
* - LIKP-WADAT 기준
* - 기간 및 복수 조건 허용
*----------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(28) TEXT-s02 FOR FIELD s_wadat.
    SELECTION-SCREEN POSITION 30.
    SELECT-OPTIONS s_wadat FOR likp-wadat OBLIGATORY.
  SELECTION-SCREEN END OF LINE.

*----------------------------------------------------------------------*
* Sold-to Party
* - LIKP-KUNAG 기준
*----------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(28) TEXT-s03 FOR FIELD s_kunag.
    SELECTION-SCREEN POSITION 30.
    SELECT-OPTIONS s_kunag FOR likp-kunag.
  SELECTION-SCREEN END OF LINE.

*----------------------------------------------------------------------*
* Ship-to Party
* - LIKP-KUNNR 기준
*----------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(28) TEXT-s04 FOR FIELD s_kunnr.
    SELECTION-SCREEN POSITION 30.
    SELECT-OPTIONS s_kunnr FOR likp-kunnr.
  SELECTION-SCREEN END OF LINE.

*----------------------------------------------------------------------*
* Delivery Number
* - 조회 단계에서는 복수 Delivery 조회 가능
* - 실제 Invoice Header는 선택한 Delivery 한 건과 연결
*----------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(28) TEXT-s05 FOR FIELD s_vbeln.
    SELECTION-SCREEN POSITION 30.
    SELECT-OPTIONS s_vbeln FOR likp-vbeln
       NO INTERVALS NO-EXTENSION OBLIGATORY.
  SELECTION-SCREEN END OF LINE.

*----------------------------------------------------------------------*
* Commercial Invoice Number
* - 기존에 저장한 Invoice 조회조건
*----------------------------------------------------------------------*
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(28) TEXT-s06 FOR FIELD s_invno.
    SELECTION-SCREEN POSITION 30.
    SELECT-OPTIONS s_invno FOR zsdt0060-zinvno.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK bl1.