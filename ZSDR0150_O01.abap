*&---------------------------------------------------------------------*
*& Include          ZSDR0150_O01
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* MODULE STATUS_0100 OUTPUT
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS '0100' EXCLUDING gt_fcode.
  SET TITLEBAR '0100'.
  PERFORM set_pushbutton_icons.
ENDMODULE.

*----------------------------------------------------------------------*
* MODULE HEADER_SCREEN_0100 OUTPUT
*----------------------------------------------------------------------*
MODULE header_screen_0100 OUTPUT.
* ?ㅻ뜑 ?쇰꺼/異쒕젰 踰꾪듉 臾멸뎄瑜?Text Element?먯꽌 ?ㅼ젙?⑸땲??
  PERFORM set_text.
ENDMODULE.

*----------------------------------------------------------------------*
* MODULE HEADER_UI_0100 OUTPUT
*----------------------------------------------------------------------*
MODULE header_ui_0100 OUTPUT.

* ?붾㈃ ?쇰꺼???쒖떆 ???덉뿉???ㅻⅨ履??뺣젹?섏뿬 媛??꾨뱶??遺숈엯?덈떎.
  PERFORM align_header_labels.

* ?뺤젙???ㅻ뜑 議고쉶 ?꾩슜 / ?꾩닔 ?쒖떆 ?띿꽦???곸슜?⑸땲??
  PERFORM set_header_attributes.

* Packing Type ?꾨찓??怨좎젙媛믪쓣 ?쒕∼?ㅼ슫 紐⑸줉?쇰줈 ?쒓났?⑸땲??
  PERFORM set_packing_values CHANGING gv_error.

* ?꾩옱 吏湲됱“嫄?肄붾뱶????묓븯???ㅻ챸??議고쉶?⑸땲??
  PERFORM get_payment_text.

* Shipping Remark ?몄쭛湲곕? ?앹꽦?섍퀬 臾몄꽌蹂??λЦ???쒖떆?⑸땲??
  PERFORM set_remark_editor CHANGING gv_error.

ENDMODULE.

*----------------------------------------------------------------------*
* MODULE SET_ALV_GRID OUTPUT
* - 0110 ?쒕툕?ㅽ겕由곗쓽 CC_ITEM??ALV瑜?理쒖큹 ?앹꽦?섍굅??媛깆떊?⑸땲??
*----------------------------------------------------------------------*
MODULE set_alv_grid OUTPUT.
* GT_ITEM???곌껐??ALV???앹꽦/?꾨뱶移댄깉濡쒓렇/媛깆떊??泥섎━?⑸땲??
  PERFORM set_alv_grid CHANGING gv_error.
ENDMODULE.