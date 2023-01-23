#include <stdio.h>
#include <stdlib.h>
#include "./nimlib/nimlib.h"

#define NUM_ROWS 5

int main(void) {
    Nim* nim = createNim(NUM_ROWS);
    printf("\n");
    printf("Initial board:\n");
    printNim(nim);
    printf("\n");

    
    Nimply* move;
    unsigned int player = 1;
    unsigned int a = 0;
    while(isNotEnded(nim) && a == 0) {
        a++;
        move = minmax(nim);
        nimming(nim, move);
        player = 1 - player;
        printf("Minmax - (%d, %d)\n", move->row, move->numSticks);
        printNim(nim);
        printf("\n");
        destroyNimply(move);

        if (isNotEnded(nim)) {
            randomStrategy(nim, true);
            player = 1 - player;
        }
    }

    printf(player == 0 ? "Minmax won!\n" : "Random won!\n");
    
    destroyNim(nim);
    return 0;
}
