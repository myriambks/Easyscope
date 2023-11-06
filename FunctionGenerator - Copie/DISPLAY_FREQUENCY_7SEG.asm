#include <p18F4550>

; config lines for interrupts    
CONFIG WDT = OFF    ; disable watchdog timer 
CONFIG MCLRE = ON   ; MCLEAR Pin On
CONFIG DEBUG = OFF  ; Disable Debug Mode
CONFIG FOSC = HS    ; Oscillator Mode 
CONFIG CPUDIV = OSC1_PLL2
CONFIG PBADEN = OFF
    
count1 equ H'00'    ; counter initialized    
 
; raw variable to be displayed
FREQUENCY_POTENTIOMETER equ 0x20
; temporary used by the decode routine
DIS_RAW equ 0x21
; masked data "ready to display"
DIS_DATA equ 0x22 
 
org 0x0000  ; reset vector
goto INIT
org 0x0008  ; interrupt vector 
goto IRQ_HANDLE
    
INIT
    ; initialization of PORTD (for the 7SEG)
    clrf TRISD	; PORTD is an OUTPUT 
    clrf PORTD	; Clear PORTD
    goto Display_Frequency
    
    Display_Frequency
	movf FREQUENCY_POTENTIOMETER, W		;load the value of FREQUENCY_POTENTIOMETER in the WREH
	CALL ConvertTo7SEG
	movwf PORTD	    ; display the value on the 7SEG
	
	call my_delay
	goto Display_Frequency	
	
    my_delay
	decfsz count1
	goto my_delay
    return
    
    ConvertTo7SEG
	
    return

END	
	
	



