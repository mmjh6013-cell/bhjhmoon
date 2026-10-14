*&---------------------------------------------------------------------*
*& Include          ZSDR0160_CLS
*&---------------------------------------------------------------------*

CLASS lcl_event DEFINITION FINAL.

  PUBLIC SECTION.

    CLASS-METHODS:
      handle_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING
          e_object
          sender,

      handle_user_command
        FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING
          e_ucomm
          sender,

      handle_data_changed
        FOR EVENT data_changed OF cl_gui_alv_grid
        IMPORTING
          er_data_changed
          e_onf4
          e_onf4_after
          e_onf4_before
          sender,

      handle_double_click
        FOR EVENT double_click OF cl_gui_alv_grid
        IMPORTING
          e_row
          e_column
          es_row_no
          sender,

      handle_data_changed_finished
        FOR EVENT data_changed_finished OF cl_gui_alv_grid
        IMPORTING
          sender
          e_modified
          et_good_cells.

ENDCLASS.

CLASS lcl_event IMPLEMENTATION.

  METHOD handle_toolbar.
    PERFORM handle_toolbar
      USING e_object
            sender.
  ENDMETHOD.

  METHOD handle_user_command.
    PERFORM handle_user_command
      USING e_ucomm
            sender.
  ENDMETHOD.

  METHOD handle_data_changed.
    PERFORM handle_data_changed
      USING er_data_changed
            e_onf4
            e_onf4_after
            e_onf4_before
            sender.
  ENDMETHOD.

  METHOD handle_double_click.
    PERFORM handle_double_click
      USING e_row
            e_column
            es_row_no
            sender.
  ENDMETHOD.

  METHOD handle_data_changed_finished.
    PERFORM handle_data_changed_fin
      USING e_modified
            et_good_cells
            sender.
  ENDMETHOD.

ENDCLASS.