#include <p18F4550>

; config lines for interrupts    
CONFIG WDT = OFF			; disable watchdog timer 
CONFIG MCLRE = ON			; MCLEAR Pin On
CONFIG DEBUG = OFF			; Disable Debug Mode
CONFIG FOSC = HS			; Oscillator Mode 
CONFIG CPUDIV = OSC1_PLL2
CONFIG PBADEN = OFF
    
count1 equ 0x005			; counter initialized    
 
; declaration of constants 
FREQ_MIN equ 10
FREQ_MAX equ 1000
;CYCLE_STEP EQU 10 ;  step for each button
 
; Declaration of my virtual register
CBLOCK Ox20
    FREQUENCY_POTENTIOMETER
    ; raw digits to be displayed
    FREQUENCY_POTENTIOMETER_0
    FREQUENCY_POTENTIOMETER_1
    FREQUENCY_POTENTIOMETER_2
    FREQUENCY_POTENTIOMETER_3
    ; temporary used by the decode routine
    FREQUENCY_TEMPORARY 
    ; final digits ready to be displayed
    FREQUENCY_DISPLAY_0 
    FREQUENCY_DISPLAY_1
    FREQUENCY_DISPLAY_2 
    FREQUENCY_DISPLAY_3 
    ;button_status
    ;temporary_variable
    ;duty_cycle
ENDC

org 0x0000				; reset vector
GOTO INIT
org 0x0008				; interrupt vector 
GOTO IRQ_HANDLE

INIT
    ; Change the ADCON1 register in digital I/O because it is analog input by default
    movlw b'00001110'
    movwf ADCON1
    
    ; initialization of PORTA (for the 7SEG)
    clrf TRISA				; PORTA is an OUTPUT
    clrf PORTA				; clear PORTA
    
    ; initialization of PORTD (for the 7SEG)
    clrf TRISD				; PORTD is an OUTPUT 
    clrf PORTD				; Clear PORTD
    
    ; initialization of PORTE (for the frequency_potentiometer)
    setf TRISE				; PORTE is an INPUT
    clrf PORTE				; Clear PORTE
    
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
    
    ; Start the Interrupt and get the potentiometer frequency
    GOTO IRQ_HANDLE
    
    ; Extracting digits from FREQUENCY_POTENTIOMETER
    ;CALL GetFrequency			; obtenue dans le fichier 'Get_Frequency', elle lit la valeur du potentiomètre
    movf FREQUENCY_POTENTIOMETER, W	; variable issue de l'autre fichier
    CALL ExtractDigits		
    
    ; Associating Extracted numbers to FREQUENCY_POTENTIOMETER_X
    movwf FREQUENCY_POTENTIOMETER_0
    movf FREQUENCY_POTENTIOMETER_1, W
     
    movwf FREQUENCY_POTENTIOMETER_1
    movf FREQUENCY_POTENTIOMETER_2, W
    
    movwf FREQUENCY_POTENTIOMETER_2
    movf FREQUENCY_POTENTIOMETER_3, W
    
    movwf FREQUENCY_POTENTIOMETER_3
    
    ; --- convert from raw to final digits ready to be displayed
    CALL ConvertToBCD
    ; --- refresh the display
    CALL DisplayFrequency
    ; --- loop back
    
    
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
    GOTO Frequency_In_Range		; if the result is positive, FREQUENCY_POTENTIOMETER is in the range
    
    ; If below FREQ_MIN, set FREQUENCY_POTENTIOMETER to FREQ_MIN
    movlw FREQ_MIN	    
    movwf FREQUENCY_POTENTIOMETER	   
    GOTO Frequency_In_Range 
    
Frequency_In_Range
    ; Check if FREQUENCY_POTENTIOMETER is above FREQ_MAX
    movlw FREQ_MAX			; load the max value in WREG
    subwf FREQUENCY_POTENTIOMETER, W	; Substract FREQUENCY_POTENTIOMETER to FREQ_MAX and stock the result in WREG
    btfsc STATUS, C			; check the carry flag
    GOTO Done
    
    ; If above FREQ_MAX, set FREQUENCY_POTENTIOMETER to FREQ_MAX
    movlw FREQ_MAX			
    movwf FREQUENCY_POTENTIOMETER	   
 
Done 
    RETURN    
    
ExtractDigits
    ; Division par 10 pour extraire les chiffres
    movlw 10
    movwf FREQUENCY_POTENTIOMETER_3	; Initialisation du quotient
    movlw 0    
    movwf FREQUENCY_POTENTIOMETER_2	; Initialisation du reste
    movwf FREQUENCY_POTENTIOMETER_1
    movwf FREQUENCY_POTENTIOMETER_0

    ; Division répétée
    ; Explication : FREQUENCY_POTENTIOMETER est divisé par 10, et le reste est stocké dans FREQUENCY_POTENTIOMETER_0. FREQUENCY_POTENTIOMETER est mis à jour avec le quotient.
    ; on recommence l'itération : FREQUENCY_POTENTIOMETER (nouvelle valeur après la première itération) est divisé par 10, et le reste est stocké dans FREQUENCY_POTENTIOMETER_1. FREQUENCY_POTENTIOMETER est mis à jour avec le quotient.
    ; on continue ainsi de suite jusqu'à ce que la division ne soit plus possible et donc que tous les chiffres qui composent la fréquence du potentiomètre soient placés dans des variables
    dig_loop
        movf FREQUENCY_POTENTIOMETER_3, W
        subwf FREQUENCY_POTENTIOMETER, W
        btfss STATUS, C			; Si C=0, FREQUENCY_POTENTIOMETER < FREQUENCY_POTENTIOMETER_3
        GOTO dig_end

        incf FREQUENCY_POTENTIOMETER_0, F
        subwf FREQUENCY_POTENTIOMETER, F

        movlw 10
        movwf FREQUENCY_POTENTIOMETER_3
        movf FREQUENCY_POTENTIOMETER_2, W
        subwf FREQUENCY_POTENTIOMETER_3, F

        GOTO dig_loop
    dig_end
RETURN
    
ConvertToBCD
    ; - decode FREQUENCY_POTENTIOMETER_0
    movf FREQUENCY_POTENTIOMETER_0, 0
    movwf FREQUENCY_TEMPORARY
    CALL decode_digit			; returns with mask in w
    movwf FREQUENCY_DISPLAY_0
    
     ; - decode FREQUENCY_POTENTIOMETER_1
    movf FREQUENCY_POTENTIOMETER_1, 0
    movwf FREQUENCY_TEMPORARY
    CALL decode_digit			; returns with mask in w
    movwf FREQUENCY_DISPLAY_1
    
     ; - decode FREQUENCY_POTENTIOMETER_2
    movf FREQUENCY_POTENTIOMETER_2, 0
    movwf FREQUENCY_TEMPORARY
    CALL decode_digit			; returns with mask in w
    movwf FREQUENCY_DISPLAY_2
    
     ; - decode FREQUENCY_POTENTIOMETER_3
    movf FREQUENCY_POTENTIOMETER_3, 0
    movwf FREQUENCY_TEMPORARY
    CALL decode_digit			; returns with mask in w
    movwf FREQUENCY_DISPLAY_3
RETURN
    
; decode the real value of the digit in BCD    
decode_digit
    movf FREQUENCY_TEMPORARY, f
    btfsc STATUS, Z
    GOTO dis_is_0			; Z flag affected, it is 0
    decfsz FREQUENCY_TEMPORARY
    GOTO dis_mark1			; marks to jump
    GOTO dis_is_1			; it is 1
    
    dis_mark1
	decfsz FREQUENCY_TEMPORARY
	GOTO dis_mark2
	GOTO dis_is_2			; it is 2

    dis_mark2
	decfsz FREQUENCY_TEMPORARY
	GOTO dis_mark3
	GOTO dis_is_3			; it is 3

    dis_mark3
	decfsz FREQUENCY_TEMPORARY
	GOTO dis_mark4
	GOTO dis_is_4			; it is 4

    dis_mark4
	decfsz FREQUENCY_TEMPORARY
	GOTO dis_mark5
	GOTO dis_is_5			; it is 5

    dis_mark5
	decfsz FREQUENCY_TEMPORARY
	GOTO dis_mark6
	GOTO dis_is_6			; it is 6

    dis_mark6
	decfsz FREQUENCY_TEMPORARY
	GOTO dis_mark7
	GOTO dis_is_7			; it is 7

    dis_mark7
	decfsz FREQUENCY_TEMPORARY
	GOTO dis_mark8
	GOTO dis_is_8			; it is 8

    dis_mark8
	decfsz FREQUENCY_TEMPORARY
	GOTO dis_error
	GOTO dis_is_9			; it is 9

    dis_error				; should never arrive here
	GOTO dis_is_error

    ; --- apply mask and continue
    dis_is_0: retlw 0x3F		; mask for 0
    dis_is_1: retlw 0x06		; mask for 1
    dis_is_2: retlw 0x5B		; mask for 2
    dis_is_3: retlw 0x4F		; mask for 3
    dis_is_4: retlw 0x66		; mask for 4
    dis_is_5: retlw 0x6D		; mask for 5
    dis_is_6: retlw 0x7D		; mask for 6
    dis_is_7: retlw 0x07		; mask for 7
    dis_is_8: retlw 0x7F		; mask for 8
    dis_is_9: retlw 0x6F		; mask for 9
    dis_is_error: retlw 0x79		; mask for E 
RETURN
  
; Displays the frequency on the 7SEG    
DisplayFrequency
    movff FREQUENCY_DISPLAY_0, PORTD	; digit 0 into PORTD
    bsf PORTA, RA0			; activate dis0
    CALL display_delay			; wait a little
    bcf PORTA, RA0			; deactivate dis0
    movff FREQUENCY_DISPLAY_1, PORTD	; digit 1 into PORTD
    bsf PORTA, RA1			; activate dis1
    CALL display_delay			; wait a little
    bcf PORTA, RA1			; deactivate dis1
    movff FREQUENCY_DISPLAY_2, PORTD	; digit 2
    bsf PORTA, RA2
    CALL display_delay
    bcf PORTA, RA2
    movff FREQUENCY_DISPLAY_3, PORTD	; digit 3
    bsf PORTA, RA3
    CALL display_delay
    bcf PORTA, RA3     
RETURN
    
display_delay
    ; --- wait a couple of hundreds of clock cycles
    ; --- if needed, this delay can be shortened
    decfsz count1
    GOTO display_delay
RETURN       
