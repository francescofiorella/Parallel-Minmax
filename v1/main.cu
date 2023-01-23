#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <cmath>
#include <cuda_runtime.h>
#include "./nimlib/nimlib.cuh"

#define NUM_ROWS 5

#define cudaHandleError(ans) {gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true) {
    if (code != cudaSuccess) {
        fprintf(stderr, "GPUerror: %s\nCode: %d\nFile: %s\nLine: %d\n", cudaGetErrorString(code), code, file, line);
        if (abort) exit(code);
    }
}

int main(void) {
    // Setup block size and max block count
    dim3 grid = dim3(NUM_ROWS*NUM_ROWS);
    dim3 thread = dim3(NUM_ROWS*NUM_ROWS);

    // Creation of the memory pointers
    Nim nim; // nim on the host CPU machine
    Nim* dev_nim; // nim for the GPU device

    MovesArray* moves; // the possible moves on the host CPU machine
    MovesArray* dev_moves; // the possible moves for the GPU device
    Nimply* dev_plys;
    ResultArray* results;
    ResultArray* dev_results;
    Result* dev_resultArray;

    // Initialize nim
    createNim(&nim, NUM_ROWS);
    printf("\n");
    printf("Initial board:\n");
    printNim(&nim);
    printf("\n");

    unsigned int player = 1;

    unsigned int a = 0;
    // Execute the minmax on the GPU device iteratively, until the game ends
    while(isNotEnded(&nim) && a == 0) {
        a++;
        // Allocate the memory on the CPU
        moves = (MovesArray*)malloc(sizeof(MovesArray));
        moves->numItems = 0;
        moves->array = (Nimply*)malloc(NUM_ROWS*NUM_ROWS * sizeof(Nimply));
        results = (ResultArray*)malloc(sizeof(ResultArray));
        results->array = (Result*)malloc(NUM_ROWS*NUM_ROWS * sizeof(Result));
        if (!results || !results->array || !moves || !moves->array) {
            fprintf(stderr, "malloc failure\n");
            exit(1);
        }

        // calculate the first level of the tree
        possibleMoves(&nim, moves);
        results->numItems = moves->numItems;

        // Allocate the memory on the GPU
        cudaHandleError( cudaMalloc( (void**)&dev_nim, sizeof(Nim) ) );
        cudaHandleError( cudaMalloc( (void**)&dev_moves, sizeof(MovesArray) ) );
        cudaHandleError( cudaMalloc( (void**)&dev_plys, NUM_ROWS*NUM_ROWS * sizeof(Nimply) ) );
        cudaHandleError( cudaMalloc( (void**)&dev_results, sizeof(ResultArray) ) );
        cudaHandleError( cudaMalloc( (void**)&dev_resultArray, NUM_ROWS*NUM_ROWS * sizeof(Result) ) );

        // Copy nim to the GPU
        cudaHandleError( cudaMemcpy( dev_nim, &nim, sizeof(Nim), cudaMemcpyHostToDevice ) );

        cudaHandleError( cudaMemcpy( dev_moves, moves, sizeof(MovesArray), cudaMemcpyHostToDevice ) );
        cudaHandleError( cudaMemcpy( dev_plys, moves->array, NUM_ROWS*NUM_ROWS * sizeof(Nimply), cudaMemcpyHostToDevice ) );

        // Execute the minmax on the GPU device
        GPU_minmax<<<grid, thread>>>(dev_nim, dev_moves, dev_plys, dev_results, dev_resultArray);
        
        cudaHandleError( cudaPeekAtLastError() );

        // Copy the move back from the GPU to the CPU
        cudaHandleError( cudaMemcpy( results->array, dev_resultArray, NUM_ROWS*NUM_ROWS * sizeof(Result), cudaMemcpyDeviceToHost ) );

        // Free the memory allocated on the GPU
        cudaFree( dev_nim );
        cudaFree( dev_moves );
        cudaFree( dev_plys );
        cudaFree( dev_results );
        cudaFree( dev_resultArray );
        
        // calculate the best move
        Nimply move;
        Result lastResult;
        minResultArray(results, &lastResult);
        move.row = lastResult.ply.row;
        move.numSticks = lastResult.ply.numSticks;

        // Perform the move
        nimming(&nim, &move);
        player = 1 - player;

        printf("GPU Minmax - (%d, %d)\n", move.row, move.numSticks);
        printNim(&nim);
        printf("\n");

        // Free the memory we allocated on the CPU
        free(moves->array);
        free(moves);
        free(results->array);
        free(results);

        // The CPU perform a random move
        if (isNotEnded(&nim)){
            randomStrategy(&nim, true);
            player = 1 - player;
        }
    }

    printf(player == 0 ? "Minmax won!\n" : "Random won!\n");

    return 0;
}
