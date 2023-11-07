#include <p18F4550.inc>

; Configuration pour mikroProg
CONFIG WDT=OFF    ; Désactive le chien de garde (Watchdog Timer)
CONFIG FOSC = HS   ; Configure la fréquence de l'oscillateur comme haute (High Speed)

; Définition des variables pour les chiffres BCD
dis0_raw equ 0x20
dis1_raw equ 0x21
dis2_raw equ 0x22
dis3_raw equ 0x23
dis_raw equ 0x24

dis0_data equ 0x25
dis1_data equ 0x26
dis2_data equ 0x27
dis3_data equ 0x28

; Définition des constantes pour les masques des chiffres BCD
DIS_0_MASK equ 0x3F
DIS_1_MASK equ 0x06
DIS_2_MASK equ 0x5B
DIS_3_MASK equ 0x4F
DIS_4_MASK equ 0x66
DIS_5_MASK equ 0x6D
DIS_6_MASK equ 0x7D
DIS_7_MASK equ 0x07
DIS_8_MASK equ 0x7F
DIS_9_MASK equ 0x6F

; Compteur de délai
count1 equ 0x29

; Définition des variables pour le DAC
dac_data equ 0x30 ; Stocke la valeur à écrire sur le DAC

; Définition des constantes pour le DAC
DAC_PORT equ PORTD ; Port utilisé pour le DAC
DAC_MASK equ 0xF0 ; Masque pour les broches utilisées pour le DAC sur PORTD

; Début du programme
org 0x0000         ; Vecteur de réinitialisation
goto prog_init
org 0x0008         ; Vecteur d'interruption
goto irq_handle

; --- Routine d'interruption (IRQ)
irq_handle
    btfsc PIR1, ADIF   ; Vérifie si l'interruption est due à une conversion A/D
    goto AD_interrupt  ; Si c'est le cas, saute à la routine AD_interrupt
    retfie             ; Sinon, retourne de l'interruption

AD_interrupt
    bcf PIR1, ADIF   ; Efface le drapeau d'interruption ADIF (conversion A/D terminée)
    
    ; Lecture de la valeur depuis le port du PIC (supposons que la valeur est lue sur le port RA4-RA7)
    movf PORTA, W
    movwf dis3_raw   ; Stockez la valeur dans dis3_raw
    swapf dis3_raw, W
    andlw 0x0F      ; Masquez les bits supérieurs
    movwf dis2_raw   ; Stockez la valeur dans dis2_raw
    swapf dis2_raw, W
    andlw 0x0F      ; Masquez les bits supérieurs
    movwf dis1_raw   ; Stockez la valeur dans dis1_raw
    swapf dis1_raw, W
    andlw 0x0F      ; Masquez les bits supérieurs
    movwf dis0_raw   ; Stockez la valeur dans dis0_raw
    swapf dis0_raw, W
    andlw 0x0F      ; Masquez les bits supérieurs

    ; Conversion des chiffres en BCD
    call apply_mask

    ; Écrire sur le DAC
    call write_to_dac

    ; Affichage sur les afficheurs 7 segments
    call display
    
    retfie           ; Retourne de l'interruption

; --- Initialisation
prog_init
    ; Configuration du port A (PORTA) en tant que DDDDDDDA, où D représente des bits de configuration et A est analogique (seul RA0 est analogique)
    ; Le résultat de la conversion A/D est justifié à gauche
    movlw B'00001110'   ; Charge la valeur binaire '00001110' dans le registre W
    movwf ADCON1         ; Copie la valeur de W dans le registre ADCON1

    ; Sélectionne le canal 0 (AN0) pour la conversion A/D
    movlw B'00000000'   ; Charge la valeur binaire '00000000' dans le registre W
    movwf ADCON0         ; Copie la valeur de W dans le registre ADCON0

    ; Active le module A/D
    bsf ADCON0, ADON

    ; Initialise le port D
    clrf TRISD   ; Configure le port PORTD comme sortie
    clrf PORTD   ; Efface le contenu du port PORTD

    ; Initialise le compteur de délai
    movlw 0xFF
    movwf count1

    ; Configure les interruptions
    bsf INTCON, GIE   ; Active les interruptions générales
    bsf PIE1, ADIE    ; Active l'interruption A/D
    bsf INTCON, PEIE  ; Active les interruptions périphériques

dis_is_0 retlw 0x3F ; mask for 0
dis_is_1 retlw 0x06 ; mask for 1
dis_is_2 retlw 0x5B ; mask for 2
dis_is_3 retlw 0x4F ; mask for 3
dis_is_4 retlw 0x66 ; mask for 4
dis_is_5 retlw 0x6D ; mask for 5
dis_is_6 retlw 0x7D ; mask for 6
dis_is_7 retlw 0x07 ; mask for 7
dis_is_8 retlw 0x7F ; mask for 8
dis_is_9 retlw 0x6F ; mask for 9
dis_is_error retlw 0x79 ; mask for E
    
; --- Boucle principale
start_AD
    ; Démarre la conversion A/D
    bsf ADCON0, GO_DONE
    goto start_AD  ; Saute vers le début de la boucle start_AD

; Fonction pour convertir les chiffres en BCD
apply_mask
; - decode dis0
    movf dis0_raw, 0
    movwf dis_raw
    call decode_digit ; returns with mask in w
    movwf dis0_data
    ; - decode dis1
    movf dis1_raw, 0
    movwf dis_raw
    call decode_digit ; returns with mask in w
    movwf dis1_data
    ; - decode dis2
    movf dis2_raw, 0
    movwf dis_raw
    call decode_digit ; returns with mask in w
    movwf dis2_data
    ; - decode dis3
    movf dis3_raw, 0
    movwf dis_raw
    call decode_digit ; returns with mask in w
    movwf dis3_data
return

decode_digit
    movf dis_raw, f
    btfsc STATUS, Z
    goto dis_is_0 ; Z flag affected, it is 0
    decfsz dis_raw
    goto dis_mark1 ; marks to jump
    goto dis_is_1 ; it is 1
dis_error ; should never arrive here
    goto dis_is_error
dis_mark8
    decfsz dis_raw
    goto dis_error
    goto dis_is_9 ; it is 9
dis_mark7
    decfsz dis_raw
    goto dis_mark8
    goto dis_is_8 ; it is 8
dis_mark6
    decfsz dis_raw
    goto dis_mark7
    goto dis_is_7 ; it is 7
dis_mark5
    decfsz dis_raw
    goto dis_mark6
    goto dis_is_6 ; it is 6
dis_mark4
    decfsz dis_raw
    goto dis_mark5
    goto dis_is_5 ; it is 5
dis_mark3
    decfsz dis_raw
    goto dis_mark4
    goto dis_is_4 ; it is 4
dis_mark2
    decfsz dis_raw
    goto dis_mark3
    goto dis_is_3 ; it is 3
dis_mark1
    decfsz dis_raw
    goto dis_mark2
    goto dis_is_2 ; it is 2
    
    
     
    
; Fonction pour écrire sur le DAC
write_to_dac

    movf dac_data, W
    andlw DAC_MASK
    iorwf PORTD, F  ; Utilisez OR pour écrire les bits du DAC sans affecter les autres bits
    return

; Fonction pour afficher les chiffres sur les afficheurs 7 segments
display
    movf dis0_data, W
    movwf PORTD ; Afficher le chiffre des unités sur PORTD
    bsf PORTD, RD0 ; Activer le chiffre des unités
    call display_delay ; Attendre un peu
    bcf PORTD, RD0 ; Désactiver le chiffre des unités

    movf dis1_data, W
    movwf PORTD ; Afficher le chiffre des dizaines sur PORTD
    bsf PORTD, RD1 ; Activer le chiffre des dizaines
    call display_delay ; Attendre un peu
    bcf PORTD, RD1 ; Désactiver le chiffre des dizaines

    movf dis2_data, W
    movwf PORTD ; Afficher le chiffre des centaines sur PORTD
    bsf PORTD, RD2 ; Activer le chiffre des centaines
    call display_delay ; Attendre un peu
    bcf PORTD, RD2 ; Désactiver le chiffre des centaines

    movf dis3_data, W
    movwf PORTD ; Afficher le chiffre des milliers sur PORTD
    bsf PORTD, RD3 ; Activer le chiffre des milliers
    call display_delay ; Attendre un peu
    bcf PORTD, RD3 ; Désactiver le chiffre des milliers

    return

; Fonction de délai pour l'affichage
display_delay
    decfsz count1
	goto display_delay
    return

; Fin du programme
end
