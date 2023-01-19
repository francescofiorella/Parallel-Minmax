CC=nvcc

v3: v3_out
	./v3.out

v3_out: v3_make
	$(CC) main.o nim.o utils.o agents.o -gencode arch=compute_53,code=sm_53 -o v3.out

v3_make: ./v3/main.cu ./v3/nimlib/nim.cu ./v3/nimlib/utils.cu ./v3/nimlib/agents.cu
	$(CC) ./v3/main.cu ./v3/nimlib/nim.cu ./v3/nimlib/utils.cu ./v3/nimlib/agents.cu -gencode arch=compute_53,code=sm_53 -dc

.PHONY: clear v0 v1 v2

v2: v2_out
	./v2.out

v2_out: v2_make
	$(CC) main.o nim.o utils.o agents.o -gencode arch=compute_53,code=sm_53 -o v2.out

v2_make: ./v2/main.cu ./v2/nimlib/nim.cu ./v2/nimlib/utils.cu ./v2/nimlib/agents.cu
	$(CC) ./v2/main.cu ./v2/nimlib/nim.cu ./v2/nimlib/utils.cu ./v2/nimlib/agents.cu -gencode arch=compute_53,code=sm_53 -dc

v1: v1_out
	./v1.out

v1_out: v1_make
	$(CC) main.o nim.o utils.o agents.o -gencode arch=compute_53,code=sm_53 -o v1.out

v1_make: ./v1/main.cu ./v1/nimlib/nim.cu ./v1/nimlib/utils.cu ./v1/nimlib/agents.cu
	$(CC) ./v1/main.cu ./v1/nimlib/nim.cu ./v1/nimlib/utils.cu ./v1/nimlib/agents.cu -gencode arch=compute_53,code=sm_53 -dc

v0: v0_out
	./v0.out

v0_out: v0_make
	$(CC) main.o nim.o utils.o agents.o -gencode arch=compute_53,code=sm_53 -o v0.out

v0_make: ./v0/main.cu ./v0/nimlib/nim.cpp ./v0/nimlib/utils.cpp ./v0/nimlib/agents.cpp
	$(CC) ./v0/main.cu ./v0/nimlib/nim.cpp ./v0/nimlib/utils.cpp ./v0/nimlib/agents.cpp -gencode arch=compute_53,code=sm_53 -dc

clear:
	rm -f main.o agents.o nim.o utils.o
