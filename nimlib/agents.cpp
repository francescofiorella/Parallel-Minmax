#include <stdlib.h>
#include <cstdio>
#include <time.h>
#include "nim.h"

void randomStrategy(Nim* nim) {
    srand(time(NULL));
    MovesArray* moves = possibleMoves(nim);

    if (moves->numMoves < 1) {
        fprintf(stderr, "There are no moves available!\n");
        exit(1);
    }
    int r = rand() % moves->numMoves;
    nimming(nim, moves->moves[r]);

    destroyMovesArray(moves);
}
