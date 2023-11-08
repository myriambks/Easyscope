#include <p18F4550.inc>

; config lines for interrupts        
CONFIG WDT = OFF			; disable watchdog timer 
CONFIG MCLRE = ON			; MCLEAR Pin On
CONFIG DEBUG = OFF			; Disable Debug Mode
CONFIG FOSC = HS			; Oscillator Mode 
CONFIG CPUDIV = OSC1_PLL2
CONFIG PBADEN = OFF
    
; Declaration of constants 
FREQ_MIN equ 10
FREQ_MAX equ 1000
; declaration of global variables 
FREQUENCY_POTENTIOMETER equ 0x20
; raw digits to be displayed
FREQUENCY_POTENTIOMETER_0 equ 0x20
FREQUENCY_POTENTIOMETER_1 equ 0x21
FREQUENCY_POTENTIOMETER_2 equ 0x22
FREQUENCY_POTENTIOMETER_3 equ 0x23
; temporary used by the decode routine
FREQUENCY_TEMPORARY equ 0x24
; final digits ready to be displayed
FREQUENCY_DISPLAY_0 equ 0x25
FREQUENCY_DISPLAY_1 equ 0x26 
FREQUENCY_DISPLAY_2 equ 0x27 
FREQUENCY_DISPLAY_3 equ 0x28  
 
count1 equ H'00'			; counter initialized    
 
org 0x0000				; reset vector
    GOTO INIT
org 0x0008				; ADC interrupt vector 
    GOTO ADCInterrupt
    
INIT
    CALL PortsInit
    CALL ADInit
    CALL InterruptsInit
    GOTO MAIN_LOOP
    
    
    
; Main function    
MAIN_LOOP
    CALL ReadPotentiometer
    
    GOTO MAIN_LOOP
    
    
    
PortsInit
    ; initialization of PORTA (for the 7SEG)
    clrf TRISA				; PORTA is an OUTPUT
    clrf PORTA				; clear PORTA
    ; initialization of PORTD (for the 7SEG)
    clrf TRISD				; PORTD is an OUTPUT 
    clrf PORTD				; Clear PORTD
    ; initialization of PORTE (for the frequency_potentiometer)
    setf TRISE				; PORTE is an INPUT
    clrf PORTE				; Clear PORTE
RETURN
    
ADInit
    ; Change the ADCON1 register in digital I/O because it is analog input by default (for 7SEG)
    movlw b'00001110'
    movwf ADCON1
    ; initialization of the A/D module
    movlw B'00000000'
    movwf ADCON0 
    ; power up the A/D module 
    bsf ADCON0, ADON
RETURN
    
InterruptsInit
    ; configure interrupts 
    bsf INTCON, GIE			; interrupts
    bsf INTCON, PEIE			; Periph. Int.
    bsf PIE1, ADIE			; active l'interruption ADC
RETURN    
    
ADCInterrupt
    bcf PIR1, ADIF			; clear the ADC interrupt flag
    ; A/D result goes into FREQUENCY_POTENTIOMETER
    movf ADRESH, W			; load the high part of the result
    movwf FREQUENCY_POTENTIOMETER	; stock the value in FREQUENCY_POTENTIOMETER
    CALL LimitFrequency
RETFIE
    
ReadPotentiometer
    ; start the A/D conversion
    bsf ADCON0, GO_DONE
    ; Wait for the A/D to complete...
    WaitLoop
	btfsc ADCON0, GO_DONE		; Check if the conversion is occuring
    GOTO WaitLoop			; If the conversion is not complete
RETURN
    
LimitFrequency
    ; Chech if FREQUENCY_POTENTIOMETER is below FREQ_MIN    
    movlw FREQ_MIN			; load the min value in WREG
    subwf FREQUENCY_POTENTIOMETER, W	; Substract FREQUENCY_POTENTIOMETER to FREQ_MIN and stock the result in WREG
    btfss STATUS, Z			; check if result is 0
    GOTO FrequencyInRange		; if the result is positive, FREQUENCY_POTENTIOMETER is in the range
    
    ; If below FREQ_MIN, set FREQUENCY_POTENTIOMETER to FREQ_MIN
    movlw FREQ_MIN	    
    movwf FREQUENCY_POTENTIOMETER	   
    GOTO FrequencyInRange		; ------------Peut être un CALL ?
RETURN  
    
FrequencyInRange
    ; Check if FREQUENCY_POTENTIOMETER is above FREQ_MAX
    movlw FREQ_MAX			; load the max value in WREG
    subwf FREQUENCY_POTENTIOMETER, W	; Substract FREQUENCY_POTENTIOMETER to FREQ_MAX and stock the result in WREG
    btfsc STATUS, C			; check the carry flag
    GOTO Done
    
    ; If above FREQ_MAX, set FREQUENCY_POTENTIOMETER to FREQ_MAX
    movlw FREQ_MAX			
    movwf FREQUENCY_POTENTIOMETER
    GOTO Done
 
Done 
    RETURN        
   
    
    
    
    
END    


