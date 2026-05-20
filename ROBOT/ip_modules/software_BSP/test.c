



// test PWM pour les moteurs 

#include <stdio.h>
#include "system.h"
#include "io.h"

// ============================================================
// ADRESSES PWM
// ============================================================
#define PWM_BASE    PWM_AVALON_INTERFACE_0_BASE   // 0x1040

// ============================================================
// FORMAT REGISTRE PWM
// bit13 = GO    (1=marche, 0=stop)
// bit12 = DIR   (0=avant, 1=arrière)
// bits11:0 = vitesse (max 3125)
// ============================================================
#define PWM_GO      (1 << 13)
#define PWM_AVANT   (0 << 12)
#define PWM_ARRIERE (1 << 12)

// Vitesses issues de la caractérisation (avec piles)
#define VIT_MIN     0x700   // minimum sur sol
#define VIT_NORMAL  0x850   // démarrage nominal 65.5%
#define VIT_MAX     0xC35   // 100%

// ============================================================
// FONCTIONS DE BASE
// ============================================================

void moteur_droit(int go, int direction, int vitesse) {
    unsigned short cmd = 0;
    if (go)
        cmd = PWM_GO | (direction ? PWM_ARRIERE : PWM_AVANT) | (vitesse & 0xFFF);
    IOWR_16DIRECT(PWM_BASE, 0x00, cmd);
}

void moteur_gauche(int go, int direction, int vitesse) {
    unsigned short cmd = 0;
    if (go)
        cmd = PWM_GO | (direction ? PWM_ARRIERE : PWM_AVANT) | (vitesse & 0xFFF);
    IOWR_16DIRECT(PWM_BASE, 0x02, cmd);
}

// ============================================================
// FONCTIONS DE DÉPLACEMENT
// ============================================================

void stop(void) {
    IOWR_16DIRECT(PWM_BASE, 0x00, 0x0000);
    IOWR_16DIRECT(PWM_BASE, 0x02, 0x0000);
}

void avancer(int vitesse) {
    moteur_droit (1, 0, vitesse);
    moteur_gauche(1, 0, vitesse);
}

void reculer(int vitesse) {
    moteur_droit (1, 1, vitesse);
    moteur_gauche(1, 1, vitesse);
}

void tourner_droite(int vitesse) {
    moteur_droit (1, 1, vitesse);   // droit  ARRIERE
    moteur_gauche(1, 0, vitesse);   // gauche AVANT
}

void tourner_gauche(int vitesse) {
    moteur_droit (1, 0, vitesse);   // droit  AVANT
    moteur_gauche(1, 1, vitesse);   // gauche ARRIERE
}

// ============================================================
// DÉLAI BUSY-WAIT
// CPU à 50 MHz → ~50000 cycles par ms
// ============================================================
void delay_ms(unsigned int ms) {
    volatile unsigned int i;
    for (i = 0; i < ms * 50000; i++);
}

// ============================================================
// MAIN
// ============================================================
int main(void) {
    printf("=== Test pilotage moteurs ===\n");

    printf("Avancer 2s\n");
    avancer(VIT_NORMAL);
    delay_ms(2000);
    stop();
    delay_ms(500);

    printf("Reculer 2s\n");
    reculer(VIT_NORMAL);
    delay_ms(2000);
    stop();
    delay_ms(500);

    printf("Tourner droite 1s\n");
    tourner_droite(VIT_NORMAL);
    delay_ms(1000);
    stop();
    delay_ms(500);

    printf("Tourner gauche 1s\n");
    tourner_gauche(VIT_NORMAL);
    delay_ms(1000);
    stop();

    printf("=== Fin ===\n");
    return 0;
}