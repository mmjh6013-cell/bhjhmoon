*&---------------------------------------------------------------------*
*& Include          ZSDR0160_TOP
*&---------------------------------------------------------------------*

TYPE-POOLS:
  icon.

TABLES:
  sscrfields,
  vbak,
  vbap,
  vbkd,
  knvv.

*---------------------------------------------------------------------*
* CONSTANTS - COMMON
*---------------------------------------------------------------------*
CONSTANTS:
  gc_a            TYPE c VALUE 'A',
  gc_b            TYPE c VALUE 'B',
  gc_c            TYPE c VALUE 'C',
  gc_d            TYPE c VALUE 'D',
  gc_e            TYPE c VALUE 'E',
  gc_i            TYPE c VALUE 'I',
  gc_s            TYPE c VALUE 'S',
  gc_u            TYPE c VALUE 'U',
  gc_w            TYPE c VALUE 'W',
  gc_x            TYPE c VALUE 'X',

  gc_0            TYPE c VALUE '0',
  gc_1            TYPE c VALUE '1',
  gc_2            TYPE c VALUE '2',

  gc_eq           TYPE c LENGTH 2 VALUE 'EQ',
  gc_style        TYPE lvc_fname  VALUE 'STYLE',

  gc_zor          TYPE vbak-auart VALUE 'ZOR',
  gc_zkb          TYPE vbak-auart VALUE 'ZKB',

  gc_kappl        TYPE kappl      VALUE 'V',
  gc_zsr1         TYPE kschl      VALUE 'ZSR1',
  gc_usd          TYPE waers      VALUE 'USD',

  gc_ag           TYPE parvw      VALUE 'AG',
  gc_we           TYPE parvw      VALUE 'WE',
  gc_re           TYPE parvw      VALUE 'RE',
  gc_rg           TYPE parvw      VALUE 'RG',

  gc_vtweg_40     TYPE vtweg      VALUE '40',
  gc_spart_00     TYPE spart      VALUE '00',
  gc_kdgrp_08     TYPE kdgrp      VALUE '08',

  gc_aff_eac      TYPE char3      VALUE 'EAC',
  gc_aff_ejp      TYPE char3      VALUE 'EJP',

  gc_row_ready    TYPE c          VALUE 'R',
  gc_row_so       TYPE c          VALUE 'S',
  gc_row_po       TYPE c          VALUE 'P',
  gc_row_error    TYPE c          VALUE 'E',
  gc_msgid        TYPE symsgid    VALUE 'ZSDM',
  gc_drdn_auart   TYPE int4       VALUE 1.

*---------------------------------------------------------------------*
* CONSTANTS - PURCHASE ORDER
*---------------------------------------------------------------------*
CONSTANTS:
  gc_po_bukrs     TYPE bukrs      VALUE '1000',
  gc_po_bsart     TYPE bsart      VALUE 'NB',
  gc_po_ekorg     TYPE ekorg      VALUE '1000',
  gc_po_ekgrp     TYPE ekgrp      VALUE '180',
  gc_po_lgort     TYPE lgort_d    VALUE '4100',
  gc_po_esokz     TYPE esokz      VALUE '0',
  gc_po_kschl     TYPE kschl      VALUE 'PB00',
  gc_po_vtweg     TYPE vtweg      VALUE '40',
  gc_smw0_objid   TYPE wwwdata-objid VALUE 'ZSDR0160'.

*---------------------------------------------------------------------*
* TYPES - PDF PARSER INTERNAL STRUCTURES
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF gty_pdf_out,
    seq  TYPE i,
    page TYPE i,
    xpos TYPE i,
    ypos TYPE i,
    text TYPE string,
  END OF gty_pdf_out,

  BEGIN OF gty_pdf_frag,
    p    TYPE i,
    x    TYPE i,
    y    TYPE i,
    text TYPE string,
  END OF gty_pdf_frag,

  BEGIN OF gty_pdf_cmap,
    idx  TYPE i,
    code TYPE i,
    uni  TYPE string,
  END OF gty_pdf_cmap.

*---------------------------------------------------------------------*
* TYPES - RAW STAGING FROM PDF / EXCEL
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF gty_raw_item,
    row_no    TYPE i,
    bstdk     TYPE char30,    " PO Date
    aff_po_no TYPE char35,    " Affiliated Com. PO No (EAC-...)
    bstkd_e   TYPE char35,    " Customer PO No (Ship-to PO)
    zterm_raw TYPE char50,    " Payment Term text from PDF
    edatu_etd TYPE char30,    " ETD
    kdmat     TYPE char35,    " Customer Code (Item)
    matnr     TYPE char50,    " Material (PN)
    arktx_pdf TYPE char100,   " Description in PDF
    kwmeng    TYPE char30,    " Qty
    po_price  TYPE char30,    " PO Unit Price (Rate)
    po_amount TYPE char30,    " Amount
    waerk     TYPE char10,    " Currency
  END OF gty_raw_item.

*---------------------------------------------------------------------*
* TYPES - ALV DISPLAY (22 Business Columns + Internal Control Fields)
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF gty_disp,
*--- 22 Visible Columns matching the requirement layout
    kunnr       TYPE kunnr,         " 01. Customer (Affiliated Company)
    name1       TYPE kna1-name1,    " 02. Name (KNA1-NAME1)
    bstdk       TYPE vbkd-bstdk,    " 03. PO Date
    aff_po_no   TYPE vbkd-bstkd,    " 04. Affiliated Com. PO No
    bstkd_e     TYPE vbkd-bstkd_e,  " 05. Customer PO No
    auart       TYPE vbak-auart,    " 06. Sales Order Type (ZOR / ZKB)
    vbeln       TYPE vbak-vbeln,    " 07. Sales Order No
    posnr       TYPE vbap-posnr,    " 08. Sales Order ITEM No
    ebeln       TYPE ekpo-ebeln,    " 09. Purchase Order No
    ebelp       TYPE ekpo-ebelp,    " 10. Purchase Order Item
    zterm       TYPE knvv-zterm,    " 11. Payment Term
    etd         TYPE vbep-edatu,    " 12. ETD
    close_dat   TYPE vbep-edatu,    " 13. Closing Date (ETD - 3 Working Days)
    kdmat       TYPE vbap-kdmat,    " 14. Customer Code
    matnr       TYPE vbap-matnr,    " 15. Material
    maktx       TYPE makt-maktx,    " 16. Description (MAKT-MAKTX)
    kwmeng      TYPE vbap-kwmeng,   " 17. Qty
    meins       TYPE mara-meins,    " 18. Unit (MARA-MEINS)
    netpr       TYPE bapicurr_d,    " 19. PO Unit Price
    netwr       TYPE netwr,         " 20. Amount
    mst_price   TYPE bapicurr_d,    " 21. Master Unit Price (ZSR1 on PO Date)
    waerk       TYPE vbak-waerk,    " 22. Currency (USD)

*--- Status / Message Columns
    status      TYPE icon_d,        " Status Icon
    message     TYPE bapiret2-message,

*--- Internal Technical Fields (tech = 'X')
    row_no      TYPE i,
    vkorg       TYPE vbak-vkorg,
    vkbur       TYPE vbak-vkbur,
    vkgrp       TYPE vbak-vkgrp,
    vtweg       TYPE vbak-vtweg,
    spart       TYPE vbak-spart,
    werks       TYPE vbap-werks,
    kunag       TYPE kunnr,
    kunwe       TYPE kunnr,
    kunrg       TYPE kunnr,
    netpr_int   TYPE vbap-netpr,
    kpein       TYPE vbap-kpein,
    price_unit  TYPE vbap-kmein,
    price_dec   TYPE c LENGTH 1,
    price_scale TYPE vbap-kpein,
    knumh       TYPE konp-knumh,
    datab       TYPE datab,
    datbi       TYPE datbi,
    new_netpr   TYPE konp-kbetr,
    new_kpein   TYPE konp-kpein,
    new_waerk   TYPE konp-konwa,
    msgty       TYPE symsgty,
    new         TYPE abap_bool,
    changed     TYPE abap_bool,
    row_kind    TYPE c LENGTH 1,
    style       TYPE lvc_t_styl,
  END OF gty_disp,

  gty_t_disp TYPE STANDARD TABLE OF gty_disp WITH EMPTY KEY.

*---------------------------------------------------------------------*
* TYPES - WORK TABLES FOR BAPI PROCESSING
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF gty_so_work,
    row_id TYPE i,
    data   TYPE gty_disp,
  END OF gty_so_work,
  gty_t_so_work TYPE STANDARD TABLE OF gty_so_work WITH EMPTY KEY,

  BEGIN OF gty_po_work,
    row_id TYPE i,
    data   TYPE gty_disp,
  END OF gty_po_work,
  gty_t_po_work TYPE STANDARD TABLE OF gty_po_work WITH EMPTY KEY,

  gty_t_bapiparex TYPE STANDARD TABLE OF bapiparex WITH EMPTY KEY.

*---------------------------------------------------------------------*
* TYPES - MASTER CACHE
*---------------------------------------------------------------------*
TYPES:
  BEGIN OF gty_kna1,
    kunnr TYPE kna1-kunnr,
    name1 TYPE kna1-name1,
  END OF gty_kna1,

  BEGIN OF gty_mara,
    matnr TYPE mara-matnr,
    meins TYPE mara-meins,
  END OF gty_mara,

  BEGIN OF gty_makt,
    matnr TYPE makt-matnr,
    maktx TYPE makt-maktx,
  END OF gty_makt.

*---------------------------------------------------------------------*
* GLOBAL DATA - GENERAL & PDF PARSER
*---------------------------------------------------------------------*
DATA:
  gv_answer      TYPE c,
  gv_changed     TYPE abap_bool,
  gv_refresh     TYPE abap_bool,
  gv_okcode      TYPE sy-ucomm,
  gv_title       TYPE sy-title,
  gv_error       TYPE abap_bool,
  gv_aff_prefix  TYPE char3,        " First 3 chars of KNA1-NAME1 (EAC / EJP)
  gv_aff_name1   TYPE kna1-name1,   " Affiliated Company Name
  gv_knvv_zterm  TYPE knvv-zterm,   " Default Payment Term from KNVV
  gt_fcode       TYPE TABLE OF sy-ucomm,
  gt_required    TYPE TABLE OF screen-name.

DATA:
  gt_pdf_out     TYPE STANDARD TABLE OF gty_pdf_out,
  gt_pdf_frag    TYPE STANDARD TABLE OF gty_pdf_frag,
  gt_pdf_cmap    TYPE STANDARD TABLE OF gty_pdf_cmap,
  gv_pdf_xstr    TYPE xstring,
  gv_curtb       TYPE c LENGTH 1,
  gv_skip        TYPE i,
  gv_cr          TYPE c LENGTH 1,
  gv_lf          TYPE c LENGTH 1,
  gv_tab         TYPE c LENGTH 1,
  gv_fsz         TYPE f VALUE 12,
  gv_tfsz        TYPE f,
  gv_tfmode      TYPE c LENGTH 1.

*---------------------------------------------------------------------*
* GLOBAL DATA - STAGING / DISPLAY / MASTER CACHE
*---------------------------------------------------------------------*
DATA:
  gt_raw  TYPE STANDARD TABLE OF gty_raw_item WITH EMPTY KEY,
  gt_disp TYPE gty_t_disp,

  gt_kna1  TYPE SORTED TABLE OF gty_kna1 WITH UNIQUE KEY kunnr,
  gt_mara  TYPE SORTED TABLE OF gty_mara WITH UNIQUE KEY matnr,
  gt_makt  TYPE SORTED TABLE OF gty_makt WITH UNIQUE KEY matnr,
  gt_tcurc TYPE SORTED TABLE OF tcurc    WITH UNIQUE KEY waers.

*---------------------------------------------------------------------*
* GLOBAL DATA - ALV GRID
*---------------------------------------------------------------------*
DATA:
  go_grid TYPE REF TO cl_gui_alv_grid,
  gt_fcat TYPE lvc_t_fcat,
  gt_sort TYPE lvc_t_sort.