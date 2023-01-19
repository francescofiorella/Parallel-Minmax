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
    Nimply* move; // the move on the host CPU machine
    Nimply* dev_move; // the move for the GPU device

    ResultArray* results;
    ResultArray* dev_results;
    Result* dev_resultArray;
    MovesArray* moves;
    MovesArray* dev_moves;
    Nimply* dev_plys;

    // Initialize nim
    unsigned int nim = createNim(NUM_ROWS);
    printf("\n");
    printf("Initial board:\n");
    printNim(nim, NUM_ROWS);
    printf("\n");

    unsigned int player = 1;

    unsigned int a = 0;
    // Execute the minmax on the GPU device iteratively, until the game ends
    while(isNotEnded(nim) && a == 0) {
        a++;
        // Allocate the memory on the CPU
        move = (Nimply*)malloc(sizeof(Nimply));
        results = (ResultArray*)malloc(sizeof(ResultArray));
        results->array = (Result*)malloc(NUM_ROWS*NUM_ROWS * sizeof(Result));
        moves = (MovesArray*)malloc(sizeof(MovesArray));
        moves->numItems = 0;
        moves->array = (Nimply*)malloc(NUM_ROWS*NUM_ROWS * sizeof(Nimply));
        if (!move || !results || !results->array || !moves || !moves->array) {
            fprintf(stderr, "malloc failure\n");
            exit(1);
        }

        // calculate the first level of the tree
        possibleMoves(nim, NUM_ROWS, moves);
        results->numItems = moves->numItems;

        // Allocate the memory on the GPU
        cudaHandleError( cudaMalloc( (void**)&dev_move, sizeof(Nimply) ) );
        cudaHandleError( cudaMalloc( (void**)&dev_results, sizeof(ResultArray) ) );
        cudaHandleError( cudaMalloc( (void**)&dev_resultArray, NUM_ROWS*NUM_ROWS * sizeof(Result) ) );
        cudaHandleError( cudaMalloc( (void**)&dev_moves, sizeof(MovesArray) ) );
        cudaHandleError( cudaMalloc( (void**)&dev_plys, NUM_ROWS*NUM_ROWS * sizeof(Nimply) ) );

        // Copy nim to the GPU
        cudaHandleError( cudaMemcpy( dev_results, results, sizeof(ResultArray), cudaMemcpyHostToDevice ) );
        cudaHandleError( cudaMemcpy( dev_resultArray, results->array, NUM_ROWS*NUM_ROWS * sizeof(Result), cudaMemcpyHostToDevice ) );
        cudaHandleError( cudaMemcpy( dev_moves, moves, sizeof(MovesArray), cudaMemcpyHostToDevice ) );
        cudaHandleError( cudaMemcpy( dev_plys, moves->array, NUM_ROWS*NUM_ROWS * sizeof(Nimply), cudaMemcpyHostToDevice ) );

        // Execute the minmax on the GPU device
        GPU_minmax<<<grid, thread>>>(nim, NUM_ROWS, dev_results, dev_resultArray, dev_moves, dev_plys, dev_move);
        
        cudaHandleError( cudaPeekAtLastError() );

        // Copy the move back from the GPU to the CPU
        cudaHandleError( cudaMemcpy( move, dev_move, sizeof(Nimply), cudaMemcpyDeviceToHost ) );

        // Free the memory allocated on the GPU
        cudaFree( dev_results );
        cudaFree( dev_resultArray );
        cudaFree( dev_moves );
        cudaFree( dev_plys );
        cudaFree( dev_move );

        // Perform the move
        nim = nimming(nim, NUM_ROWS, move);
        player = 1 - player;

        printf("GPU Minmax - (%d, %d)\n", move->row, move->numSticks);
        printNim(nim, NUM_ROWS);
        printf("\n");

        // Free the memory we allocated on the CPU
        free(move);
        free(results->array);
        free(results);
        free(moves->array);
        free(moves);

        // The CPU perform a random move
        if (isNotEnded(nim)){
            nim = randomStrategy(nim, NUM_ROWS, true);
            player = 1 - player;
        }
    }

    printf(player == 0 ? "Minmax won!\n" : "Random won!\n");

    return 0;
}
