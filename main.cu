#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <cmath>
#include <cuda_runtime.h>
#include "./nimlib/GPU/nimlib.cuh"

#define NUM_ROWS 5

#define gpuErrchk(ans) {gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true) {
    if (code != cudaSuccess) {
        fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) exit(code);
    }
}

int main(void) {
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
    if (!nim) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }
    unsigned int rows[NUM_ROWS];
    createNim(nim, rows, NUM_ROWS);
    printf("\n");
    printf("Initial board:\n");
    printRows(nim);
    printf("\n");

    results = (ResultArray*)malloc(sizeof(ResultArray));
    if (!results) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }
    results->numItems = 0;
    results->array = (Result*)malloc(NUM_ROWS*NUM_ROWS * sizeof(Result));
    if (!results->array) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }
    moves = (MovesArray*)malloc(sizeof(MovesArray));
    if (!moves) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }
    moves->numItems = 0;
    moves->array = (Nimply*)malloc(NUM_ROWS*NUM_ROWS * sizeof(Nimply));
    if (!moves->array) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }

    int a = 0;
    // Execute the minmax on the GPU device iteratively, until the game ends
    while(isNotEnded(nim) && a == 0) {
        a++;

        // calculate the first level of the tree
        possibleMoves(nim, moves);
        results->numItems = moves->numItems;

        // Allocate the memory on the GPU
        gpuErrchk( cudaMalloc( (void**)&dev_nim, sizeof(Nim) ) );
        gpuErrchk( cudaMalloc( (void**)&dev_rows, NUM_ROWS * sizeof(unsigned int) ) );
        gpuErrchk( cudaMalloc( (void**)&dev_move, sizeof(Nimply) ) );

        gpuErrchk( cudaMalloc( (void**)&dev_results, sizeof(ResultArray) ) );
        gpuErrchk( cudaMalloc( (void**)&dev_resultArray, NUM_ROWS*NUM_ROWS * sizeof(Result) ) );
        gpuErrchk( cudaMalloc( (void**)&dev_moves, sizeof(MovesArray) ) );
        gpuErrchk( cudaMalloc( (void**)&dev_plys, NUM_ROWS*NUM_ROWS * sizeof(Nimply) ) );

        // Copy nim to the GPU
        gpuErrchk( cudaMemcpy( dev_nim, nim, sizeof(Nim), cudaMemcpyHostToDevice ) );
        gpuErrchk( cudaMemcpy( dev_rows, nim->rows, NUM_ROWS * sizeof(unsigned int), cudaMemcpyHostToDevice ) );

        gpuErrchk( cudaMemcpy( dev_results, results, sizeof(ResultArray), cudaMemcpyHostToDevice ) );
        gpuErrchk( cudaMemcpy( dev_resultArray, results->array, NUM_ROWS*NUM_ROWS * sizeof(Result), cudaMemcpyHostToDevice ) );
        gpuErrchk( cudaMemcpy( dev_moves, moves, sizeof(MovesArray), cudaMemcpyHostToDevice ) );
        gpuErrchk( cudaMemcpy( dev_plys, moves->array, NUM_ROWS*NUM_ROWS * sizeof(Nimply), cudaMemcpyHostToDevice ) );

        // Execute the minmax on the GPU device
        GPU_minmax<<<grid, thread>>>(dev_nim, dev_rows, dev_results, dev_resultArray, dev_moves, dev_plys, dev_move);
        
        gpuErrchk( cudaPeekAtLastError() );

        // Copy the move back from the GPU to the CPU
        gpuErrchk( cudaMemcpy( move, dev_move, sizeof(Nimply), cudaMemcpyDeviceToHost ) );

        // Free the memory allocated on the GPU
        cudaFree( dev_nim );
        cudaFree( dev_rows );
        cudaFree( dev_results );
        cudaFree( dev_resultArray );
        cudaFree( dev_moves );
        cudaFree( dev_plys );
        cudaFree( dev_move );

        nimming(nim, move);

        // Free the memory we allocated on the CPU
        free(move);
        free(results->array);
        free(results);
        free(moves->array);
        free(moves);

        printf("GPU Minmax:\n");
        printRows(nim);
        printf("\n");

        // The CPU perform a random move
        if (isNotEnded(nim)) {
            randomStrategy(nim);
            printf("Random:\n");
            printRows(nim);
            printf("\n");
        }
    }
    
    destroyNim(nim);
    return 0;
}
