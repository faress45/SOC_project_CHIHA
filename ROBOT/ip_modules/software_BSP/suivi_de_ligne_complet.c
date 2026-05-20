#include <stdint.h>
#include "system.h"
#include "io.h"

/* ============================================================
   ADRESSES
   ============================================================ */
#define CAPT_BASE   CAPTEURS_AVALON_INTERFACE_0_BASE
#define PWM_BASE    PWM_AVALON_INTERFACE_0_BASE

/* ============================================================
   PARAMETRES PWM
   ============================================================ */
#define BASE_SPEED    1900
#define SPEED_MIN     1792
#define SPEED_MAX     4095
#define SEARCH_SPEED  1900   /* ✅ assez fort pour pivot des deux roues */
#define FORWARD       0
#define BACKWARD      1
#define PWM_GO        (1 << 13)

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
#define NIVEAU  50

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

/* Pivot droite : droit -v, gauche +v */
void chercher_droite(void) {
    set_moteur_droit (1, BACKWARD, SEARCH_SPEED);
    set_moteur_gauche(1, FORWARD,  SEARCH_SPEED);
}

/* Pivot gauche : droit +v, gauche -v */
void chercher_gauche(void) {
    set_moteur_droit (1, FORWARD,  SEARCH_SPEED);
    set_moteur_gauche(1, BACKWARD, SEARCH_SPEED);
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
    int      sum_position, count;
    float    error, integral, last_error, derivative, output;
    float    last_known_error;

    integral         = 0.0f;
    last_error       = 0.0f;
    last_known_error = 0.0f;

    IOWR_32DIRECT(CAPT_BASE, 0x00, (NIVEAU & 0xFF) << 8);

    while (1) {

        delay_ms(5);
        status    = IORD_32DIRECT(CAPT_BASE, 0x00);
        vect_capt = (uint8_t)((status >> 1) & 0x7F);

        /* ── Ligne perdue : pivot vers le bon côté ── */
        if (vect_capt == 0x00) {
            integral   = 0.0f;
            last_error = 0.0f;

            if (last_known_error > 0.0f) {
                chercher_gauche();   /* ligne perdue à droite */
            } else if (last_known_error < 0.0f) {
                chercher_droite();   /* ligne perdue à gauche */
            } else {
                stop_moteurs();
            }
            continue;
        }

        /* ── Calcul position ── */
        sum_position = 0;
        count        = 0;
        if (vect_capt & (1 << 0)) { sum_position += -3; count++; }
        if (vect_capt & (1 << 1)) { sum_position += -2; count++; }
        if (vect_capt & (1 << 2)) { sum_position += -1; count++; }
        if (vect_capt & (1 << 3)) { sum_position +=  0; count++; }
        if (vect_capt & (1 << 4)) { sum_position +=  1; count++; }
        if (vect_capt & (1 << 5)) { sum_position +=  2; count++; }
        if (vect_capt & (1 << 6)) { sum_position +=  3; count++; }

        error            = (float)sum_position / (float)count;
        last_known_error = error;

        /* ── PID ── */
        integral  += error;
        if (integral >  INTEGRAL_MAX) integral =  INTEGRAL_MAX;
        if (integral <  INTEGRAL_MIN) integral =  INTEGRAL_MIN;
        derivative = error - last_error;
        output     = (KP * error) + (KI * integral) + (KD * derivative);
        last_error = error;

        /* ── Vitesses ── */
        left_speed  = (uint32_t)(BASE_SPEED - output);
        right_speed = (uint32_t)(BASE_SPEED + output);

        if (left_speed  > SPEED_MAX) left_speed  = SPEED_MAX;
        if (right_speed > SPEED_MAX) right_speed = SPEED_MAX;
        if (left_speed  < SPEED_MIN) left_speed  = SPEED_MIN;
        if (right_speed < SPEED_MIN) right_speed = SPEED_MIN;

        set_moteur_droit (1, FORWARD, right_speed);
        set_moteur_gauche(1, FORWARD, left_speed);
    }

    return 0;
}