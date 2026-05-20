#include <stdio.h>
#include "system.h"
#include "io.h"

#define CAPT_BASE   CAPTEURS_AVALON_INTERFACE_0_BASE
#define NIVEAU      50

/* Délai court basé sur des NOP */
void delay_ms(unsigned int ms) {
    volatile unsigned int i, j;
    for (i = 0; i < ms; i++)
        for (j = 0; j < 5000; j++);
}

int main(void) {
    unsigned int status, val03, val46;
    unsigned char vect_capt;
    unsigned char data[7];
    int i;

    printf("=== Polling capteurs ===\n");
    printf("Niveau : %d\n\n", NIVEAU);
    fflush(stdout);

    IOWR_32DIRECT(CAPT_BASE, 0x00, (NIVEAU & 0xFF) << 8);

    while (1) {

        delay_ms(10);

        status    = IORD_32DIRECT(CAPT_BASE, 0x00);
        vect_capt = (status >> 1) & 0x7F;

        val03 = IORD_32DIRECT(CAPT_BASE, 0x04);
        val46 = IORD_32DIRECT(CAPT_BASE, 0x08);

        data[0] = (val03 >>  0) & 0xFF;
        data[1] = (val03 >>  8) & 0xFF;
        data[2] = (val03 >> 16) & 0xFF;
        data[3] = (val03 >> 24) & 0xFF;
        data[4] = (val46 >>  0) & 0xFF;
        data[5] = (val46 >>  8) & 0xFF;
        data[6] = (val46 >> 16) & 0xFF;

        printf("vect=0x%02X | ", vect_capt);
        for (i = 0; i < 7; i++)
            printf("%c ", (vect_capt >> i) & 1 ? 'X' : '.');
        printf("| C0=%3d C1=%3d C2=%3d C3=%3d C4=%3d C5=%3d C6=%3d\n",
               data[0], data[1], data[2], data[3],
               data[4], data[5], data[6]);

        fflush(stdout);
    }

    return 0;
}