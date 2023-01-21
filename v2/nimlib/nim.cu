#include <cstdio>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "nim.cuh"

__host__ __device__ void printNimply(Nimply* nimply) {
    if (!nimply) {
        printf("Nimply - NULL");
        return;
    }
    printf("Nimply - Row: %d, Num: %d\n", nimply->row, nimply->numSticks);
}

__host__ __device__ void printNim(unsigned int nim, unsigned int numRows) {
    if (numRows > 8) {
        printf("Not a valid number of rows!\n");
        return;
    }
    printf("Nim - %d", nim & 1);
    unsigned int shift = 0;
    for (unsigned int i = 1; i < numRows; i++) {
        unsigned int mask;
        switch(i) {
            case 1: // 3
                mask = 3;
                break;
            case 2: // 5
                mask = 7;
                break;
            case 3: // 7
                mask = 7;
                break;
            default: // > 7
                mask = 15;
        }
        shift += 4;
        printf(", %d", (nim >> shift) & mask);
    }
    printf("\n");
}

__host__ __device__ void printMovesArray(MovesArray* movesArray) {
    if (!movesArray || !movesArray->array) {
        printf("MovesArray - NULL\n");
        return;
    }
    if (movesArray->numItems == 0) {
        printf("MovesArray - void");
        return;
    }
    printf("MovesArray - [\n");
    for (int i = 0; i < movesArray->numItems; i++) {
        printf("   Row: %d, Num: %d\n", movesArray->array[i].row, movesArray->array[i].numSticks);
    }
    printf("]\n");
}

unsigned int createNim(unsigned int numRows) {
    if (numRows > 8) {
        printf("Not a valid number of rows!\n");
        return 0;
    }
    unsigned int nim = 0;
    unsigned int shift = 0;
    for (unsigned int i = 0; i < numRows; i++) {
        unsigned int num = i * 2 + 1;
        nim += (num << shift);
        shift += 4;
    }
    return nim;
}

__host__ __device__ bool isNotEnded(unsigned int nim) {
    return nim != 0;
}

__host__ __device__ unsigned int nimming(unsigned int nim, unsigned int numRows, Nimply* nimply) {
    unsigned int row = nimply->row;
    unsigned int numSticks = nimply->numSticks;
    if (numSticks < 1) {
        printf("Not a valid move!\n");
        return nim;
    }
    if (numRows <= row) {
        printf("Not enough rows!\n");
        return nim;
    }

    unsigned int mask;
    switch(row) {
        case 0:
            mask = 1;
            break;
        case 1:
            mask = 3;
            break;
        case 2:
            mask = 7;
            break;
        case 3:
            mask = 7;
            break;
        default:
            mask = 15;
    }
    unsigned int shift = 4 * row;

    unsigned int sticks = (nim >> shift) & mask;
    if (sticks < numSticks) {
        printf("Not enough sticks!\n");
        return nim;
    }
    unsigned int newMask = 4294967295 ^ (15 << shift);
    sticks = (sticks - numSticks) << shift;
    return (nim & newMask) | sticks;
}

__host__ __device__ void possibleMoves(unsigned int nim, unsigned int numRows, MovesArray* output) {
    if (numRows > 8) {
        printf("Not a valid number of rows!\n");
        return;
    }
    unsigned int shift = 0;
    unsigned int index = 0;
    for (unsigned int r = 0; r < numRows; r++) {
        unsigned int mask;
        switch(r) {
            case 0: // 1
                mask = 1;
                break;
            case 1: // 3
                mask = 3;
                break;
            case 2: // 5
                mask = 7;
                break;
            case 3: // 7
                mask = 7;
                break;
            default: // > 7
                mask = 15;
        }
        unsigned int c = (nim >> shift) & mask;
        shift += 4;
        for (int o = 1; o <= c; o++) {
            output->array[index].row = r;
            output->array[index].numSticks = o;
            index++;
        }
    }
    output->numItems = index;
}

__host__ __device__ unsigned int nim_sum(unsigned int nim, unsigned int numRows) {
    if (numRows > 8) {
        printf("Not a valid number of rows!\n");
        return false;
    }
    unsigned int nim_sum = nim & 1;
    unsigned int shift = 0;
    for (unsigned int i = 1; i < numRows; i++) {
        unsigned int mask;
        switch(i) {
            case 1: // 3
                mask = 3;
                break;
            case 2: // 5
                mask = 7;
                break;
            case 3: // 7
                mask = 7;
                break;
            default: // > 7
                mask = 15;
        }
        shift += 4;
        nim_sum ^= ((nim >> shift) & mask);
    }
    return nim_sum; 
}
