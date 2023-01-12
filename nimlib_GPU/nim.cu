#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <cmath>
#include <cuda_runtime.h>
#include "nim.cuh"

void printNimply(Nimply* nimply) {
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

void createNim(Nim* output, unsigned int numRows) {
    unsigned int rows[numRows]; // check if it is ok or it needs to be passed as argument
    output->numRows = numRows;
    output->turn = 0;
    output->rows = rows;
    for (int i = 0; i < numRows; i++) {
        output->rows[i] = i * 2 + 1;
    }
}

__device__ void deepcopyNim(Nim* nim, Nim* output, unsigned int* outputRows) {
    output->numRows = nim->numRows;
    output->turn = nim->turn;
    output->rows = outputRows;
    for (int i = 0; i < nim->numRows; i++) {
        output->rows[i] = nim->rows[i];
    }
}

__device__ bool isNotEnded(Nim* nim) {
    unsigned int sum = 0;
    for (int i = 0; i < nim->numRows; i++) {
        sum = sum + nim->rows[i];
    }
    return sum != 0;
}

bool isNotEnded(Nim* nim) {
    unsigned int sum = 0;
    for (int i = 0; i < nim->numRows; i++) {
        sum = sum + nim->rows[i];
    }
    return sum != 0;
}

void printRows(Nim* nim) {
    printf("Rows: %d", nim->rows[0]);
    for (int i = 1; i < nim->numRows; i++) {
        printf(", %d", nim->rows[i]);
    }
    printf("\n");
}

__device__ void nimming(Nim* nim, Nimply* nimply) {
    if (nim->numRows <= nimply->row) {
        fprintf(stderr, "Not enougth rows!\n");
        exit(1);
    }
    if (nim->rows[nimply->row] < nimply->numSticks) {
        fprintf(stderr, "Not enougth sticks!\n");
        exit(1);
    }
    if (nimply->numSticks < 1) {
        fprintf(stderr, "Not a valid move!\n");
        exit(1);
    }
    nim->rows[nimply->row] = nim->rows[nimply->row] - nimply->numSticks;
    nim->turn = 1 - nim->turn;
}

__device__ void possibleMoves(Nim* nim, MovesArray* output) {
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
