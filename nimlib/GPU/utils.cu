#include <cstdio>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "utils.cuh"

__device__ void printResult(Result* result) {
    if (!result) {
        printf("Result: NULL");
        return;
    }
    printf("Result:\n");
    printNimply(&(result->ply));
    printf("Val: %d\n", result->val);
}

__device__ void printResultArray(ResultArray* resultArray) {}
__device__ void printEntry(StackEntry* entry) {}

__device__ void resultArrayPush(ResultArray* resultArray, unsigned int maxSize, Nimply* ply, int val) {
    if (resultArray->numItems == maxSize) {
        printf("the resultArray size is not enougth!\n");
        return;
    }
    unsigned int index = resultArray->numItems;
    resultArray->array[index].ply = *ply;
    resultArray->array[index].val = val;
    resultArray->numItems++;
}

__device__ void minResultArray(ResultArray* results, Result* output) {
    if (results->numItems < 1) {
        printf("empty resultArray!\n");
        return;
    }
    unsigned int min_index = 0;
    int min_val = results->array[0].val;
    for (int i = 1; i < results->numItems; i++) {
        if ((results->array[i]).val < min_val) {
            min_index = i;
            min_val = (results->array[i]).val;
        }
    }
    output->ply = (results->array[min_index]).ply;
    output->val = min_val;
}

__device__ void maxResultArray(ResultArray* results, Result* output) {
    if (results->numItems < 1) {
        printf("empty ResultArray!\n");
        return;
    }
    unsigned int max_index = 0;
    int max_val = results->array[0].val;
    for (int i = 1; i < results->numItems; i++) {
        if ((results->array[i]).val > max_val) {
            max_index = i;
            max_val = (results->array[i]).val;
        }
    }
    output->ply = (results->array[max_index]).ply;
    output->val = max_val;
}

__device__ void stackPush(Stack* stack, unsigned int maxStackSize, Nim* board, int alpha, int beta, int player, int depth, int plyIndex, int stackIndex, ResultArray* evaluations, Result* result) {
    if (stack->stackSize == maxStackSize) {
        printf("the stack size is not enougth!\n");
        return;
    }
    unsigned int index = stack->stackSize;
    stack->array[index].board = board;
    stack->array[index].alpha = alpha;
    stack->array[index].beta = beta;
    stack->array[index].player = player;
    stack->array[index].depth = depth;
    stack->array[index].plyIndex = plyIndex;
    stack->array[index].stackIndex = stackIndex;
    stack->array[index].evaluations = evaluations;
    stack->array[index].result = result;
    stack->stackSize++;
}

__device__ void stackPop(Stack* stack, StackEntry* entry) {
    if (stack->stackSize < 1) {
        printf("the stack is empty!\n");
        return;
    }
    stack->stackSize--;
    unsigned int index = stack->stackSize;
    entry->board = stack->array[index].board;
    entry->alpha = stack->array[index].alpha;
    entry->beta = stack->array[index].beta;
    entry->player = stack->array[index].player;
    entry->depth = stack->array[index].depth;
    entry->plyIndex = stack->array[index].plyIndex;
    entry->stackIndex = stack->array[index].stackIndex;
    entry->evaluations = stack->array[index].evaluations;
    entry->result = stack->array[index].result;
    printf("Inner evaluations:\n");
    printf("%d\n", entry->evaluations->numItems);
}
