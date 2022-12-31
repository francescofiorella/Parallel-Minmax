#include <cstdio>
#include <stdlib.h>
#include "nim.h"

Nim* createNim(unsigned int numRows) {
    Nim* nim;
    nim = (Nim*)malloc(sizeof(Nim));
    nim->numRows = numRows;
    nim->turn = 0;
    nim->rows = (unsigned int*)malloc(numRows * sizeof(unsigned int));
    
    if (!nim->rows) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }

    for (int i = 0; i < numRows; i++) {
        nim->rows[i] = i * 2 + 1;
    }

    return nim;
}

void destroyNim(Nim* nim) {
    free(nim->rows);
    free(nim);
}

Nimply* createNimply(unsigned int row, unsigned int numSticks) {
    Nimply* nimply;
    nimply = (Nimply*)malloc(sizeof(Nimply));
    nimply->row = row;
    nimply->numSticks = numSticks;
    return nimply;
}

void destroyNimply(Nimply* nimply) {
    free(nimply);
}

bool isNotEnded(Nim* nim) {
    unsigned int sum = 0;
    for (int i = 0; i < nim->numRows; i++) {
        sum = sum + nim->rows[i];
    }
    return sum != 0;
}

void nimming(Nim* nim, Nimply* nimply) {
    if (nim->numRows <= nimply->row) {
        fprintf(stderr, "Not enougth rows!\n");
        exit(1);
    }
    if (nim->rows[nimply->row] < nimply->numSticks) {
        fprintf(stderr, "Not enougth sticks!\n");
        exit(1);
    }
    if (nimply->numSticks < 1) {
        fprintf(stderr, "Not a valid move!\n");
        exit(1);
    }
    nim->rows[nimply->row] = nim->rows[nimply->row] - nimply->numSticks;
    nim->turn = 1 - nim->turn;
}

void destroyMovesArray(MovesArray* movesArray) {
    for (int i = 0; i < movesArray->numMoves; i++) {
        destroyNimply(movesArray->moves[i]);
    }
    free(movesArray);
}

MovesArray* possibleMoves(Nim* nim) {
    MovesArray* movesArray;
    movesArray = (MovesArray*)malloc(sizeof(MovesArray));

    unsigned int maxMoves = nim->numRows * nim->numRows;
    movesArray->moves = (Nimply**)malloc(maxMoves * sizeof(Nimply*));
    if (!movesArray->moves) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }

    unsigned int index = 0;
    for (int r = 0; r < nim->numRows; r++) {
        unsigned int c = nim->rows[r];
        for (int o = 1; o <= c; o++) {
            movesArray->moves[index] = createNimply(r, o);
            index++;
        }
    }
    movesArray->numMoves = index;
    return movesArray;
}

void printRows(Nim* nim) {
    printf("Rows: %d", nim->rows[0]);
    for (int i = 1; i < nim->numRows; i++) {
        printf(", %d", nim->rows[i]);
    }
    printf("\n");
}
