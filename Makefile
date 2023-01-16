GPU_CC=nvcc
CPU_CC=gcc

gpu: gpu_out
	./nim.out

gpu_out: gpu_make
	$(GPU_CC) main.o nim.o utils.o agents.o -o nim.out

gpu_make: main.cu ./nimlib/GPU/nim.cu ./nimlib/GPU/utils.cu ./nimlib/GPU/agents.cu
	$(GPU_CC) main.cu ./nimlib/GPU/nim.cu ./nimlib/GPU/utils.cu ./nimlib/GPU/agents.cu -dc

.PHONY: cpu clear

cpu: cpu_out
	./nim.out

cpu_out: cpu_make
	$(CPU_CC) main.o nim.o utils.o agents.o -o nim.out

cpu_make: main.c ./nimlib/CPU/nim.cpp ./nimlib/CPU/utils.cpp ./nimlib/CPU/agents.cpp
	$(CPU_CC) main.c ./nimlib/CPU/nim.cpp ./nimlib/CPU/utils.cpp ./nimlib/CPU/agents.cpp -dc

clear:
	rm -f nim.out main.o agents.o nim.o utils.o