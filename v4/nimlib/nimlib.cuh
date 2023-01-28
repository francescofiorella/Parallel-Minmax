#pragma once

#include "utils.cuh"

__global__ void GPU_minmax(unsigned int nim, unsigned int numRows, unsigned char* ply);
__device__ void standard_minmax(unsigned int nim, unsigned int numRows, int player, unsigned int tid, unsigned char* sharedResults);

unsigned int randomStrategy(unsigned int nim, unsigned int numRows, bool print);
