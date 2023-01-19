#include <cstdio>
#include <stdlib.h>
#include <cuda_runtime.h>
#include "nimlib.cuh"

__global__ void GPU_minmax(unsigned int nim, unsigned int numRows, ResultArray* results, Result* resultArray, MovesArray* moves, Nimply* plys, Nimply* ply) {
    // Associate arrays to classes
    results->array = resultArray;
    moves->array = plys;

    const unsigned int maxMoves = 25; 

    // Associate thread id and block id
    unsigned int bid = blockIdx.x;
    unsigned int tid = threadIdx.x;

    unsigned int stopComputation = 0;
    // stopComputation values:
    // 0 - Keep calculating
    // 1 - Calculate only the global result
    // 2 - Calculate the shared and the global result
    
    // if (bid == 0 && tid == 0) {
    //     // initialize the global output
    //     // the max number of results is equal to the available moves => the max num of moves is rows^2
        
    //     // calculate the first moves
    //     possibleMoves(nim, moves);
    //     results->numItems = moves->numItems;
    // }
    
    // __syncthreads();
    
    if (bid >= moves->numItems)
        return;
    
    __syncthreads();
    
    __shared__ MovesArray sharedMoves;
    __shared__ Nimply sharedPlys[maxMoves];
    sharedMoves.array = sharedPlys;
    
    __shared__ unsigned int sharedBoard;
    __shared__ int sharedPlayer;
    sharedPlayer = 1;
    if (tid == 0) {
        // calculate the new board and invert the current player
        // sharedBoard = nim;
        // select the move from bid
        // calculate the resulting board for the current move
        sharedBoard = nimming(nim, numRows, &(moves->array[bid]));
        sharedPlayer = 1 - sharedPlayer;

        // check if the game is ended, if yes update the results
        if (!isNotEnded(sharedBoard)) {
            Result res;
            res.ply = moves->array[bid];
            res.val = sharedPlayer;
            results->array[bid] = res;

            // jump to min/max ending evaluation if bid == 0 and tid == 0
            if (bid == 0)
                stopComputation = 1;
        }

        // calculate the new moves on shared array
        possibleMoves(sharedBoard, numRows, &sharedMoves);
    }

    __syncthreads();

    // works also if nim is ended
    if (stopComputation == 0 && tid >= sharedMoves.numItems)
        return;

    // __syncthreads();

    // declare Nim for this thread
    unsigned int newBoard;
    int player = sharedPlayer;
    __shared__ ResultArray sharedResults;
    __shared__ Result sharedResultArray[maxMoves];
    if (stopComputation == 0) {
        sharedResults.array = sharedResultArray;
        sharedResults.numItems = sharedMoves.numItems;

        // apply tid move
        newBoard = nimming(sharedBoard, numRows, &(sharedMoves.array[tid]));
        player = 1 - player;

        // check if nim is ended
        if (!isNotEnded(newBoard)) {
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
        standard_minmax(newBoard, numRows, player, tid, sharedResults.array);

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

    __syncthreads();

    // calculate the best move from the global results
    Result lastResult;
    minResultArray(results, &lastResult);
    ply->row = lastResult.ply.row;
    ply->numSticks = lastResult.ply.numSticks;
}

// let's remove alpha beta pruning and max depth constrains
// push in the stack every move, using the same evaluations pointer
// at every move, push every move below
// use the depth value to discriminate between layers
// until 1024 (!?)

// modify the algorithm in order to perform one evaluation per thread, or
// use the same algorithm but run it several times in different threads



// bid e tid 0
// calcola mosse per nim originale
// inizializza vettore risultati [results]

// un bid per ogni mossa [25]

// tid 0
// applica mossa bid
// controlla se terminato -> se si, aggiungi a results
// inverti player
// calcola mosse per nuova board

// tid da 0 a 25
// applica mossa tid
// controlla se terminato -> se si, aggiungi a [?]
// inverti player
// fai partire loop per ogni thread

// sharedResults is the output
__device__ void standard_minmax(unsigned int nim, unsigned int numRows, int player, unsigned int tid, Result* sharedResults) {
    // printf("IN!\n");
    const unsigned int maxStackSize = 1000; /* TODO */
    const unsigned int maxMoves = 25; 

    // init the stack
    Stack stack;
    stack.stackSize = 0;
    StackEntry entries[maxStackSize];
    stack.array = entries;
    
    // push the very first empty entry
    stackPush(&stack, maxStackSize, 0, 0, 0, 0, 0, 0, 0, NULL, NULL);

    // push the first meaningful entry
    ResultArray evaluations;
    Result evaluationsArray[maxMoves];
    evaluations.array = evaluationsArray;
    evaluations.numItems = 0;
    stackPush(&stack, maxStackSize, nim, -1, 1, 1, 0, -1, stack.stackSize-1, &evaluations, NULL);

    StackEntry entry;
    
    // while there are moves to evaluate
    while (stack.stackSize > 1) {
        __syncthreads();

        stackPop(&stack, &entry);

        // stop if the max depth was reached
        if (entry.depth > 5) {
            Result res;
            // res.val = nim_sum(entry.board, numRows) == 0 ? entry.player : -entry.player;
            res.val = -entry.player;
            stack.array[entry.stackIndex].result = res;
            continue;
        }
        // stop if the game ended
        if (!isNotEnded(entry.board)) {
            Result res;
            res.val = entry.player;
            stack.array[entry.stackIndex].result = res;
            continue;
        }
        // calculate the posible moves
        MovesArray moves;
        Nimply plys[maxMoves];
        moves.array = plys;
        possibleMoves(entry.board, numRows, &moves);
        __syncthreads();
        // use the calculated result if it's not the first move
        if (entry.plyIndex != -1) {
            // exploit the previous result calculation
            int val = entry.result.val;
            resultArrayPush(&(entry.evaluations), maxMoves, &(moves.array[entry.plyIndex]), val);
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
        unsigned int newBoard;
        if (moves.array[entry.plyIndex+1].numSticks == 0) printNim(entry.board, numRows);
        newBoard = nimming(entry.board, numRows, &(moves.array[entry.plyIndex+1]));
        // push the previous state
        stackPush(&stack, maxStackSize, entry.board, entry.alpha, entry.beta, entry.player, entry.depth, entry.plyIndex + 1, entry.stackIndex, &(entry.evaluations), &(entry.result));
        __syncthreads();
        // push the current state (after making the move)
        ResultArray evaluations_;
        Result evaluationsArray_[maxMoves];
        evaluations_.array = evaluationsArray_;
        evaluations_.numItems = 0;
        stackPush(&stack, maxStackSize, newBoard, entry.alpha, entry.beta, -(entry.player), entry.depth + 1, -1, stack.stackSize - 1, &evaluations_, NULL);
    }
    stackPop(&stack, &entry);
    // printEntry(&entry);
    // push the result into the shared results
    sharedResults[tid] = entry.result;
}

unsigned int randomStrategy(unsigned int nim, unsigned int numRows, bool print) {
    MovesArray* moves;
    moves = (MovesArray*)malloc(sizeof(MovesArray));
    if (!moves) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }

    unsigned int maxMoves = numRows * numRows;
    Nimply array[maxMoves];
    moves->array = array;
    possibleMoves(nim, numRows, moves);

    if (moves->numItems < 1) {
        fprintf(stderr, "There are no moves available!\n");
        exit(1);
    }
    
    srand(time(NULL));
    int r = rand() % moves->numItems;
    Nimply* ply = &(moves->array[r]);
    nim = nimming(nim, numRows, ply);
    if (print){
        printf("Random - (%d, %d)\n", ply->row, ply->numSticks);
        printNim(nim, numRows);
        printf("\n");
    } 

    free(moves);
    return nim;
}
