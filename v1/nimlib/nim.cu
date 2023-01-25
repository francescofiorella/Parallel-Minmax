#include <cstdio>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "nim.cuh"

__host__ __device__ void printNimply(Nimply* nimply) {
    if (!nimply) {
        printf("Nimply - NULL\n");
        return;
    }
    printf("Nimply - Row: %d, Num: %d\n", nimply->row, nimply->numSticks);
}

__host__ __device__ void printNim(Nim* nim) {
    if (!nim || ! nim->rows) {
        printf("Nim - NULL");
        return;
    }
    printf("Nim - %d", nim->rows[0]);
    for (int i = 1; i < nim->numRows; i++) {
        printf(", %d", nim->rows[i]);
    }
    printf("\n");
}

__device__ void printMovesArray(MovesArray* movesArray) {
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

void createNim(Nim* output, unsigned int numRows) {
    output->numRows = numRows;
    for (int i = 0; i < numRows; i++) {
        output->rows[i] = i * 2 + 1;
    }
}

__device__ void deepcopyNim(Nim* nim, Nim* output) {
    output->numRows = nim->numRows;
    for (int i = 0; i < nim->numRows; i++) {
        output->rows[i] = nim->rows[i];
    }
}

__host__ __device__ bool isNotEnded(Nim* nim) {
    unsigned int sum = 0;
    for (int i = 0; i < nim->numRows; i++) {
        sum = sum + nim->rows[i];
    }
    return sum != 0;
}

__host__ __device__ void nimming(Nim* nim, Nimply* nimply) {
    if (nim->numRows <= nimply->row) {
        printf("Not enough rows!\n");
        return;
    }
    if (nim->rows[nimply->row] < nimply->numSticks) {
        printf("Not enough sticks!\n");
        return;
    }
    if (nimply->numSticks < 1) {
        printf("Not a valid move!\n");
        return;
    }
    nim->rows[nimply->row] = nim->rows[nimply->row] - nimply->numSticks;
}

__host__ __device__ void possibleMoves(Nim* nim, MovesArray* output) {
    unsigned int index = 0;
    for (int r = 0; r < nim->numRows; r++) {
        unsigned int c = nim->rows[r];
        for (int o = 1; o <= c; o++) {
            Nimply ply;
            ply.row = r;
            ply.numSticks = o;
            output->array[index] = ply;
            index++;
        }
    }
    output->numItems = index;
}

__host__ __device__ bool nim_sum(Nim* nim) {
    int nim_sum = nim->rows[0];
    for (int i = 1; i < nim->numRows; i++) {
        nim_sum ^= nim->rows[i];
    }
    return nim_sum == 0; 
}
