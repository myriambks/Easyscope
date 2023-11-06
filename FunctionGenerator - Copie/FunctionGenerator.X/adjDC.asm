#include <p18F4550.inc>

;Configuration pour mikroProg 
CONFIG WDT=OFF
CONFIG FOSC = HS
    
org 0x0000 ; reset vector
goto prog_init
org 0x0008 ; interrupt vector
goto irq_handle