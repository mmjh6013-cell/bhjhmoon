*&---------------------------------------------------------------------*
*& Include          ZSDR0150_F01
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* INITIALIZATION
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form init
*&---------------------------------------------------------------------*
*& 최초 실행 시 공통 상태 / 화면 라벨 초기화
*& - Shipping Point 등 업무 기본값은 임의 설정하지 않음
*& - Invoice Date는 신규 문서 초기화 단계에서 설정 예정
*&---------------------------------------------------------------------*
FORM init.

* 이전 아이템 ALV 객체를 정리하여 재실행 시 컨트롤 중복을 방지합니다.
  PERFORM free_item_alv.

* 이전 화면의 장문 컨트롤과 버퍼를 해제하여 새 실행 상태를 만듭니다.
  PERFORM free_remark_editor.

  CLEAR: gv_text_langu, gv_zterm_text,
         gt_pack_values, gv_pack_loaded.

  CLEAR:
    gv_answer,
    gv_changed,
    gv_refresh,
    gv_okcode,
    gv_save_ok,
    gv_title,
    gv_error,
    gv_ref_invno,
    gv_list_hide,
    gv_gewei,
    gv_voleh,
    gs_head,
    gs_head_old,
    gs_item,
    gs_text.

  CLEAR:
    gt_fcode,
    gt_required,
    gt_item.

* 화면 라벨과 출력 버튼 문구를 Text Element에서 초기화합니다.
  PERFORM set_text.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_text
*&---------------------------------------------------------------------*
*& Text Element 기반 Header Label / Print Button 문구 설정
*& - Selection Screen 및 0100 PBO에서 반복 호출 가능
*& - 입력 데이터 GS_HEAD / GS_ITEM은 변경하지 않음
*&---------------------------------------------------------------------*
FORM set_text.

*----------------------------------------------------------------------*
* HEADER - PARTNER / REMARK
*----------------------------------------------------------------------*
  gs_text-h01 = TEXT-h01.          "Customer
  gs_text-h02 = TEXT-h02.          "Ship to Location
  gs_text-h03 = TEXT-h03.          "Consignee Location
  gs_text-h04 = TEXT-h04.          "Bill to Location
  gs_text-h05 = TEXT-h05.          "Notify Party 1
  gs_text-h06 = TEXT-h06.          "Notify Party 2
  gs_text-h07 = TEXT-h07.          "Import Invoice No.
  gs_text-h08 = TEXT-h08.          "Remarks 1
  gs_text-h09 = TEXT-h09.          "Remarks 2

*----------------------------------------------------------------------*
* HEADER - DELIVERY / PRINT OPTION
*----------------------------------------------------------------------*
  gs_text-h10 = TEXT-h10.          "Delivery Type
  gs_text-h11 = TEXT-h11.          "Delivery No.
  gs_text-h12 = TEXT-h12.          "Total Amount
  gs_text-h13 = TEXT-h13.          "Packing Type
  gs_text-h14 = TEXT-h14.          "Print Form Option

*----------------------------------------------------------------------*
* HEADER - INVOICE
*----------------------------------------------------------------------*
  gs_text-h15 = TEXT-h15.          "Invoice No.
  gs_text-h16 = TEXT-h16.          "Date of Invoice
  gs_text-h17 = TEXT-h17.          "Payment Term

*----------------------------------------------------------------------*
* HEADER - TRANSPORT
*----------------------------------------------------------------------*
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

*----------------------------------------------------------------------*
* HEADER - PACKAGE / WEIGHT / VOLUME
*----------------------------------------------------------------------*
  gs_text-h30 = TEXT-h30.          "Package
  gs_text-h31 = TEXT-h31.          "(Package)
  gs_text-h32 = TEXT-h32.          "Measurement
  gs_text-h33 = TEXT-h33.          "Net Weight
  gs_text-h34 = TEXT-h34.          "Gross Weight
  gs_text-h35 = TEXT-h35.          "Shipping Remark

*----------------------------------------------------------------------*
* PRINT BUTTON
*----------------------------------------------------------------------*
  gv_pr_cip = TEXT-b01 .
  gv_pr_ci  = TEXT-b02.
  gv_pr_pl  = TEXT-b03.

ENDFORM.

*----------------------------------------------------------------------*
* SELECTION SCREEN
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form set_screen
*&---------------------------------------------------------------------*
*& Selection Screen PBO
*& - 입력한 Shipping Point의 언어별 Description 표시
*& - 입력값을 지우거나 변경하면 이전 Description도 초기화
*& - 유효성 검증은 CHECK_INPUT에서 수행
*&---------------------------------------------------------------------*
FORM set_screen.

  CLEAR c_vstel.

  CHECK s_vstel-low IS NOT INITIAL.

*----------------------------------------------------------------------*
* Shipping Point Description
* - 텍스트가 없어도 Shipping Point 자체가 없는 것으로 판단하지 않음
*----------------------------------------------------------------------*
  SELECT SINGLE vtext
    FROM tvstt
   WHERE spras = @sy-langu
     AND vstel = @s_vstel-low
    INTO @c_vstel.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form screen_control
*&---------------------------------------------------------------------*
*& Selection Screen PAI
*& - 현재는 모드별 조회조건 변경 사항 없음
*& - 필수 속성은 SCN의 OBLIGATORY 선언 사용
*& - 실행 전 업무 검증은 START-OF-SELECTION의 CHECK_INPUT에서 수행
*&---------------------------------------------------------------------*
FORM screen_control.

* 향후 조회 / 업로드 모드별 조건 제어가 필요하면 이곳에 추가

ENDFORM.

*&---------------------------------------------------------------------*
*& Form screen_ucomm
*&---------------------------------------------------------------------*
*& Selection Screen 전용 Function Code 처리
*& - 현재 SCN에는 별도 Function Key / Pushbutton 없음
*& - 상세 화면 명령은 I01의 USER_COMMAND_0100에서 처리
*&---------------------------------------------------------------------*
FORM screen_ucomm.

* 향후 Selection Screen 전용 버튼 추가 시 이곳에 연결

ENDFORM.

*----------------------------------------------------------------------*
* INPUT VALIDATION
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form check_input
*&---------------------------------------------------------------------*
*& 실행 전 조회조건 검증
*& - Shipping Point / Planned GI Date / Delivery 필수
*& - Planned GI Date는 단일 날짜 / 기간 / 복수 조건 허용
*& - Delivery와 기타 조건의 일치 여부는 GET_LIST에서 확인 예정
*&---------------------------------------------------------------------*
FORM check_input
  CHANGING pv_error TYPE abap_bool.

  DATA:
    lv_vstel TYPE tvst-vstel.

  CLEAR pv_error.

*----------------------------------------------------------------------*
* REQUIRED - SHIPPING POINT
*----------------------------------------------------------------------*
  IF s_vstel-low IS INITIAL.

    pv_error = abap_true.

    MESSAGE TEXT-e04
      TYPE gc_s
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

*----------------------------------------------------------------------*
* REQUIRED - PLANNED GI DATE
* - HIGH는 선택값이므로 필수 검사하지 않음
* - 날짜 형식 / LOW-HIGH 순서 등은 표준 Selection Screen 검사 사용
*----------------------------------------------------------------------*
  IF s_wadat[] IS INITIAL.

    pv_error = abap_true.

    MESSAGE TEXT-e05
      TYPE gc_s
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

*----------------------------------------------------------------------*
* REQUIRED - DELIVERY
* - 현재 SCN은 단일 Delivery 필수 입력 기준
*----------------------------------------------------------------------*
  IF s_vbeln-low IS INITIAL.

    pv_error = abap_true.

    MESSAGE TEXT-e06
      TYPE gc_s
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

*----------------------------------------------------------------------*
* SINGLE VALUE CHECK - SHIPPING POINT
* - 단일 포함 / 일치 조건만 허용
* - 제외 조건이나 패턴 조건으로 실행되지 않도록 확인
*----------------------------------------------------------------------*
  IF lines( s_vstel[] ) <> 1.

    pv_error = abap_true.

    MESSAGE TEXT-e07
      TYPE gc_s
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

  READ TABLE s_vstel INDEX 1.

  IF s_vstel-sign   <> gc_i
     OR s_vstel-option <> gc_eq
     OR s_vstel-high IS NOT INITIAL.

    pv_error = abap_true.

    MESSAGE TEXT-e07
      TYPE gc_s
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

*----------------------------------------------------------------------*
* SINGLE VALUE CHECK - DELIVERY
* - Header와 연결할 Delivery 한 건을 지정
*----------------------------------------------------------------------*
  IF lines( s_vbeln[] ) <> 1.

    pv_error = abap_true.

    MESSAGE TEXT-e08
      TYPE gc_s
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

  READ TABLE s_vbeln INDEX 1.

  IF s_vbeln-sign   <> gc_i
     OR s_vbeln-option <> gc_eq
     OR s_vbeln-high IS NOT INITIAL.

    pv_error = abap_true.

    MESSAGE TEXT-e08
      TYPE gc_s
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

*----------------------------------------------------------------------*
* MASTER CHECK - SHIPPING POINT
* - 언어별 텍스트 테이블이 아닌 TVST에서 존재 여부 확인
*----------------------------------------------------------------------*
  SELECT SINGLE vstel
    FROM tvst
   WHERE vstel = @s_vstel-low
    INTO @lv_vstel.

  IF sy-subrc <> 0.

    pv_error = abap_true.

    MESSAGE TEXT-e09
      TYPE gc_s
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_list
*&---------------------------------------------------------------------*
*& Delivery / 기존 Invoice 조회 및 상세 화면 데이터 구성
*&
*& 신규 문서
*& - Delivery 기준 기본 품목 구성
*& - 조건단가 / 포장정보 계산은 후속 단계에서 연결
*&
*& 기존 문서
*& - ZSDT0060 / ZSDT0061 저장값 표시
*& - 원본 Delivery 품목이 확인되면 SO / PO / 수량 단위 보완
*&
*& 조회 / 검증 완료 후 GS_HEAD / GT_ITEM에 결과 반영
*&---------------------------------------------------------------------*
FORM get_list
  CHANGING pv_error TYPE abap_bool.

*----------------------------------------------------------------------*
* LOCAL TYPE
* - Delivery 품목번호 기준 조회
* - 자재명 보완 시 Material Secondary Key 사용
*----------------------------------------------------------------------*
  TYPES:
    BEGIN OF lty_delivery_item,
      posnr      TYPE lips-posnr,
      matnr      TYPE lips-matnr,
      maktx      TYPE makt-maktx,
      arktx      TYPE lips-arktx,
      lfimg      TYPE lips-lfimg,
      vrkme      TYPE lips-vrkme,
      vbeln_so   TYPE vbap-vbeln,
      posnr_so   TYPE vbap-posnr,
      waerk      TYPE vbap-waerk,
      bstkd_item TYPE vbkd-bstkd_e,
      bstkd_head TYPE vbkd-bstkd,
    END OF lty_delivery_item.

*----------------------------------------------------------------------*
* LOCAL CONSTANT
*----------------------------------------------------------------------*
  CONSTANTS:
    lc_header_posnr TYPE vbkd-posnr VALUE '000000'.

*----------------------------------------------------------------------*
* LOCAL DATA
* - LT_ITEM / LS_HEAD에 구성한 후 전역 변수로 반영
*----------------------------------------------------------------------*
  DATA:
    lt_delivery TYPE SORTED TABLE OF lty_delivery_item
                WITH UNIQUE KEY posnr
                WITH NON-UNIQUE SORTED KEY material
                  COMPONENTS matnr,

    lt_currency TYPE SORTED TABLE OF waerk
                WITH UNIQUE KEY table_line,

    lt_item     TYPE STANDARD TABLE OF gty_item
                WITH EMPTY KEY,

    ls_head     TYPE zsds0060_h,

    lv_waerk    TYPE waerk.

  CLEAR pv_error.

*----------------------------------------------------------------------*
* DELIVERY HEADER
* - 출하지점 / 출고예정일 / 고객 조건 적용
* - 고객명 / Ship-to 명칭 / Delivery Type 설명 함께 조회
*----------------------------------------------------------------------*
  SELECT SINGLE
         a~vbeln,
         a~wadat,
         a~kunag,
         a~kunnr,
         a~lfart,
         a~inco1,
         b~name1 AS customer_name,
         c~name1 AS ship_name,
         d~vtext AS lfart_text
    FROM likp AS a
    LEFT OUTER JOIN kna1 AS b
      ON b~kunnr = a~kunag
    LEFT OUTER JOIN kna1 AS c
      ON c~kunnr = a~kunnr
    LEFT OUTER JOIN tvlkt AS d
      ON d~spras = @sy-langu
     AND d~lfart = a~lfart
   WHERE a~vbeln = @s_vbeln-low
     AND a~vstel IN @s_vstel
     AND a~wadat IN @s_wadat
     AND a~kunag IN @s_kunag
     AND a~kunnr IN @s_kunnr
    INTO @DATA(ls_delivery_head).

  IF sy-subrc <> 0.

    pv_error = abap_true.

    MESSAGE s022
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

*----------------------------------------------------------------------*
* DELIVERY ITEM
* - 품목번호 기준 Sorted Table에 저장
* - SO가 확인되지 않아도 Delivery 품목은 유지
* - LFIMG의 수량 단위는 VRKME 사용
*----------------------------------------------------------------------*
  SELECT a~posnr,
         a~matnr,
         b~maktx,
         a~arktx,
         a~lfimg,
         a~vrkme,
         c~vbeln   AS vbeln_so,
         c~posnr   AS posnr_so,
         c~waerk,
         d~bstkd_e AS bstkd_item,
         e~bstkd   AS bstkd_head
    FROM lips AS a
    LEFT OUTER JOIN makt AS b
      ON b~matnr = a~matnr
     AND b~spras = @sy-langu
    LEFT OUTER JOIN vbap AS c
      ON c~vbeln = a~vgbel
     AND c~posnr = a~vgpos
    LEFT OUTER JOIN vbkd AS d
      ON d~vbeln = c~vbeln
     AND d~posnr = c~posnr
    LEFT OUTER JOIN vbkd AS e
      ON e~vbeln = c~vbeln
     AND e~posnr = @lc_header_posnr
   WHERE a~vbeln = @ls_delivery_head-vbeln
    INTO CORRESPONDING FIELDS OF TABLE @lt_delivery.

  IF lt_delivery IS INITIAL.

    pv_error = abap_true.

    MESSAGE s022
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

*----------------------------------------------------------------------*
* CURRENCY CHECK
* - 통화별 Unique Key로 중복 제거
* - Header는 단일 통화만 허용
* - 통화 미확정 품목은 후속 가격 결정 단계에서 추가 검증
*----------------------------------------------------------------------*
  LOOP AT lt_delivery ASSIGNING FIELD-SYMBOL(<ls_delivery>).

    CHECK <ls_delivery>-waerk IS NOT INITIAL.

    INSERT <ls_delivery>-waerk INTO TABLE lt_currency.

  ENDLOOP.

  IF lines( lt_currency ) > 1.

    pv_error = abap_true.

    MESSAGE TEXT-e13
      TYPE gc_s
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

  lv_waerk = VALUE #( lt_currency[ 1 ] OPTIONAL ).

*----------------------------------------------------------------------*
* EXISTING INVOICE CHECK
* - 문서번호만 최대 두 건 조회하여 단일 문서 여부 확인
* - 복수 Invoice를 임의 선택하지 않음
*----------------------------------------------------------------------*
  SELECT zinvno
    FROM zsdt0060
   WHERE vbeln_vl = @ls_delivery_head-vbeln
     AND zinvno IN @s_invno
    INTO TABLE @DATA(lt_invoice_key)
      UP TO 2 ROWS.

  IF lines( lt_invoice_key ) > 1.

    pv_error = abap_true.

    MESSAGE TEXT-e10
      TYPE gc_s
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

*----------------------------------------------------------------------*
* INVOICE FILTER CHECK
* - 입력한 Invoice가 없으면 신규 문서로 전환하지 않음
*----------------------------------------------------------------------*
  IF s_invno[] IS NOT INITIAL
     AND lt_invoice_key IS INITIAL.

    pv_error = abap_true.

    MESSAGE TEXT-e11
      TYPE gc_s
      DISPLAY LIKE gc_e.

    RETURN.

  ENDIF.

  DATA(lv_existing) = xsdbool( lt_invoice_key IS NOT INITIAL ).

*----------------------------------------------------------------------*
* HEADER BASE
* - 기존 문서는 저장 Header 전체를 화면 구조체에 대응
* - 신규 문서는 Invoice Date / Ship-to / Incoterms 초기값 설정
*----------------------------------------------------------------------*
  IF lv_existing = abap_true.

    DATA(ls_invoice_key) = lt_invoice_key[ 1 ].

    SELECT SINGLE *
      FROM zsdt0060
     WHERE zinvno   = @ls_invoice_key-zinvno
       AND vbeln_vl = @ls_delivery_head-vbeln
      INTO @DATA(ls_invoice).

    IF sy-subrc <> 0.

      pv_error = abap_true.

      MESSAGE TEXT-e11
        TYPE gc_s
        DISPLAY LIKE gc_e.

      RETURN.

    ENDIF.

    ls_head = CORRESPONDING #( ls_invoice ).

  ELSE.

    ls_head = VALUE #(
      zivh15 = sy-datum
      zivh01 = ls_delivery_head-ship_name
      zivh25 = ls_delivery_head-inco1 ).

  ENDIF.

*----------------------------------------------------------------------*
* HEADER DISPLAY INFORMATION
* - 저장된 주소 / 비고 등은 유지
* - Delivery 연결 정보와 조회용 설명 필드 설정
*----------------------------------------------------------------------*
  ls_head = VALUE #(
    BASE ls_head
    vbeln_vl      = ls_delivery_head-vbeln
    kunag         = ls_delivery_head-kunag
    customer_name = ls_delivery_head-customer_name
    kunnr         = ls_delivery_head-kunnr
    lfart         = ls_delivery_head-lfart
    lfart_text    = ls_delivery_head-lfart_text
    waerk         = lv_waerk ).

*----------------------------------------------------------------------*
* EXISTING INVOICE ITEMS
* - 화면 구성 / 원본 연결에 사용하는 필드만 조회
*----------------------------------------------------------------------*
  IF lv_existing = abap_true.

    SELECT zpkgno,
           matnr,
           zivi01,
           zivi02,
           zivi03,
           zivi04,
           zivi05,
           zivi06,
           vbeln_vl,
           posnr,
           netpr,
           netwr
      FROM zsdt0061
     WHERE zinvno = @ls_invoice_key-zinvno
      INTO TABLE @DATA(lt_saved_item).

    IF lt_saved_item IS INITIAL.

      pv_error = abap_true.

      MESSAGE TEXT-e12
        TYPE gc_s
        DISPLAY LIKE gc_e.

      RETURN.

    ENDIF.

*----------------------------------------------------------------------*
* DELIVERY CONSISTENCY
* - 화면 데이터 구성 전에 저장 품목의 Delivery 연결 검증
*----------------------------------------------------------------------*
    LOOP AT lt_saved_item ASSIGNING FIELD-SYMBOL(<ls_saved_check>).

      IF <ls_saved_check>-vbeln_vl IS NOT INITIAL
         AND <ls_saved_check>-vbeln_vl <> ls_delivery_head-vbeln.

        pv_error = abap_true.

        MESSAGE TEXT-e14
          TYPE gc_s
          DISPLAY LIKE gc_e.

        RETURN.

      ENDIF.

    ENDLOOP.

    SORT lt_saved_item BY zpkgno matnr posnr.

*----------------------------------------------------------------------*
* BUILD SAVED ITEMS
* - 저장된 수량 / 포장정보 / 단가 / 금액 유지
* - 원본 품목이 확인될 때만 SO / PO / 수량 단위 보완
*----------------------------------------------------------------------*
    LOOP AT lt_saved_item ASSIGNING FIELD-SYMBOL(<ls_saved>).

      APPEND INITIAL LINE TO lt_item
        ASSIGNING FIELD-SYMBOL(<ls_item>).

      <ls_item> = CORRESPONDING #( <ls_saved> ).

      <ls_item>-wadat = ls_delivery_head-wadat.
      <ls_item>-waerk = lv_waerk.

*----------------------------------------------------------------------*
* 원본 Delivery 품목 검색
* - Sorted Primary Key 사용
* - 검색 실패 시 OPTIONAL로 초기 구조 반환
*----------------------------------------------------------------------*
      DATA(ls_source) = VALUE lty_delivery_item(
        lt_delivery[ posnr = <ls_saved>-posnr ] OPTIONAL ).

      IF ls_source-posnr IS NOT INITIAL
         AND ls_source-matnr = <ls_saved>-matnr.

        <ls_item>-maktx = COND #(
          WHEN ls_source-maktx IS NOT INITIAL
          THEN ls_source-maktx
          ELSE ls_source-arktx ).

        <ls_item>-bstkd_e = COND #(
          WHEN ls_source-bstkd_item IS NOT INITIAL
          THEN ls_source-bstkd_item
          ELSE ls_source-bstkd_head ).

        <ls_item>-meins    = ls_source-vrkme.
        <ls_item>-vbeln_so = ls_source-vbeln_so.
        <ls_item>-posnr_so = ls_source-posnr_so.

      ELSE.

*----------------------------------------------------------------------*
* 원본 품목이 불명확하면 자재명만 보완
* - Material Secondary Key 사용
* - SO / 고객 PO / 수량 단위는 다른 품목에서 임의 복사하지 않음
*----------------------------------------------------------------------*
        DATA(ls_material) = VALUE lty_delivery_item(
          lt_delivery[
            KEY material
            matnr = <ls_saved>-matnr ] OPTIONAL ).

        <ls_item>-maktx = COND #(
          WHEN ls_material-maktx IS NOT INITIAL
          THEN ls_material-maktx
          ELSE ls_material-arktx ).

      ENDIF.

    ENDLOOP.

  ELSE.

*----------------------------------------------------------------------*
* BUILD NEW ITEMS
* - Delivery 품목별 표시
* - 자재명은 현재 언어 텍스트 우선, 없으면 Delivery 품목 내역 사용
* - 고객 PO는 품목 PO 우선, 없으면 Header PO 사용
* - Pack No / 단가 / 포장수량 / 중량 / 부피는 후속 FORM에서 설정
*----------------------------------------------------------------------*
    lt_item = VALUE #(
      FOR ls_new IN lt_delivery
      (
        matnr    = ls_new-matnr

        maktx    = COND #(
          WHEN ls_new-maktx IS NOT INITIAL
          THEN ls_new-maktx
          ELSE ls_new-arktx )

        wadat    = ls_delivery_head-wadat

        bstkd_e  = COND #(
          WHEN ls_new-bstkd_item IS NOT INITIAL
          THEN ls_new-bstkd_item
          ELSE ls_new-bstkd_head )

        zivi01   = ls_new-lfimg
        meins    = ls_new-vrkme
        waerk    = ls_new-waerk

        vbeln_so = ls_new-vbeln_so
        posnr_so = ls_new-posnr_so
      ) ).

  ENDIF.

*----------------------------------------------------------------------*
* HEADER TOTAL AMOUNT
* - 동일 통화의 품목 금액 합산
* - 내부 금액을 그대로 합산하며 통화 자릿수 변환은 수행하지 않음
* - 합산 결과가 Header 금액 필드 범위를 초과하면 오류 반환
*----------------------------------------------------------------------*
  TRY.

      ls_head-total_amount = REDUCE decfloat34(
        INIT lv_total = CONV decfloat34( 0 )
        FOR ls_amount IN lt_item
        NEXT lv_total = lv_total + ls_amount-netwr ).

    CATCH cx_sy_conversion_overflow
          cx_sy_arithmetic_overflow.

      pv_error = abap_true.

      MESSAGE TEXT-e15
        TYPE gc_s
        DISPLAY LIKE gc_e.

      RETURN.

  ENDTRY.

*----------------------------------------------------------------------*
* APPLY DISPLAY DATA
* - 모든 조회 / 검증 완료 후 전역 화면 변수 갱신
* - 신규 문서의 단가 / 금액은 계산 로직 연결 전까지 초기값
*----------------------------------------------------------------------*
* 같은 Invoice를 다시 조회해도 기존 장문 버퍼가 남지 않도록 합니다.
  CLEAR: gv_remark_loaded, gv_remark_invno,
         gt_remark, gt_remark_old.
  gv_remark_push = abap_true.

  gs_head     = ls_head.
  gs_head_old = ls_head.
  gt_item     = lt_item.

  CLEAR:
    gs_item,
    gv_ref_invno,
    gv_gewei,
    gv_voleh,
    gv_changed,
    gv_refresh.

* 조회가 끝난 품목 테이블을 다음 PBO에서 ALV에 반영합니다.
  gv_refresh = abap_true.

ENDFORM.

*----------------------------------------------------------------------*
* ZSDR0150 헤더 화면 / 장문 FORM
* - 기존 조회 흐름과 헤더 변수명을 유지합니다.
* - 7.40 초기 문법 범위에서도 사용하도록 REDUCE / FOR / XSDBOOL 미사용.
* - GUI Text Edit는 SAP GUI for Windows 기준입니다.
*----------------------------------------------------------------------*
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

*----------------------------------------------------------------------*
* 화면 조회 전용 및 필수 표시
* SCREEN-REQUIRED = 2: 권장 입력 표시. 실제 필수 검사는 SAVE 때 수행.
* 복사/목록 전환을 필수값 누락만으로 차단하지 않습니다.
*----------------------------------------------------------------------*
FORM set_header_attributes.
  LOOP AT SCREEN.
    IF screen-name CP 'GS_TEXT-*' OR screen-group1 = 'DIS'
       OR screen-name = 'GV_ZTERM_TEXT'.
      screen-input = gc_0.
      screen-required = gc_0.
      MODIFY SCREEN.
      CONTINUE.
    ENDIF.

    CASE screen-name.
      WHEN 'GS_HEAD-ZIVH01' OR 'GS_HEAD-ZIVH03'
        OR 'GS_HEAD-ZIVH28' OR 'GS_HEAD-ZIVH15'
        OR 'GS_HEAD-ZIVH22' OR 'GS_HEAD-ZIVH25'.
        screen-input = gc_1.
        screen-required = gc_2.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.
ENDFORM.

*----------------------------------------------------------------------*
* Packing Type: 실제 도메인 고정값만 사용. 임의 코드 생성 금지.
*----------------------------------------------------------------------*
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
* 범위 고정값은 단일 드롭다운 값으로 임의 변환하지 않습니다.
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

*----------------------------------------------------------------------*
* Payment Term 설명은 입력값이 아닌 조회 전용 표시값입니다.
*----------------------------------------------------------------------*
FORM get_payment_text.
  CLEAR gv_zterm_text.
  CHECK gs_head-zivh22 IS NOT INITIAL.
  SELECT SINGLE vtext INTO gv_zterm_text
    FROM tvzbt
    WHERE spras = sy-langu AND zterm = gs_head-zivh22.
ENDFORM.

*----------------------------------------------------------------------*
* 저장 시 헤더 필수 6개 + 코드 존재 여부 검사
*----------------------------------------------------------------------*
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

* 화면 일자 타입 검사 외에 저장 진입 시에도 날짜 유효성을 검사합니다.
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

* 드롭다운 값 로딩 오류가 있으면 저장을 차단합니다.
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

*----------------------------------------------------------------------*
* F4: 공통 클래스 사용. Dynpro 반영은 별도로 수행합니다.
*----------------------------------------------------------------------*
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
* 선택한 지급조건 코드를 화면 입력 필드에 반영합니다.
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
* 선택한 Incoterms 코드를 화면 입력 필드에 반영합니다.
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
* 사용자 날짜 표시 형식으로 선택값을 화면에 전달합니다.
  PERFORM update_header_dynpro USING pv_field lv_text.
ENDFORM.

*----------------------------------------------------------------------*
* 장문 읽기: 화면에 적용하기 전에 임시 테이블로 읽습니다.
* 저장 언어는 세션 로그인 언어를 사용합니다.
*----------------------------------------------------------------------*
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
* 신규/기존 장문 미등록은 정상적인 빈 입력 상태입니다.
    WHEN OTHERS.
      pv_error = abap_true.
      MESSAGE TEXT-r10 TYPE gc_s DISPLAY LIKE gc_e.
  ENDCASE.
ENDFORM.

FORM set_remark_editor CHANGING pv_error TYPE abap_bool.
  DATA lt_remark TYPE gty_t_remark.
  CLEAR pv_error.
  IF gv_remark_loaded IS INITIAL OR gv_remark_invno <> gs_head-zinvno.
* 문서번호가 바뀐 경우에만 장문을 읽어 PBO의 입력 덮어쓰기를 방지합니다.
    PERFORM read_shipping_remark USING gs_head-zinvno
                                CHANGING lt_remark pv_error.
    CHECK pv_error IS INITIAL.
    gt_remark = lt_remark.
    gt_remark_old = lt_remark.
    gv_remark_invno = gs_head-zinvno.
    gv_remark_loaded = abap_true.
    gv_remark_push = abap_true.
  ENDIF.

  IF go_remark_cont IS NOT BOUND.
    CREATE OBJECT go_remark_cont
      EXPORTING
        container_name = gc_cont_remark
      EXCEPTIONS
        OTHERS         = 1.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      MESSAGE TEXT-r01 TYPE gc_s DISPLAY LIKE gc_e.
      RETURN.
    ENDIF.
  ENDIF.
  IF go_remark_edit IS NOT BOUND.
    CREATE OBJECT go_remark_edit
      EXPORTING
        parent                     = go_remark_cont
        wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
        wordwrap_position          = gc_remark_width
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true
      EXCEPTIONS
        OTHERS                     = 1.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      MESSAGE TEXT-r01 TYPE gc_s DISPLAY LIKE gc_e.
      RETURN.
    ENDIF.
    gv_remark_push = abap_true.
  ENDIF.
  CHECK gv_remark_push = abap_true.
  CALL METHOD go_remark_edit->set_text_as_r3table
    EXPORTING
      table  = gt_remark
    EXCEPTIONS
      OTHERS = 1.
  IF sy-subrc = 0.
    CALL METHOD cl_gui_cfw=>flush EXCEPTIONS OTHERS = 1.
  ENDIF.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE TEXT-r01 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  CLEAR gv_remark_push.
ENDFORM.
FORM get_remark_editor CHANGING pv_error TYPE abap_bool.
  DATA lt_remark TYPE gty_t_remark.
  CLEAR pv_error.
  IF go_remark_edit IS NOT BOUND OR gv_remark_push = abap_true
     OR gv_remark_loaded IS INITIAL
     OR gv_remark_invno <> gs_head-zinvno.
    pv_error = abap_true.
    RETURN.
  ENDIF.
  CALL METHOD go_remark_edit->get_text_as_r3table
    EXPORTING
      only_when_modified = cl_gui_textedit=>false
    IMPORTING
      table              = lt_remark
    EXCEPTIONS
      OTHERS             = 1.
  IF sy-subrc = 0.
    CALL METHOD cl_gui_cfw=>flush EXCEPTIONS OTHERS = 1.
  ENDIF.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    RETURN.
  ENDIF.
  gt_remark = lt_remark.
  IF gt_remark <> gt_remark_old.
    gv_changed = abap_true.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Copy: 헤더 및 장문만 복사. GT_ITEM은 변경하지 않습니다.
* 현재 아이템을 다른 Delivery 헤더에 잘못 연결하지 않도록 차단합니다.
* 다른 Delivery로의 아이템 교체는 사용자가 보류한 후속 범위입니다.
*----------------------------------------------------------------------*
FORM copy_header_data CHANGING pv_error TYPE abap_bool.
  DATA: lv_invno  TYPE zsdt0060-zinvno,
        ls_db     TYPE zsdt0060,
        ls_head   TYPE zsds0060_h,
        lt_remark TYPE gty_t_remark,
        lv_answer TYPE c LENGTH 1.
  CLEAR pv_error.
  lv_invno = gv_ref_invno.
  IF lv_invno IS INITIAL.
    lv_invno = gs_head-zinvno.
  ENDIF.
  IF lv_invno IS INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-r11 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  SELECT SINGLE * INTO ls_db FROM zsdt0060 WHERE zinvno = lv_invno.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE s022 DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  IF gt_item IS NOT INITIAL AND ls_db-vbeln_vl <> gs_head-vbeln_vl.
    pv_error = abap_true.
    MESSAGE TEXT-r12 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.
  IF gv_changed = abap_true.
    lv_answer = zcl_cm_util=>popup_to_confirm(
      i_text_question = TEXT-r13 i_display_cancel_button = gc_x ).
    IF lv_answer <> gc_1.
      RETURN.
    ENDIF.
  ENDIF.
* 원본 장문 읽기가 실패하면 현재 헤더를 변경하지 않습니다.
  PERFORM read_shipping_remark USING lv_invno
                              CHANGING lt_remark pv_error.
  CHECK pv_error IS INITIAL.
  ls_head = gs_head.
  MOVE-CORRESPONDING ls_db TO ls_head.
* DB 헤더 이외의 화면용 설명값은 복사한 Delivery 기준으로 다시 읽습니다.
  CLEAR: ls_head-kunag, ls_head-kunnr, ls_head-customer_name,
         ls_head-lfart, ls_head-lfart_text.
  SELECT SINGLE kunag kunnr lfart
    INTO (ls_head-kunag, ls_head-kunnr, ls_head-lfart)
    FROM likp WHERE vbeln = ls_head-vbeln_vl.
  SELECT SINGLE name1 INTO ls_head-customer_name
    FROM kna1 WHERE kunnr = ls_head-kunag.
  SELECT SINGLE vtext INTO ls_head-lfart_text
    FROM tvlkt WHERE spras = sy-langu AND lfart = ls_head-lfart.
  CLEAR ls_head-zinvno.
  gs_head = ls_head.
  gt_remark = lt_remark.
  gv_ref_invno = lv_invno.
  CLEAR gv_remark_invno.
  gv_remark_loaded = abap_true.
  gv_remark_push = abap_true.
  gv_changed = abap_true.
ENDFORM.

*----------------------------------------------------------------------*
* 장문 저장: 기존 저장 FORM의 문서번호 확정 후, COMMIT 전에 호출.
* 이 FORM 자체는 COMMIT / ROLLBACK하지 않습니다.
* 빈 장문도 SAVE_TEXT에 전달하여 기존 장문 삭제를 반영합니다.
*----------------------------------------------------------------------*
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
* Direct DB 쓰기로 부모 저장 LUW의 ROLLBACK과 동일하게 처리합니다.
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

*----------------------------------------------------------------------*
* Form REMARK_SAVED
* - 遺紐⑥쓽 COMMIT ?깃났 ?꾩뿉留?蹂寃?鍮꾧탳 湲곗???媛깆떊?⑸땲??
*----------------------------------------------------------------------*
FORM remark_saved.
  gt_remark_old = gt_remark.
  gv_changed    = abap_false.
ENDFORM.

*----------------------------------------------------------------------*
* Form SET_PUSHBUTTON_ICONS
* - 0100 硫붿씤?붾㈃ ?몄떆踰꾪듉 ?꾩씠肄?諛??댄똻 ?숈쟻 ?명똿
*----------------------------------------------------------------------*
FORM set_pushbutton_icons.
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name       = icon_print
      text       = TEXT-b01
      info       = 'Print C/I & P/L'
      add_stdinf = space
    IMPORTING
      result     = gv_pr_cip
    EXCEPTIONS
      OTHERS     = 0.

  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name       = icon_print
      text       = TEXT-b02
      info       = 'Print Commercial Invoice'
      add_stdinf = space
    IMPORTING
      result     = gv_pr_ci
    EXCEPTIONS
      OTHERS     = 0.

  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
      name       = icon_print
      text       = TEXT-b03
      info       = 'Print Packing List'
      add_stdinf = space
    IMPORTING
      result     = gv_pr_pl
    EXCEPTIONS
      OTHERS     = 0.
ENDFORM.

*----------------------------------------------------------------------*
* Form FREE_ITEM_ALV
* - ?꾩씠??ALV 洹몃━??諛?而⑦뀒?대꼫 ?댁젣
*----------------------------------------------------------------------*
FORM free_item_alv.
  IF go_grid IS BOUND.
    CALL METHOD go_grid->free.
    FREE go_grid.
  ENDIF.
  IF go_cont IS BOUND.
    CALL METHOD go_cont->free.
    FREE go_cont.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Form FREE_REMARK_EDITOR
* - Shipping Remark ?띿뒪?몄뿉?뷀꽣 諛?而⑦뀒?대꼫 ?댁젣
*----------------------------------------------------------------------*
FORM free_remark_editor.
  IF go_remark_edit IS BOUND.
    CALL METHOD go_remark_edit->free.
    FREE go_remark_edit.
  ENDIF.
  IF go_remark_cont IS BOUND.
    CALL METHOD go_remark_cont->free.
    FREE go_remark_cont.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Form LEAVE_INVOICE_SCREEN
* - 蹂寃쎌궗???뺤씤 ?앹뾽 諛??붾㈃ 醫낅즺 泥섎━
*----------------------------------------------------------------------*
FORM leave_invoice_screen USING pv_ucomm TYPE sy-ucomm.
  DATA: lv_answer TYPE c LENGTH 1.

  IF gv_changed = abap_true.
    lv_answer = zcl_cm_util=>popup_to_confirm(
      i_text_question         = TEXT-r13
      i_display_cancel_button = gc_x ).
    IF lv_answer <> gc_1.
      RETURN.
    ENDIF.
  ENDIF.

  PERFORM free_item_alv.
  PERFORM free_remark_editor.

  IF pv_ucomm = gc_exit.
    LEAVE PROGRAM.
  ELSE.
    LEAVE TO SCREEN 0.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Form SET_ALV_GRID
* - 0110 Subscreen CC_ITEM Custom Control??ALV 洹몃━???앹꽦 諛??쒖떆
*----------------------------------------------------------------------*
FORM set_alv_grid CHANGING pv_error TYPE abap_bool.
  CLEAR pv_error.

  IF go_cont IS NOT BOUND.
    CREATE OBJECT go_cont
      EXPORTING
        container_name = gc_cont_item
      EXCEPTIONS
        OTHERS         = 1.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.
  ENDIF.

  IF go_grid IS NOT BOUND.
    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_cont
      EXCEPTIONS
        OTHERS   = 1.
    IF sy-subrc <> 0.
      pv_error = abap_true.
      RETURN.
    ENDIF.

    " ?대깽???몃뱾???깅줉
    SET HANDLER lcl_event=>handle_toolbar      FOR go_grid.
    SET HANDLER lcl_event=>handle_user_command  FOR go_grid.

    " ?꾨뱶 移댄깉濡쒓렇 援ъ꽦
    PERFORM build_item_fcat.

    " ?덉씠?꾩썐 ?명똿
    gs_layout-zebra      = gc_x.
    gs_layout-cwidth_opt = gc_x.
    gs_layout-sel_mode   = gc_a.

    gs_variant-report  = sy-repid.
    gs_variant-handle  = gc_layout_item.

    CALL METHOD go_grid->set_table_for_first_display
      EXPORTING
        is_layout       = gs_layout
        is_variant      = gs_variant
        i_save          = gc_layout_save
      CHANGING
        it_outtab       = gt_item
        it_fieldcatalog = gt_fcat
      EXCEPTIONS
        OTHERS          = 1.
    IF sy-subrc <> 0.
      pv_error = abap_true.
    ENDIF.
  ELSE.
    IF gv_refresh = abap_true.
      gs_stable-row = gc_x.
      gs_stable-col = gc_x.
      CALL METHOD go_grid->refresh_table_display
        EXPORTING
          is_stable = gs_stable
        EXCEPTIONS
          OTHERS    = 1.
      CLEAR gv_refresh.
    ENDIF.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Form BUILD_ITEM_FCAT
* - ?꾩씠??ALV ?꾨뱶 移댄깉濡쒓렇 援ъ꽦
*----------------------------------------------------------------------*
FORM build_item_fcat.
  CLEAR gt_fcat.

  DATA: ls_fcat TYPE lvc_s_fcat.

  DEFINE _add_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = &1.
    ls_fcat-coltext   = &2.
    ls_fcat-scrtext_m = &2.
    ls_fcat-checkbox  = &3.
    ls_fcat-edit      = &4.
    ls_fcat-qfieldname = &5.
    ls_fcat-cfieldname = &6.
    APPEND ls_fcat TO gt_fcat.
  END-OF-DEFINITION.

  _add_fcat 'CHECK'    'Select'      gc_x gc_x '' ''.
  _add_fcat 'ZPKGNO'   'Item No'     ''   ''   '' ''.
  _add_fcat 'MATNR'    'Material'    ''   ''   '' ''.
  _add_fcat 'MAKTX'    'Description' ''   ''   '' ''.
  _add_fcat 'WADAT'    'GI Date'     ''   ''   '' ''.
  _add_fcat 'BSTKD_E'  'Cust. PO'    ''   ''   '' ''.
  _add_fcat 'ZIVI01'   'Quantity'    ''   ''   'MEINS' ''.
  _add_fcat 'MEINS'    'Unit'        ''   ''   '' ''.
  _add_fcat 'ZIVI04'   'Net Weight'  ''   ''   'GEWEI' ''.
  _add_fcat 'ZIVI05'   'Gross Weight'''   ''   'GEWEI' ''.
  _add_fcat 'GEWEI'    'Wt. Unit'    ''   ''   '' ''.
  _add_fcat 'ZIVI06'   'Measurement' ''   ''   'VOLEH' ''.
  _add_fcat 'VOLEH'    'Vol. Unit'   ''   ''   '' ''.
  _add_fcat 'ZIVI02'   'U/T Qty'     ''   ''   '' ''.
  _add_fcat 'ZIVI03'   'C/T Qty'     ''   ''   '' ''.
  _add_fcat 'NETPR'    'Unit Price'  ''   ''   '' 'WAERK'.
  _add_fcat 'NETWR'    'Amount'      ''   ''   '' 'WAERK'.
  _add_fcat 'WAERK'    'Currency'    ''   ''   '' ''.
  _add_fcat 'VBELN_SO' 'Sales Order' ''   ''   '' ''.
  _add_fcat 'POSNR_SO' 'SO Item'     ''   ''   '' ''.
ENDFORM.

*----------------------------------------------------------------------*
* Form CHECK_ITEM_ALV
* - ALV ?곗씠??蹂寃쎌궗???대??뚯씠釉?諛섏쁺
*----------------------------------------------------------------------*
FORM check_item_alv CHANGING pv_error TYPE abap_bool.
  CLEAR pv_error.
  IF go_grid IS BOUND.
    DATA: lt_cells TYPE lvc_t_modi.
    CALL METHOD go_grid->check_changed_data
      IMPORTING
        et_good_cells = lt_cells.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Form HANDLE_TOOLBAR
* - ALV ?대컮 ?꾩껜?좏깮 / ?꾩껜?댁젣 踰꾪듉 異붽?
*----------------------------------------------------------------------*
FORM handle_toolbar USING e_object TYPE REF TO cl_alv_event_toolbar_set
                          sender   TYPE REF TO cl_gui_alv_grid.
  DATA: ls_button TYPE stb_button.

  CLEAR ls_button.
  ls_button-function  = gc_tc_sall.
  ls_button-icon      = icon_select_all.
  ls_button-quickinfo = 'Select All'.
  ls_button-text      = '?꾩껜?좏깮'.
  APPEND ls_button TO e_object->mt_toolbar.

  CLEAR ls_button.
  ls_button-function  = gc_tc_dall.
  ls_button-icon      = icon_deselect_all.
  ls_button-quickinfo = 'Deselect All'.
  ls_button-text      = '?꾩껜?댁젣'.
  APPEND ls_button TO e_object->mt_toolbar.
ENDFORM.

*----------------------------------------------------------------------*
* Form HANDLE_USER_COMMAND
* - ALV ?대컮 ?ъ슜???≪뀡 泥섎━
*----------------------------------------------------------------------*
FORM handle_user_command USING e_ucomm TYPE sy-ucomm
                               sender  TYPE REF TO cl_gui_alv_grid.
  CASE e_ucomm.
    WHEN gc_tc_sall.
      LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<ls_item>).
        <ls_item>-check = abap_true.
      ENDLOOP.
      gv_refresh = abap_true.
    WHEN gc_tc_dall.
      LOOP AT gt_item ASSIGNING FIELD-SYMBOL(<ls_item_d>).
        <ls_item_d>-check = abap_false.
      ENDLOOP.
      gv_refresh = abap_true.
  ENDCASE.

  IF gv_refresh = abap_true.
    sender->refresh_table_display( is_stable = VALUE #( row = gc_x col = gc_x ) ).
    CLEAR gv_refresh.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Form SAVE_INVOICE_DATA
* - ?몃낫?댁뒪 ?곗씠?????泥섎━ (?좉퇋 梨꾨쾲 諛?CBO ???
*----------------------------------------------------------------------*
FORM save_invoice_data CHANGING pv_error TYPE abap_bool.
  CLEAR pv_error.
  " ?꾩냽 援ы쁽 ???뚮┝
  MESSAGE TEXT-e03 TYPE gc_s DISPLAY LIKE gc_w.
ENDFORM.