CC=nvcc

.PHONY: clear v0 v1

clear:
	rm -f nim.out main.o agents.o nim.o utils.o

v0: v0_out
	./nim.out

v0_out: v0_make
	$(CC) main.o nim.o utils.o agents.o -gencode arch=compute_53,code=sm_53 -o nim.out

v0_make: ./v0/main.cu ./v0/nimlib/nim.cpp ./v0/nimlib/utils.cpp ./v0/nimlib/agents.cpp
	$(CC) ./v0/main.cu ./v0/nimlib/nim.cpp ./v0/nimlib/utils.cpp ./v0/nimlib/agents.cpp -gencode arch=compute_53,code=sm_53 -dc

v1: v1_out
	./nim.out

v1_out: v1_make
	$(CC) main.o nim.o utils.o agents.o -gencode arch=compute_53,code=sm_53 -o nim.out

v1_make: ./v1/main.cu ./v1/nimlib/nim.cu ./v1/nimlib/utils.cu ./v1/nimlib/agents.cu
	$(CC) ./v1/main.cu ./v1/nimlib/nim.cu ./v1/nimlib/utils.cu ./v1/nimlib/agents.cu -gencode arch=compute_53,code=sm_53 -dc

v2: v2_out
	./nim.out

v2_out: v2_make
	$(CC) main.o nim.o utils.o agents.o -gencode arch=compute_53,code=sm_53 -o nim.out

v2_make: ./v2/main.cu ./v2/nimlib/nim.cu ./v2/nimlib/utils.cu ./v2/nimlib/agents.cu
	$(CC) ./v2/main.cu ./v2/nimlib/nim.cu ./v2/nimlib/utils.cu ./v2/nimlib/agents.cu -gencode arch=compute_53,code=sm_53 -dc
