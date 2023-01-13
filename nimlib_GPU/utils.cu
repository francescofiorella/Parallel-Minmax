#include <cstdio>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "utils.cuh"

__device__ void resultArrayPush(ResultArray* resultArray, unsigned int maxSize, Result* result) {
    if (resultArray->numItems == maxSize) {
        printf("the resultArray size is not enougth!\n");
        return;
    }
    resultArray->array[resultArray->numItems] = *result;
    resultArray->numItems++;
}

__device__ void minResultArray(ResultArray* results, Result* output) {
    if (results->numItems < 1) {
        printf("empty resultArray!\n");
        return;
    }
    output = &(results->array[0]);
    for (int i = 1; i < results->numItems; i++) {
        if ((results->array[i]).val < output->val) {
            output = &(results->array[i]);
        }
    }
}

__device__ void maxResultArray(ResultArray* resultArray, Result* output) {
    if (resultArray->numItems < 1) {
        printf("empty ResultArray!\n");
        return;
    }
    output = &(resultArray->array[0]);
    for (int i = 1; i < resultArray->numItems; i++) {
        if ((resultArray->array[i]).val > output->val) {
            output = &(resultArray->array[i]);
        }
    }
}

__device__ void createStackEntry(StackEntry* entry, Nim* board, int alpha, int beta, int player, int depth, int plyIndex, int stackIndex, ResultArray* evaluations, Result* result) {
    entry->board = board;
    entry->alpha = alpha;
    entry->beta = beta;
    entry->player = player;
    entry->depth = depth;
    entry->plyIndex = plyIndex;
    entry->stackIndex = stackIndex;
    entry->evaluations = evaluations;
    entry->result = result;
}

__device__ void stackPush(Stack* stack, unsigned int maxStackSize, StackEntry* stackEntry) {
    if (stack->stackSize == maxStackSize) {
        printf("the stack size is not enougth!\n");
        return;
    }
    stack->array[stack->stackSize] = *stackEntry;
    stack->stackSize++;
}

__device__ void stackPop(Stack* stack, StackEntry* entry) {
    if (stack->stackSize < 1) {
        printf("the stack is empty!\n");
        return;
    }
    stack->stackSize--;
    entry = &(stack->array[stack->stackSize]);
}
