*&---------------------------------------------------------------------*
*& Report ZSDR0160
*&---------------------------------------------------------------------*
REPORT zsdr0160 MESSAGE-ID zsdm.

INCLUDE zsdr0160_top.
INCLUDE zsdr0160_cls.
INCLUDE zsdr0160_scn.
INCLUDE zsdr0160_f01.
INCLUDE zsdr0160_o01.
INCLUDE zsdr0160_i01.

*---------------------------------------------------------------------*
* INITIALIZATION
*---------------------------------------------------------------------*
INITIALIZATION.
  PERFORM init.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN OUTPUT
*---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
  PERFORM set_text.
  PERFORM set_screen.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN ON VALUE-REQUEST
*---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM f4_filename CHANGING p_file.

*---------------------------------------------------------------------*
* AT SELECTION-SCREEN
*---------------------------------------------------------------------*
AT SELECTION-SCREEN.
  PERFORM screen_ucomm.
  PERFORM screen_control.

*---------------------------------------------------------------------*
* START-OF-SELECTION
*---------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM process_data.