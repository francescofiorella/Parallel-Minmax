CC=nvcc
CPU_CC=gcc

v4: v4_out
	./v4.out

v4_out: v4_make
	$(CC) main.o nim.o utils.o agents.o -gencode arch=compute_53,code=sm_53 -o v4.out

v4_make: ./v4/main.cu ./v4/nimlib/nim.cu ./v4/nimlib/utils.cu ./v4/nimlib/agents.cu
	$(CC) ./v4/main.cu ./v4/nimlib/nim.cu ./v4/nimlib/utils.cu ./v4/nimlib/agents.cu -gencode arch=compute_53,code=sm_53 -dc

.PHONY: v0 v1 v2 v3 logs v0log v1log v2log v3log v4log clear

v3: v3_out
	./v3.out

v3_out: v3_make
	$(CC) main.o nim.o utils.o agents.o -gencode arch=compute_53,code=sm_53 -o v3.out

v3_make: ./v3/main.cu ./v3/nimlib/nim.cu ./v3/nimlib/utils.cu ./v3/nimlib/agents.cu
	$(CC) ./v3/main.cu ./v3/nimlib/nim.cu ./v3/nimlib/utils.cu ./v3/nimlib/agents.cu -gencode arch=compute_53,code=sm_53 -dc


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

v0: v0_make
	./v0.out

v0_make: ./v0/main.c ./v0/nimlib/nim.c ./v0/nimlib/utils.c ./v0/nimlib/agents.c
	$(CPU_CC) ./v0/main.c ./v0/nimlib/nim.c ./v0/nimlib/utils.c ./v0/nimlib/agents.c -o v0.out

clear:
	rm -f main.o agents.o nim.o utils.o v0.out v1.out v2.out v3.out v4.out gmon.out

logs:
	make clear
	make v0log
	make v1log
	make v2log
	make v3log
	make v4log
	make clear

v0log: ./v0/main.c ./v0/nimlib/nim.c ./v0/nimlib/utils.c ./v0/nimlib/agents.c
	$(CPU_CC) ./v0/main.c ./v0/nimlib/nim.c ./v0/nimlib/utils.c ./v0/nimlib/agents.c -pg -o v0.out
	./v0.out
	gprof -b v0.out gmon.out > ./log/v0.log

v1log:
	make v1_out
	sudo nvprof --log-file ./log/v1_summary.log ./v1.out
	sudo nvprof --print-gpu-trace --log-file ./log/v1_trace.log ./v1.out
	sudo nvprof --metrics all --log-file ./log/v1_metrics.log ./v1.out
	sudo nvprof --events all --log-file ./log/v1_events.log ./v1.out

v2log:
	make v2_out
	sudo nvprof --log-file ./log/v2_summary.log ./v2.out
	sudo nvprof --print-gpu-trace --log-file ./log/v2_trace.log ./v2.out
	sudo nvprof --metrics all --log-file ./log/v2_metrics.log ./v2.out
	sudo nvprof --events all --log-file ./log/v2_events.log ./v2.out

v3log:
	make v3_out
	sudo nvprof --log-file ./log/v3_summary.log ./v3.out
	sudo nvprof --print-gpu-trace --log-file ./log/v3_trace.log ./v3.out
	sudo nvprof --metrics all --log-file ./log/v3_metrics.log ./v3.out
	sudo nvprof --events all --log-file ./log/v3_events.log ./v3.out

v4log:
	make v4_out
	sudo nvprof --log-file ./log/v4_summary.log ./v4.out
	sudo nvprof --print-gpu-trace --log-file ./log/v4_trace.log ./v4.out
	sudo nvprof --metrics all --log-file ./log/v4_metrics.log ./v4.out
	sudo nvprof --events all --log-file ./log/v4_events.log ./v4.out
