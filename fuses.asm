	list	p=16f88
	radix dec
	include "p16f88.inc"

;P16F628A_H
;   __CONFIG (_BODEN_OFF & _CP_OFF & _DATA_CP_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_NOCLKOUT & _LVP_OFF & _MCLRE_OFF)

;P16F88_H
    __CONFIG (_BODEN_ON & _CP_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_IO & _LVP_OFF & _MCLR_OFF)

;P12F683_H
;   __CONFIG (_FCMEN_OFF & _IESO_OFF & _BOD_OFF & _CPD_OFF & _CP_OFF & _MCLRE_OFF & _PWRTE_ON & _WDT_OFF & _INTOSCIO)

    end
