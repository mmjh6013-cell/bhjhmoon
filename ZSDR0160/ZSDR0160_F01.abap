*&---------------------------------------------------------------------*
*& Include          ZSDR0160_F01
*&---------------------------------------------------------------------*

*---------------------------------------------------------------------*
* INITIALIZATION (프로그램 초기화)
*---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form INIT
*&---------------------------------------------------------------------*
*& 프로그램 최초 실행 시 제어 문자(CR, LF, TAB) 및
*& 고정 조회조건(유통경로 40, 제품군 00) 기본값을 세팅한다.
*&---------------------------------------------------------------------*
FORM init.

  " PDF 바이너리/스트림 파싱 시 사용할 개행 및 탭 제어문자 초기화
  gv_cr    = cl_abap_char_utilities=>cr_lf(1).
  gv_lf    = cl_abap_char_utilities=>newline.
  gv_tab   = cl_abap_char_utilities=>horizontal_tab.
  gv_title = sy-title.

  " 설계서 기준: Distribution Channel = '40', Division = '00' 기본값 고정
  s_vtweg[] = VALUE #( ( sign = gc_i option = gc_eq low = gc_vtweg_40 ) ).
  s_spart[] = VALUE #( ( sign = gc_i option = gc_eq low = gc_spart_00 ) ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_TEXT
*&---------------------------------------------------------------------*
*& 선택화면(Selection Screen)에 입력된 조직 코드 및 관계사 코드 우측에
*& 마스터 내역(명칭)을 조회하여 표시한다.
*&---------------------------------------------------------------------*
FORM set_text.

  CLEAR:
    c_vkorg,
    c_vkbur,
    c_vkgrp,
    c_vtweg,
    c_spart,
    c_kunnr.

  " 1. 영업조직 명칭 조회 (TVKOT)
  IF s_vkorg-low IS NOT INITIAL.
    SELECT SINGLE vtext FROM tvkot
     WHERE spras = @sy-langu
       AND vkorg = @s_vkorg-low
      INTO @c_vkorg.
  ENDIF.

  " 2. 사업장(Sales Office) 명칭 조회 (TVKBT)
  IF s_vkbur-low IS NOT INITIAL.
    SELECT SINGLE bezei FROM tvkbt
     WHERE spras = @sy-langu
       AND vkbur = @s_vkbur-low
      INTO @c_vkbur.
  ENDIF.

  " 3. 영업그룹(Sales Group) 명칭 조회 (TVGRT)
  IF s_vkgrp-low IS NOT INITIAL.
    SELECT SINGLE bezei FROM tvgrt
     WHERE spras = @sy-langu
       AND vkgrp = @s_vkgrp-low
      INTO @c_vkgrp.
  ENDIF.

  " 4. 유통경로(Distribution Channel) 명칭 조회 (TVTWT)
  IF s_vtweg-low IS NOT INITIAL.
    SELECT SINGLE vtext FROM tvtwt
     WHERE spras = @sy-langu
       AND vtweg = @s_vtweg-low
      INTO @c_vtweg.
  ENDIF.

  " 5. 제품군(Division) 명칭 조회 (TSPAT)
  IF s_spart-low IS NOT INITIAL.
    SELECT SINGLE vtext FROM tspat
     WHERE spras = @sy-langu
       AND spart = @s_spart-low
      INTO @c_spart.
  ENDIF.

  " 6. 관계사(Affiliated Company) 고객명 조회 (KNA1)
  IF s_kunnr-low IS NOT INITIAL.
    SELECT SINGLE name1 FROM kna1
     WHERE kunnr = @s_kunnr-low
      INTO @c_kunnr.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_SCREEN
*&---------------------------------------------------------------------*
*& 선택화면 PBO 제어:
*& - MODIF ID 'DSP'(유통경로 40, 제품군 00) 필드를 입력 불가(회색)로 잠금
*& - 필수 입력 필드(OBLIGATORY)의 시스템 체크 대신 커스텀 체크를 위해
*&   REQUIRED 속성을 '2'로 변경하고 GT_REQUIRED 목록에 수집
*&---------------------------------------------------------------------*
FORM set_screen.

  CLEAR gt_required.

  LOOP AT SCREEN.

    " 유통경로(40), 제품군(00)은 수정 불가 처리
    IF screen-group1 = 'DSP'.
      screen-input = gc_0.
    ENDIF.

    " 표준 필수 체크에 의해 F4나 이벤트가 막히지 않도록 REQUIRED = '2'로 전환
    screen-required =
      COND #( WHEN screen-required = gc_1
              THEN gc_2
              ELSE screen-required ).

    " 활성화된 필수 필드명을 GT_REQUIRED에 수집 (실행 시 SCREEN_CONTROL에서 검증)
    IF screen-required = gc_2
       AND screen-active = gc_1.
      COLLECT screen-name INTO gt_required.
    ENDIF.

    MODIFY SCREEN.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SCREEN_UCOMM
*&---------------------------------------------------------------------*
*& 선택화면의 Function Key 이벤트 처리 (추후 엑셀 양식 다운로드 등 확장용)
*&---------------------------------------------------------------------*
FORM screen_ucomm.
  " 필요 시 Function Key(FC01 등) 처리 로직 추가
ENDFORM.

*&---------------------------------------------------------------------*
*& Form SCREEN_CONTROL
*&---------------------------------------------------------------------*
*& 실행(F8 / 'ONLI') 시 선택화면 입력값 검증:
*& 1. 필수 입력값 누락 여부 확인
*& 2. 영업영역-사업장(TVKBZ) 및 사업장-영업그룹(TVBVK) 할당 정합성 검증
*& 3. Affiliated Company가 고객그룹 '08'(관계사)인지 확인 (KNVV-KDGRP = '08')
*& 4. KNA1-NAME1의 앞 3자리 법인 식별코드(예: 'EAC', 'EJP') 추출
*&---------------------------------------------------------------------*
FORM screen_control.

  DATA:
    lv_text  TYPE string,
    lv_kdgrp TYPE knvv-kdgrp.

  " 실행 버튼(F8)을 눌렀을 때만 검증 수행
  CHECK sscrfields-ucomm = 'ONLI'.

*---------------------------------------------------------------------*
* 1. 필수 입력 필드 누락 검증
*---------------------------------------------------------------------*
  LOOP AT gt_required INTO DATA(lv_required).

    ASSIGN (lv_required) TO FIELD-SYMBOL(<lv_value>).
    CHECK sy-subrc = 0.

    IF <lv_value> IS INITIAL.
      CLEAR lv_text.
      CASE lv_required.
        WHEN 'S_VKORG-LOW'. lv_text = TEXT-f01. " Sales Organization
        WHEN 'S_VKBUR-LOW'. lv_text = TEXT-f02. " Sales Office
        WHEN 'S_VKGRP-LOW'. lv_text = TEXT-f03. " Sales Group
        WHEN 'S_VTWEG-LOW'. lv_text = TEXT-f04. " Distribution Channel
        WHEN 'S_SPART-LOW'. lv_text = TEXT-f05. " Division
        WHEN 'S_KUNNR-LOW'. lv_text = TEXT-f06. " Affiliated Company
        WHEN 'P_FILE'.      lv_text = TEXT-002. " File Upload
        WHEN OTHERS.        lv_text = lv_required.
      ENDCASE.

      SET CURSOR FIELD lv_required.
      MESSAGE e278(00) WITH lv_text.
    ENDIF.

  ENDLOOP.

*---------------------------------------------------------------------*
* 2. 영업조직-유통경로-제품군 대비 사업장(Sales Office) 할당 검증 (TVKBZ)
*    및 사업장 대비 영업그룹(Sales Group) 할당 검증 (TVBVK)
*---------------------------------------------------------------------*
  SELECT SINGLE vkbur
    FROM tvkbz
   WHERE vkorg = @s_vkorg-low
     AND vtweg = @s_vtweg-low
     AND spart = @s_spart-low
     AND vkbur = @s_vkbur-low
    INTO @DATA(lv_vkbur_chk).

  IF sy-subrc <> 0.
    MESSAGE TEXT-e01 TYPE gc_e.
  ENDIF.

  SELECT SINGLE vkgrp
    FROM tvbvk
   WHERE vkbur = @s_vkbur-low
     AND vkgrp = @s_vkgrp-low
    INTO @DATA(lv_vkgrp_chk).

  IF sy-subrc <> 0.
    MESSAGE TEXT-e02 TYPE gc_e.
  ENDIF.

*---------------------------------------------------------------------*
* 3. 관계사(Affiliated Company) 마스터 검증
*    - 설계서 기준: KNVV-KDGRP = '08' (관계사)만 선택 가능
*    - KNA1-NAME1의 앞 3글자(예: EAC, EJP)를 추출하여 PDF PO 번호와 대조 준비
*---------------------------------------------------------------------*
  CLEAR:
    gv_aff_name1,
    gv_aff_prefix,
    gv_knvv_zterm.

  SELECT SINGLE kdgrp, zterm
    FROM knvv
   WHERE kunnr = @s_kunnr-low
     AND vkorg = @s_vkorg-low
     AND vtweg = @s_vtweg-low
     AND spart = @s_spart-low
    INTO ( @lv_kdgrp, @gv_knvv_zterm ).

  IF sy-subrc <> 0 OR lv_kdgrp <> gc_kdgrp_08.
    MESSAGE TEXT-e03 TYPE gc_e.
  ENDIF.

  SELECT SINGLE name1
    FROM kna1
   WHERE kunnr = @s_kunnr-low
    INTO @gv_aff_name1.

  IF sy-subrc <> 0 OR gv_aff_name1 IS INITIAL.
    MESSAGE TEXT-e03 TYPE gc_e.
  ENDIF.

  " 고객명(KNA1-NAME1)의 앞 3자리 법인 약어 추출 (예: 'EAC', 'EJP')
  gv_aff_prefix = gv_aff_name1(3).
  TRANSLATE gv_aff_prefix TO UPPER CASE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F4_FILENAME
*&---------------------------------------------------------------------*
*& 업로드할 파일(PDF 또는 Excel) 선택 다이얼로그 호출 (ZCL_CM_UTIL 재사용)
*&---------------------------------------------------------------------*
FORM f4_filename CHANGING pv_file TYPE rlgrap-filename.

  DATA:
    lv_msg  TYPE string,
    lv_path TYPE string.

  lv_path = zcl_cm_util=>file_open_dialog(
    EXPORTING
      i_title       = TEXT-003
      i_file_filter = 'PDF / Excel (*.pdf;*.xlsx;*.xls)|*.pdf;*.xlsx;*.xls|All (*.*)|*.*'
    IMPORTING
      e_msg         = lv_msg ).

  IF lv_msg IS NOT INITIAL.
    MESSAGE lv_msg TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  IF lv_path IS NOT INITIAL.
    pv_file = lv_path.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PROCESS_DATA
*&---------------------------------------------------------------------*
*& 메인 비즈니스 처리 흐름:
*& 1. 파일 확장자 판별 (.PDF vs .XLS/.XLSX) 및 파일 파싱
*& 2. 추출된 원본 문자열(GT_RAW)을 ALV 출력 구조(GT_DISP)로 변환 및 워킹데이 계산
*& 3. 자재 마스터(MARA, MAKT) 일괄 조회
*& 4. 기생성된 판매오더(VBAK/VBAP) 및 구매오더(EKPO) 번호 매핑
*& 5. PO Date 기준의 마스터 단가(ZSR1) Access Sequence 동적 조회
*& 6. 행 단위 정합성 체크 및 공급가액(Amount) 계산
*& 7. 에러 없으면 ALV 화면(0100) 호출
*&---------------------------------------------------------------------*
FORM process_data.

  DATA:
    lv_ext   TYPE string,
    lv_count TYPE i.

  CLEAR:
    gv_error,
    gt_raw,
    gt_disp.

*---------------------------------------------------------------------*
* 1. 파일 확장자 추출 및 PDF / Excel 업로드 분기 (요구사항 1.1)
*---------------------------------------------------------------------*
  PERFORM get_file_extension
    USING    p_file
    CHANGING lv_ext.

  CASE lv_ext.

    WHEN 'PDF'.
      " A. EAC / EJP (PDF 파일 업로드 및 텍스트 좌표 파싱)
      PERFORM pdf_upload CHANGING gv_error.

    WHEN 'XLS' OR 'XLSX'.
      " B. EGE / EVN / EHK / ESH (엑셀 양식 확정 후 구현 예정인 분기 스텁)
      PERFORM excel_upload_stub CHANGING gv_error.

    WHEN OTHERS.
      gv_error = abap_true.
      MESSAGE TEXT-e04 TYPE gc_s DISPLAY LIKE gc_e.

  ENDCASE.

  CHECK gv_error = abap_false.

*---------------------------------------------------------------------*
* 2. Staging 데이터(GT_RAW) -> ALV 데이터(GT_DISP) 변환 및 마스터/단가 매핑
*---------------------------------------------------------------------*
  " 2-1) 날짜 변환, Closing Date(ETD - 3 Working Days) 계산, 자재코드/단가 변환
  PERFORM make_upload_data.

  " 2-2) 자재 기본단위(MARA-MEINS) 및 자재내역(MAKT-MAKTX) 일괄 조회
  PERFORM get_check_master_data.

  " 2-3) 기생성된 Sales Order(VBAK/VBAP) 및 Purchase Order(EKPO) 연결 조회
  PERFORM get_existing_so_po.

  " 2-4) PO Date 기준 Condition Type 'ZSR1' 마스터 단가(Master Unit Price) 조회
  PERFORM get_current_price CHANGING gv_error.
  CHECK gv_error = abap_false.

  " 2-5) 필수값 및 마스터 존재 여부 행 단위 검증
  PERFORM check_display_data.

  " 2-6) PO 수량 * PO 단가 기준 금액(Amount) 계산
  PERFORM set_display_amount.

  " 2-7) 업로드 에러 존재 여부 확인 후 에러 팝업 표시
  PERFORM check_upload_error CHANGING gv_error.

  IF gv_error = abap_true.
    PERFORM show_error_popup.
    RETURN.
  ENDIF.

  " 2-8) ALV 상태 아이콘 및 셀 편집 스타일(기생성 SO 행 잠금) 세팅
  PERFORM set_display_status.
  PERFORM set_edit_style.

  lv_count = lines( gt_disp ).
  IF lv_count = 0.
    MESSAGE s022 DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  MESSAGE s004 WITH lv_count.

  " 3. ALV 그리드 화면(0100) 호출
  CALL SCREEN 0100.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_FILE_EXTENSION
*&---------------------------------------------------------------------*
*& 파일 경로에서 마지막 마침표('.') 뒤의 확장자를 대문자로 추출한다.
*& (ZCL_CM_UTIL=>PATH_FILE_SPLIT은 CHAR3 제약이 있어 .XLSX 대응을 위해 직접 분리)
*&---------------------------------------------------------------------*
FORM get_file_extension
  USING    pv_file TYPE rlgrap-filename
  CHANGING pv_ext  TYPE string.

  DATA:
    lv_full  TYPE string,
    lt_parts TYPE STANDARD TABLE OF string WITH EMPTY KEY,
    lv_lines TYPE i.

  CLEAR pv_ext.
  lv_full = pv_file.

  SPLIT lv_full AT '.' INTO TABLE lt_parts.
  lv_lines = lines( lt_parts ).

  IF lv_lines > 1.
    READ TABLE lt_parts INTO pv_ext INDEX lv_lines.
    CONDENSE pv_ext NO-GAPS.
    TRANSLATE pv_ext TO UPPER CASE.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form EXCEL_UPLOAD_STUB
*&---------------------------------------------------------------------*
*& 엑셀 파일 업로드 시 호출되는 분기점 (양식 확정 후 세부 구현 예정)
*&---------------------------------------------------------------------*
FORM excel_upload_stub CHANGING pv_error TYPE abap_bool.
  pv_error = abap_true.
  MESSAGE TEXT-e05 TYPE gc_s DISPLAY LIKE gc_e.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_UPLOAD
*&---------------------------------------------------------------------*
*& PDF 파일 업로드 메인 제어:
*& 1. PC의 PDF 파일을 Binary(XSTRING)로 업로드
*& 2. PDF 내부 스트림 압축 해제 및 좌표별 텍스트 행(GT_PDF_OUT) 조립
*& 3. 관계사 Prefix(KNA1-NAME1 앞 3자리: EAC vs EJP)에 따라 파싱 로직 분기
*&---------------------------------------------------------------------*
FORM pdf_upload CHANGING pv_error TYPE abap_bool.

  CLEAR:
    pv_error,
    gv_pdf_xstr,
    gt_pdf_out,
    gt_pdf_frag,
    gt_pdf_cmap,
    gt_raw.

*---------------------------------------------------------------------*
* 1. PC 로컬 PDF 파일 바이너리 업로드
*---------------------------------------------------------------------*
  PERFORM pdf_read_binary CHANGING pv_error.
  CHECK pv_error = abap_false.

*---------------------------------------------------------------------*
* 2. PDF 스트림 압축 해제 및 좌표 기반 라인(GT_PDF_OUT) 추출
*---------------------------------------------------------------------*
  PERFORM pdf_extract_streams CHANGING pv_error.
  CHECK pv_error = abap_false.

*---------------------------------------------------------------------*
* 3. 법인 코드(KNA1-NAME1 앞 3자리) 기준 양식 분기 (요구사항 1, 2)
*---------------------------------------------------------------------*
  CASE gv_aff_prefix.

    WHEN gc_aff_eac.
      " EAC (ESTec America) 발주서 PDF 좌표 파싱 수행
      PERFORM parse_pdf_eac CHANGING pv_error.

    WHEN gc_aff_ejp.
      " EJP (일본 법인) PDF 양식 분기 처리 (추후 양식 확정 시 구현)
      pv_error = abap_true.
      MESSAGE TEXT-e06 TYPE gc_s DISPLAY LIKE gc_e.

    WHEN OTHERS.
      pv_error = abap_true.
      MESSAGE TEXT-e07 TYPE gc_s DISPLAY LIKE gc_e.

  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_READ_BINARY
*&---------------------------------------------------------------------*
*& 프론트엔드 PC에서 PDF 파일을 BIN 모드로 읽어 XSTRING(GV_PDF_XSTR)으로 변환
*&---------------------------------------------------------------------*
FORM pdf_read_binary CHANGING pv_error TYPE abap_bool.

  DATA:
    lt_bin TYPE solix_tab,
    lv_len TYPE i,
    lv_fn  TYPE string.

  lv_fn = p_file.

  cl_gui_frontend_services=>gui_upload(
    EXPORTING
      filename                = lv_fn
      filetype                = 'BIN'
    IMPORTING
      filelength              = lv_len
    CHANGING
      data_tab                = lt_bin
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      OTHERS                  = 9 ).

  IF sy-subrc <> 0.
    pv_error = abap_true.
    MESSAGE s017 DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  " Binary 테이블을 단일 XSTRING 버퍼로 변환
  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
    EXPORTING
      input_length = lv_len
    IMPORTING
      buffer       = gv_pdf_xstr
    TABLES
      binary_tab   = lt_bin
    EXCEPTIONS
      failed       = 1
      OTHERS       = 2.

  IF sy-subrc <> 0 OR gv_pdf_xstr IS INITIAL.
    pv_error = abap_true.
    MESSAGE s017 DISPLAY LIKE gc_e.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_EXTRACT_STREAMS
*&---------------------------------------------------------------------*
*& 순수 ABAP 기반 PDF 텍스트 추출 엔진:
*& - Latin-1(ISO-8859-1) 1:1 매핑으로 바이트 오프셋을 유지한 채 'stream' 탐색
*& - 이미지/폰트/메타데이터 등 비텍스트 스트림 제외
*& - zlib(FlateDecode) 압축 스트림을 해제한 후 텍스트 연산자(Tj, TJ) 파싱
*&---------------------------------------------------------------------*
FORM pdf_extract_streams CHANGING pv_error TYPE abap_bool.

  DATA:
    lv_str  TYPE string,
    lv_tot  TYPE i,
    lv_xlen TYPE i,
    lv_off  TYPE i,
    lv_p1   TYPE i,
    lv_sb   TYPE i,
    lv_se   TYPE i,
    lv_slen TYPE i,
    lv_dlen TYPE i,
    lv_dict TYPE string,
    lv_c    TYPE string,
    lv_xs   TYPE xstring,
    lv_out  TYPE xstring,
    lv_txt  TYPE string,
    lv_ps   TYPE i.

  CLEAR:
    gt_pdf_frag,
    gt_pdf_out,
    gt_pdf_cmap,
    gv_skip.

  " 바이트 위치와 문자 위치를 1:1로 맞추기 위해 ISO-8859-1로 문자열 변환
  PERFORM pdf_x2str USING gv_pdf_xstr CHANGING lv_str.
  lv_tot  = strlen( lv_str ).
  lv_xlen = xstrlen( gv_pdf_xstr ).

  " 오프셋 정합성 검증 (불일치 시 바이너리 슬라이싱이 깨지므로 중단)
  IF lv_tot <> lv_xlen.
    pv_error = abap_true.
    MESSAGE TEXT-e08 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  " 폰트 글리프 코드를 유니코드로 매핑하는 /ToUnicode CMap 스트림 선행 수집
  PERFORM pdf_collect_cmaps USING lv_str lv_tot lv_xlen.

  lv_off = 0.
  WHILE lv_off < lv_tot.

    " 다음 'stream' 키워드 탐색
    lv_p1 = find( val = lv_str sub = 'stream' off = lv_off ).
    IF lv_p1 < 0.
      EXIT.
    ENDIF.

    " 'endstream' 안에 포함된 'stream' 문자열 오탐 제외
    IF lv_p1 >= 3.
      lv_ps = lv_p1 - 3.
      IF lv_str+lv_ps(3) = 'end'.
        lv_off = lv_p1 + 6.
        CONTINUE.
      ENDIF.
    ENDIF.

    " PDF 표준상 'stream' 바로 뒤에는 반드시 CR 또는 LF가 와야 함
    lv_ps = lv_p1 + 6.
    IF lv_ps >= lv_tot.
      EXIT.
    ENDIF.

    lv_c = lv_str+lv_ps(1).
    IF lv_c <> gv_cr AND lv_c <> gv_lf.
      lv_off = lv_p1 + 6.
      CONTINUE.
    ENDIF.

    " 'stream' 직전의 오브젝트 사전(<< ... >>) 역추출
    PERFORM pdf_get_dict_back USING lv_str lv_p1 CHANGING lv_dict.
    IF lv_dict IS INITIAL.
      lv_off = lv_p1 + 6.
      CONTINUE.
    ENDIF.

    " 이미지, 폰트 파일, XRef, 메타데이터 등 비텍스트 스트림은 스킵
    IF lv_dict CS '/Image'     OR lv_dict CS '/FontFile'
    OR lv_dict CS '/DCTDecode' OR lv_dict CS '/JPXDecode'
    OR lv_dict CS '/XRef'      OR lv_dict CS '/Metadata'
    OR lv_dict CS '/Length1'   OR lv_dict CS '/ObjStm'
    OR lv_dict CS '/CIDSet'    OR lv_dict CS '/Subtype/Type1C'
    OR ( lv_dict CS '/S ' AND lv_dict CS '/V ' ).
      lv_off = lv_p1 + 6.
      CONTINUE.
    ENDIF.

    " 스트림 본문(바이너리) 시작 오프셋 계산 (개행문자 스킵)
    lv_sb = lv_p1 + 6.
    WHILE lv_sb < lv_tot.
      lv_c = lv_str+lv_sb(1).
      IF lv_c = gv_cr OR lv_c = gv_lf.
        lv_sb = lv_sb + 1.
      ELSE.
        EXIT.
      ENDIF.
    ENDWHILE.

    " 스트림 길이 산출: 1순위 사전의 /Length 값, 2순위 'endstream' 위치
    PERFORM pdf_get_stream_len USING lv_dict CHANGING lv_dlen.

    IF lv_dlen > 0 AND lv_sb + lv_dlen <= lv_xlen.
      lv_slen = lv_dlen.
      lv_se   = lv_sb + lv_dlen.
    ELSE.
      lv_se = find( val = lv_str sub = 'endstream' off = lv_sb ).
      IF lv_se < 0.
        lv_off = lv_p1 + 6.
        CONTINUE.
      ENDIF.
      lv_slen = lv_se - lv_sb.
    ENDIF.

    IF lv_slen <= 0 OR lv_sb + lv_slen > lv_xlen.
      gv_skip = gv_skip + 1.
      lv_off  = lv_se + 9.
      CONTINUE.
    ENDIF.

    " 스트림 구간 잘라내기 및 zlib(Deflate) 압축 해제
    lv_xs = gv_pdf_xstr+lv_sb(lv_slen).
    CLEAR lv_out.
    PERFORM pdf_inflate USING lv_xs CHANGING lv_out.
    IF lv_out IS INITIAL.
      lv_out = lv_xs.
    ENDIF.

    " 압축 해제된 Content Stream에 텍스트 출력 연산자(Tj, TJ)가 있으면 파싱
    PERFORM pdf_x2str USING lv_out CHANGING lv_txt.
    IF lv_txt CS 'Tj' OR lv_txt CS 'TJ'.
      PERFORM pdf_parse_content USING lv_txt.
    ENDIF.

    lv_off = lv_se + 9.
  ENDWHILE.

  " 추출된 텍스트 조각(GT_PDF_FRAG)들을 페이지/좌표 기준 행(GT_PDF_OUT)으로 조립
  PERFORM pdf_build_lines.

  IF gt_pdf_out IS INITIAL.
    pv_error = abap_true.
    MESSAGE s022 DISPLAY LIKE gc_e.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_INFLATE
*&---------------------------------------------------------------------*
*& PDF FlateDecode(zlib) 스트림 압축 해제:
*& PDF의 FlateDecode는 앞 2바이트 zlib 헤더와 뒤 4바이트 Adler32 체크섬을
*& 가지므로, 이를 제거한 Raw Deflate 바디를 CL_ABAP_GZIP에 전달한다.
*&---------------------------------------------------------------------*
FORM pdf_inflate USING    pv_in  TYPE xstring
                 CHANGING pv_out TYPE xstring.

  DATA:
    lv_len  TYPE i,
    lv_b1   TYPE x LENGTH 1,
    lv_cmf  TYPE i,
    lv_mod  TYPE i,
    lv_body TYPE xstring,
    lv_cut  TYPE i.

  CLEAR pv_out.
  lv_len = xstrlen( pv_in ).
  IF lv_len < 3.
    RETURN.
  ENDIF.

  " 첫 바이트 하위 4비트가 8(Deflate 방식)인지 확인
  lv_b1  = pv_in(1).
  lv_cmf = lv_b1.
  lv_mod = lv_cmf MOD 16.

  IF lv_mod = 8.
    " 1단계: 앞 2바이트(zlib 헤더) + 뒤 4바이트(체크섬) 총 6바이트 제외 후 압축 해제 시도
    IF lv_len > 6.
      lv_cut  = lv_len - 6.
      lv_body = pv_in+2(lv_cut).
      PERFORM pdf_try_raw USING lv_body CHANGING pv_out.
      IF pv_out IS NOT INITIAL.
        RETURN.
      ENDIF.
    ENDIF.

    " 1-2단계: 앞 2바이트만 제외하고 압축 해제 재시도
    lv_body = pv_in+2.
    PERFORM pdf_try_raw USING lv_body CHANGING pv_out.
    IF pv_out IS NOT INITIAL.
      RETURN.
    ENDIF.
  ENDIF.

  " 2단계: 헤더 제거 없이 원본 그대로 압축 해제 시도
  PERFORM pdf_try_raw USING pv_in CHANGING pv_out.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_TRY_RAW
*&---------------------------------------------------------------------*
*& CL_ABAP_GZIP=>DECOMPRESS_BINARY를 호출하여 Raw Deflate 스트림을 복원한다.
*&---------------------------------------------------------------------*
FORM pdf_try_raw USING    pv_in  TYPE xstring
                 CHANGING pv_out TYPE xstring.

  DATA lv_l TYPE i.

  CLEAR pv_out.
  lv_l = xstrlen( pv_in ).
  IF lv_l < 1.
    RETURN.
  ENDIF.

  TRY.
      cl_abap_gzip=>decompress_binary(
        EXPORTING
          gzip_in     = pv_in
          gzip_in_len = lv_l
        IMPORTING
          raw_out     = pv_out ).
    CATCH cx_root.
      CLEAR pv_out.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_X2STR
*&---------------------------------------------------------------------*
*& XSTRING 데이터를 ISO-8859-1(코드페이지 1100) 기준으로 STRING으로 변환한다.
*&---------------------------------------------------------------------*
FORM pdf_x2str USING    pv_x TYPE xstring
               CHANGING pv_s TYPE string.

  DATA lo_in TYPE REF TO cl_abap_conv_in_ce.

  CLEAR pv_s.
  IF pv_x IS INITIAL.
    RETURN.
  ENDIF.

  TRY.
      lo_in = cl_abap_conv_in_ce=>create(
                input    = pv_x
                encoding = '1100' ).
      lo_in->read( IMPORTING data = pv_s ).
    CATCH cx_root.
      CLEAR pv_s.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_COLLECT_CMAPS
*&---------------------------------------------------------------------*
*& PDF 내부의 '/CMapType' 스트림을 찾아 압축 해제한 뒤,
*& 글리프 인덱스(Hex)와 실제 유니코드 문자 간의 매핑 테이블(GT_PDF_CMAP)을 구축한다.
*&---------------------------------------------------------------------*
FORM pdf_collect_cmaps USING pv_str TYPE string
                             pv_tot TYPE i
                             pv_xln TYPE i.

  DATA:
    lv_off TYPE i,
    lv_p   TYPE i,
    lv_sp  TYPE i,
    lv_sb  TYPE i,
    lv_se  TYPE i,
    lv_len TYPE i,
    lv_c   TYPE string,
    lv_xs  TYPE xstring,
    lv_out TYPE xstring,
    lv_txt TYPE string,
    lv_idx TYPE i.

  lv_off = 0.
  lv_idx = 0.

  WHILE lv_off < pv_tot.
    lv_p = find( val = pv_str sub = '/CMapType' off = lv_off ).
    IF lv_p < 0.
      EXIT.
    ENDIF.

    lv_sp = find( val = pv_str sub = 'stream' off = lv_p ).
    IF lv_sp < 0.
      EXIT.
    ENDIF.

    lv_sb = lv_sp + 6.
    WHILE lv_sb < pv_tot.
      lv_c = pv_str+lv_sb(1).
      IF lv_c = gv_cr OR lv_c = gv_lf.
        lv_sb = lv_sb + 1.
      ELSE.
        EXIT.
      ENDIF.
    ENDWHILE.

    lv_se = find( val = pv_str sub = 'endstream' off = lv_sb ).
    IF lv_se < 0.
      EXIT.
    ENDIF.

    lv_len = lv_se - lv_sb.

    IF lv_len > 0 AND lv_sb + lv_len <= pv_xln.
      lv_xs = gv_pdf_xstr+lv_sb(lv_len).
      PERFORM pdf_inflate USING lv_xs CHANGING lv_out.
      IF lv_out IS INITIAL.
        lv_out = lv_xs.
      ENDIF.

      PERFORM pdf_x2str USING lv_out CHANGING lv_txt.
      IF lv_txt CS 'beginbfchar' OR lv_txt CS 'beginbfrange'.
        lv_idx = lv_idx + 1.
        PERFORM pdf_parse_cmap USING lv_txt lv_idx.
      ENDIF.
    ENDIF.

    lv_off = lv_se + 9.
  ENDWHILE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_PARSE_CMAP
*&---------------------------------------------------------------------*
*& CMap 텍스트에서 단건 매핑(bfchar: <src> <dst>)과
*& 범위 매핑(bfrange: <lo> <hi> <dst>)을 정규식으로 추출해 GT_PDF_CMAP에 저장한다.
*&---------------------------------------------------------------------*
FORM pdf_parse_cmap USING pv_txt TYPE string
                          pv_idx TYPE i.

  DATA:
    lt_m    TYPE match_result_tab,
    ls_m    TYPE match_result,
    ls_s1   TYPE submatch_result,
    ls_s2   TYPE submatch_result,
    ls_s3   TYPE submatch_result,
    lv_a    TYPE string,
    lv_b    TYPE string,
    lv_d    TYPE string,
    lv_lo   TYPE i,
    lv_hi   TYPE i,
    lv_ds   TYPE i,
    lv_i    TYPE i,
    lv_u    TYPE i,
    ls_cmap TYPE gty_pdf_cmap.

  " 1. 단건 매핑(bfchar) 정규식 추출
  FIND ALL OCCURRENCES OF
    REGEX '<([0-9A-Fa-f]{2,8})>[ \r\n\t]*<([0-9A-Fa-f]{2,32})>[ \r\n\t]*(?!<)'
    IN pv_txt RESULTS lt_m.

  LOOP AT lt_m INTO ls_m.
    READ TABLE ls_m-submatches INTO ls_s1 INDEX 1.
    IF sy-subrc <> 0. CONTINUE. ENDIF.
    READ TABLE ls_m-submatches INTO ls_s2 INDEX 2.
    IF sy-subrc <> 0. CONTINUE. ENDIF.

    lv_a = pv_txt+ls_s1-offset(ls_s1-length).
    lv_b = pv_txt+ls_s2-offset(ls_s2-length).

    CLEAR ls_cmap.
    ls_cmap-idx = pv_idx.
    PERFORM pdf_hex2int USING lv_a CHANGING ls_cmap-code.
    PERFORM pdf_hex2str USING lv_b CHANGING ls_cmap-uni.

    IF ls_cmap-uni IS NOT INITIAL.
      READ TABLE gt_pdf_cmap TRANSPORTING NO FIELDS
        WITH KEY idx = ls_cmap-idx code = ls_cmap-code.
      IF sy-subrc <> 0.
        APPEND ls_cmap TO gt_pdf_cmap.
      ENDIF.
    ENDIF.
  ENDLOOP.

  " 2. 범위 매핑(bfrange) 정규식 추출
  CLEAR lt_m.
  FIND ALL OCCURRENCES OF
    REGEX '<([0-9A-Fa-f]{2,8})>[ \r\n\t]*<([0-9A-Fa-f]{2,8})>[ \r\n\t]*<([0-9A-Fa-f]{2,32})>'
    IN pv_txt RESULTS lt_m.

  LOOP AT lt_m INTO ls_m.
    READ TABLE ls_m-submatches INTO ls_s1 INDEX 1.
    IF sy-subrc <> 0. CONTINUE. ENDIF.
    READ TABLE ls_m-submatches INTO ls_s2 INDEX 2.
    IF sy-subrc <> 0. CONTINUE. ENDIF.
    READ TABLE ls_m-submatches INTO ls_s3 INDEX 3.
    IF sy-subrc <> 0. CONTINUE. ENDIF.

    lv_a = pv_txt+ls_s1-offset(ls_s1-length).
    lv_b = pv_txt+ls_s2-offset(ls_s2-length).
    lv_d = pv_txt+ls_s3-offset(ls_s3-length).

    PERFORM pdf_hex2int USING lv_a CHANGING lv_lo.
    PERFORM pdf_hex2int USING lv_b CHANGING lv_hi.
    PERFORM pdf_hex2int USING lv_d CHANGING lv_ds.

    IF lv_hi < lv_lo OR lv_hi - lv_lo > 20000.
      CONTINUE.
    ENDIF.

    lv_i = lv_lo.
    lv_u = lv_ds.

    WHILE lv_i <= lv_hi.
      CLEAR ls_cmap.
      ls_cmap-idx  = pv_idx.
      ls_cmap-code = lv_i.
      PERFORM pdf_cp2char USING lv_u CHANGING ls_cmap-uni.

      IF ls_cmap-uni IS NOT INITIAL.
        READ TABLE gt_pdf_cmap TRANSPORTING NO FIELDS
          WITH KEY idx = ls_cmap-idx code = ls_cmap-code.
        IF sy-subrc <> 0.
          APPEND ls_cmap TO gt_pdf_cmap.
        ENDIF.
      ENDIF.

      lv_i = lv_i + 1.
      lv_u = lv_u + 1.
    ENDWHILE.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_HEX2INT
*&---------------------------------------------------------------------*
*& 16진수 문자열(예: '0041')을 10진수 정수(65)로 변환한다.
*&---------------------------------------------------------------------*
FORM pdf_hex2int USING    pv_hex TYPE string
                 CHANGING pv_i   TYPE i.

  DATA:
    lv_h TYPE string,
    lv_n TYPE i,
    lv_i TYPE i,
    lv_c TYPE string,
    lv_v TYPE i.

  pv_i = 0.
  lv_h = pv_hex.
  TRANSLATE lv_h TO UPPER CASE.
  CONDENSE lv_h NO-GAPS.

  lv_n = strlen( lv_h ).
  lv_i = 0.

  WHILE lv_i < lv_n.
    lv_c = lv_h+lv_i(1).
    lv_v = find( val = '0123456789ABCDEF' sub = lv_c ).
    IF lv_v < 0.
      lv_v = 0.
    ENDIF.
    pv_i = pv_i * 16 + lv_v.
    lv_i = lv_i + 1.
  ENDWHILE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_CP2CHAR
*&---------------------------------------------------------------------*
*& 유니코드 코드포인트(정수)를 UTF-16BE(4102) 변환기를 통해 실제 문자로 변환한다.
*&---------------------------------------------------------------------*
FORM pdf_cp2char USING    pv_cp TYPE i
                 CHANGING pv_c  TYPE string.

  DATA:
    lv_x2 TYPE x LENGTH 2,
    lv_xs TYPE xstring,
    lo_in TYPE REF TO cl_abap_conv_in_ce.

  CLEAR pv_c.
  IF pv_cp < 32 OR pv_cp > 65533.
    RETURN.
  ENDIF.

  lv_x2 = pv_cp.
  lv_xs = lv_x2.

  TRY.
      lo_in = cl_abap_conv_in_ce=>create(
                input    = lv_xs
                encoding = '4102' ).
      lo_in->read( IMPORTING data = pv_c ).
    CATCH cx_root.
      CLEAR pv_c.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_HEX2STR
*&---------------------------------------------------------------------*
*& UTF-16BE 16진수 문자열을 4자리씩 끊어 유니코드 문자열로 변환한다.
*&---------------------------------------------------------------------*
FORM pdf_hex2str USING    pv_hex TYPE string
                 CHANGING pv_s   TYPE string.

  DATA:
    lv_h TYPE string,
    lv_n TYPE i,
    lv_i TYPE i,
    lv_u TYPE i,
    lv_c TYPE string.

  CLEAR pv_s.
  lv_h = pv_hex.
  TRANSLATE lv_h TO UPPER CASE.
  CONDENSE lv_h NO-GAPS.

  lv_n = strlen( lv_h ).
  lv_i = 0.

  WHILE lv_i + 4 <= lv_n.
    lv_c = lv_h+lv_i(4).
    PERFORM pdf_hex2int USING lv_c CHANGING lv_u.
    CLEAR lv_c.
    PERFORM pdf_cp2char USING lv_u CHANGING lv_c.
    CONCATENATE pv_s lv_c INTO pv_s RESPECTING BLANKS.
    lv_i = lv_i + 4.
  ENDWHILE.

  IF lv_n = 2.
    lv_c = lv_h.
    PERFORM pdf_hex2int USING lv_c CHANGING lv_u.
    CLEAR lv_c.
    PERFORM pdf_cp2char USING lv_u CHANGING lv_c.
    CONCATENATE pv_s lv_c INTO pv_s RESPECTING BLANKS.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_PARSE_CONTENT
*&---------------------------------------------------------------------*
*& PDF Content Stream 내부의 위치 연산자(Td, TD, Tm, TL, T*)와
*& 텍스트 출력 연산자(Tj, TJ)를 해석하여 (X, Y) 좌표별 텍스트 조각을 수집한다.
*&---------------------------------------------------------------------*
FORM pdf_parse_content USING pv_txt TYPE string.

  DATA:
    lv_len   TYPE i,
    lv_i     TYPE i,
    lv_c     TYPE string,
    lv_d     TYPE string,
    lv_nx    TYPE string,
    lv_buf   TYPE string,
    lv_dep   TYPE i,
    lv_esc   TYPE c LENGTH 1,
    lv_pend  TYPE string,
    lv_tok   TYPE string,
    lv_tok2  TYPE string,
    lv_hx    TYPE string,
    lv_he    TYPE i,
    lt_num   TYPE STANDARD TABLE OF string,
    lv_num   TYPE string,
    lv_n     TYPE i,
    lv_isop  TYPE c LENGTH 1,
    lv_x     TYPE f,
    lv_y     TYPE f,
    lv_lx    TYPE f,
    lv_ly    TYPE f,
    lv_lead  TYPE f,
    lv_f     TYPE f,
    lv_ratio TYPE f,
    lv_char  TYPE c LENGTH 1.

  lv_len  = strlen( pv_txt ).
  lv_i    = 0.
  lv_lead = '12.0'.
  CLEAR: lv_x, lv_y, lv_lx, lv_ly.

  WHILE lv_i < lv_len.
    lv_char = lv_c = pv_txt+lv_i(1).

    " 1. 리터럴 문자열 ( ... ) 처리
    IF lv_c = '('.
      IF gv_fsz > 0.
        lv_ratio = abs( lv_tok2 ) / ( gv_fsz * 1000 ).
      ELSE.
        lv_ratio = abs( lv_tok2 ) / 3500.
      ENDIF.

      " TJ 배열 내 커닝(간격)이 일정 비율(0.15) 이상 벌어지면 별도 컬럼 조각으로 분리
      IF lv_pend IS NOT INITIAL AND lv_ratio > '0.15'.
        PERFORM pdf_add_frag USING lv_x lv_y lv_pend.
        CLEAR: lv_pend, lv_tok2.
        lv_x = lv_x + 1.
      ENDIF.

      CLEAR lv_buf.
      lv_dep = 1.
      CLEAR lv_esc.
      lv_i = lv_i + 1.

      WHILE lv_i < lv_len.
        lv_d = pv_txt+lv_i(1).
        IF lv_esc = 'X'.
          CONCATENATE lv_buf lv_d INTO lv_buf RESPECTING BLANKS.
          CLEAR lv_esc.
        ELSEIF lv_d = '\'.
          lv_esc = 'X'.
        ELSEIF lv_d = '('.
          lv_dep = lv_dep + 1.
          CONCATENATE lv_buf lv_d INTO lv_buf RESPECTING BLANKS.
        ELSEIF lv_d = ')'.
          lv_dep = lv_dep - 1.
          IF lv_dep = 0.
            EXIT.
          ENDIF.
          CONCATENATE lv_buf lv_d INTO lv_buf RESPECTING BLANKS.
        ELSE.
          CONCATENATE lv_buf lv_d INTO lv_buf RESPECTING BLANKS.
        ENDIF.
        lv_i = lv_i + 1.
      ENDWHILE.

      CONCATENATE lv_pend lv_buf INTO lv_pend RESPECTING BLANKS.
      lv_i = lv_i + 1.
      CONTINUE.
    ENDIF.

    " 2. HEX 문자열 < ... > 처리
    IF lv_c = '<'.
      IF gv_fsz > 0.
        lv_ratio = abs( lv_tok2 ) / ( gv_fsz * 1000 ).
      ELSE.
        lv_ratio = abs( lv_tok2 ) / 3500.
      ENDIF.

      IF lv_pend IS NOT INITIAL AND lv_ratio > '0.15'.
        PERFORM pdf_add_frag USING lv_x lv_y lv_pend.
        CLEAR lv_pend.
        lv_x = lv_x + 1.
      ENDIF.

      IF lv_i + 2 <= lv_len.
        lv_d = pv_txt+lv_i(2).
        IF lv_d = '<<'.
          lv_i = lv_i + 2.
          CONTINUE.
        ENDIF.
      ENDIF.

      lv_he = find( val = pv_txt sub = '>' off = lv_i ).
      IF lv_he < 0.
        EXIT.
      ENDIF.

      lv_n = lv_he - lv_i - 1.
      IF lv_n > 0.
        lv_d  = lv_i + 1.
        lv_hx = pv_txt+lv_d(lv_n).
        CLEAR lv_d.
        PERFORM pdf_decode_hex USING lv_hx CHANGING lv_d.
        CONCATENATE lv_pend lv_d INTO lv_pend RESPECTING BLANKS.
      ENDIF.

      lv_i = lv_he + 1.
      CONTINUE.
    ENDIF.

    " 3. 공백/괄호 구분자 처리
    IF lv_c = space OR lv_c = gv_cr OR lv_c = gv_lf OR lv_c = gv_tab OR
       lv_c = '[' OR lv_c = ']' OR lv_c = '>' OR lv_char = space.
      IF lv_tok IS NOT INITIAL.
        APPEND lv_tok TO lt_num.
        CLEAR lv_tok.
      ENDIF.
      lv_i = lv_i + 1.
      CONTINUE.
    ENDIF.

    " 4. 일반 토큰(숫자 피연산자 및 PDF 연산자) 누적 및 해석
    CONCATENATE lv_tok lv_c INTO lv_tok RESPECTING BLANKS.

    IF lv_i + 1 < lv_len.
      lv_n  = lv_i + 1.
      lv_nx = pv_txt+lv_n(1).
    ELSE.
      lv_nx = space.
    ENDIF.

    IF lv_nx = space OR lv_nx = gv_cr OR lv_nx = gv_lf OR lv_nx = gv_tab OR
       lv_nx = '[' OR lv_nx = ']' OR lv_nx = '(' OR lv_nx = '<' OR
       lv_nx = '/' OR lv_i + 1 = lv_len.
      lv_isop = 'X'.

      CASE lv_tok.

        " 텍스트 그리기 완료 또는 텍스트 블록 종료(ET) 시 조각 저장
        WHEN 'Tj' OR 'TJ' OR 'ET'.
          IF lv_pend IS NOT INITIAL.
            PERFORM pdf_add_frag USING lv_x lv_y lv_pend.
            CLEAR: lv_pend, lv_tok2.
          ENDIF.

        " 상대 좌표 이동 (tx, ty)
        WHEN 'Td' OR 'TD'.
          lv_n = lines( lt_num ).
          IF lv_n >= 2.
            lv_n = lv_n - 1.
            READ TABLE lt_num INTO lv_num INDEX lv_n.
            PERFORM pdf_str2f USING lv_num CHANGING lv_f.
            lv_lx = lv_lx + lv_f.

            lv_n = lv_n + 1.
            READ TABLE lt_num INTO lv_num INDEX lv_n.
            PERFORM pdf_str2f USING lv_num CHANGING lv_f.
            lv_ly = lv_ly + lv_f.
            lv_x  = lv_lx.
            lv_y  = lv_ly.
          ENDIF.

        " 텍스트 변환 행렬 (a b c d e f Tm -> e, f가 절대 X, Y 좌표)
        WHEN 'Tm'.
          lv_n = lines( lt_num ).
          IF lv_n >= 6.
            lv_n = lv_n - 1.
            READ TABLE lt_num INTO lv_num INDEX lv_n.
            PERFORM pdf_str2f USING lv_num CHANGING lv_f.
            lv_lx = lv_f.

            lv_n = lv_n + 1.
            READ TABLE lt_num INTO lv_num INDEX lv_n.
            PERFORM pdf_str2f USING lv_num CHANGING lv_f.
            lv_ly = lv_f.
            lv_x  = lv_lx.
            lv_y  = lv_ly.
          ENDIF.

          lv_n = lines( lt_num ).
          IF lv_n >= 4 AND gv_tfmode = 'S'.
            READ TABLE lt_num INTO lv_num INDEX 4.
            PERFORM pdf_str2f USING lv_num CHANGING gv_fsz.
          ENDIF.

        " 줄간격(Leading) 설정
        WHEN 'TL'.
          lv_n = lines( lt_num ).
          IF lv_n >= 1.
            READ TABLE lt_num INTO lv_num INDEX lv_n.
            PERFORM pdf_str2f USING lv_num CHANGING lv_lead.
          ENDIF.

        " 다음 줄로 개행
        WHEN 'T*'.
          lv_ly = lv_ly - lv_lead.
          lv_x  = lv_lx.
          lv_y  = lv_ly.

        " 텍스트 블록 시작 초기화
        WHEN 'BT'.
          CLEAR: lv_x, lv_y, lv_lx, lv_ly, gv_tfmode.

        " 폰트 및 폰트 크기 설정
        WHEN 'Tf'.
          LOOP AT lt_num INTO lv_num.
            IF strlen( lv_num ) > 1.
              lv_d = lv_num(1).
              IF lv_d = '/'.
                lv_hx = lv_num+1.
              ENDIF.
            ENDIF.
          ENDLOOP.

          PERFORM pdf_set_font USING lv_hx.

          lv_n = lines( lt_num ).
          IF lv_n >= 1.
            READ TABLE lt_num INTO lv_num INDEX lv_n.
            PERFORM pdf_str2f USING lv_num CHANGING gv_tfsz.
          ENDIF.

          IF gv_tfsz > 2.
            gv_fsz    = gv_tfsz.
            gv_tfmode = 'D'.
          ELSE.
            gv_fsz    = 12.
            gv_tfmode = 'S'.
          ENDIF.

        " 연산자가 아닌 일반 숫자 피연산자는 스택(LT_NUM)에 보관
        WHEN OTHERS.
          CLEAR lv_isop.
          APPEND lv_tok TO lt_num.
          TRY.
              lv_tok2 = CONV decfloat34( lv_tok ).
            CATCH cx_sy_conversion_no_number.
          ENDTRY.

      ENDCASE.

      IF lv_isop = 'X'.
        CLEAR lt_num.
      ENDIF.
      CLEAR lv_tok.
    ENDIF.

    lv_i = lv_i + 1.
  ENDWHILE.

  IF lv_pend IS NOT INITIAL.
    PERFORM pdf_add_frag USING lv_x lv_y lv_pend.
    CLEAR: lv_pend, lv_tok2.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_SET_FONT
*&---------------------------------------------------------------------*
*& CMap 테이블 존재 여부에 따라 2바이트(4자리 Hex) CMap 디코딩 활성화 여부를 결정한다.
*&---------------------------------------------------------------------*
FORM pdf_set_font USING pv_name TYPE string.

  IF lines( gt_pdf_cmap ) > 0.
    gv_curtb = 'X'.
  ELSE.
    CLEAR gv_curtb.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_DECODE_HEX
*&---------------------------------------------------------------------*
*& Content Stream의 <...> Hex 문자열을 CMap 테이블로 조회하여 유니코드 문자로 디코딩한다.
*&---------------------------------------------------------------------*
FORM pdf_decode_hex USING    pv_hex TYPE string
                    CHANGING pv_s   TYPE string.

  DATA:
    lv_h    TYPE string,
    lv_n    TYPE i,
    lv_i    TYPE i,
    lv_step TYPE i,
    lv_cd   TYPE i,
    lv_c    TYPE string,
    lv_sub  TYPE string,
    ls_cmap TYPE gty_pdf_cmap.

  CLEAR pv_s.
  lv_h = pv_hex.
  TRANSLATE lv_h TO UPPER CASE.
  CONDENSE lv_h NO-GAPS.
  REPLACE ALL OCCURRENCES OF '>' IN lv_h WITH ''.
  REPLACE ALL OCCURRENCES OF '<' IN lv_h WITH ''.

  lv_n = strlen( lv_h ).
  IF lv_n = 0.
    RETURN.
  ENDIF.

  lv_step = COND #( WHEN gv_curtb = 'X' THEN 4 ELSE 2 ).
  lv_i    = 0.

  WHILE lv_i + lv_step <= lv_n.
    lv_sub = lv_h+lv_i(lv_step).
    PERFORM pdf_hex2int USING lv_sub CHANGING lv_cd.
    CLEAR lv_c.

    READ TABLE gt_pdf_cmap INTO ls_cmap WITH KEY code = lv_cd.
    IF sy-subrc = 0.
      lv_c = ls_cmap-uni.
    ENDIF.

    IF lv_c IS INITIAL AND lv_cd >= 32 AND lv_cd <= 65533.
      PERFORM pdf_cp2char USING lv_cd CHANGING lv_c.
    ENDIF.

    IF lv_c IS NOT INITIAL.
      CONCATENATE pv_s lv_c INTO pv_s RESPECTING BLANKS.
    ENDIF.

    lv_i = lv_i + lv_step.
  ENDWHILE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_STR2F
*&---------------------------------------------------------------------*
*& 문자열 숫자를 부동소수점(F) 타입으로 안전하게 변환한다.
*&---------------------------------------------------------------------*
FORM pdf_str2f USING    pv_s TYPE string
               CHANGING pv_f TYPE f.

  DATA lv_s TYPE string.

  pv_f = 0.
  lv_s = pv_s.
  CONDENSE lv_s NO-GAPS.
  IF lv_s IS INITIAL OR lv_s CN '0123456789.-+'.
    RETURN.
  ENDIF.

  TRY.
      pv_f = lv_s.
    CATCH cx_root.
      pv_f = 0.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_GET_STREAM_LEN
*&---------------------------------------------------------------------*
*& PDF 스트림 사전(Dictionary)에서 '/Length 숫자' 패턴을 추출한다.
*&---------------------------------------------------------------------*
FORM pdf_get_stream_len USING    pv_dict TYPE string
                        CHANGING pv_len  TYPE i.

  DATA:
    lt_m TYPE match_result_tab,
    ls_m TYPE match_result,
    ls_s TYPE submatch_result,
    lv_s TYPE string,
    lv_n TYPE i.

  CLEAR pv_len.
  FIND ALL OCCURRENCES OF REGEX '/Length[ ]+([0-9]+)[^0-9R]' IN pv_dict RESULTS lt_m.
  lv_n = lines( lt_m ).

  IF lv_n = 0.
    pv_len = -1.
    RETURN.
  ENDIF.

  READ TABLE lt_m INTO ls_m INDEX lv_n.
  READ TABLE ls_m-submatches INTO ls_s INDEX 1.
  IF sy-subrc <> 0.
    pv_len = -1.
    RETURN.
  ENDIF.

  lv_s   = pv_dict+ls_s-offset(ls_s-length).
  pv_len = lv_s.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_GET_DICT_BACK
*&---------------------------------------------------------------------*
*& 'stream' 키워드 바로 앞에 위치한 PDF 사전('<< ... >>') 블록을 역방향 탐색하여 추출한다.
*&---------------------------------------------------------------------*
FORM pdf_get_dict_back USING    pv_str  TYPE string
                                pv_spos TYPE i
                       CHANGING pv_dict TYPE string.

  DATA:
    lv_b   TYPE i,
    lv_len TYPE i,
    lv_c   TYPE string,
    lv_dep TYPE i,
    lv_i   TYPE i.

  CLEAR pv_dict.
  lv_b = pv_spos - 1.

  WHILE lv_b > 0.
    lv_c = pv_str+lv_b(1).
    IF lv_c = gv_cr OR lv_c = gv_lf OR lv_c = space.
      lv_b = lv_b - 1.
    ELSE.
      EXIT.
    ENDIF.
  ENDWHILE.

  IF lv_b < 1.
    RETURN.
  ENDIF.

  lv_i = lv_b - 1.
  lv_c = pv_str+lv_i(2).
  IF lv_c <> '>>'.
    RETURN.
  ENDIF.

  lv_dep = 0.
  lv_i   = lv_b - 1.

  WHILE lv_i > 0.
    lv_c = pv_str+lv_i(2).
    IF lv_c = '>>'.
      lv_dep = lv_dep + 1.
      lv_i   = lv_i - 2.
      CONTINUE.
    ELSEIF lv_c = '<<'.
      lv_dep = lv_dep - 1.
      IF lv_dep = 0.
        lv_len  = pv_spos - lv_i.
        pv_dict = pv_str+lv_i(lv_len).
        RETURN.
      ENDIF.
      lv_i = lv_i - 2.
      CONTINUE.
    ENDIF.
    lv_i = lv_i - 1.
  ENDWHILE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_BUILD_LINES
*&---------------------------------------------------------------------*
*& 추출된 텍스트 조각(GT_PDF_FRAG)들을 등장 순서대로 순회하면서:
*& - Y좌표가 크게 위로 점프(+550 이상)하면 새 페이지(PAGE + 1)로 판정
*& - 연속된 동일 Y좌표 조각들은 '|' 구분자로 병합하여 GT_PDF_OUT에 저장
*&---------------------------------------------------------------------*
FORM pdf_build_lines.

  CONSTANTS lc_jump TYPE i VALUE 550.

  DATA:
    ls_s     TYPE gty_pdf_frag,
    lv_py    TYPE i,
    lv_seq   TYPE i,
    lv_page  TYPE i,
    lv_txt   TYPE string,
    lv_1st   TYPE c LENGTH 1,
    lv_x1    TYPE i,
    lv_prevy TYPE i.

  CLEAR gt_pdf_out.
  IF gt_pdf_frag IS INITIAL.
    RETURN.
  ENDIF.

  lv_1st  = 'X'.
  lv_page = 1.

  LOOP AT gt_pdf_frag INTO ls_s.
    IF lv_1st = 'X'.
      lv_prevy = ls_s-y.
      lv_py    = ls_s-y.
      lv_x1    = ls_s-x.
      lv_txt   = ls_s-text.
      CLEAR lv_1st.
      CONTINUE.
    ENDIF.

    " Y좌표가 하단에서 상단으로 크게 점프하면 페이지 전환으로 인식
    IF ls_s-y > lv_prevy + lc_jump.
      PERFORM pdf_flush_line USING    lv_page lv_x1 lv_py
                             CHANGING lv_seq  lv_txt.
      lv_page  = lv_page + 1.
      lv_py    = ls_s-y.
      lv_x1    = ls_s-x.
      lv_txt   = ls_s-text.
      lv_prevy = ls_s-y.
      CONTINUE.
    ENDIF.

    lv_prevy = ls_s-y.

    " 직전 조각과 Y좌표가 같으면 '|'로 이어붙이고, 다르면 줄바꿈 Flush
    IF ls_s-y = lv_py.
      CONCATENATE lv_txt '|' ls_s-text INTO lv_txt SEPARATED BY space.
    ELSE.
      PERFORM pdf_flush_line USING    lv_page lv_x1 lv_py
                             CHANGING lv_seq  lv_txt.
      lv_py  = ls_s-y.
      lv_x1  = ls_s-x.
      lv_txt = ls_s-text.
    ENDIF.
  ENDLOOP.

  PERFORM pdf_flush_line USING    lv_page lv_x1 lv_py
                         CHANGING lv_seq  lv_txt.

  " 페이지 오름차순, Y좌표 내림차순(위->아래), X좌표 오름차순(좌->우) 정렬
  SORT gt_pdf_out BY page ASCENDING ypos DESCENDING xpos ASCENDING.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_FLUSH_LINE
*&---------------------------------------------------------------------*
*& 조립된 한 줄의 텍스트와 좌표를 GT_PDF_OUT 인터널 테이블에 추가한다.
*&---------------------------------------------------------------------*
FORM pdf_flush_line USING    pv_page TYPE i
                             pv_x    TYPE i
                             pv_y    TYPE i
                    CHANGING pv_seq  TYPE i
                             pv_txt  TYPE string.

  DATA ls_out TYPE gty_pdf_out.

  CONDENSE pv_txt.
  IF pv_txt IS INITIAL.
    RETURN.
  ENDIF.

  pv_seq = pv_seq + 1.
  ls_out-seq  = pv_seq.
  ls_out-page = pv_page.
  ls_out-xpos = pv_x.
  ls_out-ypos = pv_y.
  ls_out-text = pv_txt.
  APPEND ls_out TO gt_pdf_out.

  CLEAR pv_txt.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PDF_ADD_FRAG
*&---------------------------------------------------------------------*
*& 파싱된 개별 텍스트 조각(X, Y, 문자열)을 GT_PDF_FRAG에 추가한다.
*&---------------------------------------------------------------------*
FORM pdf_add_frag USING pv_x    TYPE f
                        pv_y    TYPE f
                        pv_pend TYPE string.

  DATA ls_frag TYPE gty_pdf_frag.

  ls_frag-x    = pv_x.
  ls_frag-y    = pv_y.
  ls_frag-text = pv_pend.
  APPEND ls_frag TO gt_pdf_frag.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PARSE_PDF_EAC
*&---------------------------------------------------------------------*
*& EAC (ESTec America) 발주서 PDF 좌표 데이터(GT_PDF_OUT)를 분석하여
*& 헤더 및 품목(다중 페이지 & 단일 페이지 양식 모두 호환)을 GT_RAW에 담는다.
*& - 요구사항 2: 추출된 P.O. No.(예: EAC-25-0077)의 앞 3자리('EAC')가
*&   선택화면 고객의 KNA1-NAME1 앞 3자리(GV_AFF_PREFIX)와 일치하는지 검증한다.
*&---------------------------------------------------------------------*
FORM parse_pdf_eac CHANGING pv_error TYPE abap_bool.

  DATA:
    ls_out       TYPE gty_pdf_out,
    ls_sub       TYPE gty_pdf_out,
    lt_starter   TYPE STANDARD TABLE OF gty_pdf_out WITH EMPTY KEY,
    ls_start     TYPE gty_pdf_out,
    ls_next      TYPE gty_pdf_out,
    lt_split     TYPE STANDARD TABLE OF string WITH EMPTY KEY,
    ls_raw       TYPE gty_raw_item,
    lv_idx       TYPE i,
    lv_y_low     TYPE i,
    lv_x_etd     TYPE i,
    lv_x_code    TYPE i,
    lv_row_no    TYPE i VALUE 0,
    lv_po_date   TYPE string,
    lv_aff_po_no TYPE string,
    lv_cust_po   TYPE string,
    lv_terms     TYPE string,
    lv_po_prefix TYPE char3.

  CLEAR:
    pv_error,
    gt_raw.

*---------------------------------------------------------------------*
* 1. 1페이지 헤더 영역에서 주요 정보 추출
*    (1차 양식과 2차 양식에서 ETD와 CODE의 좌우 위치가 다르므로 라벨 X좌표 선행 파악)
*---------------------------------------------------------------------*
  LOOP AT gt_pdf_out INTO ls_out WHERE page = 1 AND ypos BETWEEN 505 AND 520.
    IF ls_out-text = 'ETD'.
      lv_x_etd = ls_out-xpos.
    ELSEIF ls_out-text = 'CODE'.
      lv_x_code = ls_out-xpos.
    ENDIF.
  ENDLOOP.

  LOOP AT gt_pdf_out INTO ls_out WHERE page = 1.
    " 1-1) 우측 상단 Date(발주일) 및 P.O. No.(관계사 PO번호) 추출 (Y = 688 부근)
    IF ls_out-ypos BETWEEN 680 AND 695.
      IF ls_out-xpos BETWEEN 430 AND 480 AND ls_out-text CS '/'.
        lv_po_date = ls_out-text.
      ELSEIF ls_out-xpos >= 490.
        lv_aff_po_no = ls_out-text.
      ENDIF.
    ENDIF.

    " 1-2) 중단 Terms(결제조건) 및 Customer PO No 추출 (Y = 490 부근)
    IF ls_out-ypos BETWEEN 485 AND 495.
      IF lv_x_etd > 0 AND ls_out-xpos BETWEEN ( lv_x_etd - 25 ) AND ( lv_x_etd + 25 ).
        CONTINUE.
      ELSEIF lv_x_code > 0 AND ls_out-xpos BETWEEN ( lv_x_code - 25 ) AND ( lv_x_code + 25 ).
        CONTINUE.
      ELSEIF ls_out-xpos < 200.
        lv_terms = ls_out-text.
      ELSEIF ls_out-xpos BETWEEN 200 AND 380.
        lv_cust_po = ls_out-text.
      ENDIF.
    ENDIF.
  ENDLOOP.

  CONDENSE:
    lv_po_date,
    lv_aff_po_no,
    lv_cust_po,
    lv_terms.

*---------------------------------------------------------------------*
* 2. 법인 정합성 검증 (요구사항 2)
*    PDF의 P.O. No. 앞 3글자(예: 'EAC')와 KNA1-NAME1 앞 3글자가 다르면 에러 처리
*---------------------------------------------------------------------*
  IF strlen( lv_aff_po_no ) >= 3.
    lv_po_prefix = lv_aff_po_no(3).
    TRANSLATE lv_po_prefix TO UPPER CASE.
  ENDIF.

  IF lv_po_prefix <> gv_aff_prefix.
    pv_error = abap_true.
    MESSAGE TEXT-e09 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
* 3. 품목(Line Item) 시작점 행 수집
*    기준: XPOS = 39, YPOS = 45 ~ 455 사이에 위치하며 '|' 구분자를 포함한 행
*---------------------------------------------------------------------*
  LOOP AT gt_pdf_out INTO ls_out WHERE xpos = 39
                                   AND ypos BETWEEN 45 AND 455.
    IF ls_out-text CS '|'.
      APPEND ls_out TO lt_starter.
    ENDIF.
  ENDLOOP.

  SORT lt_starter BY page ASCENDING ypos DESCENDING.

*---------------------------------------------------------------------*
* 4. 품목별 하위 조각(우측 수치 행 + 2~3줄 줄바꿈 품명) 병합 조립
*---------------------------------------------------------------------*
  LOOP AT lt_starter INTO ls_start.
    lv_idx = sy-tabix.
    CLEAR: ls_raw, lt_split.

    lv_row_no        = lv_row_no + 1.
    ls_raw-row_no    = lv_row_no.
    ls_raw-bstdk     = lv_po_date.
    ls_raw-aff_po_no = lv_aff_po_no.
    ls_raw-bstkd_e   = lv_cust_po.
    ls_raw-zterm_raw = lv_terms.
    ls_raw-waerk     = gc_usd.

    " 현재 품목에 속하는 Y좌표 하한선(LV_Y_LOW) = 다음 품목의 Y좌표 + 1
    READ TABLE lt_starter INTO ls_next INDEX ( lv_idx + 1 ).
    IF sy-subrc = 0 AND ls_next-page = ls_start-page.
      lv_y_low = ls_next-ypos + 1.
    ELSE.
      lv_y_low = 40. " 페이지 마지막 품목이면 하단까지 탐색
    ENDIF.

    SPLIT ls_start-text AT '|' INTO TABLE lt_split.

    " [Case A] 품명이 짧아 한 줄에 7개 컬럼이 모두 들어온 경우
    IF lines( lt_split ) >= 7.
      READ TABLE lt_split INTO ls_raw-kdmat     INDEX 1. " Item (Customer Code)
      READ TABLE lt_split INTO ls_raw-arktx_pdf INDEX 2. " Description
      READ TABLE lt_split INTO ls_raw-matnr     INDEX 3. " PN (Material)
      READ TABLE lt_split INTO ls_raw-edatu_etd INDEX 4. " ETD
      READ TABLE lt_split INTO ls_raw-kwmeng    INDEX 5. " Qty
      READ TABLE lt_split INTO ls_raw-po_price  INDEX 6. " Rate (PO Unit Price)
      READ TABLE lt_split INTO ls_raw-po_amount INDEX 7. " Amount

    " [Case B] 품명 줄바꿈으로 인해 우측 수치 데이터(PN|ETD|Qty|Rate|Amount)와
    "          2~3번째 줄 품명 조각이 분리된 경우 (1차 양식 X=143/201, 2차 양식 X=50/58 모두 대응)
    ELSEIF lines( lt_split ) >= 2.
      READ TABLE lt_split INTO ls_raw-kdmat     INDEX 1.
      READ TABLE lt_split INTO ls_raw-arktx_pdf INDEX 2.
      CONDENSE: ls_raw-kdmat, ls_raw-arktx_pdf.

      LOOP AT gt_pdf_out INTO ls_sub WHERE page = ls_start-page
                                       AND ypos BETWEEN lv_y_low AND ls_start-ypos
                                       AND seq  <> ls_start-seq.
        IF ls_sub-xpos = 39.
          CONTINUE.
        ENDIF.

        CLEAR lt_split.
        SPLIT ls_sub-text AT '|' INTO TABLE lt_split.

        " '|'로 분리된 항목이 5개 이상이면 -> 우측 수치 데이터 행 (PN | ETD | Qty | Rate | Amount)
        IF lines( lt_split ) >= 5.
          READ TABLE lt_split INTO ls_raw-matnr     INDEX 1.
          READ TABLE lt_split INTO ls_raw-edatu_etd INDEX 2.
          READ TABLE lt_split INTO ls_raw-kwmeng    INDEX 3.
          READ TABLE lt_split INTO ls_raw-po_price  INDEX 4.
          READ TABLE lt_split INTO ls_raw-po_amount INDEX 5.

        " '|'가 없고 Total 금액('USD ') 행도 아니면 -> 줄바꿈된 품명(Description) 연장 텍스트
        ELSEIF NOT ( ls_sub-text CS '|' ) AND NOT ( ls_sub-text CS 'USD ' ).
          CONCATENATE ls_raw-arktx_pdf ls_sub-text
                 INTO ls_raw-arktx_pdf SEPARATED BY space.
        ENDIF.
      ENDLOOP.
    ENDIF.

    CONDENSE:
      ls_raw-kdmat,
      ls_raw-arktx_pdf,
      ls_raw-matnr,
      ls_raw-edatu_etd,
      ls_raw-kwmeng,
      ls_raw-po_price,
      ls_raw-po_amount.

    APPEND ls_raw TO gt_raw.
  ENDLOOP.

  IF gt_raw IS INITIAL.
    pv_error = abap_true.
    MESSAGE s022 DISPLAY LIKE gc_e.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form MAKE_UPLOAD_DATA
*&---------------------------------------------------------------------*
*& 문자열 Staging 테이블(GT_RAW)을 ALV 출력 테이블(GT_DISP)로 변환한다.
*& - 조회조건의 단일 관계사 코드(S_KUNNR-LOW) 및 고객명 매핑
*& - Payment Term 분기 추출 ('F007 / ...' -> 'F007')
*& - PO Date, ETD 날짜 변환 및 Closing Date(ETD - 3 워킹데이) 계산
*& - 자재코드 내부 포맷 변환 (ZCL_CM_UTIL=>CONV_MAT_CODE)
*&---------------------------------------------------------------------*
FORM make_upload_data.

  DATA:
    ls_disp  TYPE gty_disp,
    lv_posnr TYPE posnr_va VALUE 0,
    lv_error TYPE abap_bool,
    lv_text  TYPE string.

  CLEAR gt_disp.

  LOOP AT gt_raw INTO DATA(ls_raw).

    CLEAR:
      ls_disp,
      lv_error,
      lv_text.

    " Sales Order 품목번호 기본 10단위 채번 (10, 20, 30...)
    lv_posnr = lv_posnr + 10.

    ls_disp-row_no    = ls_raw-row_no.
    ls_disp-new       = abap_true.
    ls_disp-row_kind  = gc_row_ready.
    ls_disp-kpein     = 1.

    " 1. 선택화면 조직 정보 및 관계사(Affiliated Company) 매핑 (요구사항 2)
    ls_disp-vkorg     = s_vkorg-low.
    ls_disp-vkbur     = s_vkbur-low.
    ls_disp-vkgrp     = s_vkgrp-low.
    ls_disp-vtweg     = s_vtweg-low.
    ls_disp-spart     = s_spart-low.
    ls_disp-werks     = s_vkorg-low. " 플랜트 = Sales Organization

    ls_disp-kunnr     = s_kunnr-low.
    ls_disp-name1     = gv_aff_name1.
    ls_disp-kunag     = s_kunnr-low.
    ls_disp-kunwe     = s_kunnr-low.
    ls_disp-kunrg     = s_kunnr-low.

    " 2. 기본 오더유형 = ZOR (ALV 드롭다운에서 ZOR / ZKB 선택 가능)
    ls_disp-auart     = gc_zor.
    ls_disp-posnr     = lv_posnr.
    ls_disp-aff_po_no = ls_raw-aff_po_no.
    ls_disp-bstkd_e   = ls_raw-bstkd_e.
    ls_disp-kdmat     = ls_raw-kdmat.
    ls_disp-waerk     = gc_usd.

    " 3. Payment Term 코드 분기 추출 (요구사항 2: 'F007' 등 추출)
    PERFORM parse_payment_term
      USING    ls_raw-zterm_raw
      CHANGING ls_disp-zterm.

    " 4. PO Date 날짜 변환 및 검증
    PERFORM convert_date
      USING    CONV string( ls_raw-bstdk )
      CHANGING ls_disp-bstdk
               lv_error.
    IF lv_error = abap_true.
      PERFORM set_upload_error USING ls_raw-row_no TEXT-e10 CHANGING ls_disp.
    ENDIF.

    " 5. ETD 날짜 변환 및 Closing Date (ETD - 3 Working Days) 산출
    PERFORM convert_date
      USING    CONV string( ls_raw-edatu_etd )
      CHANGING ls_disp-etd
               lv_error.
    IF lv_error = abap_true.
      PERFORM set_upload_error USING ls_raw-row_no TEXT-e10 CHANGING ls_disp.
    ELSE.
      PERFORM calc_closing_date
        USING    ls_disp-vkorg
                 ls_disp-etd
        CHANGING ls_disp-close_dat.
    ENDIF.

    " 6. Material Code 내부 포맷 변환 (ZCL_CM_UTIL=>CONV_MAT_CODE 재사용)
    IF ls_raw-matnr IS INITIAL.
      PERFORM set_upload_error USING ls_raw-row_no TEXT-e11 CHANGING ls_disp.
    ELSE.
      zcl_cm_util=>conv_mat_code(
        EXPORTING
          iv_matnr = ls_raw-matnr
          iv_code  = 'I'
        IMPORTING
          ev_matnr = ls_disp-matnr ).
    ENDIF.

    " 7. 수량(Qty) 및 발주단가(PO Unit Price) 숫자/통화 변환
    PERFORM apply_upload_field USING ls_raw-row_no 'KWMENG' ls_raw-kwmeng   CHANGING ls_disp.
    PERFORM apply_upload_field USING ls_raw-row_no 'NETPR'  ls_raw-po_price CHANGING ls_disp.

    APPEND ls_disp TO gt_disp.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PARSE_PAYMENT_TERM
*&---------------------------------------------------------------------*
*& PDF의 Terms 텍스트에서 SAP 지급조건 코드(ZTERM)를 분기 추출한다 (요구사항 2):
*& - 'F007 / within 90 Days Due net' 처럼 '/'가 있으면 앞의 'F007'을 추출
*& - 'Net 90 days' 처럼 코드가 직접 적혀있지 않으면 KNVV-ZTERM(없으면 'F007') 적용
*&---------------------------------------------------------------------*
FORM parse_payment_term
  USING    pv_raw   TYPE clike
  CHANGING pv_zterm TYPE dzterm.

  DATA:
    lv_str  TYPE string,
    lv_code TYPE string,
    lv_rest TYPE string.

  CLEAR pv_zterm.
  lv_str = pv_raw.
  CONDENSE lv_str.

  IF lv_str CS '/'.
    SPLIT lv_str AT '/' INTO lv_code lv_rest.
    CONDENSE lv_code NO-GAPS.
    TRANSLATE lv_code TO UPPER CASE.
    pv_zterm = lv_code.
  ELSEIF lv_str CS '90'.
    pv_zterm = COND #( WHEN gv_knvv_zterm IS NOT INITIAL
                       THEN gv_knvv_zterm
                       ELSE 'F007' ).
  ELSE.
    pv_zterm = gv_knvv_zterm.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CALC_CLOSING_DATE
*&---------------------------------------------------------------------*
*& 설계서 기준 Closing Date 계산 로직:
*& - 영업조직(TVKO-VKORG)에 할당된 공장달력(FABKL)을 조회
*& - DAY_ATTRIBUTES_GET 함수를 호출하여 휴일/주말(FREEDAY = 'X')을 제외한
*&   평일(워킹데이) 기준 ETD - 3일 날짜를 산출한다.
*&---------------------------------------------------------------------*
FORM calc_closing_date
  USING    pv_vkorg     TYPE vkorg
           pv_etd       TYPE dats
  CHANGING pv_close_dat TYPE dats.

  DATA:
    lv_fabkl    TYPE tvko-fabkl,
    lv_date_frm TYPE dats,
    lv_date_to  TYPE dats,
    lt_day_attr TYPE STANDARD TABLE OF casdayattr,
    ls_day_attr TYPE casdayattr,
    lv_work_cnt TYPE i VALUE 0,
    lv_idx      TYPE i.

  CLEAR pv_close_dat.
  CHECK pv_etd IS NOT INITIAL.

  " 1. 영업조직(TVKO)에서 공장달력 ID(FABKL) 조회
  SELECT SINGLE fabkl
    FROM tvko
   WHERE vkorg = @pv_vkorg
    INTO @lv_fabkl.

  " 주말/공휴일이 연속될 경우를 대비해 ETD - 15일 ~ ETD - 1일 구간 조회
  lv_date_to  = pv_etd - 1.
  lv_date_frm = pv_etd - 15.

  CALL FUNCTION 'DAY_ATTRIBUTES_GET'
    EXPORTING
      factory_calendar           = lv_fabkl
      holiday_calendar           = lv_fabkl
      date_from                  = lv_date_frm
      date_to                    = lv_date_to
      language                   = sy-langu
    TABLES
      day_attributes             = lt_day_attr
    EXCEPTIONS
      factory_calendar_not_found = 1
      holiday_calendar_not_found = 2
      date_invalid               = 3
      OTHERS                     = 4.

  IF sy-subrc <> 0 OR lt_day_attr IS INITIAL.
    pv_close_dat = pv_etd - 3.
    RETURN.
  ENDIF.

  " 2. ETD-1일부터 과거 방향으로 역순 탐색하며 평일(FREEDAY = SPACE) 3번째 날짜 선택
  lv_idx = lines( lt_day_attr ).
  WHILE lv_idx >= 1.
    READ TABLE lt_day_attr INTO ls_day_attr INDEX lv_idx.
    IF sy-subrc = 0 AND ls_day_attr-freeday IS INITIAL.
      lv_work_cnt = lv_work_cnt + 1.
      IF lv_work_cnt = 3.
        pv_close_dat = ls_day_attr-date.
        RETURN.
      ENDIF.
    ENDIF.
    lv_idx = lv_idx - 1.
  ENDWHILE.

  pv_close_dat = pv_etd - 3.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form APPLY_UPLOAD_FIELD
*&---------------------------------------------------------------------*
*& 개별 업로드 필드값을 검증 후 GT_DISP 행에 반영하고 오류 시 메시지를 기록한다.
*&---------------------------------------------------------------------*
FORM apply_upload_field
  USING    pv_line      TYPE i
           pv_fieldname TYPE lvc_fname
           pv_value     TYPE any
  CHANGING ps_disp      TYPE gty_disp.

  DATA:
    lv_value TYPE string,
    lv_error TYPE abap_bool,
    lv_text  TYPE string.

  lv_value = pv_value.

  PERFORM check_field_value
    USING    pv_fieldname
             lv_value
    CHANGING ps_disp
             lv_error
             lv_text.

  IF lv_error = abap_true.
    PERFORM set_upload_error
      USING    pv_line
               lv_text
      CHANGING ps_disp.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_FIELD_VALUE
*&---------------------------------------------------------------------*
*& 오더유형(AUART: ZOR/ZKB), 수량(KWMENG), 단가(NETPR)의 포맷 및 유효성을 검증한다.
*&---------------------------------------------------------------------*
FORM check_field_value
  USING    pv_fieldname TYPE lvc_fname
           pv_value     TYPE string
  CHANGING ps_disp      TYPE gty_disp
           pv_error     TYPE abap_bool
           pv_text      TYPE string.

  DATA lv_value TYPE string.

  CLEAR:
    pv_error,
    pv_text.

  lv_value = pv_value.

  CASE pv_fieldname.

    " 1. 판매오더 유형 검증 (설계서 기준: ZOR 또는 ZKB만 허용)
    WHEN 'AUART'.
      CONDENSE lv_value NO-GAPS.
      TRANSLATE lv_value TO UPPER CASE.
      IF lv_value <> gc_zor AND lv_value <> gc_zkb.
        pv_error = abap_true.
        pv_text  = TEXT-e12.
        RETURN.
      ENDIF.
      ps_disp-auart = lv_value.

    " 2. 수량(Qty) 숫자 변환 및 양수 검증
    WHEN 'KWMENG'.
      lv_value = zcl_cm_util=>regex_replace(
                   i_data  = lv_value
                   i_space = abap_true ).
      REPLACE ALL OCCURRENCES OF ',' IN lv_value WITH ``.
      TRY.
          ps_disp-kwmeng = EXACT #( CONV decfloat34( lv_value ) ).
          IF ps_disp-kwmeng <= 0.
            RAISE EXCEPTION TYPE cx_sy_conversion_no_number.
          ENDIF.
        CATCH cx_sy_conversion_error cx_sy_arithmetic_error.
          pv_error = abap_true.
          pv_text  = TEXT-e13.
      ENDTRY.

    " 3. 발주단가(PO Unit Price) 외부->내부 통화 변환
    WHEN 'NETPR'.
      PERFORM price_set_external
        USING    lv_value
        CHANGING ps_disp
                 pv_error
                 pv_text.

  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_UPLOAD_ERROR
*&---------------------------------------------------------------------*
*& 한 행에 최초 발생한 업로드 오류 메시지를 기록한다.
*&---------------------------------------------------------------------*
FORM set_upload_error
  USING    pv_line TYPE i
           pv_text TYPE clike
  CHANGING ps_disp TYPE gty_disp.

  CHECK ps_disp-msgty IS INITIAL.

  ps_disp-msgty = gc_e.

  MESSAGE s003
    WITH TEXT-005
         pv_line
         pv_text
         space
    INTO ps_disp-message.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_CHECK_MASTER_DATA
*&---------------------------------------------------------------------*
*& 업로드된 자재코드(MATNR)들을 모아 FOR ALL ENTRIES로 한 번에
*& 기본단위(MARA-MEINS)와 자재내역(MAKT-MAKTX)을 조회하여 매핑한다.
*&---------------------------------------------------------------------*
FORM get_check_master_data.

  TYPES:
    BEGIN OF lty_matnr,
      matnr TYPE matnr,
    END OF lty_matnr.

  DATA lt_matnr TYPE SORTED TABLE OF lty_matnr WITH UNIQUE KEY matnr.

  CLEAR:
    gt_mara,
    gt_makt.

  LOOP AT gt_disp INTO DATA(ls_disp) WHERE matnr IS NOT INITIAL.
    INSERT VALUE #( matnr = ls_disp-matnr ) INTO TABLE lt_matnr.
  ENDLOOP.

  IF lt_matnr IS NOT INITIAL.
    " 1. 기본 단위(MARA-MEINS) 일괄 조회
    SELECT matnr, meins
      FROM mara
       FOR ALL ENTRIES IN @lt_matnr
     WHERE matnr = @lt_matnr-matnr
      INTO TABLE @gt_mara.

    " 2. 자재 내역(MAKT-MAKTX) 일괄 조회
    SELECT matnr, maktx
      FROM makt
       FOR ALL ENTRIES IN @lt_matnr
     WHERE spras = @sy-langu
       AND matnr = @lt_matnr-matnr
      INTO TABLE @gt_makt.
  ENDIF.

  " 3. 조회된 마스터 단위 및 품명을 GT_DISP에 반영
  LOOP AT gt_disp ASSIGNING FIELD-SYMBOL(<ls_disp>).
    READ TABLE gt_mara INTO DATA(ls_mara)
      WITH TABLE KEY matnr = <ls_disp>-matnr.
    IF sy-subrc = 0.
      <ls_disp>-meins      = ls_mara-meins.
      <ls_disp>-price_unit = ls_mara-meins.
    ENDIF.

    READ TABLE gt_makt INTO DATA(ls_makt)
      WITH TABLE KEY matnr = <ls_disp>-matnr.
    IF sy-subrc = 0.
      <ls_disp>-maktx = ls_makt-maktx.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_EXISTING_SO_PO
*&---------------------------------------------------------------------*
*& 요구사항 4 반영:
*& - Affiliated Com. PO No(VBAK-BSTNK)와 자재코드(VBAP-MATNR)로 기생성된
*&   Sales Order(VBAK-VBELN, VBAP-POSNR) 및 VBAP-ZZEBELN/ZZEBELP를 조회한다.
*& - 또한 EKPO-ZZVBELN = VBAP-VBELN, EKPO-ZZVBELP = VBAP-POSNR 조건으로
*&   연결된 Purchase Order(EKPO-EBELN, EKPO-EBELP)를 조회하여 화면에 표시한다.
*&---------------------------------------------------------------------*
FORM get_existing_so_po.

  TYPES:
    BEGIN OF lty_so_item,
      bstnk   TYPE vbak-bstnk,
      vbeln   TYPE vbak-vbeln,
      auart   TYPE vbak-auart,
      posnr   TYPE vbap-posnr,
      matnr   TYPE vbap-matnr,
      zzebeln TYPE vbap-zzebeln,
      zzebelp TYPE vbap-zzebelp,
    END OF lty_so_item,

    BEGIN OF lty_ekpo_link,
      ebeln   TYPE ekpo-ebeln,
      ebelp   TYPE ekpo-ebelp,
      zzvbeln TYPE ekpo-zzvbeln,
      zzvbelp TYPE ekpo-zzvbelp,
    END OF lty_ekpo_link,

    BEGIN OF lty_bstnk,
      bstnk TYPE vbak-bstnk,
    END OF lty_bstnk.

  DATA:
    lt_bstnk TYPE SORTED TABLE OF lty_bstnk WITH UNIQUE KEY bstnk,
    lt_so    TYPE STANDARD TABLE OF lty_so_item WITH EMPTY KEY,
    lt_ekpo  TYPE STANDARD TABLE OF lty_ekpo_link WITH EMPTY KEY.

  CHECK gt_disp IS NOT INITIAL.

  LOOP AT gt_disp INTO DATA(ls_disp) WHERE aff_po_no IS NOT INITIAL.
    INSERT VALUE #( bstnk = ls_disp-aff_po_no ) INTO TABLE lt_bstnk.
  ENDLOOP.

  CHECK lt_bstnk IS NOT INITIAL.

  " 1. 기생성된 Sales Order 및 VBAP-ZZEBELN / ZZEBELP 조회
  SELECT a~bstnk,
         a~vbeln,
         a~auart,
         b~posnr,
         b~matnr,
         b~zzebeln,
         b~zzebelp
    FROM vbak AS a
    INNER JOIN vbap AS b
      ON b~vbeln = a~vbeln
     FOR ALL ENTRIES IN @lt_bstnk
   WHERE a~vkorg = @s_vkorg-low
     AND a~vtweg = @s_vtweg-low
     AND a~kunnr = @s_kunnr-low
     AND a~bstnk = @lt_bstnk-bstnk
     AND b~abgru = @space
    INTO TABLE @lt_so.

  CHECK lt_so IS NOT INITIAL.

  " 2. EKPO-ZZVBELN / ZZVBELP 기준으로 연결된 구매오더(PO) 조회 (요구사항 4)
  SELECT ebeln,
         ebelp,
         zzvbeln,
         zzvbelp
    FROM ekpo
     FOR ALL ENTRIES IN @lt_so
   WHERE zzvbeln = @lt_so-vbeln
     AND zzvbelp = @lt_so-posnr
     AND loekz   = @space
    INTO TABLE @lt_ekpo.

  SORT lt_so   BY bstnk matnr posnr.
  SORT lt_ekpo BY zzvbeln zzvbelp.

  " 3. GT_DISP 행에 기생성 SO 번호 및 PO 번호 매핑
  LOOP AT gt_disp ASSIGNING FIELD-SYMBOL(<ls_disp>).

    READ TABLE lt_so INTO DATA(ls_so)
      WITH KEY bstnk = <ls_disp>-aff_po_no
               matnr = <ls_disp>-matnr.

    IF sy-subrc = 0.
      <ls_disp>-auart = ls_so-auart.
      <ls_disp>-vbeln = ls_so-vbeln.
      <ls_disp>-posnr = ls_so-posnr.

      " 1순위: EKPO(ZZVBELN/ZZVBELP) 조회값, 2순위: VBAP(ZZEBELN/ZZEBELP) 값 매핑
      READ TABLE lt_ekpo INTO DATA(ls_ekpo)
        WITH KEY zzvbeln = ls_so-vbeln
                 zzvbelp = ls_so-posnr
        BINARY SEARCH.

      IF sy-subrc = 0.
        <ls_disp>-ebeln = ls_ekpo-ebeln.
        <ls_disp>-ebelp = ls_ekpo-ebelp.
      ELSEIF ls_so-zzebeln IS NOT INITIAL.
        <ls_disp>-ebeln = ls_so-zzebeln.
        <ls_disp>-ebelp = ls_so-zzebelp.
      ENDIF.

      " 동일 PO 내 동일 자재가 여러 줄일 때 중복 매핑되지 않도록 매칭된 행 제거
      DELETE lt_so INDEX sy-tabix.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_CURRENT_PRICE
*&---------------------------------------------------------------------*
*& 요구사항 1 & 3 반영 (ZSDR0080 로직 이식 + PO Date 기준 적용):
*& - 가격 조건유형 'ZSR1'(GC_ZSR1)에 연결된 Access Sequence(T685 -> T682I)를 조회
*& - 접근 우선순위(KOLNR)별로 조건 테이블(Axxx)과 KONP를 동적 조인하여
*&   각 행의 'PO Date'(BSTDK) 시점에 유효한 마스터 단가(MST_PRICE)를 산출한다.
*&---------------------------------------------------------------------*
FORM get_current_price CHANGING pv_error TYPE abap_bool.

  TYPES:
    BEGIN OF lty_access,
      kolnr   TYPE t682i-kolnr,
      kotabnr TYPE t682i-kotabnr,
      kobed   TYPE t682i-kobed,
    END OF lty_access,

    BEGIN OF lty_price,
      vkorg TYPE vbak-vkorg,
      kunnr TYPE kunnr,
      matnr TYPE vbap-matnr,
      knumh TYPE konp-knumh,
      datab TYPE datab,
      datbi TYPE datbi,
      kbetr TYPE konp-kbetr,
      kpein TYPE konp-kpein,
      konwa TYPE konp-konwa,
    END OF lty_price.

  DATA:
    lv_kozgf     TYPE t685-kozgf,
    lv_tabname   TYPE tabname,
    lv_from      TYPE string,
    lv_columns   TYPE string,
    lv_where     TYPE string,
    lv_has_kunnr TYPE abap_bool,
    lv_kunnr     TYPE kunnr,
    lv_message   TYPE string,
    lv_external  TYPE bapicurr_d,

    lt_access    TYPE STANDARD TABLE OF lty_access WITH EMPTY KEY,
    lt_fields    TYPE STANDARD TABLE OF dfies      WITH EMPTY KEY,
    lt_price     TYPE STANDARD TABLE OF lty_price  WITH EMPTY KEY,
    lt_pending   TYPE gty_t_disp.

  CLEAR pv_error.
  CHECK gt_disp IS NOT INITIAL.

  " 마스터 단가 관련 필드 초기화
  LOOP AT gt_disp ASSIGNING FIELD-SYMBOL(<ls_disp>).
    CLEAR:
      <ls_disp>-mst_price,
      <ls_disp>-new_netpr,
      <ls_disp>-new_kpein,
      <ls_disp>-new_waerk,
      <ls_disp>-knumh,
      <ls_disp>-datab,
      <ls_disp>-datbi.
  ENDLOOP.

  " 1. 조건유형 ZSR1에 연결된 접근순서(Access Sequence) 조회 (T685)
  SELECT SINGLE kozgf
    FROM t685
   WHERE kvewe = 'A'
     AND kappl = @gc_kappl
     AND kschl = @gc_zsr1
    INTO @lv_kozgf.

  IF sy-subrc <> 0 OR lv_kozgf IS INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-e14 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  " 2. 접근순서 내 조건 테이블 목록 조회 (T682I)
  SELECT kolnr,
         kotabnr,
         kobed
    FROM t682i
   WHERE kvewe = 'A'
     AND kappl = @gc_kappl
     AND kozgf = @lv_kozgf
    INTO TABLE @lt_access.

  IF lt_access IS INITIAL.
    pv_error = abap_true.
    MESSAGE TEXT-e15 TYPE gc_s DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  SORT lt_access BY kolnr.

  " 3. 우선순위(KOLNR) 순서대로 아직 단가를 못 찾은 품목에 대해 조건 테이블 조회
  LOOP AT lt_access INTO DATA(ls_access).

    CLEAR lt_pending.
    LOOP AT gt_disp INTO DATA(ls_disp)
      WHERE knumh IS INITIAL
        AND matnr IS NOT INITIAL
        AND bstdk IS NOT INITIAL.
      APPEND ls_disp TO lt_pending.
    ENDLOOP.

    IF lt_pending IS INITIAL.
      EXIT.
    ENDIF.

    IF ls_access-kobed IS NOT INITIAL.
      CONTINUE.
    ENDIF.

    " 조건 테이블명 조립 (예: A901, A305 등)
    lv_tabname = |A{ ls_access-kotabnr }|.

    CLEAR:
      lt_fields,
      lt_price,
      lv_has_kunnr.

    " 조건 테이블의 DDIC 필드 구조 읽기
    CALL FUNCTION 'DDIF_FIELDINFO_GET'
      EXPORTING
        tabname        = lv_tabname
        langu          = sy-langu
      TABLES
        dfies_tab      = lt_fields
      EXCEPTIONS
        not_found      = 1
        internal_error = 2
        OTHERS         = 3.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    " 필수 조건 키 필드 존재 여부 확인
    IF NOT line_exists( lt_fields[ fieldname = 'KAPPL' ] )
       OR NOT line_exists( lt_fields[ fieldname = 'KSCHL' ] )
       OR NOT line_exists( lt_fields[ fieldname = 'VKORG' ] )
       OR NOT line_exists( lt_fields[ fieldname = 'MATNR' ] )
       OR NOT line_exists( lt_fields[ fieldname = 'DATAB' ] )
       OR NOT line_exists( lt_fields[ fieldname = 'DATBI' ] )
       OR NOT line_exists( lt_fields[ fieldname = 'KNUMH' ] ).
      CONTINUE.
    ENDIF.

    lv_has_kunnr = xsdbool( line_exists( lt_fields[ fieldname = 'KUNNR' ] ) ).

    " 동적 JOIN 및 SELECT 절 구성
    lv_from =
      |{ lv_tabname } AS a INNER JOIN konp AS b | &&
      |ON b~knumh = a~knumh AND b~kopos = '01'|.

    lv_columns =
      |a~vkorg, a~matnr, a~knumh, a~datab, a~datbi, | &&
      |b~kbetr, b~kpein, b~konwa|.

    IF lv_has_kunnr = abap_true.
      lv_columns = lv_columns && |, a~kunnr|.
    ENDIF.

    " ★ 요구사항 1: 유효기간을 SY-DATUM이 아닌 PO Date(LT_PENDING-BSTDK) 기준으로 조회
    lv_where =
      |a~kappl = @gc_kappl | &&
      |AND a~kschl = @gc_zsr1 | &&
      |AND a~vkorg = @lt_pending-vkorg | &&
      |AND a~matnr = @lt_pending-matnr | &&
      |AND a~datab <= @lt_pending-bstdk | &&
      |AND a~datbi >= @lt_pending-bstdk | &&
      |AND b~loevm_ko = @space|.

    IF lv_has_kunnr = abap_true.
      lv_where = lv_where && | AND a~kunnr = @lt_pending-kunag|.
    ENDIF.

    IF line_exists( lt_fields[ fieldname = 'VTWEG' ] ).
      lv_where = lv_where && | AND a~vtweg = @lt_pending-vtweg|.
    ENDIF.

    IF line_exists( lt_fields[ fieldname = 'KFRST' ] ).
      lv_where = lv_where && | AND a~kfrst = @space|.
    ENDIF.

    TRY.
        SELECT (lv_columns)
          FROM (lv_from)
           FOR ALL ENTRIES IN @lt_pending
         WHERE (lv_where)
          INTO CORRESPONDING FIELDS OF TABLE @lt_price.

      CATCH cx_sy_dynamic_osql_error INTO DATA(lx_sql).
        pv_error   = abap_true.
        lv_message = lx_sql->get_text( ).
        MESSAGE lv_message TYPE gc_s DISPLAY LIKE gc_e.
        RETURN.
    ENDTRY.

    " 동일 조건에 복수 레코드가 있을 경우 최근 효력시작일(DATAB) 및 최신 조건번호(KNUMH) 우선
    SORT lt_price BY
      vkorg
      kunnr
      matnr
      datab DESCENDING
      knumh DESCENDING.

    " 4. 조회된 ZSR1 단가를 GT_DISP-MST_PRICE(Master Unit Price)로 변환하여 반영
    LOOP AT gt_disp ASSIGNING <ls_disp> WHERE knumh IS INITIAL.
      CLEAR lv_kunnr.
      IF lv_has_kunnr = abap_true.
        lv_kunnr = <ls_disp>-kunag.
      ENDIF.

      LOOP AT lt_price INTO DATA(ls_price)
        WHERE vkorg = <ls_disp>-vkorg
          AND kunnr = lv_kunnr
          AND matnr = <ls_disp>-matnr
          AND datab <= <ls_disp>-bstdk
          AND datbi >= <ls_disp>-bstdk.

        <ls_disp>-new_netpr = ls_price-kbetr.
        <ls_disp>-new_kpein = ls_price-kpein.
        <ls_disp>-new_waerk = ls_price-konwa.
        <ls_disp>-knumh     = ls_price-knumh.
        <ls_disp>-datab     = ls_price-datab.
        <ls_disp>-datbi     = ls_price-datbi.

        " 내부 금액(KBETR)을 ZCL_CM_UTIL=>CONV_CURR로 외부 금액 변환 후 가격단위(KPEIN)로 나눔
        IF <ls_disp>-new_kpein > 0.
          TRY.
              CLEAR lv_external.
              zcl_cm_util=>conv_curr(
                EXPORTING
                  i_in       = space
                  i_currency = <ls_disp>-new_waerk
                  i_amount   = <ls_disp>-new_netpr
                IMPORTING
                  e_amount   = lv_external ).

              <ls_disp>-mst_price =
                CONV bapicurr_d(
                  CONV decfloat34( lv_external )
                  / CONV decfloat34( <ls_disp>-new_kpein ) ).
            CATCH cx_sy_arithmetic_error cx_sy_conversion_overflow.
              CLEAR <ls_disp>-mst_price.
          ENDTRY.
        ENDIF.

        EXIT.
      ENDLOOP.
    ENDLOOP.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_DISPLAY_DATA
*&---------------------------------------------------------------------*
*& 전체 업로드 행에 대해 마스터 및 필수값 정합성 검증을 수행한다.
*&---------------------------------------------------------------------*
FORM check_display_data.

  DATA:
    lv_error TYPE abap_bool,
    lv_text  TYPE string.

  LOOP AT gt_disp ASSIGNING FIELD-SYMBOL(<ls_disp>).
    IF <ls_disp>-msgty = gc_e.
      CONTINUE.
    ENDIF.

    CLEAR: lv_error, lv_text.
    PERFORM check_row_data
      USING    <ls_disp>
      CHANGING lv_error
               lv_text.

    IF lv_error = abap_true.
      PERFORM set_upload_error
        USING    <ls_disp>-row_no
                 lv_text
        CHANGING <ls_disp>.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_ROW_DATA
*&---------------------------------------------------------------------*
*& 단일 행 기준 필수 날짜(PO Date, ETD, Closing Date), 오더유형,
*& 자재 마스터 존재 여부, 수량, 단가를 검증한다.
*&---------------------------------------------------------------------*
FORM check_row_data
  USING    ps_disp  TYPE gty_disp
  CHANGING pv_error TYPE abap_bool
           pv_text  TYPE string.

  CLEAR: pv_error, pv_text.

  IF ps_disp-bstdk IS INITIAL OR ps_disp-etd IS INITIAL OR ps_disp-close_dat IS INITIAL.
    pv_error = abap_true.
    pv_text  = TEXT-e10.
    RETURN.
  ENDIF.

  IF ps_disp-auart <> gc_zor AND ps_disp-auart <> gc_zkb.
    pv_error = abap_true.
    pv_text  = TEXT-e12.
    RETURN.
  ENDIF.

  READ TABLE gt_mara TRANSPORTING NO FIELDS
    WITH TABLE KEY matnr = ps_disp-matnr.
  IF sy-subrc <> 0.
    pv_error = abap_true.
    pv_text  = TEXT-e11.
    RETURN.
  ENDIF.

  IF ps_disp-kwmeng <= 0.
    pv_error = abap_true.
    pv_text  = TEXT-e13.
    RETURN.
  ENDIF.

  IF ps_disp-netpr <= 0.
    pv_error = abap_true.
    pv_text  = TEXT-e16.
    RETURN.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_DISPLAY_AMOUNT
*&---------------------------------------------------------------------*
*& ALV 최초 조회 전 각 품목의 공급가액(Amount = Qty * PO Unit Price)을 계산한다.
*&---------------------------------------------------------------------*
FORM set_display_amount.

  DATA:
    lv_error TYPE abap_bool,
    lv_text  TYPE string.

  LOOP AT gt_disp ASSIGNING FIELD-SYMBOL(<ls_disp>).
    IF <ls_disp>-msgty CA 'AEX' AND <ls_disp>-msgty IS NOT INITIAL.
      CONTINUE.
    ENDIF.

    PERFORM price_calculate_amount
      CHANGING <ls_disp>
               lv_error
               lv_text.

    IF lv_error = abap_true.
      PERFORM set_upload_error
        USING    <ls_disp>-row_no
                 lv_text
        CHANGING <ls_disp>.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PRICE_GET_DECIMALS
*&---------------------------------------------------------------------*
*& 통화키(WAERK)의 소수점 자릿수를 TCURX에서 조회한다 (기본값 2자리).
*&---------------------------------------------------------------------*
FORM price_get_decimals
  USING    pv_waerk    TYPE waers
  CHANGING pv_decimals TYPE i
           pv_error    TYPE abap_bool
           pv_text     TYPE string.

  CLEAR: pv_decimals, pv_error, pv_text.

  IF pv_waerk IS INITIAL.
    pv_error = abap_true.
    pv_text  = TEXT-e16.
    RETURN.
  ENDIF.

  pv_decimals = 2.
  SELECT SINGLE currdec
    FROM tcurx
   WHERE currkey = @pv_waerk
    INTO @pv_decimals.
  IF sy-subrc <> 0.
    pv_decimals = 2.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PRICE_SET_EXTERNAL
*&---------------------------------------------------------------------*
*& 외부 문자열 단가(Rate)를 표시용 단가(NETPR) 및 SAP 내부 금액(NETPR_INT)으로 변환한다.
*&---------------------------------------------------------------------*
FORM price_set_external
  USING    pv_value TYPE string
  CHANGING ps_disp  TYPE gty_disp
           pv_error TYPE abap_bool
           pv_text  TYPE string.

  DATA:
    lv_value     TYPE string,
    lv_decimals  TYPE i,
    lv_base      TYPE decfloat34,
    lv_scaled    TYPE decfloat34,
    lv_scale     TYPE decfloat34,
    lv_unit      TYPE vbap-kpein,
    lv_display   TYPE bapicurr_d,
    lv_netpr_int TYPE vbap-netpr,
    lv_bapi      TYPE bapicurr_d,
    lv_internal  TYPE bapicurr_d,
    ls_return    TYPE bapireturn.

  CLEAR: pv_error, pv_text.

  lv_value = zcl_cm_util=>regex_replace(
               i_data  = pv_value
               i_space = abap_true ).
  REPLACE ALL OCCURRENCES OF ',' IN lv_value WITH ``.

  IF lv_value IS INITIAL.
    pv_error = abap_true.
    pv_text  = TEXT-e16.
    RETURN.
  ENDIF.

  PERFORM price_get_decimals
    USING    ps_disp-waerk
    CHANGING lv_decimals
             pv_error
             pv_text.
  CHECK pv_error = abap_false.

  TRY.
      lv_base = CONV decfloat34( lv_value ).
      IF lv_base <= 0.
        pv_error = abap_true.
        pv_text  = TEXT-e16.
        RETURN.
      ENDIF.

      lv_display = EXACT #( lv_base ).
      lv_scale   = COND #( WHEN lv_decimals = 0 THEN 1
                           WHEN lv_decimals = 1 THEN 10
                           ELSE 100 ).
      lv_unit    = 1.
      lv_scaled  = lv_base.

      WHILE frac( lv_scaled * lv_scale ) <> 0.
        IF lv_unit >= 10000.
          pv_error = abap_true.
          pv_text  = TEXT-e16.
          RETURN.
        ENDIF.
        lv_unit   = lv_unit * 10.
        lv_scaled = lv_base * lv_unit.
      ENDWHILE.

      lv_bapi = EXACT #( lv_scaled ).

      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_INTERNAL'
        EXPORTING
          currency             = ps_disp-waerk
          amount_external      = lv_bapi
          max_number_of_digits = 23
        IMPORTING
          amount_internal      = lv_internal
          return               = ls_return.

      IF ls_return-type CA 'AEX' AND ls_return-type IS NOT INITIAL.
        pv_error = abap_true.
        pv_text  = TEXT-e16.
        RETURN.
      ENDIF.

      lv_netpr_int = EXACT #( lv_internal ).

    CATCH cx_sy_conversion_error cx_sy_arithmetic_error.
      pv_error = abap_true.
      pv_text  = TEXT-e16.
      RETURN.
  ENDTRY.

  ps_disp-netpr       = lv_display.
  ps_disp-netpr_int   = lv_netpr_int.
  ps_disp-kpein       = 1.
  ps_disp-price_scale = lv_unit.
  ps_disp-price_dec   = COND #( WHEN lv_decimals = 0 THEN '0' ELSE '4' ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PRICE_CALCULATE_AMOUNT
*&---------------------------------------------------------------------*
*& 단가(NETPR) * 수량(KWMENG)으로 금액(NETWR)을 계산하여 내부 통화 포맷으로 저장한다.
*&---------------------------------------------------------------------*
FORM price_calculate_amount
  CHANGING ps_disp  TYPE gty_disp
           pv_error TYPE abap_bool
           pv_text  TYPE string.

  DATA:
    lv_decimals TYPE i,
    lv_amount   TYPE decfloat34,
    lv_bapi     TYPE bapicurr_d,
    lv_internal TYPE bapicurr_d,
    ls_return   TYPE bapireturn.

  CLEAR: pv_error, pv_text, ps_disp-netwr.
  IF ps_disp-netpr IS INITIAL.
    RETURN.
  ENDIF.

  PERFORM price_get_decimals
    USING    ps_disp-waerk
    CHANGING lv_decimals
             pv_error
             pv_text.
  CHECK pv_error = abap_false.

  TRY.
      lv_amount = ( CONV decfloat34( ps_disp-netpr )
                    / CONV decfloat34( ps_disp-kpein ) )
                  * CONV decfloat34( ps_disp-kwmeng ).
      lv_amount = round( val = lv_amount dec = lv_decimals ).
      lv_bapi   = EXACT #( lv_amount ).

      CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_INTERNAL'
        EXPORTING
          currency             = ps_disp-waerk
          amount_external      = lv_bapi
          max_number_of_digits = 23
        IMPORTING
          amount_internal      = lv_internal
          return               = ls_return.

      IF ls_return-type CA 'AEX' AND ls_return-type IS NOT INITIAL.
        pv_error = abap_true.
        pv_text  = TEXT-e16.
        RETURN.
      ENDIF.

      ps_disp-netwr = EXACT #( lv_internal ).

    CATCH cx_sy_arithmetic_error cx_sy_conversion_error.
      pv_error = abap_true.
      pv_text  = TEXT-e16.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form PREPARE_CONDITION_PRICE
*&---------------------------------------------------------------------*
*& BAPI 조건 테이블(ORDER_CONDITIONS_IN)에 전달할 단가(COND_VALUE)와
*& 가격단위(COND_P_UNT)를 통화 소수점 스케일에 맞춰 변환한다.
*&---------------------------------------------------------------------*
FORM prepare_condition_price
  USING    ps_row     TYPE gty_disp
  CHANGING pv_value   TYPE bapicond-cond_value
           pv_unit    TYPE bapicond-cond_p_unt
           pv_error   TYPE abap_bool
           pv_message TYPE string.

  DATA:
    lv_decimals  TYPE i,
    lv_factor    TYPE decfloat34,
    lv_scale     TYPE decfloat34,
    lv_amount    TYPE decfloat34,
    lv_unit_calc TYPE decfloat34.

  CLEAR: pv_value, pv_unit, pv_error, pv_message.

  PERFORM price_get_decimals
    USING    ps_row-waerk
    CHANGING lv_decimals
             pv_error
             pv_message.
  CHECK pv_error = abap_false.

  TRY.
      lv_factor = 10 ** lv_decimals.
      lv_scale  = 1.
      lv_amount = ps_row-netpr.

      WHILE frac( lv_amount * lv_factor ) <> 0.
        lv_scale = lv_scale * 10.
        IF lv_scale > 10000.
          pv_error   = abap_true.
          pv_message = TEXT-e16.
          RETURN.
        ENDIF.
        lv_amount = ps_row-netpr * lv_scale.
      ENDWHILE.

      pv_value     = lv_amount.
      lv_unit_calc = CONV decfloat34( ps_row-kpein ) * lv_scale.
      pv_unit      = lv_unit_calc.

    CATCH cx_sy_conversion_error cx_sy_arithmetic_error.
      pv_error   = abap_true.
      pv_message = TEXT-e16.
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CONVERT_DATE
*&---------------------------------------------------------------------*
*& PDF/엑셀의 다양한 날짜 포맷을 SAP 내부 포맷(YYYYMMDD)으로 변환 후
*& DATE_CHECK_PLAUSIBILITY로 실제 존재하는 달력 날짜인지 검증한다.
*& - 지원 포맷:
*&   1) YYYY.MM.DD 또는 YYYY-MM-DD (예: 2025.04.07)
*&   2) MM/DD/YYYY (미국식 발주일 포맷, 예: 2/21/2025, 10/6/2026)
*&   3) YYYYMMDD (8자리 숫자)
*&---------------------------------------------------------------------*
FORM convert_date
  USING    pv_value TYPE string
  CHANGING pv_date  TYPE sy-datum
           pv_error TYPE abap_bool.

  DATA:
    lv_value TYPE string,
    lv_p1    TYPE string,
    lv_p2    TYPE string,
    lv_p3    TYPE string,
    lv_m2    TYPE n LENGTH 2,
    lv_d2    TYPE n LENGTH 2,
    lv_date  TYPE sy-datum.

  CLEAR: pv_date, pv_error.

  lv_value = pv_value.
  CONDENSE lv_value NO-GAPS.

  IF lv_value IS INITIAL.
    pv_error = abap_true.
    RETURN.
  ENDIF.

  " 1. YYYY.MM.DD 또는 YYYY-MM-DD 포맷 검사
  FIND FIRST OCCURRENCE OF
    REGEX '^([0-9]{4})[./-]([0-9]{1,2})[./-]([0-9]{1,2})$'
    IN lv_value
    SUBMATCHES lv_p1 lv_p2 lv_p3.

  IF sy-subrc = 0.
    lv_m2   = lv_p2.
    lv_d2   = lv_p3.
    lv_date = |{ lv_p1 }{ lv_m2 }{ lv_d2 }|.
  ELSE.
    " 2. MM/DD/YYYY 미국식 날짜 포맷 검사 (예: 2/21/2025 -> 20250221)
    FIND FIRST OCCURRENCE OF
      REGEX '^([0-9]{1,2})/([0-9]{1,2})/([0-9]{4})$'
      IN lv_value
      SUBMATCHES lv_p1 lv_p2 lv_p3.

    IF sy-subrc = 0.
      lv_m2   = lv_p1.
      lv_d2   = lv_p2.
      lv_date = |{ lv_p3 }{ lv_m2 }{ lv_d2 }|.
    ELSEIF strlen( lv_value ) = 8 AND lv_value CO '0123456789'.
      lv_date = lv_value.
    ELSE.
      pv_error = abap_true.
      RETURN.
    ENDIF.
  ENDIF.

  " 3. 날짜 정합성 검증 (윤년, 월별 일수 초과 등 확인)
  CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
    EXPORTING
      date                      = lv_date
    EXCEPTIONS
      plausibility_check_failed = 1
      OTHERS                    = 2.

  IF sy-subrc <> 0.
    pv_error = abap_true.
    RETURN.
  ENDIF.

  pv_date = lv_date.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_UPLOAD_ERROR
*&---------------------------------------------------------------------*
*& GT_DISP 내에 오류(MSGTY = 'E')가 한 건이라도 있는지 확인한다.
*&---------------------------------------------------------------------*
FORM check_upload_error CHANGING pv_error TYPE abap_bool.

  pv_error = abap_false.
  READ TABLE gt_disp TRANSPORTING NO FIELDS WITH KEY msgty = gc_e.
  IF sy-subrc = 0.
    pv_error = abap_true.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SHOW_ERROR_POPUP
*&---------------------------------------------------------------------*
*& 업로드 단계에서 발생한 오류 목록을 ZCL_CM_UTIL=>ERR_POPUP_SHOW로 표시한다.
*&---------------------------------------------------------------------*
FORM show_error_popup.

  DATA:
    lt_return TYPE bapiret2_t,
    ls_return TYPE bapiret2.

  LOOP AT gt_disp INTO DATA(ls_disp) WHERE msgty = gc_e.
    CLEAR ls_return.
    ls_return-type    = ls_disp-msgty.
    ls_return-message = ls_disp-message.
    ls_return-row     = ls_disp-row_no.
    APPEND ls_return TO lt_return.
  ENDLOOP.

  IF lt_return IS NOT INITIAL.
    zcl_cm_util=>err_popup_show(
      iv_title = TEXT-t03
      it_msg   = lt_return ).
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
* ALV SETUP & DROPDOWN (ALV 그리드 및 드롭다운 설정)
*---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form SET_ALV_GRID
*&---------------------------------------------------------------------*
*& Screen 0100 컨테이너에 ALV Grid를 생성하고 필드카탈로그, 드롭다운, 이벤트를 바인딩한다.
*&---------------------------------------------------------------------*
FORM set_alv_grid.

  go_grid = NEW cl_gui_alv_grid(
    i_parent = cl_gui_container=>screen0 ).

  gt_fcat = zcl_cm_util=>table_to_fieldcatalog( it_tab = gt_disp ).

  PERFORM set_fcat USING gt_fcat.
  PERFORM set_alv_dropdown.
  PERFORM set_event.

  go_grid->set_table_for_first_display(
    EXPORTING
      i_save               = 'A'
      is_variant           = VALUE #( report   = sy-cprog
                                      username = sy-uname )
      is_layout            = VALUE #( cwidth_opt = gc_x
                                      no_rowins  = gc_x
                                      stylefname = gc_style
                                      sel_mode   = gc_d )
      it_toolbar_excluding = VALUE #( ( cl_gui_alv_grid=>mc_fg_edit ) )
    CHANGING
      it_outtab            = gt_disp
      it_fieldcatalog      = gt_fcat
      it_sort              = gt_sort ).

  go_grid->set_ready_for_input( i_ready_for_input = 1 ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_ALV_DROPDOWN
*&---------------------------------------------------------------------*
*& 요구사항 6 반영:
*& Sales Order Type(AUART) 컬럼에 드롭다운 리스트('ZOR', 'ZKB')를 등록한다.
*&---------------------------------------------------------------------*
FORM set_alv_dropdown.

  DATA lt_drdn TYPE lvc_t_drop.

  CHECK go_grid IS BOUND.

  lt_drdn = VALUE #(
    ( handle = gc_drdn_auart value = gc_zor )
    ( handle = gc_drdn_auart value = gc_zkb )
  ).

  go_grid->set_drop_down_table(
    it_drop_down = lt_drdn ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_FCAT
*&---------------------------------------------------------------------*
*& 요구사항 레이아웃(22개 비즈니스 컬럼 + 상태/메시지) 순서와 컬럼명을 설정한다.
*&---------------------------------------------------------------------*
FORM set_fcat USING pt_fcat TYPE lvc_t_fcat.

  DATA:
    lv_col_pos TYPE lvc_colpos,
    lv_text    TYPE lvc_txtcol.

  CLEAR lv_col_pos.

  LOOP AT pt_fcat ASSIGNING FIELD-SYMBOL(<ls_fcat>).

    CLEAR:
      lv_text,
      <ls_fcat>-col_pos,
      <ls_fcat>-coltext,
      <ls_fcat>-seltext,
      <ls_fcat>-scrtext_l,
      <ls_fcat>-scrtext_m,
      <ls_fcat>-scrtext_s,
      <ls_fcat>-tooltip,
      <ls_fcat>-edit,
      <ls_fcat>-drdn_hndl,
      <ls_fcat>-tech.

    <ls_fcat>-no_out = abap_true.

    CASE <ls_fcat>-fieldname.

      WHEN 'KUNNR'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c01. " 01. Customer

      WHEN 'NAME1'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c02. " 02. Name

      WHEN 'BSTDK'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c03. " 03. PO Date

      WHEN 'AFF_PO_NO'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c04. " 04. Affiliated Com. PO No

      WHEN 'BSTKD_E'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c05. " 05. Customer PO No

      WHEN 'AUART'.
        <ls_fcat>-no_out    = abap_false.
        <ls_fcat>-edit      = abap_true.
        <ls_fcat>-drdn_hndl = gc_drdn_auart. " 드롭다운 핸들 연결
        lv_text             = TEXT-c06.      " 06. Sales Order Type

      WHEN 'VBELN'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c07. " 07. Sales Order No

      WHEN 'POSNR'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c08. " 08. Sales Order ITEM No

      WHEN 'EBELN'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c09. " 09. Purchase Order No

      WHEN 'EBELP'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c10. " 10. Purchase Order Item

      WHEN 'ZTERM'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c11. " 11. Payment Term

      WHEN 'ETD'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c12. " 12. ETD

      WHEN 'CLOSE_DAT'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c13. " 13. Closing Date

      WHEN 'KDMAT'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c14. " 14. Customer Code

      WHEN 'MATNR'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c15. " 15. Material

      WHEN 'MAKTX'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c16. " 16. Description

      WHEN 'KWMENG'.
        <ls_fcat>-no_out     = abap_false.
        <ls_fcat>-qfieldname = 'MEINS'.
        <ls_fcat>-do_sum     = abap_true.
        lv_text              = TEXT-c17. " 17. Qty

      WHEN 'MEINS'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c18. " 18. Unit

      WHEN 'NETPR'.
        <ls_fcat>-no_out     = abap_false.
        <ls_fcat>-decmlfield = 'PRICE_DEC'.
        <ls_fcat>-just       = 'R'.
        lv_text              = TEXT-c19. " 19. PO Unit Price

      WHEN 'NETWR'.
        <ls_fcat>-no_out     = abap_false.
        <ls_fcat>-cfieldname = 'WAERK'.
        <ls_fcat>-do_sum     = abap_true.
        lv_text              = TEXT-c20. " 20. Amount

      WHEN 'MST_PRICE'.
        <ls_fcat>-no_out     = abap_false.
        <ls_fcat>-decmlfield = 'PRICE_DEC'.
        <ls_fcat>-just       = 'R'.
        lv_text              = TEXT-c21. " 21. Master Unit Price

      WHEN 'WAERK'.
        <ls_fcat>-no_out = abap_false.
        lv_text          = TEXT-c22. " 22. Currency

      WHEN 'STATUS'.
        <ls_fcat>-no_out = abap_false.
        <ls_fcat>-icon   = abap_true.
        lv_text          = TEXT-c23. " Status

      WHEN 'MESSAGE'.
        <ls_fcat>-no_out    = abap_false.
        <ls_fcat>-outputlen = 35.
        lv_text             = TEXT-c24. " Message

      WHEN OTHERS.
        " 내부 관리용 필드는 화면에서 숨김 처리
        <ls_fcat>-tech   = abap_true.
        <ls_fcat>-no_out = abap_true.

    ENDCASE.

    IF <ls_fcat>-no_out = abap_false AND <ls_fcat>-tech = abap_false.
      lv_col_pos        = lv_col_pos + 1.
      <ls_fcat>-col_pos = lv_col_pos.
      IF lv_text IS NOT INITIAL.
        <ls_fcat>-coltext   = lv_text.
        <ls_fcat>-seltext   = lv_text.
        <ls_fcat>-scrtext_l = lv_text.
        <ls_fcat>-scrtext_m = lv_text.
        <ls_fcat>-scrtext_s = lv_text.
        <ls_fcat>-tooltip   = lv_text.
      ENDIF.
    ENDIF.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_EVENT
*&---------------------------------------------------------------------*
*& ALV Grid 이벤트 핸들러 및 셀 수정 이벤트를 등록한다.
*&---------------------------------------------------------------------*
FORM set_event.

  SET HANDLER:
    lcl_event=>handle_toolbar               FOR go_grid,
    lcl_event=>handle_user_command          FOR go_grid,
    lcl_event=>handle_data_changed          FOR go_grid,
    lcl_event=>handle_double_click          FOR go_grid,
    lcl_event=>handle_data_changed_finished FOR go_grid.

  go_grid->register_edit_event(
    i_event_id = cl_gui_alv_grid=>mc_evt_modified ).

  go_grid->register_edit_event(
    i_event_id = cl_gui_alv_grid=>mc_evt_enter ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_EDIT_STYLE
*&---------------------------------------------------------------------*
*& Sales Order가 아직 생성되지 않은 행(VBELN IS INITIAL)만
*& Sales Order Type(AUART) 드롭다운을 수정할 수 있도록 활성화하고,
*& 이미 SO가 생성된 행은 수정 불가(Disabled)로 잠근다.
*&---------------------------------------------------------------------*
FORM set_edit_style.

  LOOP AT gt_disp ASSIGNING FIELD-SYMBOL(<ls_disp>).
    CLEAR <ls_disp>-style.

    INSERT VALUE #(
      fieldname = 'AUART'
      style     = COND #(
                    WHEN <ls_disp>-vbeln IS INITIAL
                    THEN cl_gui_alv_grid=>mc_style_enabled
                    ELSE cl_gui_alv_grid=>mc_style_disabled )
    ) INTO TABLE <ls_disp>-style.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_DISPLAY_STATUS
*&---------------------------------------------------------------------*
*& 행별 처리 상태(오류: 빨간불, SO/PO 생성완료: 초록불, 대기: 회색불)를 설정한다.
*&---------------------------------------------------------------------*
FORM set_display_status.

  LOOP AT gt_disp ASSIGNING FIELD-SYMBOL(<ls_disp>).
    CLEAR <ls_disp>-status.

    IF <ls_disp>-msgty CA 'AEX' AND <ls_disp>-msgty IS NOT INITIAL.
      <ls_disp>-status   = icon_red_light.
      <ls_disp>-row_kind = gc_row_error.
    ELSEIF <ls_disp>-ebeln IS NOT INITIAL.
      <ls_disp>-status   = icon_green_light.
      <ls_disp>-row_kind = gc_row_po.
    ELSEIF <ls_disp>-vbeln IS NOT INITIAL.
      <ls_disp>-status   = icon_green_light.
      <ls_disp>-row_kind = gc_row_so.
    ELSE.
      <ls_disp>-status   = icon_light_out.
      <ls_disp>-row_kind = gc_row_ready.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form REFRESH_GRID
*&---------------------------------------------------------------------*
*& 스크롤 위치(행/열)를 유지한 채 ALV 그리드를 새로고침한다.
*&---------------------------------------------------------------------*
FORM refresh_grid USING po_grid TYPE REF TO cl_gui_alv_grid.

  CHECK po_grid IS BOUND.

  po_grid->refresh_table_display(
    EXPORTING
      is_stable = VALUE #( row = gc_x col = gc_x ) ).

ENDFORM.

*---------------------------------------------------------------------*
* ALV EVENTS (툴바 버튼, 사용자 명령, 데이터 변경, 더블클릭)
*---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form HANDLE_TOOLBAR
*&---------------------------------------------------------------------*
*& ALV 툴바에 Create Sales Order(CRSO), Delete Sales Order(DLSO),
*& Create Purchase Order(CRPO) 버튼을 추가한다.
*&---------------------------------------------------------------------*
FORM handle_toolbar
  USING po_obj TYPE REF TO cl_alv_event_toolbar_set
        po_snd TYPE REF TO cl_gui_alv_grid.

  CHECK po_snd = go_grid.

  APPEND VALUE #( butn_type = 3 ) TO po_obj->mt_toolbar.

  " 1. Create Sales Order 버튼
  APPEND VALUE #(
    function  = 'CRSO'
    text      = TEXT-b01
    quickinfo = TEXT-b01
    icon      = icon_create
  ) TO po_obj->mt_toolbar.

  " 2. Delete Sales Order 버튼
  APPEND VALUE #(
    function  = 'DLSO'
    text      = TEXT-b06
    quickinfo = TEXT-b06
    icon      = icon_delete
  ) TO po_obj->mt_toolbar.

  " 3. Create Purchase Order 버튼
  APPEND VALUE #(
    function  = 'CRPO'
    text      = TEXT-b02
    quickinfo = TEXT-b02
    icon      = icon_create
  ) TO po_obj->mt_toolbar.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form HANDLE_USER_COMMAND
*&---------------------------------------------------------------------*
*& ALV 툴바 버튼 클릭 시:
*& 1. CHECK_CHANGED_DATA로 화면 편집값을 내부 테이블에 반영
*& 2. ZCL_CM_UTIL=>POPUP_TO_CONFIRM으로 확인 팝업 표시 (CONFIRM_YES = 'Y' 확인)
*& 3. 각 비즈니스 로직(SO 생성, SO 삭제, PO 생성) 호출
*&---------------------------------------------------------------------*
FORM handle_user_command
  USING pv_ucomm TYPE sy-ucomm
        po_snd   TYPE REF TO cl_gui_alv_grid.

  DATA:
    lv_valid  TYPE abap_bool,
    lv_answer TYPE char01.

  CHECK po_snd IS BOUND AND po_snd = go_grid.
  CHECK pv_ucomm = 'CRSO' OR pv_ucomm = 'DLSO' OR pv_ucomm = 'CRPO'.

  " 프론트엔드 ALV에서 변경된 드롭다운 값을 먼저 검증 및 동기화
  po_snd->check_changed_data(
    IMPORTING
      e_valid = lv_valid ).

  CHECK lv_valid = abap_true.

  CASE pv_ucomm.

    " 1. 판매오더 생성
    WHEN 'CRSO'.
      lv_answer = zcl_cm_util=>popup_to_confirm(
        i_titlebar              = TEXT-b01
        i_text_question         = TEXT-m02
        i_default_button        = '2'
        i_display_cancel_button = space ).
      CHECK lv_answer = zcl_cm_util=>confirm_yes.
      PERFORM create_sales_order.

    " 2. 판매오더 삭제
    WHEN 'DLSO'.
      lv_answer = zcl_cm_util=>popup_to_confirm(
        i_titlebar              = TEXT-b06
        i_text_question         = TEXT-m05
        i_default_button        = '2'
        i_display_cancel_button = space ).
      CHECK lv_answer = zcl_cm_util=>confirm_yes.
      PERFORM delete_sales_order.

    " 3. 구매오더 생성
    WHEN 'CRPO'.
      lv_answer = zcl_cm_util=>popup_to_confirm(
        i_titlebar              = TEXT-b02
        i_text_question         = TEXT-m03
        i_default_button        = '2'
        i_display_cancel_button = space ).
      CHECK lv_answer = zcl_cm_util=>confirm_yes.
      PERFORM create_purchase_order.

  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form HANDLE_DATA_CHANGED
*&---------------------------------------------------------------------*
*& 사용자가 ALV에서 Sales Order Type(AUART) 드롭다운을 변경했을 때:
*& - ZOR 또는 ZKB인지 검증하고,
*& - 설계서 규칙("Affiliated Com. PO No 기준으로 Sales Order Type을 하나로만 입력")에
*&   따라 동일한 Affiliated Com. PO No를 가진 미생성 행들의 AUART를 일괄 동기화한다.
*&---------------------------------------------------------------------*
FORM handle_data_changed
  USING er_data_changed TYPE REF TO cl_alv_changed_data_protocol
        e_onf4          TYPE char01
        e_onf4_after    TYPE char01
        e_onf4_before   TYPE char01
        sender          TYPE REF TO cl_gui_alv_grid.

  DATA:
    lv_value TYPE string,
    lv_error TYPE abap_bool,
    lv_text  TYPE string,
    ls_work  TYPE gty_disp.

  CHECK sender IS BOUND AND sender = go_grid.
  CHECK er_data_changed IS BOUND.

  LOOP AT er_data_changed->mt_mod_cells INTO DATA(ls_cell)
    WHERE fieldname = 'AUART'.

    CHECK ls_cell-row_id > 0.
    READ TABLE gt_disp ASSIGNING FIELD-SYMBOL(<ls_disp>) INDEX ls_cell-row_id.
    CHECK sy-subrc = 0 AND <ls_disp>-vbeln IS INITIAL.

    ls_work  = <ls_disp>.
    lv_value = ls_cell-value.

    PERFORM check_field_value
      USING    'AUART'
               lv_value
      CHANGING ls_work
               lv_error
               lv_text.

    IF lv_error = abap_true.
      er_data_changed->add_protocol_entry(
        EXPORTING
          i_msgid     = gc_msgid
          i_msgno     = '000'
          i_msgty     = gc_e
          i_msgv1     = CONV #( lv_text )
          i_fieldname = ls_cell-fieldname
          i_row_id    = ls_cell-row_id
          i_tabix     = ls_cell-tabix ).
      CONTINUE.
    ENDIF.

    " 동일한 Affiliated Com. PO No를 가진 모든 미생성 행의 오더유형을 하나로 통일
    LOOP AT gt_disp ASSIGNING FIELD-SYMBOL(<ls_peer>)
      WHERE aff_po_no = <ls_disp>-aff_po_no
        AND vbeln     = space.
      DATA(lv_peer_idx) = sy-tabix.
      <ls_peer>-auart   = ls_work-auart.
      <ls_peer>-changed = abap_true.

      er_data_changed->modify_cell(
        EXPORTING
          i_row_id    = lv_peer_idx
          i_fieldname = 'AUART'
          i_value     = ls_work-auart ).
    ENDLOOP.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form HANDLE_DATA_CHANGED_FIN
*&---------------------------------------------------------------------*
*& 셀 수정 완료 후 그리드를 새로고침한다.
*&---------------------------------------------------------------------*
FORM handle_data_changed_fin
  USING pv_modified   TYPE abap_bool
        pt_good_cells TYPE lvc_t_modi
        po_snd        TYPE REF TO cl_gui_alv_grid.

  CHECK po_snd IS BOUND AND po_snd = go_grid.
  CHECK pv_modified = abap_true.

  PERFORM refresh_grid USING po_snd.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form HANDLE_DOUBLE_CLICK
*&---------------------------------------------------------------------*
*& ALV 셀 더블클릭 시 해당 문서 조회 트랜잭션으로 Drill-down 한다:
*& - Sales Order No (VBELN) 더블클릭 -> VA03 이동
*& - Purchase Order No (EBELN) 더블클릭 -> ME23N 이동
*&---------------------------------------------------------------------*
FORM handle_double_click
  USING ps_row    TYPE lvc_s_row
        ps_column TYPE lvc_s_col
        ps_row_no TYPE lvc_s_roid
        po_sender TYPE REF TO cl_gui_alv_grid.

  DATA lv_row_id TYPE i.

  CHECK po_sender IS BOUND AND po_sender = go_grid.

  lv_row_id = COND #( WHEN ps_row_no-row_id IS NOT INITIAL
                      THEN ps_row_no-row_id
                      ELSE ps_row-index ).
  CHECK lv_row_id > 0.

  READ TABLE gt_disp ASSIGNING FIELD-SYMBOL(<ls_disp>) INDEX lv_row_id.
  CHECK sy-subrc = 0.

  CASE ps_column-fieldname.
    WHEN 'VBELN'.
      CHECK <ls_disp>-vbeln IS NOT INITIAL.
      SET PARAMETER ID 'AUN' FIELD <ls_disp>-vbeln.
      CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN.

    WHEN 'EBELN'.
      CHECK <ls_disp>-ebeln IS NOT INITIAL.
      SET PARAMETER ID 'BES' FIELD <ls_disp>-ebeln.
      CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN.
  ENDCASE.

ENDFORM.

*---------------------------------------------------------------------*
* BUSINESS PROCESS - SALES ORDER & PURCHASE ORDER (요구사항 4, 5 반영)
*---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form GET_SELECTED_SO_DATA
*&---------------------------------------------------------------------*
*& ALV에서 사용자가 선택한 행들을 수집하고, 이미 SO가 생성된 행이 포함되었는지 검증한다.
*&---------------------------------------------------------------------*
FORM get_selected_so_data
  CHANGING pt_so    TYPE gty_t_so_work
           pv_error TYPE abap_bool.

  DATA lt_rows TYPE lvc_t_roid.

  CLEAR: pt_so, pv_error.
  CHECK go_grid IS BOUND.

  go_grid->get_selected_rows( IMPORTING et_row_no = lt_rows ).
  DELETE lt_rows WHERE row_id <= 0.

  IF lt_rows IS INITIAL.
    pv_error = abap_true.
    MESSAGE s006 DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  LOOP AT lt_rows INTO DATA(ls_row).
    READ TABLE gt_disp INTO DATA(ls_disp) INDEX ls_row-row_id.
    CHECK sy-subrc = 0.

    " 이미 Sales Order가 생성된 행이 선택되어 있으면 에러 메시지 출력
    IF ls_disp-vbeln IS NOT INITIAL.
      pv_error = abap_true.
      MESSAGE s000 WITH TEXT-e17 DISPLAY LIKE gc_e.
      RETURN.
    ENDIF.

    APPEND VALUE #( row_id = ls_row-row_id data = ls_disp ) TO pt_so.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_CREATE_SO_GROUP
*&---------------------------------------------------------------------*
*& 동일 Affiliated Com. PO No 그룹 내에 서로 다른 Sales Order Type이 섞여 있는지 검증한다.
*&---------------------------------------------------------------------*
FORM check_create_so_group
  USING    pt_group TYPE gty_t_so_work
  CHANGING pv_error TYPE abap_bool
           pv_text  TYPE string.

  CLEAR: pv_error, pv_text.
  CHECK pt_group IS NOT INITIAL.

  READ TABLE pt_group INTO DATA(ls_first) INDEX 1.
  CHECK sy-subrc = 0.

  LOOP AT pt_group INTO DATA(ls_group).
    IF ls_group-data-auart <> ls_first-data-auart.
      pv_error = abap_true.
      pv_text  = TEXT-e18.
      RETURN.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CREATE_SALES_ORDER
*&---------------------------------------------------------------------*
*& 선택된 행들을 Affiliated Com. PO No 기준으로 그룹핑하여
*& BAPI_SALESORDER_CREATEFROMDAT2로 판매오더를 생성하고 COMMIT/ROLLBACK을 수행한다.
*&---------------------------------------------------------------------*
FORM create_sales_order.

  DATA:
    lt_so        TYPE gty_t_so_work,
    lt_group     TYPE gty_t_so_work,
    lv_error     TYPE abap_bool,
    lv_group_err TYPE abap_bool,
    lv_vbeln     TYPE vbak-vbeln,
    lv_message   TYPE string,
    lv_success   TYPE i,
    lv_failed    TYPE i.

  PERFORM get_selected_so_data CHANGING lt_so lv_error.
  CHECK lv_error = abap_false.

  " Affiliated Com. PO No 단위로 그룹핑하여 1개의 Sales Order로 생성
  LOOP AT lt_so INTO DATA(ls_so)
    GROUP BY ( aff_po_no = ls_so-data-aff_po_no )
    ASSIGNING FIELD-SYMBOL(<ls_group_key>).

    CLEAR:
      lt_group,
      lv_error,
      lv_group_err,
      lv_vbeln,
      lv_message.

    LOOP AT GROUP <ls_group_key> INTO DATA(ls_group_row).
      APPEND ls_group_row TO lt_group.
    ENDLOOP.

    PERFORM check_create_so_group
      USING    lt_group
      CHANGING lv_group_err
               lv_message.

    IF lv_group_err = abap_true.
      lv_failed = lv_failed + 1.
      PERFORM update_sales_order_result USING lt_group space abap_true lv_message.
      CONTINUE.
    ENDIF.

    PERFORM create_sales_order_group
      CHANGING lt_group
               lv_vbeln
               lv_error
               lv_message.

    IF lv_error = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      lv_failed = lv_failed + 1.
      PERFORM update_sales_order_result USING lt_group space abap_true lv_message.
      CONTINUE.
    ENDIF.

    PERFORM commit_standard CHANGING lv_error lv_message.
    IF lv_error = abap_true.
      lv_failed = lv_failed + 1.
      PERFORM update_sales_order_result USING lt_group lv_vbeln abap_true lv_message.
      CONTINUE.
    ENDIF.

    lv_success = lv_success + 1.
    PERFORM update_sales_order_result USING lt_group lv_vbeln abap_false lv_message.

  ENDLOOP.

  PERFORM set_display_status.
  PERFORM set_edit_style.
  PERFORM refresh_grid USING go_grid.
  PERFORM show_process_result USING lv_success lv_failed.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CREATE_SALES_ORDER_GROUP
*&---------------------------------------------------------------------*
*& 설계서 A.2 매핑 규칙에 따라 BAPI_SALESORDER_CREATEFROMDAT2 파라미터를 구성한다:
*& - HEADER:
*&   * PURCH_NO_C = Affiliated Com. PO No (EAC-25-0077)
*&   * PURCH_NO_S = Customer PO No (Ship-to Party PO, 요구사항 4.2)
*&   * PRICE_DATE / PURCH_DATE = PO Date
*&   * PMNTTRMS = Payment Term (예: F007)
*& - ITEM & SCHEDULE:
*&   * REQ_DATE = Closing Date (ETD - 3 Working Days)
*&   * PLANT    = Sales Organization
*& - CONDITION:
*&   * PO Unit Price(NETPR)와 Master Unit Price(MST_PRICE)가 다를 때만
*&     조건유형 'ZSR1'(GC_ZSR1)에 PO Unit Price를 담아 전송한다.
*&---------------------------------------------------------------------*
FORM create_sales_order_group
  CHANGING pt_group   TYPE gty_t_so_work
           pv_vbeln   TYPE vbak-vbeln
           pv_error   TYPE abap_bool
           pv_message TYPE string.

  DATA:
    ls_header     TYPE bapisdhd1,
    ls_headerx    TYPE bapisdhd1x,
    lt_item       TYPE TABLE OF bapisditm,
    lt_itemx      TYPE TABLE OF bapisditmx,
    lt_partner    TYPE TABLE OF bapiparnr,
    lt_schedule   TYPE TABLE OF bapischdl,
    lt_schedulex  TYPE TABLE OF bapischdlx,
    lt_cond       TYPE TABLE OF bapicond,
    lt_condx      TYPE TABLE OF bapicondx,
    lt_return     TYPE TABLE OF bapiret2,
    lv_item_no    TYPE i,
    lv_posnr      TYPE posnr_va,
    lv_cond_value TYPE bapicond-cond_value,
    lv_cond_p_unt TYPE bapicond-cond_p_unt,
    lv_bapi_vbeln TYPE bapivbeln-vbeln.

  CLEAR: pv_vbeln, pv_error, pv_message.
  CHECK pt_group IS NOT INITIAL.

  READ TABLE pt_group ASSIGNING FIELD-SYMBOL(<ls_first>) INDEX 1.
  CHECK sy-subrc = 0.

*---------------------------------------------------------------------*
* 1. ORDER_HEADER_IN 매핑 (설계서 기준)
*---------------------------------------------------------------------*
  ls_header-doc_type   = <ls_first>-data-auart.     " 리스트 Sales Order Type (ZOR / ZKB)
  ls_header-sales_org  = <ls_first>-data-vkorg.     " 조회조건 Sales Organization
  ls_header-distr_chan = <ls_first>-data-vtweg.     " 조회조건 Distribution Channel (40)
  ls_header-division   = <ls_first>-data-spart.     " 조회조건 Division (00)
  ls_header-doc_date   = sy-datum.                  " 생성일 (SY-DATUM)
  ls_header-price_date = <ls_first>-data-bstdk.     " 리스트 PO Date
  ls_header-purch_date = <ls_first>-data-bstdk.     " 리스트 PO Date
  ls_header-pmnttrms   = <ls_first>-data-zterm.     " 리스트 Payment Term
  ls_header-sales_off  = <ls_first>-data-vkbur.     " 조회조건 Sales Office
  ls_header-sales_grp  = <ls_first>-data-vkgrp.     " 조회조건 Sales Group
  ls_header-purch_no_c = <ls_first>-data-aff_po_no. " 리스트 Affiliated Com. PO No
  ls_header-purch_no_s = <ls_first>-data-bstkd_e.   " Ship-To Customer PO No (요구사항 4.2)

  ls_headerx-updateflag = gc_i.
  ls_headerx-doc_type   = gc_x.
  ls_headerx-sales_org  = gc_x.
  ls_headerx-distr_chan = gc_x.
  ls_headerx-division   = gc_x.
  ls_headerx-doc_date   = gc_x.
  ls_headerx-price_date = gc_x.
  ls_headerx-purch_date = gc_x.
  ls_headerx-pmnttrms   = gc_x.
  ls_headerx-sales_off  = gc_x.
  ls_headerx-sales_grp  = gc_x.
  ls_headerx-purch_no_c = gc_x.
  ls_headerx-purch_no_s = gc_x.

*---------------------------------------------------------------------*
* 2. ORDER_PARTNERS 매핑 (SP, SH, BP, PY 모두 Affiliated Company)
*---------------------------------------------------------------------*
  APPEND VALUE #( partn_role = gc_ag partn_numb = <ls_first>-data-kunnr ) TO lt_partner.
  APPEND VALUE #( partn_role = gc_we partn_numb = <ls_first>-data-kunnr ) TO lt_partner.
  APPEND VALUE #( partn_role = gc_re partn_numb = <ls_first>-data-kunnr ) TO lt_partner.
  APPEND VALUE #( partn_role = gc_rg partn_numb = <ls_first>-data-kunnr ) TO lt_partner.

*---------------------------------------------------------------------*
* 3. ORDER_ITEMS_IN / ORDER_SCHEDULES_IN / ORDER_CONDITIONS_IN 매핑
*---------------------------------------------------------------------*
  LOOP AT pt_group ASSIGNING FIELD-SYMBOL(<ls_group>).
    lv_item_no = lv_item_no + 10.
    lv_posnr   = lv_item_no.
    <ls_group>-data-posnr = lv_posnr.

    " 품목 데이터 (Customer PO는 Ship-to PO 필드인 PURCH_NO_S에 매핑)
    APPEND VALUE #(
      itm_number = lv_posnr
      material   = <ls_group>-data-matnr
      cust_mat22 = <ls_group>-data-kdmat
      purch_no_s = <ls_group>-data-bstkd_e
      pr_date    = <ls_group>-data-bstdk
      plant      = <ls_group>-data-vkorg
    ) TO lt_item.

    APPEND VALUE #(
      itm_number = lv_posnr
      updateflag = gc_i
      material   = gc_x
      cust_mat22 = gc_x
      purch_no_s = gc_x
      pr_date    = gc_x
      plant      = gc_x
    ) TO lt_itemx.

    " 납품일정 라인 (REQ_DATE = Closing Date, REQ_QTY = Qty)
    APPEND VALUE #(
      itm_number = lv_posnr
      sched_line = '0001'
      req_date   = <ls_group>-data-close_dat
      req_qty    = <ls_group>-data-kwmeng
    ) TO lt_schedule.

    APPEND VALUE #(
      itm_number = lv_posnr
      sched_line = '0001'
      updateflag = gc_i
      req_date   = gc_x
      req_qty    = gc_x
    ) TO lt_schedulex.

    " ★ PO Unit Price와 Master Unit Price가 다를 때만 ZSR1 수동 조건값 전송
    IF <ls_group>-data-netpr <> <ls_group>-data-mst_price.
      CLEAR: lv_cond_value, lv_cond_p_unt.
      PERFORM prepare_condition_price
        USING    <ls_group>-data
        CHANGING lv_cond_value
                 lv_cond_p_unt
                 pv_error
                 pv_message.
      IF pv_error = abap_true.
        RETURN.
      ENDIF.

      APPEND VALUE #(
        itm_number = lv_posnr
        cond_type  = gc_zsr1
        cond_value = lv_cond_value
        currency   = <ls_group>-data-waerk
        cond_unit  = <ls_group>-data-meins
        cond_p_unt = lv_cond_p_unt
      ) TO lt_cond.

      APPEND VALUE #(
        itm_number = lv_posnr
        updateflag = gc_i
        cond_type  = gc_zsr1
        cond_value = gc_x
        currency   = gc_x
        cond_unit  = gc_x
        cond_p_unt = gc_x
      ) TO lt_condx.
    ENDIF.
  ENDLOOP.

  " 4. 판매오더 생성 BAPI 호출
  CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
    EXPORTING
      order_header_in      = ls_header
      order_header_inx     = ls_headerx
    IMPORTING
      salesdocument        = lv_bapi_vbeln
    TABLES
      return               = lt_return
      order_items_in       = lt_item
      order_items_inx      = lt_itemx
      order_partners       = lt_partner
      order_schedules_in   = lt_schedule
      order_schedules_inx  = lt_schedulex
      order_conditions_in  = lt_cond
      order_conditions_inx = lt_condx.

  LOOP AT lt_return INTO DATA(ls_return) WHERE type CA 'AEX'.
    pv_error   = abap_true.
    pv_message = ls_return-message.
    EXIT.
  ENDLOOP.

  IF lv_bapi_vbeln IS INITIAL OR pv_error = abap_true.
    pv_error = abap_true.
    IF pv_message IS INITIAL.
      pv_message = TEXT-e19.
    ENDIF.
    RETURN.
  ENDIF.

  pv_vbeln   = lv_bapi_vbeln.
  pv_message = replace( val = TEXT-s01 sub = '&1' with = pv_vbeln ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form UPDATE_SALES_ORDER_RESULT
*&---------------------------------------------------------------------*
*& 판매오더 생성 결과(생성된 SO 번호 또는 오류 메시지)를 GT_DISP에 업데이트한다.
*&---------------------------------------------------------------------*
FORM update_sales_order_result
  USING pt_group   TYPE gty_t_so_work
        pv_vbeln   TYPE vbak-vbeln
        pv_error   TYPE abap_bool
        pv_message TYPE string.

  LOOP AT pt_group INTO DATA(ls_group).
    READ TABLE gt_disp ASSIGNING FIELD-SYMBOL(<ls_disp>) INDEX ls_group-row_id.
    CHECK sy-subrc = 0.

    IF pv_error = abap_true.
      <ls_disp>-msgty   = gc_e.
      <ls_disp>-message = pv_message.
    ELSE.
      <ls_disp>-vbeln   = pv_vbeln.
      <ls_disp>-posnr   = ls_group-data-posnr.
      <ls_disp>-msgty   = gc_s.
      <ls_disp>-message = pv_message.
      <ls_disp>-changed = abap_false.
      <ls_disp>-new     = abap_false.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form DELETE_SALES_ORDER
*&---------------------------------------------------------------------*
*& 선택된 행의 Sales Order를 BAPI_SALESORDER_CHANGE(UPDATEFLAG = 'D')로 삭제한다.
*& (후속 구매오더 EBELN이 이미 존재하는 경우에는 삭제를 차단한다.)
*&---------------------------------------------------------------------*
FORM delete_sales_order.

  TYPES:
    BEGIN OF lty_vbeln,
      vbeln TYPE vbak-vbeln,
    END OF lty_vbeln.

  DATA:
    lt_rows    TYPE lvc_t_roid,
    lt_vbeln   TYPE SORTED TABLE OF lty_vbeln WITH UNIQUE KEY vbeln,
    lv_error   TYPE abap_bool,
    lv_message TYPE string,
    lv_success TYPE i,
    lv_failed  TYPE i.

  go_grid->get_selected_rows( IMPORTING et_row_no = lt_rows ).
  DELETE lt_rows WHERE row_id <= 0.

  IF lt_rows IS INITIAL.
    MESSAGE s006 DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  LOOP AT lt_rows INTO DATA(ls_row).
    READ TABLE gt_disp INTO DATA(ls_disp) INDEX ls_row-row_id.
    CHECK sy-subrc = 0.

    IF ls_disp-vbeln IS INITIAL.
      MESSAGE s000 WITH TEXT-e20 DISPLAY LIKE gc_e.
      RETURN.
    ENDIF.

    " 후속 PO가 이미 생성된 경우 SO 삭제 불가
    IF ls_disp-ebeln IS NOT INITIAL.
      lv_message = replace( val = TEXT-e21 sub = '&1' with = ls_disp-vbeln ).
      MESSAGE lv_message TYPE gc_s DISPLAY LIKE gc_e.
      RETURN.
    ENDIF.

    INSERT VALUE #( vbeln = ls_disp-vbeln ) INTO TABLE lt_vbeln.
  ENDLOOP.

  LOOP AT lt_vbeln INTO DATA(ls_vbeln).
    CLEAR: lv_error, lv_message.

    PERFORM delete_so_group
      USING    ls_vbeln-vbeln
      CHANGING lv_error
               lv_message.

    IF lv_error = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      lv_failed = lv_failed + 1.
      PERFORM update_delete_so_result USING ls_vbeln-vbeln abap_true lv_message.
      CONTINUE.
    ENDIF.

    PERFORM commit_standard CHANGING lv_error lv_message.
    IF lv_error = abap_true.
      lv_failed = lv_failed + 1.
      PERFORM update_delete_so_result USING ls_vbeln-vbeln abap_true lv_message.
      CONTINUE.
    ENDIF.

    lv_success = lv_success + 1.
    PERFORM update_delete_so_result USING ls_vbeln-vbeln abap_false lv_message.
  ENDLOOP.

  PERFORM set_display_status.
  PERFORM set_edit_style.
  PERFORM refresh_grid USING go_grid.
  PERFORM show_process_result USING lv_success lv_failed.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form DELETE_SO_GROUP
*&---------------------------------------------------------------------*
*& 단일 Sales Order에 대해 헤더 삭제 플래그('D')로 BAPI_SALESORDER_CHANGE를 호출한다.
*&---------------------------------------------------------------------*
FORM delete_so_group
  USING    pv_vbeln   TYPE vbak-vbeln
  CHANGING pv_error   TYPE abap_bool
           pv_message TYPE string.

  DATA:
    ls_headerx TYPE bapisdh1x,
    lt_return  TYPE TABLE OF bapiret2.

  CLEAR: pv_error, pv_message.
  ls_headerx-updateflag = gc_d.

  CALL FUNCTION 'BAPI_SALESORDER_CHANGE'
    EXPORTING
      salesdocument    = pv_vbeln
      order_header_inx = ls_headerx
    TABLES
      return           = lt_return.

  LOOP AT lt_return INTO DATA(ls_return) WHERE type CA 'AEX'.
    pv_error   = abap_true.
    pv_message = ls_return-message.
    EXIT.
  ENDLOOP.

  IF pv_error = abap_false.
    LOOP AT lt_return INTO ls_return WHERE type = gc_s.
      pv_message = ls_return-message.
      EXIT.
    ENDLOOP.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form UPDATE_DELETE_SO_RESULT
*&---------------------------------------------------------------------*
*& SO 삭제 성공 시 ALV 행은 유지하면서 VBELN만 초기화하여 재처리 가능 상태로 만든다.
*&---------------------------------------------------------------------*
FORM update_delete_so_result
  USING pv_vbeln   TYPE vbak-vbeln
        pv_error   TYPE abap_bool
        pv_message TYPE string.

  LOOP AT gt_disp ASSIGNING FIELD-SYMBOL(<ls_disp>) WHERE vbeln = pv_vbeln.
    IF pv_error = abap_true.
      <ls_disp>-msgty   = gc_e.
      <ls_disp>-message = pv_message.
      CONTINUE.
    ENDIF.

    CLEAR <ls_disp>-vbeln.
    <ls_disp>-msgty   = gc_s.
    <ls_disp>-message = pv_message.
    <ls_disp>-new     = abap_true.
    <ls_disp>-changed = abap_false.
  ENDLOOP.

ENDFORM.

*---------------------------------------------------------------------*
* PURCHASE ORDER CREATION (기존 ZSDR0140 로직 재사용 + ZZVBELN/ZZVBELP 매핑)
*---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form GET_SELECTED_PO_DATA
*&---------------------------------------------------------------------*
*& 선택된 행의 Sales Order(VBELN) 전체 품목을 수집하여 구매오더(PO) 생성 대상을 구성한다.
*&---------------------------------------------------------------------*
FORM get_selected_po_data
  CHANGING pt_po    TYPE gty_t_po_work
           pv_error TYPE abap_bool.

  TYPES:
    BEGIN OF lty_vbeln,
      vbeln TYPE vbak-vbeln,
    END OF lty_vbeln.

  DATA:
    lt_rows  TYPE lvc_t_roid,
    lt_vbeln TYPE SORTED TABLE OF lty_vbeln WITH UNIQUE KEY vbeln.

  CLEAR: pt_po, pv_error.

  go_grid->get_selected_rows( IMPORTING et_row_no = lt_rows ).
  DELETE lt_rows WHERE row_id <= 0.

  IF lt_rows IS INITIAL.
    pv_error = abap_true.
    MESSAGE s006 DISPLAY LIKE gc_e.
    RETURN.
  ENDIF.

  LOOP AT lt_rows INTO DATA(ls_row).
    READ TABLE gt_disp INTO DATA(ls_disp) INDEX ls_row-row_id.
    CHECK sy-subrc = 0.

    " Sales Order가 먼저 생성되어 있어야 PO 생성 가능
    IF ls_disp-vbeln IS INITIAL.
      pv_error = abap_true.
      MESSAGE s000 WITH TEXT-e22 DISPLAY LIKE gc_e.
      RETURN.
    ENDIF.

    INSERT VALUE #( vbeln = ls_disp-vbeln ) INTO TABLE lt_vbeln.
  ENDLOOP.

  LOOP AT lt_vbeln INTO DATA(ls_vbeln).
    LOOP AT gt_disp INTO ls_disp WHERE vbeln = ls_vbeln-vbeln.
      DATA(lv_tabix) = sy-tabix.
      IF ls_disp-ebeln IS NOT INITIAL.
        pv_error = abap_true.
        MESSAGE s000 WITH replace( val = TEXT-e23 sub = '&1' with = ls_vbeln-vbeln ) DISPLAY LIKE gc_e.
        RETURN.
      ENDIF.
      APPEND VALUE #( row_id = lv_tabix data = ls_disp ) TO pt_po.
    ENDLOOP.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CHECK_DUPLICATE_PO
*&---------------------------------------------------------------------*
*& EKPO 테이블에서 ZZVBELN / ZZVBELP 기준으로 이미 생성된 PO가 있는지 중복 체크한다 (요구사항 4).
*&---------------------------------------------------------------------*
FORM check_duplicate_po
  USING    pt_group TYPE gty_t_po_work
  CHANGING pv_error TYPE abap_bool
           pv_text  TYPE string.

  CLEAR: pv_error, pv_text.

  LOOP AT pt_group INTO DATA(ls_group).
    SELECT SINGLE ebeln, ebelp
      FROM ekpo
     WHERE zzvbeln = @ls_group-data-vbeln
       AND zzvbelp = @ls_group-data-posnr
       AND loekz   = @space
      INTO @DATA(ls_po).

    IF sy-subrc = 0.
      pv_error = abap_true.
      pv_text  = replace( val = replace( val = TEXT-e24 sub = '&1' with = ls_po-ebeln )
                          sub = '&2' with = ls_group-data-vbeln ).
      RETURN.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form GET_PO_MASTER
*&---------------------------------------------------------------------*
*& 구매정보레코드(EINA/EINE) 및 조건테이블(A018/KONP, PB00)에서
*& 공급업체(LIFNR), 통화(WAERS), 세금코드(MWSKZ), 구매단가를 조회한다 (기존 0140 로직 재사용).
*&---------------------------------------------------------------------*
FORM get_po_master
  USING    ps_row      TYPE gty_disp
  CHANGING pv_vendor   TYPE lifnr
           pv_currency TYPE waers
           pv_tax_code TYPE mwskz
           pv_price    TYPE bapicurext
           pv_error    TYPE abap_bool
           pv_text     TYPE string.

  DATA:
    lv_infnr      TYPE infnr,
    lv_knumh      TYPE knumh,
    lv_kbetr      TYPE konp-kbetr,
    lv_kpein      TYPE konp-kpein,
    lv_konwa      TYPE konp-konwa,
    lv_kbetr_calc TYPE decfloat34,
    lv_kpein_calc TYPE decfloat34.

  CLEAR: pv_vendor, pv_currency, pv_tax_code, pv_price, pv_error, pv_text.

  SELECT SINGLE b~lifnr, a~waers, a~mwskz, a~infnr
    FROM eine AS a
    INNER JOIN eina AS b ON b~infnr = a~infnr
   WHERE a~ekorg = @gc_po_ekorg
     AND a~esokz = @gc_po_esokz
     AND a~loekz = @space
     AND b~matnr = @ps_row-matnr
     AND b~loekz = @space
    INTO ( @pv_vendor, @pv_currency, @pv_tax_code, @lv_infnr ).

  IF sy-subrc <> 0.
    pv_error = abap_true.
    pv_text  = replace( val = TEXT-e25 sub = '&1' with = ps_row-matnr ).
    RETURN.
  ENDIF.

  SELECT knumh
    FROM a018
   WHERE kappl = 'M'
     AND kschl = @gc_po_kschl
     AND lifnr = @pv_vendor
     AND matnr = @ps_row-matnr
     AND ekorg = @gc_po_ekorg
     AND esokz = @gc_po_esokz
     AND datab <= @sy-datum
     AND datbi >= @sy-datum
   ORDER BY datab DESCENDING
    INTO @lv_knumh
    UP TO 1 ROWS.
  ENDSELECT.

  IF lv_knumh IS INITIAL.
    pv_error = abap_true.
    pv_text  = replace( val = TEXT-e26 sub = '&1' with = ps_row-matnr ).
    RETURN.
  ENDIF.

  SELECT SINGLE kbetr, konwa, kpein
    FROM konp
   WHERE knumh = @lv_knumh
     AND kappl = 'M'
     AND kschl = @gc_po_kschl
    INTO ( @lv_kbetr, @lv_konwa, @lv_kpein ).

  IF sy-subrc <> 0 OR lv_kpein <= 0.
    pv_error = abap_true.
    pv_text  = replace( val = TEXT-e26 sub = '&1' with = ps_row-matnr ).
    RETURN.
  ENDIF.

  IF lv_konwa IS NOT INITIAL.
    pv_currency = lv_konwa.
  ENDIF.

  TRY.
      lv_kbetr_calc = lv_kbetr.
      lv_kpein_calc = lv_kpein.
      pv_price      = EXACT #( lv_kbetr_calc / lv_kpein_calc ).
    CATCH cx_sy_arithmetic_error cx_sy_conversion_error.
      pv_error = abap_true.
      pv_text  = replace( val = TEXT-e26 sub = '&1' with = ps_row-matnr ).
  ENDTRY.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SET_PO_EXTENSION
*&---------------------------------------------------------------------*
*& 요구사항 4 반영:
*& BAPI_PO_CREATE1의 EXTENSIONIN(BAPI_TE_MEPOITEM)을 통해
*& EKPO-ZZVBELN(판매오더 번호)과 EKPO-ZZVBELP(판매오더 품목번호)를 매핑한다.
*&---------------------------------------------------------------------*
FORM set_po_extension
  USING    pv_ebelp TYPE ebelp
           pv_vbeln TYPE vbak-vbeln
           pv_posnr TYPE vbap-posnr
  CHANGING pt_ext   TYPE gty_t_bapiparex
           pv_error TYPE abap_bool
           pv_text  TYPE string.

  DATA:
    ls_ext      TYPE bapiparex,
    ls_te_item  TYPE bapi_te_mepoitem,
    ls_te_itemx TYPE bapi_te_mepoitemx.

  FIELD-SYMBOLS:
    <lv_vbeln>  TYPE any,
    <lv_posnr>  TYPE any,
    <lv_vbelnx> TYPE any,
    <lv_posnrx> TYPE any.

  CLEAR: pv_error, pv_text.

  ls_te_item-po_item  = pv_ebelp.
  ls_te_itemx-po_item = pv_ebelp.

  ASSIGN COMPONENT 'ZZVBELN' OF STRUCTURE ls_te_item  TO <lv_vbeln>.
  ASSIGN COMPONENT 'ZZVBELN' OF STRUCTURE ls_te_itemx TO <lv_vbelnx>.
  ASSIGN COMPONENT 'ZZVBELP' OF STRUCTURE ls_te_item  TO <lv_posnr>.
  ASSIGN COMPONENT 'ZZVBELP' OF STRUCTURE ls_te_itemx TO <lv_posnrx>.

  IF <lv_vbeln> IS NOT ASSIGNED OR <lv_posnr> IS NOT ASSIGNED
     OR <lv_vbelnx> IS NOT ASSIGNED OR <lv_posnrx> IS NOT ASSIGNED.
    pv_error = abap_true.
    pv_text  = TEXT-e27.
    RETURN.
  ENDIF.

  <lv_vbeln>  = pv_vbeln.
  <lv_posnr>  = pv_posnr.
  <lv_vbelnx> = gc_x.
  <lv_posnrx> = gc_x.

  CLEAR ls_ext.
  ls_ext-structure = 'BAPI_TE_MEPOITEM'.
  MOVE ls_te_item TO ls_ext-valuepart1.
  APPEND ls_ext TO pt_ext.

  CLEAR ls_ext.
  ls_ext-structure = 'BAPI_TE_MEPOITEMX'.
  MOVE ls_te_itemx TO ls_ext-valuepart1.
  APPEND ls_ext TO pt_ext.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CREATE_PURCHASE_ORDER
*&---------------------------------------------------------------------*
*& 생성된 Sales Order 단위로 그룹핑하여 구매오더(PO)를 생성한다 (기존 0140 로직 재사용).
*&---------------------------------------------------------------------*
FORM create_purchase_order.

  DATA:
    lt_po      TYPE gty_t_po_work,
    lt_group   TYPE gty_t_po_work,
    lv_error   TYPE abap_bool,
    lv_ebeln   TYPE ekko-ebeln,
    lv_message TYPE string.

  PERFORM get_selected_po_data CHANGING lt_po lv_error.
  CHECK lv_error = abap_false.

  LOOP AT lt_po INTO DATA(ls_po)
    GROUP BY ( vbeln = ls_po-data-vbeln )
    ASSIGNING FIELD-SYMBOL(<ls_po_group_key>).

    CLEAR: lt_group, lv_error, lv_ebeln, lv_message.

    LOOP AT GROUP <ls_po_group_key> INTO DATA(ls_group_row).
      APPEND ls_group_row TO lt_group.
    ENDLOOP.

    PERFORM check_duplicate_po
      USING    lt_group
      CHANGING lv_error
               lv_message.

    IF lv_error = abap_true.
      PERFORM update_purchase_order_result USING lt_group space abap_true lv_message.
      CONTINUE.
    ENDIF.

    PERFORM create_purchase_order_group
      CHANGING lt_group
               lv_ebeln
               lv_error
               lv_message.

    IF lv_error = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      PERFORM update_purchase_order_result USING lt_group space abap_true lv_message.
      CONTINUE.
    ENDIF.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = gc_x.
    PERFORM update_purchase_order_result USING lt_group lv_ebeln abap_false lv_message.

  ENDLOOP.

  PERFORM set_display_status.
  PERFORM set_edit_style.
  PERFORM refresh_grid USING go_grid.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form CREATE_PURCHASE_ORDER_GROUP
*&---------------------------------------------------------------------*
*& BAPI_PO_CREATE1을 호출하여 하나의 Sales Order에 대응하는 Purchase Order를 생성한다.
*&---------------------------------------------------------------------*
FORM create_purchase_order_group
  CHANGING pt_group   TYPE gty_t_po_work
           pv_ebeln   TYPE ekko-ebeln
           pv_error   TYPE abap_bool
           pv_message TYPE string.

  DATA:
    ls_header     TYPE bapimepoheader,
    ls_headerx    TYPE bapimepoheaderx,
    lt_item       TYPE TABLE OF bapimepoitem,
    lt_itemx      TYPE TABLE OF bapimepoitemx,
    lt_schedule   TYPE TABLE OF bapimeposchedule,
    lt_schedulex  TYPE TABLE OF bapimeposchedulx,
    lt_ext        TYPE gty_t_bapiparex,
    lt_return     TYPE TABLE OF bapiret2,
    lv_po_item    TYPE i,
    lv_ebelp      TYPE ebelp,
    lv_vendor     TYPE lifnr,
    lv_currency   TYPE waers,
    lv_tax_code   TYPE mwskz,
    lv_price      TYPE bapicurext,
    lv_vendor_h   TYPE lifnr,
    lv_currency_h TYPE waers,
    lv_text       TYPE string.

  CLEAR: pv_ebeln, pv_error, pv_message.
  CHECK pt_group IS NOT INITIAL.

  LOOP AT pt_group ASSIGNING FIELD-SYMBOL(<ls_group>).
    PERFORM get_po_master
      USING    <ls_group>-data
      CHANGING lv_vendor
               lv_currency
               lv_tax_code
               lv_price
               pv_error
               lv_text.

    IF pv_error = abap_true.
      pv_message = lv_text.
      RETURN.
    ENDIF.

    IF lv_vendor_h IS INITIAL.
      lv_vendor_h   = lv_vendor.
      lv_currency_h = lv_currency.
    ENDIF.

    lv_po_item = lv_po_item + 10.
    lv_ebelp   = lv_po_item.
    <ls_group>-data-ebelp = lv_ebelp.

    APPEND VALUE #(
      po_item   = lv_ebelp
      material  = <ls_group>-data-matnr
      plant     = <ls_group>-data-werks
      quantity  = <ls_group>-data-kwmeng
      po_unit   = <ls_group>-data-meins
      net_price = lv_price
      stge_loc  = gc_po_lgort
      tax_code  = lv_tax_code
    ) TO lt_item.

    APPEND VALUE #(
      po_item   = lv_ebelp
      po_itemx  = gc_x
      material  = gc_x
      plant     = gc_x
      quantity  = gc_x
      po_unit   = gc_x
      net_price = gc_x
      stge_loc  = gc_x
      tax_code  = gc_x
    ) TO lt_itemx.

    APPEND VALUE #(
      po_item       = lv_ebelp
      sched_line    = '0001'
      delivery_date = <ls_group>-data-close_dat
      quantity      = <ls_group>-data-kwmeng
    ) TO lt_schedule.

    APPEND VALUE #(
      po_item       = lv_ebelp
      sched_line    = '0001'
      po_itemx      = gc_x
      sched_linex   = gc_x
      delivery_date = gc_x
      quantity      = gc_x
    ) TO lt_schedulex.

    PERFORM set_po_extension
      USING    lv_ebelp
               <ls_group>-data-vbeln
               <ls_group>-data-posnr
      CHANGING lt_ext
               pv_error
               lv_text.

    IF pv_error = abap_true.
      pv_message = lv_text.
      RETURN.
    ENDIF.
  ENDLOOP.

  ls_header-comp_code = gc_po_bukrs.
  ls_header-doc_type  = gc_po_bsart.
  ls_header-vendor    = lv_vendor_h.
  ls_header-purch_org = gc_po_ekorg.
  ls_header-pur_group = gc_po_ekgrp.
  ls_header-doc_date  = sy-datum.
  ls_header-currency  = lv_currency_h.

  ls_headerx-comp_code = gc_x.
  ls_headerx-doc_type  = gc_x.
  ls_headerx-vendor    = gc_x.
  ls_headerx-purch_org = gc_x.
  ls_headerx-pur_group = gc_x.
  ls_headerx-doc_date  = gc_x.
  ls_headerx-currency  = gc_x.

  CALL FUNCTION 'BAPI_PO_CREATE1'
    EXPORTING
      poheader         = ls_header
      poheaderx        = ls_headerx
    IMPORTING
      exppurchaseorder = pv_ebeln
    TABLES
      return           = lt_return
      poitem           = lt_item
      poitemx          = lt_itemx
      poschedule       = lt_schedule
      poschedulex      = lt_schedulex
      extensionin      = lt_ext.

  LOOP AT lt_return INTO DATA(ls_return) WHERE type CA 'AEX'.
    pv_error   = abap_true.
    pv_message = ls_return-message.
    EXIT.
  ENDLOOP.

  IF pv_ebeln IS INITIAL OR pv_error = abap_true.
    pv_error = abap_true.
    IF pv_message IS INITIAL.
      pv_message = TEXT-e28.
    ENDIF.
    RETURN.
  ENDIF.

  pv_message = replace( val = TEXT-s02 sub = '&1' with = pv_ebeln ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form UPDATE_PURCHASE_ORDER_RESULT
*&---------------------------------------------------------------------*
*& 구매오더(PO) 생성 결과를 GT_DISP 행의 EBELN / EBELP 필드에 반영한다.
*&---------------------------------------------------------------------*
FORM update_purchase_order_result
  USING pt_group   TYPE gty_t_po_work
        pv_ebeln   TYPE ekko-ebeln
        pv_error   TYPE abap_bool
        pv_message TYPE string.

  LOOP AT pt_group INTO DATA(ls_group).
    READ TABLE gt_disp ASSIGNING FIELD-SYMBOL(<ls_disp>) INDEX ls_group-row_id.
    CHECK sy-subrc = 0.

    IF pv_error = abap_true.
      <ls_disp>-msgty   = gc_e.
      <ls_disp>-message = pv_message.
    ELSE.
      <ls_disp>-ebeln   = pv_ebeln.
      <ls_disp>-ebelp   = ls_group-data-ebelp.
      <ls_disp>-msgty   = gc_s.
      <ls_disp>-message = pv_message.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form COMMIT_STANDARD
*&---------------------------------------------------------------------*
*& BAPI_TRANSACTION_COMMIT(WAIT = 'X')을 수행하고 COMMIT 오류 발생 여부를 확인한다.
*&---------------------------------------------------------------------*
FORM commit_standard
  CHANGING pv_error   TYPE abap_bool
           pv_message TYPE string.

  DATA ls_return TYPE bapiret2.

  CLEAR pv_error.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait   = abap_true
    IMPORTING
      return = ls_return.

  IF ls_return-type CA 'AEX' AND ls_return-type IS NOT INITIAL.
    pv_error   = abap_true.
    pv_message = ls_return-message.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form SHOW_PROCESS_RESULT
*&---------------------------------------------------------------------*
*& 일괄 처리 결과(성공 건수 / 실패 건수)를 하단 상태바 메시지로 출력한다.
*&---------------------------------------------------------------------*
FORM show_process_result
  USING pv_success TYPE i
        pv_failed  TYPE i.

  DATA lv_result TYPE string.

  lv_result = TEXT-m06.
  REPLACE '&1' IN lv_result WITH |{ pv_success }|.
  REPLACE '&2' IN lv_result WITH |{ pv_failed }|.

  MESSAGE lv_result TYPE gc_s.

ENDFORM.