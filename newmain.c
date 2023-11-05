#include "main.h"
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#pragma config FOSC = HS 		//oscillator HS
#pragma config PWRT = OFF
#pragma config BOR = OFF
#pragma config WDT = OFF 		//Disable watchDog
#pragma config LVP = OFF 		//Disable low voltage programmig
#pragma config DEBUG = ON		//Debug ON
// Remplacez cette valeur par la hauteur de votre écran GLCD

#define GLCD_SIZE 30
#define SQUARE_SIZE 20

void main(void) {

    initMyPIC18F();
    glcd_FillScreen(0);
    glcd_Init(GLCD_ON);
    glcd_Image();
    __delay_us(2000000);
    glcd_FillScreen(0);

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

    for (int x = 1; x < 83; x++) {
        int y = (int) (LCD_HEIGHT / 2 * (1 + sin(2 * 3.1415 * x / 90))) + yOffset;
        glcd_PlotPixel(x + xOffset, y, 1); // Afficher un point sur l'écran avec décalage
    }

    while (1) {



    }
}
