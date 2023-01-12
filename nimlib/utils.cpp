#include <stdlib.h>
#include <cstdio>
#include "utils.h"

Result* createResult(Nimply* ply, int val) {
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

void destroyResult(Result* result) {
    if (result) {
        destroyNimply(result->ply);
        free(result);
    }
}

ResultArray* createResultArray(unsigned int maxSize) {
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

void destroyResultArray(ResultArray* resultArray) {
    if (resultArray) {
        if (resultArray->numItems > 0) {
            for (int i = resultArray->numItems + 1; i >= 0; i--) {
                destroyResult(resultArray->array[i]);
            }
        }
        if (resultArray->array) {
            free(resultArray->array);
        }
        free(resultArray);
    }
}

void resultArrayPush(ResultArray* resultArray, Result* result) {
    if (resultArray->numItems == resultArray->maxSize) {
        // allocate more memory
        resultArray->maxSize = 2 * resultArray->maxSize;
        Result** temp = resultArray->array;
        resultArray->array = (Result**)malloc(resultArray->maxSize * sizeof(Result*));
        if (!resultArray->array) {
            fprintf(stderr, "malloc failure\n");
            exit(1);
        }
        for (int i = resultArray->numItems-1; i >= 0; i--) {
            resultArray->array[i] = temp[i];
        }
        free(temp);
    }
    resultArray->array[resultArray->numItems] = result;
    resultArray->numItems++;
}

Result* minResultArray(ResultArray* resultArray) {
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

Result* maxResultArray(ResultArray* resultArray) {
    if (resultArray->numItems < 1) {
        fprintf(stderr, "Empty ResultArray!\n");
        exit(1);
    }
    Result* max = resultArray->array[0];
    for (int i = 1; i < resultArray->numItems; i++) {
        if ((resultArray->array[i])->val > max->val) {
            max = (resultArray->array[i]);
        }
    }
    return max;
}

StackEntry* createStackEntry(Nim* board, int alpha, int beta, int player, int depth, int plyIndex, int stackIndex, ResultArray* evaluations, Result* result) {
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

void destroyStackEntry(StackEntry* stackEntry) {
    if (stackEntry) {
        destroyNim(stackEntry->board);
        destroyResultArray(stackEntry->evaluations);
        destroyResult(stackEntry->result);
        free(stackEntry);
    }
}

Stack* createStack(unsigned int maxSize) {
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

void destroyStack(Stack* stack) {
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

void stackPush(Stack* stack, StackEntry* stackEntry) {
    if (stack->stackSize == stack->maxSize) {
        // allocate more memory
        stack->maxSize = 2 * stack->maxSize;
        StackEntry** temp = stack->array;
        stack->array = (StackEntry**)malloc(stack->maxSize * sizeof(StackEntry*));
        if (!stack->array) {
            fprintf(stderr, "malloc failure\n");
            exit(1);
        }
        for (int i = stack->stackSize-1; i >= 0; i--) {
            stack->array[i] = temp[i];
        }
        free(temp);
    }
    stack->array[stack->stackSize] = stackEntry;
    stack->stackSize++;
}

StackEntry* stackPop(Stack* stack) {
    if (stack->stackSize < 1) {
        fprintf(stderr, "The stack is empty!\n");
        exit(1);
    }
    stack->stackSize--;
    StackEntry* entry = stack->array[stack->stackSize];
    stack->array[stack->stackSize] = NULL;
    return entry;
}
