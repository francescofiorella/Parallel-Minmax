#pragma once

#include "utils.cuh"

__global__ void GPU_minmax(Nim* nim, ResultArray* results, Result* resultArray, MovesArray* moves, Nimply* plys, Nimply* ply);
__device__ void standard_minmax(Nim* nim, int player, unsigned int tid, Result* sharedResults);

void randomStrategy(Nim* nim, bool print);
