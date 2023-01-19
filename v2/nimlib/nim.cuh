#pragma once

#include <stdbool.h>

// represent the move to be performed on Nim
typedef struct {
    unsigned int row, numSticks;
} Nimply;

typedef struct {
    unsigned int numItems;
    Nimply* array;
} MovesArray;

__host__ __device__ void printNimply(Nimply* nimply);
__host__ __device__ void printNim(unsigned int nim, unsigned int numRows);
__host__ __device__ void printMovesArray(MovesArray* movesArray);

unsigned int createNim(unsigned int numRows);
__host__ __device__ bool isNotEnded(unsigned int nim);
__host__ __device__ unsigned int nimming(unsigned int nim, unsigned int numRows, Nimply* nimply);
__host__ __device__ void possibleMoves(unsigned int nim, unsigned int numRows, MovesArray* output);
__host__ __device__ unsigned int nim_sum(unsigned int nim, unsigned int numRows);
