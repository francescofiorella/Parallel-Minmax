# Profiling

## GPU Profiling

### Summary mode

> sudo nvprof --log-file ./log/summary.log ./nim.out

### Trace mode

> sudo nvprof --print-gpu-trace --log-file ./log/trace.log ./nim.out

### Event/metric summary mode

> sudo nvprof --metrics all --log-file ./log/metric.log ./nim.out

### Event/metric mode

> sudo nvprof --log-file event_metric.log ./nim.out

## CPU Profiling
