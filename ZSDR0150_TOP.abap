*&---------------------------------------------------------------------*
*& Include          ZSDR0150_TOP
*&---------------------------------------------------------------------*
TYPE-POOLS: icon, vrm.

TABLES: sscrfields, likp, zsdt0060.

*----------------------------------------------------------------------*
* 공통 상수: 기존 이름/값 유지
*----------------------------------------------------------------------*
CONSTANTS:
  gc_a         TYPE c VALUE 'A', gc_b TYPE c VALUE 'B',
  gc_c         TYPE c VALUE 'C', gc_e TYPE c VALUE 'E',
  gc_i         TYPE c VALUE 'I', gc_s TYPE c VALUE 'S',
  gc_w         TYPE c VALUE 'W', gc_x TYPE c VALUE 'X',
  gc_0         TYPE c VALUE '0', gc_1 TYPE c VALUE '1', gc_2 TYPE c VALUE '2',
  gc_eq(2)     TYPE c VALUE 'EQ',
  gc_style     TYPE lvc_fname VALUE 'STYLE',
  gc_zcr       TYPE vbak-auart VALUE 'ZCR',
  gc_zdr       TYPE vbak-auart VALUE 'ZDR',
  gc_zke       TYPE vbak-auart VALUE 'ZKE',
  gc_zkr       TYPE vbak-auart VALUE 'ZKR',
  gc_zsr3      TYPE kschl VALUE 'ZSR3',
  gc_ag(2)     TYPE c VALUE 'AG', gc_we(2) TYPE c VALUE 'WE',
  gc_rg(2)     TYPE c VALUE 'RG',
  gc_spart_00  TYPE spart VALUE '00',
  gc_row_ready TYPE c VALUE 'R', gc_row_so TYPE c VALUE 'S',
  gc_row_po    TYPE c VALUE 'P', gc_row_error TYPE c VALUE 'E'.

*----------------------------------------------------------------------*
* 0100 헤더 / 0110 아이템 ALV 서브스크린
*----------------------------------------------------------------------*
CONSTANTS:
  gc_dynnr_main  TYPE sy-dynnr VALUE '0100',
  gc_dynnr_item  TYPE sy-dynnr VALUE '0110',
  gc_cont_item   TYPE scrfname VALUE 'CC_ITEM',
  gc_back        TYPE sy-ucomm VALUE 'BACK',
  gc_exit        TYPE sy-ucomm VALUE 'EXIT',
  gc_canc        TYPE sy-ucomm VALUE 'CANC',
  gc_copy        TYPE sy-ucomm VALUE 'COPY',
  gc_save        TYPE sy-ucomm VALUE 'SAVE',
  gc_list        TYPE sy-ucomm VALUE 'LIST',
  gc_pr_cip      TYPE sy-ucomm VALUE 'PR_CIP',
  gc_pr_ci       TYPE sy-ucomm VALUE 'PR_CI',
  gc_pr_pl       TYPE sy-ucomm VALUE 'PR_PL',
* 기존 전체선택/해제 상수명과 Function Code를 ALV 툴바에도 유지합니다.
  gc_tc_sall     TYPE sy-ucomm VALUE 'SALL2',
  gc_tc_dall     TYPE sy-ucomm VALUE 'DALL2',
  gc_layout_save TYPE c VALUE 'U',
  gc_layout_item TYPE disvariant-handle VALUE 'ITEM'.

*----------------------------------------------------------------------*
* 헤더 라벨: 기존 GS_TEXT-H01 ~ H35 유지
*----------------------------------------------------------------------*
TYPES:
  BEGIN OF gty_text,
    h01 TYPE char40,  "Customer
    h02 TYPE char40,  "Ship to Location
    h03 TYPE char40,  "Consignee Location
    h04 TYPE char40,  "Bill to Location
    h05 TYPE char40,  "Notify Party 1
    h06 TYPE char40,  "Notify Party 2
    h07 TYPE char40,  "Import Invoice No.
    h08 TYPE char40,  "Remarks 1
    h09 TYPE char40,  "Remarks 2
    h10 TYPE char40,  "Delivery Type
    h11 TYPE char40,  "Delivery No.
    h12 TYPE char40,  "Total Amount
    h13 TYPE char40,  "Packing Type
    h14 TYPE char40,  "Print Form Option
    h15 TYPE char40,  "Invoice No.
    h16 TYPE char40,  "Date of Invoice
    h17 TYPE char40,  "Payment Term
    h18 TYPE char40,  "House Waybill
    h19 TYPE char40,  "Master Waybill
    h20 TYPE char40,  "Forwarder
    h21 TYPE char40,  "Port of Loading
    h22 TYPE char40,  "Discharging Port
    h23 TYPE char40,  "Destination
    h24 TYPE char40,  "Voyage No.
    h25 TYPE char40,  "Freight Terms
    h26 TYPE char40,  "Incoterms
    h27 TYPE char40,  "On Board Date
    h28 TYPE char40,  "ETA Date
    h29 TYPE char40,  "Shipping Method
    h30 TYPE char40,  "Package
    h31 TYPE char40,  "(Package)
    h32 TYPE char40,  "Measurement
    h33 TYPE char40,  "Net Weight
    h34 TYPE char40,  "Gross Weight
    h35 TYPE char40,  "Shipping Remark
  END OF gty_text.

* 아이템 구조 및 GT_ITEM / GS_ITEM 이름을 그대로 사용합니다.
TYPES:
  BEGIN OF gty_item,
    check    TYPE abap_bool,
    zpkgno   TYPE zsdt0061-zpkgno, "Item No
    matnr    TYPE matnr, "Material
    maktx    TYPE makt-maktx, "Material Name
    wadat    TYPE likp-wadat, "Closing Date
    bstkd_e  TYPE vbkd-bstkd_e, "Customer PO
    zivi01   TYPE zsdt0061-zivi01, "Qty
    meins    TYPE meins, "Unit
    zivi04   TYPE zsdt0061-zivi04, "Net Weight
    zivi05   TYPE zsdt0061-zivi05, "Gross Weight
    gewei    TYPE mara-gewei, "Unit
    zivi06   TYPE zsdt0061-zivi06, "Measurement
    voleh    TYPE mara-voleh, "Unit
    zivi02   TYPE zsdt0061-zivi02, "U/T Qty
    zivi03   TYPE zsdt0061-zivi03, "C/T Qty
    netpr    TYPE zsdt0061-netpr, "Unit Price
    netwr    TYPE zsdt0061-netwr, "Amount
    waerk    TYPE waerk, "Curr.
    vbeln_so TYPE vbak-vbeln, "Sales Order
    posnr_so TYPE vbap-posnr, "Item No
  END OF gty_item.

DATA:
  gs_item TYPE gty_item,
  gt_item TYPE STANDARD TABLE OF gty_item WITH EMPTY KEY.


*----------------------------------------------------------------------*
* 공통 상태 / 헤더 화면 데이터
*----------------------------------------------------------------------*
DATA:
  gv_answer    TYPE c,
  gv_changed   TYPE abap_bool,
  gv_refresh   TYPE abap_bool,
  gv_okcode    TYPE sy-ucomm,
  gv_save_ok   TYPE sy-ucomm,
  gv_title     TYPE sy-title,
  gv_error     TYPE abap_bool,
  gt_fcode     TYPE TABLE OF sy-ucomm,
  gt_required  TYPE TABLE OF screen-name,
  gs_head      TYPE zsds0060_h,
  gs_head_old  TYPE zsds0060_h,
  gs_text      TYPE gty_text,
  gv_gewei     TYPE mara-gewei,
  gv_voleh     TYPE mara-voleh,
  gv_pr_cip    TYPE char40,
  gv_pr_ci     TYPE char40,
  gv_pr_pl     TYPE char40,
  gv_ref_invno TYPE zsdt0060-zinvno,
  gv_list_hide TYPE abap_bool.

* 왼쪽 Invoice 목록 전용 객체: 기존 이름 유지, 이번 범위에서 생성하지 않음
DATA:
  go_dock       TYPE REF TO cl_gui_docking_container,
  go_inv_grid   TYPE REF TO cl_gui_alv_grid,
  gt_inv_fcat   TYPE lvc_t_fcat,
  gt_inv_sort   TYPE lvc_t_sort,
  gs_inv_layout TYPE lvc_s_layo.

* 오른쪽 아이템 ALV: 기존에 사용하던 GO_CONT / GO_GRID 이름 복원
DATA:
  go_cont    TYPE REF TO cl_gui_custom_container,
  go_grid    TYPE REF TO cl_gui_alv_grid,
  gt_fcat    TYPE lvc_t_fcat,
  gt_sort    TYPE lvc_t_sort,
  gs_layout  TYPE lvc_s_layo,
  gs_stable  TYPE lvc_s_stbl,
  gs_variant TYPE disvariant,
  gt_exclude TYPE ui_functions.

CONSTANTS:
  gc_cont_remark  TYPE scrfname     VALUE 'CC_REMARK',
  gc_text_object  TYPE thead-tdobject VALUE 'ZSDINV',
  gc_text_id      TYPE thead-tdid   VALUE '001',
  gc_pack_domain  TYPE dd07l-domname VALUE 'ZDSDPACKTYP',
  gc_pack_field   TYPE vrm_id      VALUE 'GS_HEAD-ZIVH28',
  gc_upl_cip      TYPE sy-ucomm    VALUE 'UPL_CIP',
  gc_upl_pl       TYPE sy-ucomm    VALUE 'UPL_PL',
  gc_remark_width TYPE i           VALUE 132.

TYPES:
  gty_t_remark TYPE STANDARD TABLE OF tline-tdline
              WITH DEFAULT KEY.

DATA:
  go_remark_cont   TYPE REF TO cl_gui_custom_container,
  go_remark_edit   TYPE REF TO cl_gui_textedit,
  gt_remark        TYPE gty_t_remark,
  gt_remark_old    TYPE gty_t_remark,
  gv_remark_loaded TYPE abap_bool,
  gv_remark_push   TYPE abap_bool,
  gv_remark_invno  TYPE zsdt0060-zinvno,
  gv_text_langu    TYPE thead-tdspras,
  gv_zterm_text    TYPE c LENGTH 50,
  gt_pack_values   TYPE vrm_values,
  gv_pack_loaded   TYPE abap_bool.