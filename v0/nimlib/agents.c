#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "utils.h"

Nimply* minmax(Nim* nim) {
    Nimply* ply;
    unsigned int maxStackSize = 10;
    // the max number of evaluations is equal to the available moves => the max num of moves is rows^2
    unsigned int maxEvaluationsSize = nim->numRows * nim->numRows;
    Stack* stack = createStack(maxStackSize);
    StackEntry* entry = createStackEntry(NULL, 0, 0, 0, 0, 0, 0, NULL, NULL);
    stackPush(stack, entry);
    entry = createStackEntry(deepcopyNim(nim), -1, 1, 1, 0, -1, stack->stackSize-1, createResultArray(maxEvaluationsSize), NULL);
    stackPush(stack, entry);

    // while there are moves to evaluate
    while (stack->stackSize > 1) {
        entry = stackPop(stack);
        // stop if exceed maximum depth
        if (entry->depth > 7) {
            destroyResult((stack->array[entry->stackIndex])->result);
            (stack->array[entry->stackIndex])->result = createResult(NULL, -entry->player);

            destroyNim(entry->board);
            destroyResult(entry->result);
            free(entry);
            continue;
        }
        
        // stop if the game ended
        if (!isNotEnded(entry->board)) {
            destroyResult((stack->array[entry->stackIndex])->result);

            (stack->array[entry->stackIndex])->result = createResult(NULL, entry->player);

            destroyNim(entry->board);
            destroyResult(entry->result);
            free(entry);
            continue;
        }
        // calculate the posible moves
        MovesArray* moves = possibleMoves(entry->board);
        // use the calculated result if it's not the first move
        if (entry->plyIndex != -1) {
            ply = moves->array[entry->plyIndex];
            // exploit the previous result calculation
            int val = (entry->result)->val;
            resultArrayPush(entry->evaluations, createResult(ply, val));
            // update alpha or beta
            if (entry->player == 1) {
                if (entry->beta > val) entry->beta = val;
            } else {
                if (entry->alpha < val) entry->alpha = val;
            }
            // stop if it's the last move or it's time to prune
            if (entry->plyIndex == moves->numItems - 1 || entry->beta <= entry->alpha) {
                if (entry->player == 1) {
                    (stack->array[entry->stackIndex])->result = minResultArray(entry->evaluations);
                } else {
                    (stack->array[entry->stackIndex])->result = maxResultArray(entry->evaluations);
                }

                // we need to preserve the evaluations
                destroyNim(entry->board);
                destroyResult(entry->result);
                free(entry);
    
                continue;
            }
        }
        // evaluate the next move
        ply = moves->array[entry->plyIndex+1];
        Nim* newBoard = deepcopyNim(entry->board);
        nimming(newBoard, ply);
        // push the previous state
        StackEntry* newEntry = createStackEntry(entry->board, entry->alpha, entry->beta, entry->player, entry->depth, entry->plyIndex + 1, entry->stackIndex, entry->evaluations, entry->result);
        stackPush(stack, newEntry);
        // push the current state (after making the move)
        newEntry = createStackEntry(newBoard, entry->alpha, entry->beta, -(entry->player), entry->depth + 1, -1, stack->stackSize - 1, createResultArray(maxEvaluationsSize), NULL);
        stackPush(stack, newEntry);
        free(entry);
        destroyMovesArray(moves);
    }
    entry = stackPop(stack);
    ply = (entry->result)->ply;

    // there is no need to destroy all the entry, because the pointers are set to NULL
    // also, we need to preserve the Nimply object of the result
    free(entry->result);
    free(entry);
    destroyStack(stack);

    return ply;
}

void randomStrategy(Nim* nim, bool print) {
    MovesArray* moves = possibleMoves(nim);

    if (moves->numItems < 1) {
        fprintf(stderr, "There are no moves available!\n");
        exit(1);
    }
    
    srand(time(NULL));
    int r = rand() % moves->numItems;
    Nimply* ply = moves->array[r];
    nimming(nim, ply);
    if (print){
        printf("Random - (%d, %d)\n", ply->row, ply->numSticks);
        printNim(nim);
        printf("\n");
    } 

    destroyMovesArray(moves);
}
