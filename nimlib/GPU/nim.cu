#include <cstdio>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "nim.cuh"

__host__ __device__ void printNimply(Nimply* nimply) {
    printf("Row: %d, Num: %d\n", nimply->row, nimply->numSticks);
}

void destroyNim(Nim* nim) {
    if (nim) {
        if (nim->rows) {
            free(nim->rows);
        }
        free(nim);
    }
}

void createNim(Nim* output, unsigned int* rows, unsigned int numRows) {
    // unsigned int rows[numRows]; // check if it is ok or it needs to be passed as argument
    output->numRows = numRows;
    output->turn = 0;
    for (int i = 0; i < numRows; i++) {
        rows[i] = i * 2 + 1;
    }
    output->rows = rows;
}

__device__ void deepcopyNim(Nim* nim, Nim* output, unsigned int* outputRows) {
    output->numRows = nim->numRows;
    output->turn = nim->turn;
    for (int i = 0; i < nim->numRows; i++) {
        outputRows[i] = nim->rows[i];
    }
    output->rows = outputRows;
}

__host__ __device__ bool isNotEnded(Nim* nim) {
    unsigned int sum = 0;
    for (int i = 0; i < nim->numRows; i++) {
        sum = sum + nim->rows[i];
    }
    return sum != 0;
}

__host__ __device__ void printRows(Nim* nim) {
    printf("Rows: %d", nim->rows[0]);
    for (int i = 1; i < nim->numRows; i++) {
        printf(", %d", nim->rows[i]);
    }
    printf("\n");
}

__host__ __device__ void nimming(Nim* nim, Nimply* nimply) {
    if (nim->numRows <= nimply->row) {
        printf("Not enougth rows!\n");
        return;
    }
    if (nim->rows[nimply->row] < nimply->numSticks) {
        printf("Not enougth sticks!\n");
        return;
    }
    if (nimply->numSticks < 1) {
        printf("Not a valid move!\n");
        return;
    }
    nim->rows[nimply->row] = nim->rows[nimply->row] - nimply->numSticks;
    nim->turn = 1 - nim->turn;
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
