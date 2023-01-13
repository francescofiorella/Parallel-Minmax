#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <cmath>
#include <cuda_runtime.h>
// #include "./nimlib/nimlib.h"
#include "./nimlib_GPU/nimlib.cuh"

int main_CPU(void);
int main_GPU(void);

#define NUM_ROWS 5

int main(void) {
    return main_GPU();
}

int main_GPU(void) {
    // remember to include ONLY the GPU library [nimlib_GPU/nimlib.cuh]

    // Setup block size and max block count
    dim3 grid = dim3(NUM_ROWS*NUM_ROWS);
    dim3 thread = dim3(NUM_ROWS*NUM_ROWS);

    // Creation of the memory pointers
    Nim* nim; // nim on the host CPU machine
    Nim* dev_nim; // nim for the GPU device
    unsigned int* dev_rows;
    Nimply* move; // the move on the host CPU machine
    Nimply* dev_move; // the move for the GPU device

    ResultArray* results;
    ResultArray* dev_results;
    Result* dev_resultArray;
    MovesArray* moves;
    MovesArray* dev_moves;
    Nimply* dev_plys;

    // Allocate the memory on the CPU, initialize nim
    nim = (Nim*)malloc(sizeof(Nim));
    unsigned int rows[NUM_ROWS];
    createNim(nim, rows, NUM_ROWS);
    printRows(nim);

    results = (ResultArray*)malloc(sizeof(ResultArray));
    results->numItems = 0;
    results->array = (Result*)malloc(NUM_ROWS*NUM_ROWS * sizeof(Result));
    moves = (MovesArray*)malloc(sizeof(MovesArray));
    moves->numItems = 0;
    moves->array = (Nimply*)malloc(NUM_ROWS*NUM_ROWS * sizeof(Nimply));

    int a = 0;
    // Execute the minmax on the GPU device iteratively, until the game ends
    while(isNotEnded(nim) && a == 0) {
        a++;

        // Allocate the memory on the GPU
        cudaMalloc( (void**)&dev_nim, sizeof(Nim) );
        cudaMalloc( (void**)&dev_rows, NUM_ROWS * sizeof(unsigned int) );
        cudaMalloc( (void**)&dev_move, sizeof(Nimply) );

        cudaMalloc( (void**)&dev_results, sizeof(ResultArray) );
        cudaMalloc( (void**)&dev_resultArray, NUM_ROWS*NUM_ROWS * sizeof(Result) );
        cudaMalloc( (void**)&dev_moves, sizeof(MovesArray) );
        cudaMalloc( (void**)&dev_plys, NUM_ROWS*NUM_ROWS * sizeof(Nimply) );

        // Copy nim to the GPU
        cudaMemcpy( dev_nim, nim, sizeof(Nim), cudaMemcpyHostToDevice );
        cudaMemcpy( dev_rows, nim->rows, NUM_ROWS * sizeof(unsigned int), cudaMemcpyHostToDevice );

        cudaMemcpy( dev_results, results, sizeof(ResultArray), cudaMemcpyHostToDevice );
        cudaMemcpy( dev_resultArray, results->array, NUM_ROWS*NUM_ROWS * sizeof(Result), cudaMemcpyHostToDevice );
        cudaMemcpy( dev_moves, moves, sizeof(MovesArray), cudaMemcpyHostToDevice );
        cudaMemcpy( dev_plys, moves->array, NUM_ROWS*NUM_ROWS * sizeof(Nimply), cudaMemcpyHostToDevice );

        // Execute the minmax on the GPU device
        GPU_minmax<<<grid, thread>>>(dev_nim, dev_rows, dev_results, dev_resultArray, dev_moves, dev_plys, dev_move);

        // Copy the move back from the GPU to the CPU
        cudaMemcpy( move, dev_move, sizeof(Nimply), cudaMemcpyDeviceToHost );

        // Free the memory allocated on the GPU
        cudaFree( dev_rows );
        cudaFree( dev_nim );
        cudaFree( dev_move );

        nimming(nim, move);

        // Free the memory we allocated on the CPU
        free(move);

        printf("GPU Minmax: ");
        printRows(nim);

        // The CPU perform a random move
        if (isNotEnded(nim)) {
            randomStrategy(nim);
            printf("Random: ");
            printRows(nim);
        }
    }
    
    destroyNim(nim);
    return 0;
}

/* int main_CPU(void) {
    // remember to include ONLY the CPU library [nimlib/nimlib.h]

    Nim* nim = createNim(NUM_ROWS);
    printRows(nim);

    
    Nimply* move;
    while(isNotEnded(nim)) {
        move = minmax(nim);
        nimming(nim, move);
        destroyNimply(move);
        printf("Minmax: ");
        printRows(nim);

        if (isNotEnded(nim)) {
            randomStrategy(nim);
            printf("Random: ");
            printRows(nim);
        }
    }
    
    destroyNim(nim);
    return 0;
} */
