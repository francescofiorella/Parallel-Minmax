#include <cstdio>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "utils.cuh"

__device__ void printResult(unsigned char result) {
    if (result == 16) {
        printf("Result - void\n");
        return;
    }
    printf("Result - Ply: (%d, %d), Val: %d\n", (result >> 4) & 7, result & 15, (result >> 7) == 0 ? -1 : 1);
}

__device__ void printResultArray(unsigned char* resultArray, unsigned int level) {
    for (int i = 0; i < level; i++) {
        printf("   ");
    }
    if (!resultArray) {
        printf("ResultArray - NULL\n");
        return;
    }
    unsigned char result = resultArray[0];
    if (result == 16) {
        printf("ResultArray - void\n");
        return;
    }
    printf("ResultArray - [\n");
    unsigned int index = 0;
    do {
        printf("   ");
        for (int j = 0; j < level; j++) {
            printf("   ");
        }
        printResult(result);
        index++;
        result = resultArray[index];
    } while (result != 16);
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
    printResultArray(entry->evaluations, 1);
    printf("   ");
    printResult(entry->result);
    printf("} \n");
}

__device__ unsigned char minResultArray(unsigned char results[]) {
    unsigned char result = results[0];
    if (result == 16) {
        printf("Empty resultArray!\n");
        return 16;
    }

    unsigned int min_index = 0;
    int min_val = 2;
    unsigned int index = 0;
    int val;
    do {
        val = result >> 7 == 0 ? -1 : 1;
        if(val < min_val) {
            min_index = index;
            min_val = val;
        }
        index++;
        result = results[index];
    } while (result != 16);
    return results[min_index];
}

__device__ unsigned char maxResultArray(unsigned char results[]) {
    unsigned char result = results[0];
    if (result == 16) {
        printf("Empty resultArray!\n");
        return 16;
    }

    unsigned int max_index = 0;
    int max_val = -2;
    unsigned int index = 0;
    int val;
    do {
        val = result >> 7 == 0 ? -1 : 1;
        if(val > max_val) {
            max_index = index;
            max_val = val;
        }
        index++;
        result = results[index];
    } while (result != 16);
    return results[max_index];
}

__device__ void stackPush(Stack* stack, unsigned int maxStackSize, unsigned int board, int alpha, int beta, int player, int depth, int plyIndex, int stackIndex, unsigned char evaluations[], unsigned char result) {
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
}
