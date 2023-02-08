# Nim: parallelized MinMax

This repo contains the project developed for the final exam of the GPU Programming master's course at Politecnico di Torino.

The aim is to create a parallel version of the minmax algorithm for Nim, developed during the [Computational Intelligence](https://github.com/squillero/computational-intelligence) course; the [original implementation](https://github.com/francescofiorella/computational_intelligence_2022_2023/tree/main/lab3) of the algorithm was written in Python, and has been adapted to C and CUDA in an iterative form (instead of a recursive).

The project is meant to be run on the Nvidia Jetson Nano; however it can be easily adapted to any kind of GPU.<br>
The report folder contains:
- An [abstract](./report/abstract.pdf).
- A [report](./report/report.pdf).
- A [presentation](./report/presentation.pdf).

The project can be run by executing the following commands:
- `make v0`
- `make v1`
- `make v2`
- `make v3`
- `make v4`

V0 can be executed on the CPU, while all the other versions can be executed only on a GPU device.

It is possible to compile without running by using:
- `make v0_make`
- `make v1_out`
- `make v2_out`
- `make v3_out`
- `make v4_out`

The makefile also contains some commands to produce some statistics:
- `make v0log`
- `make v1log`
- `make v2log`
- `make v3log`
- `make v4log`
- `make logs`

Finally, `make clear` removes all the object files from the folder.
