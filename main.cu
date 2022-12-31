#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <cmath>
#include <cuda_runtime.h>
#include "./nimlib/nim.h"
#include "./nimlib/agents.h"

#define NUM_ROWS 3

int main(void) {
    Nim* nim = createNim(NUM_ROWS);
    printRows(nim);

    randomStrategy(nim);

    printRows(nim);

    destroyNim(nim);
    return 0;
}
