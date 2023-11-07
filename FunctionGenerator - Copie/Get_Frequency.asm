#include <p18F4550>
	
; config lines for interrupts        
CONFIG WDT = OFF			; disable watchdog timer 
CONFIG MCLRE = ON			; MCLEAR Pin On
CONFIG DEBUG = OFF			; Disable Debug Mode
CONFIG FOSC = HS			; Oscillator Mode 
CONFIG CPUDIV = OSC1_PLL2
CONFIG PBADEN = OFF
    
; declaration of constants 
FREQ_MIN equ 10
FREQ_MAX equ 1000
 
 ; declaration of global variables 
FREQUENCY_POTENTIOMETER equ 0x20
 
org 0x0000				; reset vector
goto INIT
org 0x0008				; interrupt vector 
goto IRQ_HANDLE
    
INIT
    ; initialization of PORTA (for the frequency_potentiometer)
    setf TRISA				; PORTA is an INPUT
    clrf PORTA				; Clear PORTA
    
    ; initialization of the A/D module
    movlw B'00000000'
    movwf ADCON0 

    ; power up the A/D module 
    bsf ADCON0, ADON

    ; configure interrupts 
    bsf INTCON, GIE			; interrupts
    bsf INTCON, PEIE			; Periph. Int.
    
    GOTO MAIN_LOOP


MAIN_LOOP
    ; start the A/D conversion
    bsf ADCON0, GO_DONE
    
    ; Wait for a short delay
    nop
    nop
    
    GOTO MAIN_LOOP
END 
    
;   --Interrupt routine 
IRQ_HANDLE				; flag test 
    btfsc PIR1, ADIF			; Check if the interrupt is from the A/D module
    GOTO ADInterrupt			; yes, it is AD
RETFIE					; no, return from interrupt
    
ADInterrupt 
    bcf PIR1, ADIF			; clear the A/D interrupt flag
    ; A/D result goes into FREQUENCY_POTENTIOMETER
    movf ADRESH, W			; load the high part of the result
    movf FREQUENCY_POTENTIOMETER	; stock the value in FREQUENCY_POTENTIOMETER
    
    CALL Limit_Frequency
    bsf ADCON0, GO_DONE			; Start another A/D Conversion
RETFIE
    
Limit_Frequency
    ; Chech if FREQUENCY_POTENTIOMETER is below FREQ_MIN    
    movlw FREQ_MIN			; load the min value in WREG
    subwf FREQUENCY_POTENTIOMETER, W	; Substract FREQUENCY_POTENTIOMETER to FREQ_MIN and stock the result in WREG
    btfss STATUS, Z			; check if result is 0
    goto Frequency_In_Range		; if the result is positive, FREQUENCY_POTENTIOMETER is in the range
    
    ; If below FREQ_MIN, set FREQUENCY_POTENTIOMETER to FREQ_MIN
    movlw FREQ_MIN	    
    movwf FREQUENCY_POTENTIOMETER	   
    goto Frequency_In_Range 
    
Frequency_In_Range
    ; Check if FREQUENCY_POTENTIOMETER is above FREQ_MAX
    movlw FREQ_MAX			; load the max value in WREG
    subwf FREQUENCY_POTENTIOMETER, W	; Substract FREQUENCY_POTENTIOMETER to FREQ_MAX and stock the result in WREG
    btfsc STATUS, C			; check the carry flag
    goto Done
    
    ; If above FREQ_MAX, set FREQUENCY_POTENTIOMETER to FREQ_MAX
    movlw FREQ_MAX			
    movwf FREQUENCY_POTENTIOMETER	   
 
Done 
    return
    
 