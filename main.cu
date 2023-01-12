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

    // Allocate the memory on the CPU, initialize nim
    nim = (Nim*)malloc(sizeof(Nim));
    nim->rows = (unsigned int*)malloc(NUM_ROWS * sizeof(unsigned int));
    createNim(nim, NUM_ROWS);
    printRows(nim);

    int a = 0;
    // Execute the minmax on the GPU device iteratively, until the game ends
    while(isNotEnded(nim) && a == 0) {
        a++;

        // Allocate the memory on the GPU
        cudaMalloc( (void**)&dev_nim, sizeof(Nim) );
        cudaMalloc( (void**)&dev_rows, NUM_ROWS * sizeof(unsigned int) );
        cudaMalloc( (void**)&dev_move, sizeof(Nimply) );

        // Copy nim to the GPU
        cudaMemcpy( dev_nim, nim, sizeof(Nim), cudaMemcpyHostToDevice );
        cudaMemcpy( dev_rows, nim->rows, NUM_ROWS * sizeof(unsigned int), cudaMemcpyHostToDevice );

        // Execute the minmax on the GPU device
        GPU_minmax<<<grid, thread>>>(dev_nim, dev_rows, dev_move);

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

int main_CPU(void) {
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
}