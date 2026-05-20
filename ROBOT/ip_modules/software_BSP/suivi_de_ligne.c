#include <stdio.h>
#include <stdint.h>
#include "system.h"
#include "io.h"

/* ============================================================
   ADRESSES (depuis system.h)
   ============================================================ */
#define CAPT_BASE   CAPTEURS_AVALON_INTERFACE_0_BASE
#define PWM_BASE    PWM_AVALON_INTERFACE_0_BASE

/* ============================================================
   PARAMETRES PWM
   ============================================================ */
#define BASE_SPEED   1900 //2048
#define SPEED_MIN    1792
#define SPEED_MAX    4095

#define FORWARD      0
#define BACKWARD     1
#define PWM_GO       (1 << 13)

/* ============================================================
   PARAMETRES PID
   ============================================================ */
#define KP             80.0f
#define KI              0.0f
#define KD              5.0f
#define INTEGRAL_MAX  100.0f
#define INTEGRAL_MIN -100.0f

/* ============================================================
   NIVEAU CAPTEUR
   ============================================================ */
#define NIVEAU       50

/* ============================================================
   FONCTIONS MOTEUR
   ============================================================ */
void set_moteur_droit(int go, int dir, uint32_t speed) {
    uint16_t cmd = 0;
    if (go)
        cmd = (uint16_t)(PWM_GO | (dir ? (1<<12) : 0) | (speed & 0xFFF));
    IOWR_16DIRECT(PWM_BASE, 0x00, cmd);
}

void set_moteur_gauche(int go, int dir, uint32_t speed) {
    uint16_t cmd = 0;
    if (go)
        cmd = (uint16_t)(PWM_GO | (dir ? (1<<12) : 0) | (speed & 0xFFF));
    IOWR_16DIRECT(PWM_BASE, 0x02, cmd);
}

void stop_moteurs(void) {
    IOWR_16DIRECT(PWM_BASE, 0x00, 0x0000);
    IOWR_16DIRECT(PWM_BASE, 0x02, 0x0000);
}

/* ============================================================
   DELAI
   ============================================================ */
void delay_ms(uint32_t ms) {
    volatile uint32_t i;
    while (ms) {
        for (i = 0; i < 5000; i++);
        --ms;
    }
}

/* ============================================================
   MAIN
   ============================================================ */
int main(void) {
    uint32_t status;
    uint8_t  vect_capt;
    uint32_t left_speed, right_speed;
    int      left_dir, right_dir;
    int      sum_position, count;
    float    error, integral, last_error, derivative, output;

    integral   = 0.0f;
    last_error = 0.0f;

    printf("=== Suivi de ligne ===\n");
    fflush(stdout);

    /* Ecrire le seuil capteurs : bits 15:8 = NIVEAU */
    IOWR_32DIRECT(CAPT_BASE, 0x00, (NIVEAU & 0xFF) << 8);

    while (1) {

        /* ── Lire les capteurs ── */
        delay_ms(5);
        status    = IORD_32DIRECT(CAPT_BASE, 0x00);
        vect_capt = (uint8_t)((status >> 1) & 0x7F);

        /* ── Aucun capteur : arrêt ── */
        if (vect_capt == 0x00) {
            stop_moteurs();
            integral   = 0.0f;
            last_error = 0.0f;
            printf("STOP - aucun capteur\n");
            fflush(stdout);
            continue;
        }

        /* ── Calcul de position pondérée ──
           C0 = extrême gauche (-3)
           C3 = centre         ( 0)
           C6 = extrême droite (+3) */
        sum_position = 0;
        count        = 0;
        if (vect_capt & (1 << 0)) { sum_position += -3; count++; }
        if (vect_capt & (1 << 1)) { sum_position += -2; count++; }
        if (vect_capt & (1 << 2)) { sum_position += -1; count++; }
        if (vect_capt & (1 << 3)) { sum_position +=  0; count++; }
        if (vect_capt & (1 << 4)) { sum_position +=  1; count++; }
        if (vect_capt & (1 << 5)) { sum_position +=  2; count++; }
        if (vect_capt & (1 << 6)) { sum_position +=  3; count++; }

        error = (float)sum_position / (float)count;

        /* ── PID ── */
        integral += error;
        if (integral > INTEGRAL_MAX) integral = INTEGRAL_MAX;
        if (integral < INTEGRAL_MIN) integral = INTEGRAL_MIN;

        derivative = error - last_error;
        output     = (KP * error) + (KI * integral) + (KD * derivative);
        last_error = error;

        /* ── Calcul vitesses ✅ corrigé ──
           error > 0 → ligne à droite → droit accélère
           error < 0 → ligne à gauche → gauche accélère */
        left_speed  = (uint32_t)(BASE_SPEED - output);
        right_speed = (uint32_t)(BASE_SPEED + output);

        /* Clamp max */
        if (left_speed  > SPEED_MAX) left_speed  = SPEED_MAX;
        if (right_speed > SPEED_MAX) right_speed = SPEED_MAX;

        /* Clamp min */
        if (left_speed  < SPEED_MIN) left_speed  = SPEED_MIN;
        if (right_speed < SPEED_MIN) right_speed = SPEED_MIN;

        left_dir  = FORWARD;
        right_dir = FORWARD;

        /* ── Appliquer aux moteurs ── */
        set_moteur_droit (1, right_dir, right_speed);
        set_moteur_gauche(1, left_dir,  left_speed);

        /* ── Debug terminal ── */
        printf("v=0x%02X err=%.1f L=%lu R=%lu\n",
               vect_capt, error,
               (unsigned long)left_speed,
               (unsigned long)right_speed);
        fflush(stdout);
    }

    return 0;
}