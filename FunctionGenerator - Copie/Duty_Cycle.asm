#include <p18F4550>

org 0x0000  ; reset vector
goto INIT
org 0x0008  ; interrupt vector 
goto IRQ_HANDLE

; Declaration of constants 
CYCLE_STEP EQU 10 ;  step for each button
 
; Declaration of my virtual register
CBLOCK Ox20    
    button_status
    temporary_variable
    duty_cycle
ENDC
    
INIT
    ; initialization of PORTB (for the buttons)
    setf TRISB		; PORTB is an INPUT
    clrf PORTB		; Clear PORTB
    
    goto Read_Buttons
    
Read_Buttons
    ; Read the state of the buttons
    movf PORTB, W
    movwf button_status		; Load the button status in the register
RETURN 
    
Change_Duty_Cycle
    ; Shift to the right to align the bits of port B with the number of buttons
    movf button_status, W
    movwf temporary_variable
    
    ; Mask to keep only the bits corresponding to the buttons
    andlw OxFF >> (8 - CYCLE_STEP)
    
    ; Detection of the buttons pressed 
    movwf temporary_variable		; Load the result temporarily 
    xorlw 0xFF		; invert the bits
    movwf temporary_variable		; load the result in temporary_variable
    
    ; find the first active bit (button)
    btfss temporary_variable, 0		; test the bit 0
    goto $+2				; jump 2 instructions if the bit 0 is 0
    btfsc temporary_variable, 0
    goto $+4				; jump 4 instructions if the bit 0 is 1
    btfss temporary_variable, 1
    goto $+2
    btfsc temporary_variable, 1
    goto $+3
    btfss temporary_variable, 2
    goto $+2 
    btfsc temporary_variable, 2
    goto $+4
    btfss temporary_variable, 3 
    goto $+2
    btfsc temporary_variable, 3
    goto $+3
    btfss temporary_variable, 4
    goto $+2
    btfsc temporary_variable, 4
    goto $+4
    btfss temporary_variable, 5
    goto $+2
    btfsc temporary_variable, 5
    goto $+3
    btfss temporary_variable, 6
    goto $+2
    btfsc temporary_variable, 6
    goto $+4
    btfss temporary_variable, 7
    goto $+2
    btfsc temporary_variable, 7
    goto $+3
    
    ; Calculate the duty cycle according to the active button
    movf temporary_variable, W		; load the result in the WREG
    movwf duty_cycle			; stock the result in the duty_cycle register
    
RETURN   
END    


