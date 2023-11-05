#include "init.h"

// --- init the PIC18F device
void initMyPIC18F(void)
{
ADCON0 = 0b00000001;  // Configuration de l'ADC, canal 1 (RC3)
ADCON1 = 0b00001110; 
	// set all ports as OUTPUTS
	
	TRISB = 0x00;
	TRISC = 1;
	TRISD = 0x00;
	TRISE = 0x00;

	// set port by port on "all zeros"
	
	PORTB = 0x00;
	PORTC = 0x00;
	PORTD = 0x00;
// make sure to have an empty LAST line in any *.c file (just hit an Enter)!

	PORTE = 0x00;

}
// make sure to have an empty LAST line in any *.c file (just hit an Enter)!

