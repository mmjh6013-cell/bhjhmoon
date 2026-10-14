************************************************************************
* Program ID   : ZSDR0150
* Title        : [SD] Commercial Invoice Issuance
* Create Date  : 2026.09.11
* Developer    : ESTABSD
* Tech. Script :
************************************************************************
* Change History.
************************************************************************
* Mod.         | Date       | Developer | Description(Reason)
************************************************************************
* Initial      | 2026.09.11 | ESTABSD   | Initial Coding
************************************************************************
REPORT zsdr0150 MESSAGE-ID zsdm.

*----------------------------------------------------------------------*
* INCLUDE
*----------------------------------------------------------------------*
INCLUDE zsdr0150_top.
INCLUDE zsdr0150_cls.
INCLUDE zsdr0150_scn.
INCLUDE zsdr0150_f01.
INCLUDE zsdr0150_o01.
INCLUDE zsdr0150_i01.

*----------------------------------------------------------------------*
* INITIALIZATION
* - 怨듯넻 ?곹깭 / ?붾㈃ ?쇰꺼 珥덇린??*----------------------------------------------------------------------*
INITIALIZATION.

  PERFORM init.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN OUTPUT
* - 議고쉶議곌굔 Description / ?붾㈃ ?쇰꺼 ?ㅼ젙
*----------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

  PERFORM set_screen.
  PERFORM set_text.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN
* - 議고쉶議곌굔 ?쒖뼱 / Selection Screen Function Code 泥섎━
*----------------------------------------------------------------------*
AT SELECTION-SCREEN.

  PERFORM screen_control.
  PERFORM screen_ucomm.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.

*----------------------------------------------------------------------*
* CHECK INPUT
* - ?댁쟾 ?ㅽ뻾???ㅻ쪟 ?곹깭 珥덇린??* - Shipping Point / Planned GI Date / Delivery ?꾩닔媛??뺤씤
* - ?⑥씪 ?낅젰 議곌굔 / Shipping Point 議댁옱 ?щ? ?뺤씤
*----------------------------------------------------------------------*
  CLEAR gv_error.

  PERFORM check_input
    CHANGING gv_error.

  IF gv_error IS NOT INITIAL.
    RETURN.
  ENDIF.

*----------------------------------------------------------------------*
* GET LIST
* - 議고쉶議곌굔???대떦?섎뒗 Delivery / 湲곗〈 Invoice 議고쉶
* - ?곸꽭 ?붾㈃??Header / Item ?쒖떆 ?곗씠??援ъ꽦
* - 議고쉶 ?ㅽ뙣 / ????놁쓬? GET_LIST?먯꽌 硫붿떆吏 諛??ㅻ쪟 ?곹깭 ?ㅼ젙
*----------------------------------------------------------------------*
  PERFORM get_list
    CHANGING gv_error.

  IF gv_error IS NOT INITIAL.
    RETURN.
  ENDIF.

*----------------------------------------------------------------------*
* CALL MAIN SCREEN
* - 0100 : Header / ?쇱そ Invoice 紐⑸줉
* - 0110 : Item ALV Subscreen, 0100?먯꽌 Subscreen?쇰줈 ?몄텧
*----------------------------------------------------------------------*
  CALL SCREEN gc_dynnr_main.