#pragma once

#include "nim.h"

typedef struct {
    Nimply* ply;
    int val;
} Result;

typedef struct {
    unsigned int maxSize, numItems;
    Result** array;
} ResultArray;

typedef struct {
    Nim* board;
    int alpha, beta, player, depth, plyIndex, stackIndex;
    ResultArray* evaluations;
    Result* result;
} StackEntry;

typedef struct {
    unsigned int maxSize, stackSize;
    StackEntry** array;
} Stack;


Result* createResult(Nimply* ply, int val);
void destroyResult(Result* result);

ResultArray* createResultArray(unsigned int maxSize);
void destroyResultArray(ResultArray* resultArray);
void resultArrayPush(ResultArray* resultArray, Result* result);
Result* minResultArray(ResultArray* resultArray);
Result* maxResultArray(ResultArray* resultArray);

StackEntry* createStackEntry(Nim* board, int alpha, int beta, int player, int depth, int plyIndex, int stackIndex, ResultArray* evaluations, Result* result);
void destroyStackEntry(StackEntry* stackEntry);

Stack* createStack(unsigned int maxSize) ;
void destroyStack(Stack* stack);
void stackPush(Stack* stack, StackEntry* stackEntry);
StackEntry* stackPop(Stack* stack);
