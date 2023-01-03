#include <stdlib.h>
#include <cstdio>
#include <time.h>
#include "utils.h"

void randomStrategy(Nim* nim) {
    MovesArray* moves = possibleMoves(nim);

    if (moves->numItems < 1) {
        fprintf(stderr, "There are no moves available!\n");
        exit(1);
    }
    
    srand(time(NULL));
    int r = rand() % moves->numItems;
    nimming(nim, moves->array[r]);

    destroyMovesArray(moves);
}

Nimply* minmax(Nim* nim) {
    Nimply* ply;
    unsigned int maxStackSize = 100; /*TODO*/
    // the max number of evaluations is equal to the available moves => the max num of moves is rows^2
    unsigned int maxEvaluationsSize = nim->numRows * nim->numRows;
    Stack* stack = createStack(maxStackSize);
    StackEntry* entry = createStackEntry(NULL, 0, 0, 0, 0, 0, 0, NULL, NULL);
    stackPush(stack, entry);
    entry = createStackEntry(deepcopyNim(nim), -1, 1, 1, 0, -1, stack->stackSize-1, createResultArray(maxEvaluationsSize), NULL);
    stackPush(stack, entry);

    while (stack->stackSize > 1) {
        entry = stackPop(stack);
        if (entry->depth > 10) {
            destroyResult((stack->array[entry->stackIndex])->result);
            (stack->array[entry->stackIndex])->result = createResult(NULL, -entry->player);

            destroyNim(entry->board);
            destroyResult(entry->result);
            free(entry);
            continue;
        }
        
        if (!isNotEnded(entry->board)) {
            destroyResult((stack->array[entry->stackIndex])->result);

            (stack->array[entry->stackIndex])->result = createResult(NULL, entry->player);

            destroyNim(entry->board);
            destroyResult(entry->result);
            free(entry);
            continue;
        }
        MovesArray* moves = possibleMoves(entry->board);
        if (entry->plyIndex != -1) {
            ply = moves->array[entry->plyIndex];
            int val = (entry->result)->val;
            resultArrayPush(entry->evaluations, createResult(ply, val));
            if (entry->player == 1) {
                if (entry->beta > val) entry->beta = val;
            } else {
                if (entry->alpha < val) entry->alpha = val;
            }
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
        ply = moves->array[entry->plyIndex+1];
        Nim* newBoard = deepcopyNim(entry->board);
        nimming(newBoard, ply);
        StackEntry* newEntry = createStackEntry(entry->board, entry->alpha, entry->beta, entry->player, entry->depth, entry->plyIndex + 1, entry->stackIndex, entry->evaluations, entry->result);
        stackPush(stack, newEntry);
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