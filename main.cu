#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <cmath>
#include <cuda_runtime.h>
#include "./nimlib/nim.h"
#include "./nimlib/agents.h"

#define NUM_ROWS 5

int main(void) {
    Nim* nim = createNim(NUM_ROWS);
    printRows(nim);

    
    Nimply* move;
    while(isNotEnded(nim)) {
        move = minmax(nim);
        nimming(nim, move);
        destroyNimply(move);
        printf("Minmax: ");
        printRows(nim);

        if (isNotEnded(nim)) {
            randomStrategy(nim);
            printf("Random: ");
            printRows(nim);
        }
    }
    
    destroyNim(nim);
    return 0;
}
