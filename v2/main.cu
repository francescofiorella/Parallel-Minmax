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

    unsigned int maxMoves = NUM_ROWS * NUM_ROWS + 1;

    // Creation of the memory pointers
    unsigned char* moves; // the possible moves on the host CPU machine
    unsigned char* dev_moves; // the possible moves for the GPU device
    unsigned char* results;
    unsigned char* dev_results;

    // Initialize nim
    unsigned int nim = createNim(NUM_ROWS);
    printf("\n");
    printf("Initial board:\n");
    printNim(nim, NUM_ROWS);
    printf("\n");

    unsigned int player = 1;

    // Execute the minmax on the GPU device iteratively, until the game ends
    unsigned int a = 0;
    while(isNotEnded(nim) && a ==  0) {
        a++;
        // Allocate the memory on the CPU
        results = (unsigned char*)malloc(maxMoves * sizeof(unsigned char));
        moves = (unsigned char*)malloc(maxMoves * sizeof(unsigned char));
        if (!results || !moves) {
            fprintf(stderr, "malloc failure\n");
            exit(1);
        }
        // results[0] = 16;
        moves[0] = 16;

        // calculate the first level of the tree
        unsigned char numMoves = possibleMoves(nim, NUM_ROWS, moves, -1);

        // Allocate the memory on the GPU
        cudaHandleError( cudaMalloc( (void**)&dev_moves, maxMoves * sizeof(unsigned char) ) );
        cudaHandleError( cudaMalloc( (void**)&dev_results, maxMoves * sizeof(unsigned char) ) );

        // Copy nim to the GPU
        cudaHandleError( cudaMemcpy( dev_moves, moves, maxMoves * sizeof(unsigned char), cudaMemcpyHostToDevice ) );

        // Execute the minmax on the GPU device
        GPU_minmax<<<grid, thread>>>(nim, NUM_ROWS, dev_moves, numMoves, dev_results);
        
        cudaHandleError( cudaPeekAtLastError() );

        // Copy the move back from the GPU to the CPU
        cudaHandleError( cudaMemcpy( results, dev_results, maxMoves * sizeof(unsigned char), cudaMemcpyDeviceToHost ) );

        // Free the memory allocated on the GPU
        cudaFree( dev_moves );
        cudaFree( dev_results );

        // calculate the best move
        unsigned char move = minResultArray(results) & 127;

        // Perform the move
        nim = nimming(nim, NUM_ROWS, move);
        player = 1 - player;

        printf("GPU Minmax - (%d, %d)\n", (move >> 4) & 7, move & 15);
        printNim(nim, NUM_ROWS);
        printf("\n");

        // Free the memory we allocated on the CPU
        free(results);
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
