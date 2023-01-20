#pragma once

#include <stdbool.h>

// represent the move to be performed on Nim

__host__ __device__ void printNimply(unsigned char nimply);
__host__ __device__ void printNim(unsigned int nim, unsigned int numRows);
__host__ __device__ void printMovesArray(unsigned char movesArray[]);

unsigned int createNim(unsigned int numRows);
__host__ __device__ bool isNotEnded(unsigned int nim);
__host__ __device__ unsigned int nimming(unsigned int nim, unsigned int numRows, unsigned char nimply);
__host__ __device__ unsigned char possibleMoves(unsigned int nim, unsigned int numRows, unsigned char* output, int index);
__host__ __device__ unsigned int nim_sum(unsigned int nim, unsigned int numRows);
