#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <cmath>
#include <cuda_runtime.h>
#include "./nimlib/nim.h"
#include "./nimlib/agents.h"
#include "./nimlib/utils.h"
#include "nim.cuh"

__global__ void GPU_minmax(Nim* nim, unsigned int* rows, Nimply* ply) {
    // Associate rows to nim
    nim->rows = rows;

    // Associate thread id and block id
    unsigned int bid = blockIdx.x;
    unsigned int tid = threadIdx.x;

    ResultArray* results;
    MovesArray* moves;

    unsigned int maxMoves = nim->numRows * nim->numRows;

    // resulve bug of global variables

    if (bid == 0 && tid == 0) {
        // initialize the global output
        // the max number of results is equal to the available moves => the max num of moves is rows^2
        results = GPU_createResultArray(maxMoves);
        
        // calculate the first moves
        moves = GPU_possibleMoves(nim);
    }

    __syncthreads();

    if (bid >= moves->numItems) {
        return;
    }

    __syncthreads();

    if (tid == 0) {
        // calculate the new board and invert the current player
        Nim* newBoard = GPU_deepcopyNim(nim);
        // select the move from bid
        // calculate the resulting board for the current move
        GPU_nimming(newBoard, moves->array[bid]);

        // check if the game is ended

        // create the shared stack (maybe initially use another global stack)
        unsigned int maxStackSize = 100000; /* TODO */
        // the max number of evaluations is equal to the available moves => the max num of moves is rows^2
        Stack* stack;
        StackEntry* entry;
        stack = GPU_createStack(maxStackSize);
        // entry = GPU_createStackEntry(NULL, 0, 0, 0, 0, NULL, NULL);
        // GPU_stackPush(stack, entry);
        entry = GPU_createStackEntry(newBoard, -1, 0, -1, stack->stackSize-1, createResultArray(maxMoves), NULL);
        GPU_stackPush(stack, entry);
    }

    __syncthreads();

    // start to calculate, one move for each thread

    // when all secondary threads finished
    __syncthreads();

    // calculate the best move from the global results
    ply = GPU_minResultArray(entry->evaluations)->ply;

    // free global results
    GPU_destroyMovesArray(results); // to keep ply

    printf("GPU nimply:\n");
    GPU_printNimply(ply);
}

// let's remove alpha beta pruning and max depth constrains
// push in the stack every move, using the same evaluations pointer
// at every move, push every move below
// use the depth value to discriminate between layers
// until 1024 (!?)
