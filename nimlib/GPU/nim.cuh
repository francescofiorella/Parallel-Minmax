#pragma once

#include <stdbool.h>

typedef struct {
    unsigned int numRows;
    unsigned int rows[5];
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

__host__ __device__ void printNimply(Nimply* nimply);
__host__ __device__ void printNim(Nim* nim);
__device__ void printMovesArray(MovesArray* movesArray);

void createNim(Nim* output, unsigned int numRows);
__device__ void deepcopyNim(Nim* nim, Nim* output);
__host__ __device__ bool isNotEnded(Nim* nim);
__host__ __device__ void nimming(Nim* nim, Nimply* nimply);
__host__ __device__ void possibleMoves(Nim* nim, MovesArray* output);
__host__ __device__ bool nim_sum(Nim* nim);
