#include <cstdio>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "nimlib.cuh"

#define NUM_MOVES 25 // NUM_ROWS*NUM_ROW

__global__ void GPU_minmax(Nim* nim, MovesArray* moves, Nimply* plys, ResultArray* results, Result* resultArray) {
    // Associate arrays to classes
    results->array = resultArray;
    results->numItems = moves->numItems;
    moves->array = plys;

    // Associate thread id and block id
    unsigned int bid = blockIdx.x;
    unsigned int tid = threadIdx.x;

    unsigned int stopComputation = 0;
    // stopComputation values:
    // 0 - Keep calculating
    // 1 - Calculate only the global result
    // 2 - Calculate the shared and the global result
    
    if (bid >= moves->numItems)
        return;
    
    __syncthreads();
    
    __shared__ MovesArray sharedMoves;
    __shared__ Nimply sharedPlys[NUM_MOVES];
    sharedMoves.array = sharedPlys;
    
    __shared__ Nim sharedBoard;
    __shared__ int sharedPlayer;
    sharedPlayer = 1;
    if (tid == 0) {
        // calculate the new board and invert the current player
        deepcopyNim(nim, &sharedBoard);
        // select the move from bid
        // calculate the resulting board for the current move
        nimming(&sharedBoard, &(moves->array[bid]));
        sharedPlayer = -sharedPlayer;

        // check if the game is ended, if yes update the results
        if (!isNotEnded(&sharedBoard)) {
            Result res;
            res.ply = moves->array[bid];
            res.val = sharedPlayer;
            results->array[bid] = res;

            // jump to min/max ending evaluation if bid == 0 and tid == 0
            if (bid == 0)
                stopComputation = 1;
        }

        // calculate the new moves on shared array
        possibleMoves(&sharedBoard, &sharedMoves);
    }

    __syncthreads();

    // works also if nim is ended
    if (stopComputation == 0 && tid >= sharedMoves.numItems)
        return;

    Nim newBoard;
    int player = sharedPlayer;
    __shared__ ResultArray sharedResults;
    __shared__ Result sharedResultArray[NUM_MOVES];
    if (stopComputation == 0) {
        sharedResults.array = sharedResultArray;
        sharedResults.numItems = sharedMoves.numItems;

        // declare Nim for this thread
        deepcopyNim(&sharedBoard, &newBoard);
        // apply tid move
        nimming(&newBoard, &(sharedMoves.array[tid]));
        player = -player;

        // check if nim is ended
        if (!isNotEnded(&newBoard)) {
            Result res;
            res.ply = sharedMoves.array[tid];
            res.val = player;
            sharedResults.array[tid] = res;
            
            if (tid != 0)
                return;

            // stop the kernel only if tid != 0 else evaluate all the shared
            stopComputation = 2;
        }
    }

    __syncthreads();

    if (stopComputation == 0) {
        // start to calculate the minmax, store the result in sharedResults
        standard_minmax(&newBoard, player, tid, sharedResults.array);

        if (tid != 0)
            return;
    }

    // when all secondary threads finished
    __syncthreads();

    if (stopComputation != 1) {
        // calculate the best move from the shared results
        Result sharedResult;
        maxResultArray(&sharedResults, &sharedResult);
        results->array[bid] = sharedResult;

        if (bid != 0)
            return;
    }
}

// sharedResults is the output
__device__ void standard_minmax(Nim* nim, int player, unsigned int tid, Result* sharedResults) {
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
    stackPush(&stack, maxStackSize, NULL, 0, 0, 0, 0, 0, 0, NULL, NULL);

    // push the first meaningful entry
    Nim newBoard;
    deepcopyNim(nim, &newBoard);
    ResultArray evaluations;
    Result evaluationsArray[NUM_MOVES];
    evaluations.array = evaluationsArray;
    evaluations.numItems = 0;
    stackPush(&stack, maxStackSize, &newBoard, -1, 1, 1, 0, -1, stack.stackSize-1, &evaluations, NULL);

    StackEntry entry;
    
    // while there are moves to evaluate
    while (stack.stackSize > 1) {
        __syncthreads();

        stackPop(&stack, &entry);

        // stop if the max depth was reached
        if (entry.depth > maxDepth) {
            Result res;
            // res.val = nim_sum(&(entry.board)) ? entry.player : -entry.player;
            res.val = -entry.player;
            stack.array[entry.stackIndex].result = res;
            continue;
        }
        // stop if the game ended
        if (!isNotEnded(&(entry.board))) {
            Result res;
            res.val = entry.player;
            stack.array[entry.stackIndex].result = res;
            continue;
        }
        // calculate the posible moves
        MovesArray moves;
        Nimply plys[NUM_MOVES];
        moves.array = plys;
        possibleMoves(&(entry.board), &moves);
        __syncthreads();
        // use the calculated result if it's not the first move
        if (entry.plyIndex != -1) {
            // exploit the previous result calculation
            int val = entry.result.val;
            resultArrayPush(&(entry.evaluations), NUM_MOVES, &(moves.array[entry.plyIndex]), val);
            // update alpha or beta
            if (entry.player == 1) {
                if (entry.beta > val) entry.beta = val;
            } else {
                if (entry.alpha < val) entry.alpha = val;
            }
            // stop if it's the last move or it's time to prune
            if (entry.plyIndex == moves.numItems - 1 || entry.beta <= entry.alpha) {
                Result r;
                if (entry.player == 1) {
                    minResultArray(&(entry.evaluations), &r);
                } else {
                    maxResultArray(&(entry.evaluations), &r);
                }
                stack.array[entry.stackIndex].result = r;
                continue;
            }
        }
        __syncthreads();
        // evaluate the next move
        deepcopyNim(&(entry.board), &newBoard);
        nimming(&newBoard, &(moves.array[entry.plyIndex+1]));
        // push the previous state
        stackPush(&stack, maxStackSize, &(entry.board), entry.alpha, entry.beta, entry.player, entry.depth, entry.plyIndex + 1, entry.stackIndex, &(entry.evaluations), &(entry.result));
        __syncthreads();
        // push the current state (after making the move)
        ResultArray evaluations_;
        Result evaluationsArray_[NUM_MOVES];
        evaluations_.array = evaluationsArray_;
        evaluations_.numItems = 0;
        stackPush(&stack, maxStackSize, &newBoard, entry.alpha, entry.beta, -(entry.player), entry.depth + 1, -1, stack.stackSize - 1, &evaluations_, NULL);
    }
    stackPop(&stack, &entry);
    // printEntry(&entry);
    // push the result into the shared results
    sharedResults[tid] = entry.result;
}

void randomStrategy(Nim* nim, bool print) {
    MovesArray* moves;
    moves = (MovesArray*)malloc(sizeof(MovesArray));
    if (!moves) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }

    unsigned int numMoves = nim->numRows * nim->numRows;
    Nimply array[numMoves];
    moves->array = array;
    possibleMoves(nim, moves);

    if (moves->numItems < 1) {
        fprintf(stderr, "There are no moves available!\n");
        exit(1);
    }
    
    srand(time(NULL));
    int r = rand() % moves->numItems;
    Nimply* ply = &(moves->array[r]);
    nimming(nim, ply);
    if (print){
        printf("Random - (%d, %d)\n", ply->row, ply->numSticks);
        printNim(nim);
        printf("\n");
    } 

    free(moves);
}
