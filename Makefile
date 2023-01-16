CC=nvcc

gpu: gpu_out
	./nim.out

gpu_out: gpu_make
	$(CC) main.o nim.o utils.o agents.o -o nim.out

gpu_make: main.cu ./nimlib_GPU/nim.cu ./nimlib_GPU/utils.cu ./nimlib_GPU/agents.cu
	$(CC) main.cu ./nimlib_GPU/nim.cu ./nimlib_GPU/utils.cu ./nimlib_GPU/agents.cu -dc

.PHONY: cpu clear

cpu: cpu_out
	./nim.out

cpu_out: cpu_make
	$(CC) main.o nim.o utils.o agents.o -o nim.out

cpu_make: main.cu ./nimlib/nim.cpp ./nimlib/utils.cpp ./nimlib/agents.cpp
	$(CC) main.cu ./nimlib/nim.cpp ./nimlib/utils.cpp ./nimlib/agents.cpp -dc

clear:
	rm -f nim.out main.o agents.o nim.o utils.o