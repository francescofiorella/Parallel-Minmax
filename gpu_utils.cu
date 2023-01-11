#include <stdlib.h>
#include <cstdio>
#include "nim.cuh"

__device__ Nimply* GPU_createNimply(unsigned int row, unsigned int numSticks) {
    Nimply* nimply;
    nimply = (Nimply*)malloc(sizeof(Nimply));
    nimply->row = row;
    nimply->numSticks = numSticks;
    return nimply;
}

__device__ void GPU_destroyNimply(Nimply* nimply) {
    if (nimply) {
        free(nimply);
    }
}

__device__ void GPU_printNimply(Nimply* nimply) {
    printf("Row: %d, Num: %d\n", nimply->row, nimply->numSticks);
}

__device__ Nim* GPU_deepcopyNim(Nim* nim) {
    Nim* copy;
    copy = (Nim*)malloc(sizeof(Nim));
    copy->numRows = nim->numRows;
    copy->turn = nim->turn;
    copy->rows = (unsigned int*)malloc(nim->numRows * sizeof(unsigned int));
    if (!copy->rows) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }
    for (int i = 0; i < nim->numRows; i++) {
        copy->rows[i] = nim->rows[i];
    }
    return copy;
}

__device__ void GPU_printRows(Nim* nim) {
    printf("Rows: %d", nim->rows[0]);
    for (int i = 1; i < nim->numRows; i++) {
        printf(", %d", nim->rows[i]);
    }
    printf("\n");
}

__device__ void GPU_nimming(Nim* nim, Nimply* nimply) {
    if (nim->numRows <= nimply->row) {
        fprintf(stderr, "Not enougth rows!\n");
        exit(1);
    }
    if (nim->rows[nimply->row] < nimply->numSticks) {
        fprintf(stderr, "Not enougth sticks!\n");
        exit(1);
    }
    if (nimply->numSticks < 1) {
        fprintf(stderr, "Not a valid move!\n");
        exit(1);
    }
    nim->rows[nimply->row] = nim->rows[nimply->row] - nimply->numSticks;
    nim->turn = 1 - nim->turn;
}

__device__ MovesArray* GPU_possibleMoves(Nim* nim) {
    MovesArray* moves;
    moves = (MovesArray*)malloc(sizeof(MovesArray));

    unsigned int maxMoves = nim->numRows * nim->numRows;
    moves->array = (Nimply**)malloc(maxMoves * sizeof(Nimply*));
    if (!moves->array) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }

    unsigned int index = 0;
    for (int r = 0; r < nim->numRows; r++) {
        unsigned int c = nim->rows[r];
        for (int o = 1; o <= c; o++) {
            moves->array[index] = GPU_createNimply(r, o);
            index++;
        }
    }
    moves->numItems = index;
    return moves;
}

__device__ void GPU_destroyMovesArray(MovesArray* moves) {
    if (moves) {
        for (int i = 0; i < moves->numItems; i++) {
            GPU_destroyNimply(moves->array[i]);
        }
        if (moves->array) {
            free(moves->array);
        }
        free(moves);
    }
}

__device__ Result* GPU_createResult(Nimply* ply, int val) {
    Result* result;
    result = (Result*)malloc(sizeof(Result));
    if (!result) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }
    result->ply = ply;
    result->val = val;
    return result;
}

__device__ void GPU_destroyResult(Result* result) {
    if (result) {
        GPU_destroyNimply(result->ply);
        free(result);
    }
}

__device__ ResultArray* GPU_createResultArray(unsigned int maxSize) {
    ResultArray* resultArray;
    resultArray = (ResultArray*)malloc(sizeof(ResultArray));
    if (!resultArray) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }
    resultArray->maxSize = maxSize;
    resultArray->numItems = 0;
    resultArray->array = (Result**)malloc(maxSize * sizeof(Result*));
    if (!resultArray->array) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }
    return resultArray;
}

__device__ void GPU_destroyResultArray(ResultArray* resultArray) {
    if (resultArray) {
        if (resultArray->numItems > 0) {
            for (int i = resultArray->numItems + 1; i >= 0; i--) {
                GPU_destroyResult(resultArray->array[i]);
            }
        }
        if (resultArray->array) {
            free(resultArray->array);
        }
        free(resultArray);
    }
}

__device__ Result* GPU_minResultArray(ResultArray* resultArray) {
    if (resultArray->numItems < 1) {
        fprintf(stderr, "Empty ResultArray!\n");
        exit(1);
    }
    Result* min = resultArray->array[0];
    for (int i = 1; i < resultArray->numItems; i++) {
        if ((resultArray->array[i])->val < min->val) {
            min = (resultArray->array[i]);
        }
    }
    return min;
}

__device__ StackEntry* GPU_createStackEntry(Nim* board, int alpha, int beta, int player, int depth, int plyIndex, int stackIndex, ResultArray* evaluations, Result* result) {
    StackEntry* stackEntry;
    stackEntry = (StackEntry*)malloc(sizeof(StackEntry));
    if (!stackEntry) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }
    stackEntry->board = board;
    stackEntry->alpha = alpha;
    stackEntry->beta = beta;
    stackEntry->player = player;
    stackEntry->depth = depth;
    stackEntry->plyIndex = plyIndex;
    stackEntry->stackIndex = stackIndex;
    stackEntry->evaluations = evaluations;
    stackEntry->result = result;
    return stackEntry;    
}

__device__ void GPU_destroyStackEntry(StackEntry* stackEntry) {
    if (stackEntry) {
        destroyNim(stackEntry->board);
        destroyResultArray(stackEntry->evaluations);
        destroyResult(stackEntry->result);
        free(stackEntry);
    }
}

__device__ Stack* GPU_createStack(unsigned int maxSize) {
    Stack* stack;
    stack = (Stack*)malloc(sizeof(Stack));
    if (!stack) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }
    stack->maxSize = maxSize;
    stack->stackSize = 0;
    stack->array = (StackEntry**)malloc(maxSize * sizeof(StackEntry*));
    if (!stack->array) {
        fprintf(stderr, "malloc failure\n");
        exit(1);
    }
    return stack;
}

__device__ void GPU_destroyStack(Stack* stack) {
    if (stack) {
        if (stack->stackSize > 0) {
            for (int i = stack->stackSize - 1; i >= 0; i--) {
                destroyStackEntry(stack->array[i]);
            }
        }
        if (stack->array) {
            free(stack->array);
        }
        free(stack);
    }
}

__device__ void GPU_stackPush(Stack* stack, StackEntry* stackEntry) {
    /* TODO */
    // if (stack->stackSize == stack->maxSize) {
    //     // allocate more memory
    //     stack->maxSize = 2 * stack->maxSize;
    //     StackEntry** temp = stack->array;
    //     stack->array = (StackEntry**)malloc(stack->maxSize * sizeof(StackEntry*));
    //     if (!stack->array) {
    //         fprintf(stderr, "malloc failure\n");
    //         exit(1);
    //     }
    //     for (int i = stack->stackSize-1; i >= 0; i--) {
    //         stack->array[i] = temp[i];
    //     }
    //     free(temp);
    // }
    stack->array[stack->stackSize] = stackEntry;
    stack->stackSize++;
}

__device__ StackEntry* GPU_stackPop(Stack* stack) {
    if (stack-> stackSize < 1) {
        fprintf(stderr, "The stack is empty!\n");
        exit(1);
    }
    stack->stackSize--;
    StackEntry* entry = stack->array[stack->stackSize];
    stack->array[stack->stackSize] = NULL;
    return entry;
}
