#pragma once

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
    Nimply* array;
} MovesArray;

void printNimply(Nimply* nimply);
void createNim(Nim* output, unsigned int numRows);
void destroyNim(Nim* nim);
__device__ void deepcopyNim(Nim* nim, Nim* output, , unsigned int* outputRows);
__device__ bool isNotEnded(Nim* nim);
bool isNotEnded(Nim* nim);
void printRows(Nim* nim);
__device__ void nimming(Nim* nim, Nimply* nimply);
__device__ void possibleMoves(Nim* nim, MovesArray* output);
