#include <cstdio>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "nimlib.cuh"

#define NUM_MOVES 26 // NUM_ROWS*NUM_ROWS + 1 (for the termination character)

__device__ __constant__ unsigned char dev_moves[NUM_MOVES]; // the possible moves for the GPU device

__global__ void GPU_minmax(unsigned int nim, unsigned int numRows, unsigned char numPlys, unsigned char* results) {
    // Associate thread id and block id
    unsigned int bid = blockIdx.x;
    unsigned int tid = threadIdx.x;

    unsigned int stopComputation = 0;
    // stopComputation values:
    // 0 - Keep calculating
    // 1 - Calculate only the global result
    // 2 - Calculate the shared and the global result
    
    if (bid >= numPlys)
        return;
    
    __syncthreads();
    
    __shared__ unsigned char sharedMoves[NUM_MOVES];
    __shared__ unsigned char sharedNumPlys;
    sharedMoves[0] = 16;
    sharedNumPlys = 0;

    __shared__ unsigned int sharedBoard;
    __shared__ int sharedPlayer;
    sharedPlayer = 1;
    if (tid == 0) {
        // calculate the new board and invert the current player
        // select the move from bid
        // calculate the resulting board for the current move
        sharedBoard = nimming(nim, numRows, dev_moves[bid]);
        sharedPlayer = -sharedPlayer;

        // check if the game is ended, if yes update the results
        if (!isNotEnded(sharedBoard)) {
            // 0 -> -1
            // 1 -> 1
            results[bid] = sharedPlayer == -1 ? 0 + (dev_moves[bid] & 127) : 128 + (dev_moves[bid] & 127); // 128 = 1 << 7

            // jump to min/max ending evaluation if bid == 0 and tid == 0
            if (bid == 0)
                stopComputation = 1;
        }

        // calculate the new moves on shared array
        sharedNumPlys = possibleMoves(sharedBoard, numRows, sharedMoves, -1);
    }

    __syncthreads();

    // works also if nim is ended
    if (stopComputation == 0 && tid >= sharedNumPlys)
        return;

    // declare Nim for this thread
    unsigned int newBoard;
    int player = sharedPlayer;
    __shared__ unsigned char sharedResults[NUM_MOVES];
    sharedResults[0] = 16;
    if (stopComputation == 0) {
        // apply tid move
        unsigned char move = sharedMoves[tid];
        newBoard = nimming(sharedBoard, numRows, move);
        player = -player;

        // check if nim is ended
        if (!isNotEnded(newBoard)) {
            sharedResults[tid] = player == -1 ? 0 + (move & 127) : 128 + (move & 127);
            
            if (tid != 0)
                return;

            // stop the kernel only if tid != 0 else evaluate all the shared
            stopComputation = 2;
        }
    }

    __syncthreads();

    if (stopComputation == 0) {
        // start to calculate the minmax, store the result in sharedResults
        standard_minmax(newBoard, numRows, player, tid, sharedResults);
    }

    if (tid != 0)
        return;

    // when all secondary threads finished
    __syncthreads();

    if (stopComputation != 1) {
        // calculate the best move from the shared results
        sharedResults[sharedNumPlys] = 16;
        results[bid] = maxResultArray(sharedResults);
    }

    if (bid != 0)
        return;

    // insert the termination char
    results[numPlys] = 16;
}

// sharedResults is the output
__device__ void standard_minmax(unsigned int nim, unsigned int numRows, int player, unsigned int tid, unsigned char* sharedResults) {
    const unsigned int maxDepth = 5;
    const unsigned int maxStackSize = 8;
    /*
    | Max Depth | Max Stack Size |
    | --------- | -------------- |
    | 1         | 4              |
    | 2         | 5              |
    | 3         | 6              |
    | 4         | 7              |
    | 5         | 8              |
    | 6         | 9              |
    | 7         | 10             |
    */

    // init the stack
    Stack stack;
    stack.stackSize = 0;
    StackEntry entries[maxStackSize];
    stack.array = entries;
    
    // push the very first empty entry
    stackPush(&stack, maxStackSize, 0, 0, 0, 0, 0, 0, 0, NULL, 16);

    // push the first meaningful entry
    unsigned char evaluations[maxStackSize-1][NUM_MOVES];
    evaluations[0][0] = 16;
    stackPush(&stack, maxStackSize, nim, -1, 1, 1, 0, -1, stack.stackSize-1, evaluations[0], 16);

    StackEntry entry;
    
    // while there are moves to evaluate
    while (stack.stackSize > 1) {
        __syncthreads();

        stackPop(&stack, &entry);

        // stop if the max depth was reached
        if (entry.depth > maxDepth) {
            stack.array[entry.stackIndex].result = entry.player == -1 ? 128 : 0;
            continue;
        }
        // stop if the game ended
        if (!isNotEnded(entry.board)) {
            stack.array[entry.stackIndex].result = entry.player == -1 ? 0 : 128;
            continue;
        }
        // calculate the posible moves
        unsigned char curr_move = possibleMoves(entry.board, numRows, NULL, entry.plyIndex+1);
        __syncthreads();
        // use the calculated result if it's not the first move
        if (entry.plyIndex != -1) {
            unsigned char prev_move = possibleMoves(entry.board, numRows, NULL, entry.plyIndex);
            // exploit the previous result calculation
            entry.evaluations[entry.plyIndex] = (entry.result & 128) + prev_move;
            entry.evaluations[entry.plyIndex + 1] = 16;
            int val = entry.result >> 7 == 0 ? -1 : 1;
            // update alpha or beta
            if (entry.player == 1) {
                if (entry.beta > val) entry.beta = val;
            } else {
                if (entry.alpha < val) entry.alpha = val;
            }
            // stop if it's the last move or it's time to prune
            if (curr_move == 16 || entry.beta <= entry.alpha) {
                unsigned char r;
                if (entry.player == 1) {
                    r = minResultArray(entry.evaluations);
                } else {
                    r = maxResultArray(entry.evaluations);
                }
                stack.array[entry.stackIndex].result = r;
                continue;
            }
        }
        __syncthreads();
        // evaluate the next move
        unsigned int newBoard;
        newBoard = nimming(entry.board, numRows, curr_move);
        // push the previous state
        stackPush(&stack, maxStackSize, entry.board, entry.alpha, entry.beta, entry.player, entry.depth, entry.plyIndex + 1, entry.stackIndex, entry.evaluations, entry.result);
        __syncthreads();
        // push the current state (after making the move)
        evaluations[stack.stackSize-1][0] = 16;
        stackPush(&stack, maxStackSize, newBoard, entry.alpha, entry.beta, -(entry.player), entry.depth + 1, -1, stack.stackSize - 1, evaluations[stack.stackSize-1], 16);
    }
    stackPop(&stack, &entry);
    // push the result into the shared results
    sharedResults[tid] = entry.result;
}

unsigned int randomStrategy(unsigned int nim, unsigned int numRows, bool print) {
    unsigned int maxMoves = numRows * numRows + 1;
    unsigned char moves[maxMoves];
    moves[0] = 16;
    unsigned char numMoves = possibleMoves(nim, numRows, moves, -1);

    if (numMoves == 0) {
        fprintf(stderr, "There are no moves available!\n");
        exit(1);
    }
    
    srand(time(NULL));
    int r = rand() % numMoves;
    unsigned char ply = moves[r];
    nim = nimming(nim, numRows, ply);
    if (print){
        printf("Random - (%d, %d)\n", (ply >> 4) & 7, ply & 15);
        printNim(nim, numRows);
        printf("\n");
    } 

    return nim;
}
