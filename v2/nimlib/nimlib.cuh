#pragma once

#include "utils.cuh"

__global__ void GPU_minmax(unsigned int nim, unsigned int numRows, ResultArray* results, Result* resultArray, MovesArray* moves, Nimply* plys, Nimply* ply);
__device__ void standard_minmax(unsigned int nim, unsigned int numRows, int player, unsigned int tid, Result* sharedResults);

unsigned int randomStrategy(unsigned int nim, unsigned int numRows, bool print);
