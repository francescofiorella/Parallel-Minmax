#pragma once

#include <stdbool.h>

/*
Nim is now an unsigned integer, composed by 32 bit:
Each row is represented by a group of 4 bit, starting from the LSB.
In this way, a Nim board with maximum eight rows can be represented,
which can be increased to 16 by using the unsigned long long type.
*/

/*
The Nimply struct is now an unsigned char, and has been unified with the Result.
- the first four LSB represent the number of sticks to be removed (0 - 15),
- the following three represent the row index (0 - 7),
- and the last one is the value (of the result).
The value bit is set to 0 for val == -1, and to 1 for val == 1.
This representation is perfect for Nim board with maximum eigth rows;
for higher rows number, an unsigned int type can be used.
*/

__host__ __device__ void printNimply(unsigned char nimply);
__host__ __device__ void printNim(unsigned int nim, unsigned int numRows);
__host__ __device__ void printMovesArray(unsigned char movesArray[]);

unsigned int createNim(unsigned int numRows);
__host__ __device__ bool isNotEnded(unsigned int nim);
__host__ __device__ unsigned int nimming(unsigned int nim, unsigned int numRows, unsigned char nimply);
__host__ __device__ unsigned char possibleMoves(unsigned int nim, unsigned int numRows, unsigned char* output, int index);
__host__ __device__ unsigned int nim_sum(unsigned int nim, unsigned int numRows);
