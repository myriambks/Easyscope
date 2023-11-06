#include "main.h"
#include <xc.h>
#include <pic18f4550.h>
#include "glcd.h"
#include <math.h>
#pragma config FOSC = HS      // Oscillator HS
#pragma config PWRT = OFF
#pragma config BOR = OFF
#pragma config WDT = OFF      // Disable watchDog
#pragma config LVP = OFF      // Disable low voltage programming
#pragma config DEBUG = ON     // Debug ON



int main(void) {

    initMyPIC18F();
    glcd_Init(GLCD_ON);
    glcd_Image();
    __delay_us(2000000);
     initMyPIC18F();
    glcd_FillScreen(0);
    glcd_Init(GLCD_ON);
    glcd_Image();
    __delay_us(2000000);
    glcd_FillScreen(0);

   
    
    while (1) {
         unsigned char x = 1;
    unsigned char y = 1;



   drawRectangleG(x, y, 86, 58, GLCD_ON);
    drawRectangle(x, y, 90, 62, GLCD_ON);
    // glcd_text_write("t(V) :", unsigned char x, unsigned char y)
    glcd_SetCursor(96, 1);
    glcd_WriteString("T(V)", f8X8, GLCD_ON);
    glcd_SetCursor(94, 2);
    glcd_WriteString("20.5", f8X8, GLCD_ON);
    glcd_SetCursor(96, 5);
    glcd_WriteString("I(A)", f8X8, GLCD_ON);
    glcd_SetCursor(94, 6);
    glcd_WriteString("0.45", f8X8, GLCD_ON);
    unsigned char xOffset = 0; // Centrer horizontalement
    unsigned char yOffset = (LCD_HEIGHT - 20) / 2; // Centrer verticalement
        // Lire la valeur du potentiomètre P1 connecté à RA0
        int potValue = readPotentiometer();
        // Calculer les coordonnées x du point sur l'écran
        int ap = (potValue * (1))/2 ; // Assurez-vous que le potentiomètre génère une valeur de 0 à 1023

       for (int x = 1; x < 83; x++) {
        int y = (int) (ap / 2 * (sin(2 * 3.1415 * x / 90))) +30;
        glcd_PlotPixel(x + xOffset, y, 1); // Afficher un point sur l'écran avec décalage
       __delay_us(200);
    }      
         glcd_FillScreen(0);// Ajoutez un délai pour ralentir la mise à jour de l'écran
        
    }

    return 0;
}
