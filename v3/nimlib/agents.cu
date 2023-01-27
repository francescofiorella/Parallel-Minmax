#include <cstdio>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <math.h>
#include "nimlib.cuh"

__global__ void GPU_minmax(unsigned int nim, unsigned int numRows, unsigned char* moves, unsigned char numPlys, unsigned char* results) {
    const unsigned int maxMoves = 26; // + 1 for the ending code (16)

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

    // const unsigned int totArrays = maxMoves + (maxMoves - 1) * (maxMoves - 1); // 1 + n + n^2
    const unsigned int totArrays = maxMoves; // 1 + n

    __shared__ unsigned char sharedResults[totArrays][maxMoves];
    __shared__ unsigned char sharedMoves[totArrays][maxMoves];
    __shared__ unsigned char sharedNumPlys[totArrays];
    __shared__ unsigned int sharedBoards[totArrays];

    /* Level 0 */
    // player = 1;

    if (tid == 0) {
        // calculate the new board and invert the current player
        // select the move from bid
        // calculate the resulting board for the current move
        unsigned char move = moves[bid];
        unsigned int newBoard = nimming(nim, numRows, move);
        // player = -1;

        // check if the game is ended, if yes update the results
        if (!isNotEnded(newBoard)) {
            // 0 -> -1
            // 1 -> 1
            results[bid] = 0 + (move & 127);

            sharedNumPlys[0] = 0;

            // if bid == 0 and tid == 0 => should put 16 in the last element
            if (bid == 0)
                stopComputation = 1;
        }

        // calculate the new moves on shared array
        sharedBoards[0] = newBoard;
        sharedNumPlys[0] = possibleMoves(newBoard, numRows, sharedMoves[0], -1);
    }

    __syncthreads();

    /* Level 1 */
    // player = -1;
    unsigned int l1_index;
    unsigned int shift;
    if (tid < maxMoves-1) {
        l1_index = tid + 1;
        shift = 0;
    } else {
        l1_index = (tid - (maxMoves - 1)) / (maxMoves - 2) + 1;
        shift = (tid - (maxMoves - 1)) % (maxMoves - 2) + 1;
    }

    __syncthreads();

    if (stopComputation == 0 && tid < sharedNumPlys[0]) {
        // apply tid move
        unsigned char move = sharedMoves[0][tid];
        unsigned int newBoard = nimming(sharedBoards[0], numRows, move);
        // player = 1;

        // check if nim is ended
        if (!isNotEnded(newBoard)) {
            sharedResults[0][tid] = 128 + (move & 127);
            sharedNumPlys[l1_index] = 0;

            // jump to min/max evaluation            
            if (tid == 0)
                stopComputation = 2;
        }

        sharedBoards[l1_index] = newBoard;
        sharedNumPlys[l1_index] = possibleMoves(newBoard, numRows, sharedMoves[l1_index], -1);
    }

    __syncthreads();

    /* Level 2 */
    // player = 1;

    // unsigned int l2_index = tid + 1 + maxMoves-1; // from 26 to 651
    // if (bid == 1) printf("T %d - SH %d - L1 %d - Num %d\n", tid, shift, l1_index, sharedNumPlys[l1_index]);
    unsigned int newBoard = 0;
    if (stopComputation == 0 && sharedNumPlys[l1_index] > shift) {
        unsigned char move = sharedMoves[l1_index][shift];
        newBoard = nimming(sharedBoards[l1_index], numRows, move);
        // player = -1;

        // check if nim is ended
        if (!isNotEnded(newBoard)) {
            sharedResults[l1_index][shift] = 128 + (move & 127);
            // sharedNumPlys[l2_index] = 0;

            // jump to min/max evaluation            
            if (tid == 0)
                stopComputation = 3;
        }
        // sharedNumPlys[l2_index] = possibleMoves(newBoard, numRows, sharedMoves[l2_index], -1);
        // sharedBoards[l2_index] = newBoard;
    }

    /* Level 3 */
    // player = -1;
    // Can be done in global memory [we don't have enough threads]
    
    __syncthreads();

    if (stopComputation == 0 && newBoard != 0) {
        // start to calculate the minmax, store the result in sharedResults
        standard_minmax(newBoard, numRows, -1, shift, sharedResults[l1_index]);
    }

    if (tid >= sharedNumPlys[0])
        return;

    if (stopComputation != 2) {
        // calculate the best move from the shared results
        sharedResults[l1_index][sharedNumPlys[l1_index]] = 16;
        sharedResults[0][shift] = minResultArray(sharedResults[l1_index]);
    }

    __syncthreads();
    
    if (tid != 0)
        return;

    if (stopComputation != 1) {
        // calculate the best move from the shared results
        sharedResults[0][sharedNumPlys[0]] = 16;
        results[bid] = maxResultArray(sharedResults[0]);
    }

    __syncthreads();

    if (bid != 0) return;

    // insert the termination char
    results[numPlys] = 16;
}

// sharedResults is the output
__device__ void standard_minmax(unsigned int nim, unsigned int numRows, int player, unsigned int tid, unsigned char* sharedResults) {
    const unsigned int maxMoves = 26;
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
    unsigned char evaluations[maxStackSize-1][maxMoves];
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
