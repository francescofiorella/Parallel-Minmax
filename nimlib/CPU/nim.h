#pragma once

#include <stdbool.h>

typedef struct {
    unsigned int turn, numRows;
    // if turn == 0 then player 1 should move
    // if turn == 1 then player 2 should move
    unsigned int* rows;
    // rows is a vector that contains
    // the number of sticks remaining for each row
} Nim;

// represent the move to be performed on Nim
typedef struct {
    unsigned int row, numSticks;
} Nimply;

typedef struct {
    unsigned int numItems;
    Nimply** array;
} MovesArray;

Nimply* createNimply(unsigned int row, unsigned int numSticks);
void destroyNimply(Nimply* nimply);
void printNimply(Nimply* nimply);

Nim* createNim(unsigned int numRows);
void destroyNim(Nim* nim);
Nim* deepcopyNim(Nim* nim);
bool isNotEnded(Nim* nim);
void printRows(Nim* nim);
void nimming(Nim* nim, Nimply* nimply);
MovesArray* possibleMoves(Nim* nim);

void destroyMovesArray(MovesArray* moves);
