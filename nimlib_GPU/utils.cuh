#pragma once

#include "nim.cuh"

typedef struct {
    Nimply ply;
    int val;
} Result;

typedef struct {
    unsigned int numItems;
    Result* array;
} ResultArray;

typedef struct {
    Nim* board;
    int alpha, beta, player, depth, plyIndex, stackIndex;
    ResultArray* evaluations;
    Result* result;
} StackEntry;

typedef struct {
    unsigned int stackSize;
    StackEntry* array;
} Stack;

__device__ void resultArrayPush(ResultArray* resultArray, unsigned int maxSize, Result* result);
__device__ void minResultArray(ResultArray* results, Result* output);
__device__ void maxResultArray(ResultArray* resultArray, Result* output);

__device__ void createStackEntry(StackEntry* entry, Nim* board, int alpha, int beta, int player, int depth, int plyIndex, int stackIndex, ResultArray* evaluations, Result* result);
__device__ void stackPush(Stack* stack, unsigned int maxStackSize, StackEntry* stackEntry);
__device__ void stackPop(Stack* stack, StackEntry* entry);
