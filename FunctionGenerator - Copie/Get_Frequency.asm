#include <p18F4550>
	
; config lines for interrupts        
CONFIG WDT = OFF    ; disable watchdog timer 
CONFIG MCLRE = ON   ; MCLEAR Pin On
CONFIG DEBUG = OFF  ; Disable Debug Mode
CONFIG FOSC = HS    ; Oscillator Mode 
CONFIG CPUDIV = OSC1_PLL2
CONFIG PBADEN = OFF
    
; declaration of constants 
FREQ_MIN equ 10
FREQ_MAX equ 1000
 
 ; declaration of global variables 
FREQUENCY_POTENTIOMETER equ 0x20
 
org 0x0000  ; reset vector
goto INIT
org 0x0008  ; interrupt vector 
goto IRQ_HANDLE
    
INIT
    ; initialization of PORTA (for the frequency_potentiometer)
    setf TRISA  ; PORTA is an INPUT
    clrf PORTA  ; Clear PORTA
    
    ; initialization of the A/D module
    movlw B'00000000'
    movwf ADCON0 

    ; power up the A/D module 
    bsf ADCON0, ADON

    ; configure interrupts 
    bsf INTCON, GIE	    ; interrupts
    bsf INTCON, PEIE    ; Periph. Int.
    
    bsf ADCON0, GO_DONE		; start A/D conversion
return 
    
;   --Interrupt routine 
IRQ_HANDLE		; flag test 
    btfsc PIR1, ADIF	; is it AD ?
    goto AD_interrupt	; yes, it is AD
retfie	; no, return from interrupt
    
AD_interrupt 
    bcf PIR1, ADIF	; clear the A/D interrupt flag
    ; A/D result goes into FREQUENCY_POTENTIOMETER
    movf ADRESH, W	    ; load the high part of the result
    movf FREQUENCY_POTENTIOMETER	; stock the value in FREQUENCY_POTENTIOMETER
    bsf ADCON0, GO_DONE 
retfie 
    
Limit_Frequency
    movlw FREQ_MIN	    ; load the min value in WREG
    subwf FREQUENCY_POTENTIOMETER, W	    ; Substract FREQUENCY_POTENTIOMETER to FREQ_MIN and stock the result in WREG
    
    ; if FREQUENCY_POTENTIOMETER < FREQ_MIN, FREQUENCY_POTENTIOMETER takes the value of FREQ_MIN
    btfss STATUS, C	    ; check the carry flag
    goto Frequency_In_Range    ; if the result is positive, FREQUENCY_POTENTIOMETER is in the range
    
    movlw FREQ_MIN	    ; load the min value in WREG
    movwf FREQUENCY_POTENTIOMETER	    ; FREQ_POT takes the value of FREQ_MIN
    goto Frequency_In_Range
    
Frequency_In_Range
    movlw FREQ_MAX	    ; load the max value in WREG
    subwf FREQUENCY_POTENTIOMETER, W	    ; Substract FREQUENCY_POTENTIOMETER to FREQ_MAX and stock the result in WREG

    ; if FREQUENCY_POTENTIOMETER > FREQ_MAX, FREQUENCY_POTENTIOMETER takes the value of FREQ_MAX
    btfsc STATUS, C	    ; check the carry flag
    goto Done
    
    movlw FREQ_MAX	    ; load FREQ_MAX in WREG
    movwf FREQUENCY_POTENTIOMETER	    ; FREQUENCY_POTENTIOMETER takes the value of FREQ_MAX
 
Done 
    return
    
    
MAIN_LOOP
    ; start the A/D conversion
    goto MAIN_LOOP
    bsf ADCON0, GO_DONE
END 