#pragma once

#include "./nimlib/nim.h"
#include "./nimlib/agents.h"
#include "./nimlib/utils.h"

__global__ void GPU_minmax(Nim* nim, unsigned int* rows, Nimply* ply);

__device__ Nimply* GPU_createNimply(unsigned int row, unsigned int numSticks);
__device__ void GPU_destroyNimply(Nimply* nimply);
__device__ void GPU_printNimply(Nimply* nimply);
__device__ Nim* GPU_deepcopyNim(Nim* nim);
__device__ void GPU_printRows(Nim* nim);
__device__ void GPU_nimming(Nim* nim, Nimply* nimply);
__device__ MovesArray* GPU_possibleMoves(Nim* nim);
__device__ void GPU_destroyMovesArray(MovesArray* moves);

__device__ Result* GPU_createResult(Nimply* ply, int val);
__device__ void GPU_destroyResult(Result* result);
__device__ ResultArray* GPU_createResultArray(unsigned int maxSize);
__device__ void GPU_destroyResultArray(ResultArray* resultArray);
__device__ Result* GPU_minResultArray(ResultArray* resultArray);
__device__ StackEntry* GPU_createStackEntry(Nim* board, int alpha, int beta, int player, int depth, int plyIndex, int stackIndex, ResultArray* evaluations, Result* result);
__device__ void GPU_destroyStackEntry(StackEntry* stackEntry);
__device__ Stack* GPU_createStack(unsigned int maxSize);
__device__ void GPU_destroyStack(Stack* stack);
__device__ void GPU_stackPush(Stack* stack, StackEntry* stackEntry);
__device__ StackEntry* GPU_stackPop(Stack* stack);
