#include <cstdio>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "utils.cuh"

__device__ void printResult(Result* result) {
    if (!result) {
        printf("Result - NULL\n");
        return;
    }
    printf("Result - Ply: (%d, %d), Val: %d\n", result->ply.row, result->ply.numSticks, result->val);
}

__device__ void printResultArray(ResultArray* resultArray, unsigned int level) {
    for (int i = 0; i < level; i++) {
        printf("   ");
    }
    if (!resultArray || !resultArray->array) {
        printf("ResultArray - NULL\n");
        return;
    }
    if (resultArray->numItems == 0) {
        printf("ResultArray - void\n");
        return;
    }
    printf("ResultArray - [\n");
    for (int i = 0; i < resultArray->numItems; i++) {
        printf("   ");
        for (int j = 0; j < level; j++) {
            printf("   ");
        }
        printResult(&(resultArray->array[i]));
    }
    for (int i = 0; i < level; i++) {
        printf("   ");
    }
    printf("]\n");
}
__device__ void printEntry(StackEntry* entry, unsigned int numRows) {
    if (numRows > 8) {
        printf("Not a valid number of rows!\n");
        return;
    }
    if (!entry) {
        printf("StackEntry - NULL\n");
        return;
    }
    printf("StackEntry - {\n");
    printf("   ");
    printNim(entry->board, numRows);
    printf("   Alpha: %d, Beta: %d, Player: %d\n", entry->alpha, entry->beta, entry->player);
    printf("   Depth: %d, PlyIndex: %d, StackIndex: %d\n", entry->depth, entry->plyIndex, entry->stackIndex);
    printResultArray(&(entry->evaluations), 1);
    printf("   ");
    printResult(&(entry->result));
    printf("} \n");
}

__device__ void resultArrayPush(ResultArray* resultArray, unsigned int maxSize, Nimply* ply, int val) {
    if (resultArray->numItems == maxSize) {
        printf("the resultArray size is not enough!\n");
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

__device__ void stackPush(Stack* stack, unsigned int maxStackSize, unsigned int board, int alpha, int beta, int player, int depth, int plyIndex, int stackIndex, ResultArray* evaluations, Result* result) {
    if (stack->stackSize == maxStackSize) {
        printf("the stack size is not enough!\n");
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
    if (evaluations) stack->array[index].evaluations = *evaluations;
    if (result) stack->array[index].result = *result;
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
}
