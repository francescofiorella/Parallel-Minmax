#pragma once

typedef struct {
    unsigned int turn, numRows;
    // if turn == 0 then player 1 should move
    // if turn == 1 then player 2 should move
    unsigned int* rows;
    // rows is a vector that contains
    // the number of sticks remaining for each row
} Nim;

// represent the move to be performed on Nim
typedef struct {
    unsigned int row, numSticks;
} Nimply;

typedef struct {
    unsigned int numMoves;
    Nimply** moves;
} MovesArray;

Nim* createNim(unsigned int numRows);

void destroyNim(Nim* nim);

Nimply* createNimply(unsigned int row, unsigned int numSticks);

void destroyNimply(Nimply* nimply);

bool isNotEnded(Nim* nim);

void nimming(Nim* nim, Nimply* nimply);

void destroyMovesArray(MovesArray* movesArray);

MovesArray* possibleMoves(Nim* nim);

void printRows(Nim* nim);
