# Profiling

## GPU Profiling

### Summary mode

> sudo nvprof --log-file ./log/summary.log ./nim.out

### Trace mode

> sudo nvprof --print-gpu-trace --log-file ./log/trace.log ./nim.out

### Metric mode

> sudo nvprof --metrics all --log-file ./log/metrics.log ./nim.out

### Event mode

> sudo nvprof --events all --log-file ./log/events.log ./nim.out

## CPU Profiling


## Utils

To perform long-lasting operations:

> sudo -s
> 
> echo N > /sys/kernel/debug/gpu.0/timeouts_enabled

To re-enable the timeout:

> sudo -s
> 
> echo Y > /sys/kernel/debug/gpu.0/timeouts_enabled