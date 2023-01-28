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
    unsigned char* ply;
    unsigned char* dev_ply;

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
        ply = (unsigned char*)malloc(sizeof(unsigned char));
        if (!ply) {
            fprintf(stderr, "malloc failure\n");
            exit(1);
        }

        // Allocate the memory on the GPU
        cudaHandleError( cudaMalloc( (void**)&dev_ply, sizeof(unsigned char) ) );

        // Execute the minmax on the GPU device
        GPU_minmax<<<grid, thread>>>(nim, NUM_ROWS, dev_ply);
        
        cudaHandleError( cudaPeekAtLastError() );

        // Copy the move back from the GPU to the CPU
        cudaHandleError( cudaMemcpy( ply, dev_ply, sizeof(unsigned char), cudaMemcpyDeviceToHost ) );

        // Free the memory allocated on the GPU
        cudaFree( dev_ply );

        // Perform the move
        nim = nimming(nim, NUM_ROWS, *ply);
        player = 1 - player;

        printf("GPU Minmax - (%d, %d)\n", (*ply >> 4) & 7, *ply & 15);
        printNim(nim, NUM_ROWS);
        printf("\n");

        // Free the memory we allocated on the CPU
        free(ply);

        // The CPU perform a random move
        if (isNotEnded(nim)){
            nim = randomStrategy(nim, NUM_ROWS, true);
            player = 1 - player;
        }
    }

    printf(player == 0 ? "Minmax won!\n" : "Random won!\n");

    return 0;
}
