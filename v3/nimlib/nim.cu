#include <cstdio>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "nim.cuh"

__host__ __device__ void printNimply(unsigned char nimply) {
    if (!nimply) {
        printf("Nimply - NULL");
        return;
    }
    printf("Nimply - Row: %d, Num: %d\n", (nimply >> 4) & 7, nimply & 15);
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

__host__ __device__ void printMovesArray(unsigned char movesArray[]) {
    unsigned char move = movesArray[0];
    if (move == 16) {
        printf("MovesArray - void\n");
        return;
    }
    printf("MovesArray - [\n");
    unsigned int index = 0;
    do {
        printf("   ");
        printNimply(move);
        index++;
        move = movesArray[index];
    } while (move != 16);
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

__host__ __device__ unsigned int nimming(unsigned int nim, unsigned int numRows, unsigned char nimply) {
    unsigned int row = (nimply >> 4) & 7;
    unsigned int numSticks = nimply & 15;
    if (numSticks < 1) {
        printf("Not a valid move!\n");
        return nim;
    }
    if (numRows <= row) {
        printf("Not enougth rows!\n");
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
        printf("Not enougth sticks!\n");
        return nim;
    }
    unsigned int newMask = 4294967295 ^ (15 << shift);
    sticks = (sticks - numSticks) << shift;
    return (nim & newMask) | sticks;
}

__host__ __device__ unsigned char possibleMoves(unsigned int nim, unsigned int numRows, unsigned char* output, int index) {
    if (numRows > 8) {
        printf("Not a valid number of rows!\n");
        return 0;
    }
    unsigned int shift = 0;
    int i = 0;
    for (unsigned char r = 0; r < numRows; r++) {
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
        for (unsigned char o = 1; o <= c; o++) {
            if (index == -1) {
                output[i] = (r << 4) + o;
            } else if (index == i) {
                return (r << 4) + o;
            }
            i++;
        }
    }
    if (index >= i) {
        if (index > i) printf("Index: %d - I: %d\n", index, i);
        return 16;
    }

    output[i] = 16; // 1 << 4 - row 1, num 0
    return i;
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
