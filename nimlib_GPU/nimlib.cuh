#pragma once

#include "utils.cuh"

__global__ void GPU_minmax(Nim* nim, unsigned int* rows, Nimply* ply);
__device__ void standard_minmax(Nim* nim, int player, unsigned int tid, ResultArray sharedResults);
