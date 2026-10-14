*&---------------------------------------------------------------------*
*& Include          ZSDR0160_O01
*&---------------------------------------------------------------------*

MODULE status_0100 OUTPUT.

  DATA lv_title TYPE sy-title.
  lv_title = sy-title.

  SET PF-STATUS '0100' EXCLUDING gt_fcode.
  SET TITLEBAR  '0100' WITH lv_title.

ENDMODULE.

MODULE set_alv_grid OUTPUT.

  IF go_grid IS NOT BOUND.
    PERFORM set_alv_grid.
  ELSEIF gv_refresh = abap_true.
    CLEAR gv_refresh.
    PERFORM refresh_grid USING go_grid.
  ENDIF.

ENDMODULE.